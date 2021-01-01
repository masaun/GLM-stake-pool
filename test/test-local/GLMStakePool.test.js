/// Using local network
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));

//@dev - Import from exported file
const contractAddressList = require('../../migrations/addressesList/contractAddress/contractAddress.js');
const tokenAddressList = require('../../migrations/addressesList/tokenAddress/tokenAddress.js');

/// Artifact of the GLMStakePool contract 
const GLMStakePool = artifacts.require("GLMStakePool");
const GLMMockToken = artifacts.require("GLMMockToken");
const GolemFarmingLPToken = artifacts.require("GolemFarmingLPToken");
const GolemGovernanceToken = artifacts.require("GolemGovernanceToken");
const ERC20 = artifacts.require("ERC20");

/// Global variable
let glmStakePool;
let glmToken;
let golemFarmingLPToken;
let golemGovernanceToken;
let dai;

/// Deployed address
let DAI_ADDRESS = tokenAddressList["Mainnet"]["DAI"];  /// DAI on Mainnet;



/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/GLMStakePool.test.js
 **/
contract("GLMStakePool", function(accounts) {

    const deployer = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];

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
            const _uniswapV2Factory = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Factory"];   /// [Note]: common contract address on mainnet and testnet
            const _uniswapV2Router02 = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Router02"]; /// [Note]: common contract address on mainnet and testnet

            glmStakePool = await GLMStakePool.new(_glmToken, 
                                                  _golemFarmingLPToken, 
                                                  _golemGovernanceToken, 
                                                  _uniswapV2Factory, 
                                                  _uniswapV2Router02,
                                                  { from: accounts[0] });
        });

        it("Setup DAI contract instance", async () => {
            dai = await ERC20.new(DAI_ADDRESS, { from: accounts[0] });
        });
    });

    describe("Swap on Uniswap-V2", () => {
        it("Get initial DAI balance of user1", async () => {
            let _daiBalance = await dai.balanceOf(user1, { from: user1 });
            let daiBalance = parseFloat(web3.utils.fromWei(_daiBalance));
            console.log('===  DAI Balance of user1 ===', daiBalance);  /// [Result]: "0"         
        });

       it("Get initial ETH balance of user1", async () => {
            let ethBalance = await web3.eth.getBalance(user1);
            //let _ethBalance = await web3.eth.getBalance(user1, { from: user1 });
            //let ethBalance = parseFloat(web3.utils.fromWei(_ethBalance));
            console.log('===  ETH Balance of user1 ===', ethBalance);  /// [Result]: "100"         
        });

        it("Swap ETH for DAI on Uniswap-V2", async () => {
            /// [Todo]
        });
    });

    describe("Create a pair (LP token)", () => {
        it("Create a pair (LP token) between the GLM tokens and another ERC20 tokens", async () => {
            const erc20 = DAI_ADDRESS;  /// DAI on Mainnet
            let res = await glmStakePool.createPairWithERC20(erc20, { from: user1 });
            console.log('=== res ===', res);
        });           
    });

});
