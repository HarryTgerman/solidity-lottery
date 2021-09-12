require("dotenv");
const { assert, should } = require("chai");
const networkParams = require("../helpers.js");
const chai = require("chai")
chai.use(require("chai-as-promised"))

const expect = chai.expect

const Lottery = artifacts.require("Lottery");


export const EVM_REVERT = 'VM Exception while processing transaction: revert'



contract('Lottery', accounts => {
    let admin = accounts[0];
    let user1 = accounts[1]
    let lottery;
    const entranceFee = 100;
    const entranceFeeInUSD = process.env.FEEINETH;
    const usdPriceFeed = networkParams[999].PRICEFEED;
    const vrfCoordinator = networkParams[999].VRFCOORDINATOR;
    const link = networkParams[999].LINK;
    const fee = networkParams[999].FEE;
    const keyHash = networkParams[999].KEYHASH

    beforeEach(async () => {
        lottery = await Lottery.new(entranceFee, usdPriceFeed, vrfCoordinator, link, fee, keyHash)
    })


    describe('Enter Lottery', () => {
        it('Enter Lottery success', async () => {
            await lottery.enter({ from: user1, value: 0.1 });
            let result = lottery.players[0];
            result.toString().should.equal(user1.toString())
        })

        it('Enter Lottery fail', async () => {
            await lottery.enter({ from: user1, value: 0.00000000001 }).should.be.rejectedWith(EVM_REVERT);
        })
    })

    describe('Start Lottery', () => {

        it('Start Lottery success', async () => {
            await lottery.startLottery({ from: admin });
            await lottery.lottery_state.call().should.equal(0)
        })

        it('Start Lottery fail', async () => {
            await lottery.startLottery({ from: user1 }).should.be.rejectedWith(EVM_REVERT);
            await lottery.lottery_state.call().should.equal(1)
        })
    })


    describe('end Lottery', () => {
        it('Start Lottery success', async () => {
            await lottery.endLottery({ from: admin });
            await lottery.lottery_state.call().should.equal(2)
        })

        it('Start Lottery fail', async () => {
            await lottery.startLottery({ from: user1 }).should.be.rejectedWith(EVM_REVERT);
            await lottery.lottery_state.call().should.equal(1)
        })
    })

})