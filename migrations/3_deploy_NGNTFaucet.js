const NGNTFaucet = artifacts.require("NGNTFaucet");
const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");

module.exports = async function(deployer) {
    await deployer.deploy(NGNTFaucet);
    
    /// Execute setNGNT() method of NGNTFaucet.sol
    const nGNTFaucet = await NGNTFaucet.deployed();
    await nGNTFaucet.setNGNT(NewGolemNetworkToken.address);
    console.log("=== Success to execute setNGNT() ===");

    /// Testing for the GLM fancet
    //await nGNTFaucet.create();  /// [Note]: GLM tokens are minted for msg.sender (onlyOwner)
};
