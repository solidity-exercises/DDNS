const DDNS = artifacts.require("../contracts/DDNS.sol");
const DomainLib = artifacts.require("../contracts/libs/DomainLib.sol");
const Destructible = artifacts.require("../contracts/common/Destructible.sol");

module.exports = (deployer) => {
	deployer.deploy(Destructible);
	deployer.deploy(DomainLib);
	deployer.link(DomainLib, DDNS);
	deployer.deploy(DDNS);
};