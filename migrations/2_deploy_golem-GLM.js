const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");

require('dotenv').config();

/// Get chain ID on the local
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
const _networkId = web3.eth.net.getId();

const _migrationAgent = process.env.WALLET_ADDRESS_2;
const _chainId = web3.eth.getChainId();

module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(NewGolemNetworkToken, _migrationAgent, _chainId);

    /// Test mint
    const GLMToken = await NewGolemNetworkToken.deployed();
    await GLMToken.mint(accounts[0], 100);  /// [Error]: "MinterRole: caller does not have the Minter role.""
};
