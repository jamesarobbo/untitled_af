// var Hello = artifacts.require ("Hello.sol");
var Crowdfund = artifacts.require ("Crowdfund.sol");

module.exports = function (deployer) {
  // deployer.deploy (Hello);
  deployer.deploy (Crowdfund);
};