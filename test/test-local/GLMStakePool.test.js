/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

/// Artifact of the GLMStakePool contract 
const GLMStakePool = artifacts.require("GLMStakePool");
const GLMMockToken = artifacts.require("GLMMockToken");
const GolemFarmingLPToken = artifacts.require("GolemFarmingLPToken");
const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");

/// Global variable
let glmStakePool;
let glmToken;
let golemFarmingLPToken;
let golemGovernanceToken;

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

        it("Setup GolemFarmingLPToken contract instance", async () => {
            golemFarmingLPToken = await GolemFarmingLPToken.new({ from: accounts[0] });
        });

        it("Setup GolemGovernanceToken contract instance", async () => {
            golemGovernanceToken = await GolemGovernanceToken.new({ from: accounts[0] });
        });

        it("Setup GLMStakePool contract instance", async () => {
            const _glmToken = glmToken.address;
            const _golemFarmingLPToken = golemFarmingLPToken.address;
            const _golemGovernanceToken = golemGovernanceToken.address;
            const _uniswapV2Factory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";   /// [Note]: common contract address on mainnet and testnet
            const _uniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";  /// [Note]: common contract address on mainnet and testnet

            glmStakePool = await GLMStakePool.new(_glmToken, 
                                                  _golemFarmingLPToken, 
                                                  _golemGovernanceToken, 
                                                  _uniswapV2Factory, 
                                                  _uniswapV2Router02,
                                                  { from: accounts[0] });
        });
    });

    describe("GLMStakePool", () => {

    });

});
