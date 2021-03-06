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

    if (network == 'local' || network == 'test') {
        _migrationAgent = accounts[1];
        _chainId = await web3.eth.getChainId();
    } else if (network == 'rinkeby') {
        _migrationAgent = accounts[1];
        _chainId = 4;   /// Rinkeby's network ID
    }

    await deployer.deploy(NewGolemNetworkToken, _migrationAgent, _chainId);

    const GLMToken = await NewGolemNetworkToken.deployed();
    const isMinter0 = await GLMToken.isMinter(accounts[0]);
    const isMinter1 = await GLMToken.isMinter(accounts[1]);
    console.log("=== isMinter() for accounts[0] ===", isMinter0);  /// [Result]: false
    console.log("=== isMinter() for accounts[1] ===", isMinter1);  /// [Result]: true

};
