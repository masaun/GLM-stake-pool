const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(GolemGovernanceToken);
};
