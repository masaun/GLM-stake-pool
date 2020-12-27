const NGNTFaucet = artifacts.require("NGNTFaucet");
const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(NGNTFaucet);
    
    /// Execute setNGNT() method of NGNTFaucet.sol
    const nGNTFaucet = await NGNTFaucet.deployed();
    await nGNTFaucet.setNGNT(NewGolemNetworkToken.address);
    console.log("=== Success to execute setNGNT() ===");

    /// Add "Minter-Role"
    const GLMToken = await NewGolemNetworkToken.deployed();
    await GLMToken.addMinter(accounts[0], { from: accounts[1] });

    /// Check whether "Minter-Role" is true/false
    const isMinter0 = await GLMToken.isMinter(accounts[0]);
    const isMinter1 = await GLMToken.isMinter(accounts[1]);
    console.log("=== isMinter() for accounts[0] ===", isMinter0);  /// [Result]: false
    console.log("=== isMinter() for accounts[1] ===", isMinter1);  /// [Result]: true

    /// Testing for the GLM fancet
    await nGNTFaucet.create();  /// [Note]: GLM tokens are minted for msg.sender (onlyOwner)
};
