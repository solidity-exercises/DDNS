const DDNS = artifacts.require("DDNS");

module.exports = (deployer) => {
	deployer.deploy(DDNS);
};