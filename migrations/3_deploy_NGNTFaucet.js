const NGNTFaucet = artifacts.require("NGNTFaucet");

module.exports = async function(deployer) {
    await deployer.deploy(NGNTFaucet);
};
