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
const UniswapV2Helper = artifacts.require("UniswapV2Helper");
const ERC20 = artifacts.require("ERC20");
const Dai = artifacts.require("Dai");

/// Global variable
let glmStakePool;
let glmToken;
let golemFarmingLPToken;
let golemGovernanceToken;
let uniswapV2Helper;
let dai;


/// Deployed address
let UNISWAP_V2_ROUTER_02 = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Router02"]; /// [Note]: common contract address on mainnet and testnet
let UNISWAP_V2_FACTORY = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Factory"];   /// [Note]: common contract address on mainnet and testnet
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
            const _uniswapV2Factory = UNISWAP_V2_FACTORY;
            const _uniswapV2Router02 = UNISWAP_V2_ROUTER_02;

            glmStakePool = await GLMStakePool.new(_glmToken, 
                                                  _golemFarmingLPToken, 
                                                  _golemGovernanceToken, 
                                                  _uniswapV2Factory, 
                                                  _uniswapV2Router02,
                                                  { from: accounts[0] });
        });

        it("Setup DAI contract instance", async () => {
            dai = await Dai.at(DAI_ADDRESS);
        });

        it("Setup UniswapV2Helper contract instance", async () => {
            uniswapV2Helper = await UniswapV2Helper.new(UNISWAP_V2_FACTORY, UNISWAP_V2_ROUTER_02, { from: accounts[0] });
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
            console.log('===  ETH Balance of user1 ===', ethBalance);  /// [Result]: "100"         
        });

        it("Swap ETH for DAI on Uniswap-V2", async () => {
            /// [Todo]: Swap ETH for DAI
            const erc20 = DAI_ADDRESS;
            const erc20Amount = web3.utils.toWei('100', 'ether');  /// 100 DAI
            const ethAmount = web3.utils.toWei('1', 'ether');      /// 1 ETH
            uniswapV2Helper.convertEthToERC20(erc20, erc20Amount, { from: user1, value: ethAmount });

            /// Check DAI balance
            let _daiBalance = await dai.balanceOf(user1, { from: user1 });
            let daiBalance = parseFloat(web3.utils.fromWei(_daiBalance));
            assert.equal(
                daiBalance,
                100,
                "DAI Balance of user1 should be 100 DAI"
            );
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
