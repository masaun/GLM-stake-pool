const GolemFarmingLPToken = artifacts.require("GolemFarmingLPToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(GolemFarmingLPToken);
};
