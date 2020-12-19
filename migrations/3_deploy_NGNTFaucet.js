const NGNTFaucet = artifacts.require("NGNTFaucet");

module.exports = async function(deployer) {
    await deployer.deploy(NGNTFaucet);
    
    /// Execute setNGNT() method of NGNTFaucet.sol
    const nGNTFaucet = await NGNTFaucet.deployed();
    await nGNTFaucet.setNGNT(nGNTFaucet.address);
};
