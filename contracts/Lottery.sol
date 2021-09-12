// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase {
    address payable[] public players;
    uint256 usdEntryFee;
    address owner;
    address payable public recentWinner;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomness;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;
    AggregatorV3Interface internal priceFeed;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(
        uint256 _usdEntryFee,
        address usdPriceFeed,
        address _vrfCoordinator,
        address _link,
        uint256 _fee,
        bytes32 _keyHash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        owner = msg.sender;
        usdEntryFee = _usdEntryFee;
        priceFeed = AggregatorV3Interface(usdPriceFeed);
        lottery_state = LOTTERY_STATE.CLOSED;
        fee = _fee;
        keyHash = _keyHash;
    }

    function enter() public payable {
        // 50$ minimum
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value > getEntranceFee(), "Not enough ETH");
        players.push(msg.sender);
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10**10; // 18 decimals
        uint256 costToEnter = (usdEntryFee * 10**18) / adjustedPrice;
        return costToEnter;
    }

    function startLottery() public onlyOwner {
        require(
            lottery_state == LOTTERY_STATE.CLOSED,
            "Lottery already started"
        );
        lottery_state = LOTTERY_STATE.OPEN;
    }

    function endLottery() public onlyOwner returns (bytes32 requestId) {
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        return requestId = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER,
            "not calculating winner"
        );
        require(_randomness > 0, "Random not found");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);
        // Reset
        players = new address payable[](0);
        lottery_state = LOTTERY_STATE.CLOSED;
        randomness = _randomness;
    }
}
