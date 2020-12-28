/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// Artifact of the GLMMockToken contract 
const GLMMockToken = artifacts.require("GLMMockToken");

/// Global variable
let GLMToken;


/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/GLMMockToken/GLMMockToken.test.js
 **/
contract("GLMMockToken", function(accounts) {

    describe("Setup", () => {
        it("Check all accounts", async () => {
            console.log('=== accounts ===\n', accounts);
        });        

        it("Setup GLMMockToken contract instance", async () => {
            GLMToken = await GLMMockToken.new({ from: accounts[0] });
        });
    });

    describe("Mint", () => {
        it('Mint GLMMockToken', async () => {
            await GLMToken.mint(accounts[1], web3.utils.toWei("1000000", "ether"), { from: accounts[0] });
            
            assert.equal(
                await GLMToken.balanceOf(accounts[1]), 
                web3.utils.toWei("1000000", "ether"), 
                "Balance of accounts[1] should be 1000000 GLM"
            );

            console.log('=== Balance of accounts[1] ===\n', await GLMToken.balanceOf(accounts[1]));
        });
    });

});
