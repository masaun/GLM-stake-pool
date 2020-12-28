/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// My contract
const NewGolemNetworkToken = artifacts.require("NewGolemNetworkToken");
const NGNTFaucet = artifacts.require("NGNTFaucet");


/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/golem/NGNTFaucet.test.js
 **/
contract("NGNTFaucet", function(accounts) {
    /***
     * @notice - Global variable
     **/
    let GLMToken;
    let nGNTFaucet;
    let GLM_TOKEN;       /// Contract address of GLMToken
    let migrationAgent;  /// [Note]: This wallet address will become "Minter Role" for GLM tokens (in the NewGolemNetworkToken.sol)
    let chainId;

    console.log("=== accounts ===\n", accounts);


    /***
     * @notice - Setup
     **/
    describe("Setup", () => {
        it('Setup NewGolemNetworkToken contract instance', async () => {
            //migrationAgent = accounts[0];
            migrationAgent = accounts[1];
            chainId = await web3.eth.getChainId();  /// e.g). 1337
            console.log('=== chainId ===', chainId, typeof chainId);

            /// Deploy the NewGolemNetworkToken contract
            GLMToken = await NewGolemNetworkToken.new(migrationAgent, chainId, { from: accounts[0] });
        });

        it('Setup NGNTFaucet contract instance', async () => {           
            /// Deploy the NGNTFaucet contract
            nGNTFaucet = await NGNTFaucet.new({ from: accounts[0] });
        });
    });

    /***
     * @notice - Fancet GLM tokens
     **/
    describe("Fancet GLM tokens", () => {
        it('setNGNT', async () => {
            GLM_TOKEN = NewGolemNetworkToken.address;
            await nGNTFaucet.setNGNT(GLM_TOKEN, { from: accounts[0] });
        });

        it('create', async () => {
            /// Give "Minter" role for accounts[0]
            await GLMToken.addMinter(accounts[0], { from: accounts[1] });
            //await GLMToken.renounceMinter({ from: accounts[0] });
            const isMinter0 = await GLMToken.isMinter(accounts[0]);
            const isMinter1 = await GLMToken.isMinter(accounts[1]);
            console.log("=== isMinter() for accounts[0] ===", isMinter0);  /// [Result]: true
            console.log("=== isMinter() for accounts[1] ===", isMinter1);  /// [Result]: true

            /// [Error]: revert MinterRole: caller does not have the Minter role 
            ///          -- Reason given: MinterRole: caller does not have the Minter role.
            await nGNTFaucet.create({ from: accounts[0] });
            //await nGNTFaucet.create({ from: accounts[1] });
        });
    });

});
