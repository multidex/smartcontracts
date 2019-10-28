/* globals artifacts */
const TradeAccount = artifacts.require("TradeAccount");

// dummy owner, replace with real wallet/owner
const kyberProxyContract = "0x818E6FECD516Ecc3849DAf6845e3EC868087B755";
const oracleAddress = "0xc99B3D447826532722E41bc36e644ba3479E4365";
const oracleJobId = "76ca51361e4e444f8a9b18ae350a5725";

module.exports = function(deployer) {
  deployer.deploy(TradeAccount, kyberProxyContract, oracleAddress, oracleJobId);
};
