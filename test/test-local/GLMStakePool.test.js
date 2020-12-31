/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// Artifact of the GLMStakePool contract 
const GLMStakePool = artifacts.require("GLMStakePool");
const GLMMockToken = artifacts.require("GLMMockToken");
const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");

/// Global variable
let glmStakePool;
let glmToken;
let glmGovernanceToken;

/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/GLMStakePool.test.js
 **/
contract("GLMStakePool", function(accounts) {

    describe("Setup", () => {
        it("Check all accounts", async () => {
            console.log('=== accounts ===\n', accounts);
        });        

        it("Setup GLMMockToken contract instance", async () => {
            glmToken = await GLMMockToken.new({ from: accounts[0] });
        });

        it("Setup GLMMockToken contract instance", async () => {
            glmGovernanceToken = await GolemGovernanceToken.new({ from: accounts[0] });
        });

        // it("Setup GLMStakePool contract instance", async () => {
        //     const _oceanFarmingToken = oceanFarmingToken.address;
        //     const _oceanGovernanceToken = oceanGovernanceToken.address;
        //     const _oceanGovernanceTokenPerBlock = 1000;
        //     const _startBlock = 0;
        //     const _endBlock = 1000;

        //     glmStakePool = await GLMStakePool.new({ from: accounts[0] });
        // });
    });

    describe("GLMStakePool", () => {

    });

});
