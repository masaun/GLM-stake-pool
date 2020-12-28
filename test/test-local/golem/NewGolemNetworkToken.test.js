/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// My contract
const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");


/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/golem/NewGolemNetworkToken.test.js
 **/
contract("NewGolemNetworkToken", function(accounts) {
    /***
     * @notice - Global variable
     **/
    let GLMToken;
    let migrationAgent;  /// [Note]: This wallet address will become "Minter Role" for GLM tokens (in the NewGolemNetworkToken.sol)
    let chainId;

    /***
     * @notice - Setup
     **/
    describe("Setup", () => {
        it('Setup NewGolemNetworkToken contract instance', async () => {
            //migrationAgent = accounts[0];
            migrationAgent = accounts[1];
            chainId = await web3.eth.getChainId();  /// e.g). 1337
            console.log('=== chainId ===', chainId, typeof chainId);

            // Get the contract instance.
            GLMToken = await NewGolemNetworkToken.new(migrationAgent, chainId, { from: accounts[0] });
            //console.log('=== GLMToken contract instance ===', GLMToken);
        });

    });
});
