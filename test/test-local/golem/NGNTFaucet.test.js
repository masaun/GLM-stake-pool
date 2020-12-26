/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// My contract
const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");
const NGNTFaucet = artifacts.require("NGNTFaucet");

/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/golem/NGNTFaucet.test.js
 **/
contract("NewGolemNetworkToken", function(accounts) {
    /***
     * @notice - Global variable
     **/
    let GLMToken;
    let nGNTFaucet;
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
        });

        it('Setup NGNTFaucet contract instance', async () => {           
            // Get the contract instance.
            nGNTFaucet = await NGNTFaucet.new({ from: accounts[0] });
        });
    });

    /***
     * @notice - Fancet GLM tokens
     **/
    describe("Fancet GLM tokens", () => {
        it('setNGNT', async () => {
            const _token = NewGolemNetworkToken.address;
            NGNTFaucet = await nGNTFaucet.setNGNT(_token, { from: accounts[0] });
        });

        it('create', async () => {
            NGNTFaucet = await nGNTFaucet.create({ from: accounts[0] });
        });
    });

});
