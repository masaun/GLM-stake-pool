const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");

require('dotenv').config();

/// Get chain ID on the local
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
const _networkId = web3.eth.net.getId();

let _migrationAgent;  /// [Note]: This wallet address will become "Minter Role" for GLM tokens (in the NewGolemNetworkToken.sol)
let _chainId;

module.exports = async function(deployer, network, accounts) {

    console.log('=== network ===', network);
    console.log('=== accounts[0] ===', accounts[0]);

    if (network == 'local') {
        _migrationAgent = accounts[0];
        _chainId = web3.eth.getChainId();
    } else if (network == 'rinkeby') {
        _migrationAgent = accounts[0];
        _chainId = 4;   /// Rinkeby's network ID
    }

    await deployer.deploy(NewGolemNetworkToken, _migrationAgent, _chainId);
};
