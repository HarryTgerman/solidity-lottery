const Lottery = artifacts.require("Lottery");
const { networkParams } = require("../helpers.js");




module.exports = function (deployer) {

  const usdPriceFeed = networkParams[999].PRICEFEED;
  const vrfCoordinator = networkParams[999].VRFCOORDINATOR;
  const link = networkParams[999].LINK;
  const fee = networkParams[999].FEE;
  const keyHash = networkParams[999].KEYHASH

  deployer.deploy(Lottery, 100, usdPriceFeed, vrfCoordinator, link, fee, keyHash);
};
