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
const UniswapV2Factory = artifacts.require("IUniswapV2Factory");
const UniswapV2Pair = artifacts.require("IUniswapV2Pair");
const UniswapV2ERC20 = artifacts.require("IUniswapV2ERC20");
const UniswapV2Router02 = artifacts.require("IUniswapV2Router02");
const UniswapV2Helper = artifacts.require("UniswapV2Helper");
const IERC20 = artifacts.require("IERC20");

/// Global variable
let glmStakePool;
let glmToken;
let golemFarmingLPToken;
let golemGovernanceToken;
let uniswapV2Factory;
let uniswapV2Router02;
let uniswapV2Helper;
let wETH;
let dai;

/// Deployed address
let GLM_STAKE_POOL;
let GLM_TOKEN;
let GOLEM_FARMING_LP_TOKEN;
let PAIR_GLM_ERC20;
let PAIR_GLM_ETH;
let WETH_TOKEN;
let UNISWAP_V2_ROUTER_02 = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Router02"]; /// [Note]: common contract address on mainnet and testnet
let UNISWAP_V2_FACTORY = contractAddressList["Mainnet"]["Uniswap"]["UniswapV2Factory"];   /// [Note]: common contract address on mainnet and testnet
let DAI_TOKEN = tokenAddressList["Mainnet"]["DAI"];  /// DAI on Mainnet;


/***
 * @dev - Execution COMMAND: $ truffle test ./test/test-local/GLMStakePool.test.js
 **/
contract("GLMStakePool", function(accounts) {

    const deployer = accounts[0];
    const user1 = accounts[1];
    const user2 = accounts[2];

    describe("Setup", () => {
        it("Check all accounts", async () => {
            console.log('\n=== accounts ===\n', accounts);
        });        

        it("Setup GLMToken contract instance (by using GLMMockToken)", async () => {
            glmToken = await GLMMockToken.new({ from: accounts[0] });
            GLM_TOKEN = glmToken.address;
        });

        it("Mint 100000 GLMToken to user1", async () => {
            const mintAmount = web3.utils.toWei('100000', 'ether');     /// 100000 GLM
            await glmToken.mint(user1, mintAmount, { from: user1 });
            
            let _glmBalance = await glmToken.balanceOf(user1, { from: user1 });
            let glmBalance = parseFloat(web3.utils.fromWei(_glmBalance));
            console.log('\n=== GLM balance of user1 ===', glmBalance);  /// [Result]: 100000 GLM
        });

        it("Setup GolemFarmingLPToken contract instance", async () => {
            golemFarmingLPToken = await GolemFarmingLPToken.new({ from: accounts[0] });
            GOLEM_FARMING_LP_TOKEN = golemFarmingLPToken.address;
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

            GLM_STAKE_POOL = glmStakePool.address;
        });

        it("Setup UniswapV2Factory contract instance", async () => {
            uniswapV2Factory = await UniswapV2Factory.at(UNISWAP_V2_FACTORY, { from: accounts[0] });
        });

        it("Setup UniswapV2Router02 contract instance", async () => {
            uniswapV2Router02 = await UniswapV2Router02.at(UNISWAP_V2_ROUTER_02, { from: accounts[0] });
        });

        it("Setup UniswapV2Helper contract instance", async () => {
            uniswapV2Helper = await UniswapV2Helper.new(UNISWAP_V2_FACTORY, UNISWAP_V2_ROUTER_02, { from: accounts[0] });
        });

        it("Setup WETH contract instance", async () => {
            WETH_TOKEN = await uniswapV2Router02.WETH();
            console.log('\n=== WETH_TOKEN ===', WETH_TOKEN);
        });

        it("Setup DAI contract instance", async () => {
            dai = await IERC20.at(DAI_TOKEN, { from: accounts[0] });
        });
    });

    describe("Swap on Uniswap-V2", () => {
        it("Get initial DAI balance of user1", async () => {
            let _daiBalance = await dai.balanceOf(user1, { from: user1 });
            let daiBalance = parseFloat(web3.utils.fromWei(_daiBalance));
            console.log('\n===  DAI Balance of user1 ===', daiBalance);  /// [Result]: "0"         
        });

       it("Get initial ETH balance of user1", async () => {
            let ethBalance = await web3.eth.getBalance(user1);
            console.log('\n===  ETH Balance of user1 ===', ethBalance);  /// [Result]: "100"         
        });

        it("Swap ETH for DAI on Uniswap-V2", async () => {
            /// [Todo]: Swap ETH for DAI
            const erc20 = DAI_TOKEN;
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
            const erc20 = DAI_TOKEN;  /// DAI on Mainnet
            let pair = await glmStakePool.createPairWithERC20(erc20, { from: user1 });

            /// Get created pair address
            PAIR_GLM_ERC20 = await uniswapV2Factory.getPair(GLM_TOKEN, DAI_TOKEN, { from: user1 });
            console.log('\n=== pair (GLM-ERC20)===', PAIR_GLM_ERC20);
        });

        it("Create a pair (LP token) between the GLM tokens and ETH", async () => {
            let pair = await glmStakePool.createPairWithETH({ from: user1 });

            /// Get created pair address
            PAIR_GLM_ETH = await uniswapV2Factory.getPair(GLM_TOKEN, WETH_TOKEN, { from: user1 });            
            console.log('\n=== pair (GLM-ETH) ===', PAIR_GLM_ETH);
        }); 
    });

    describe("Add liquidity GLM tokens with ETH or ERC20 tokens", () => {
        it("Add liquidity GLM tokens with ERC20", async () => {
            /// [Todo]: addLiquidityWithERC20()
        });

        it("Add liquidity GLM tokens with ETH", async () => {
            /// [Note]: Exchange rate is "5 GLM per 0.1 ETH"
            const GLMTokenAmountDesired = web3.utils.toWei('500', 'ether');   /// 500 GLM
            const ETHAmountMin = `${ 1 * 1e19 }`;  /// 10 ETH
            await glmToken.approve(GLM_STAKE_POOL, GLMTokenAmountDesired, { from: user1 });  /// Approve GLM tokens
            await glmToken.approve(UNISWAP_V2_ROUTER_02, GLMTokenAmountDesired, { from: user1 });  /// Approve GLM tokens

            /// [Note]: Using addLiquidityETH() method of the UniswapV2Router02 directly.
            const GLMTokenMin = GLMTokenAmountDesired;
            const now = Math.floor(new Date().getTime() / 1000);
            const deadline = now + 18000;  /// [Note]: Current timestamp + 300 seconds
            await uniswapV2Router02.addLiquidityETH(GLM_TOKEN, 
                                                    GLMTokenAmountDesired, 
                                                    GLMTokenMin, 
                                                    ETHAmountMin, 
                                                    user1, 
                                                    deadline, 
                                                    { from: user1, value: ETHAmountMin });
            //await glmStakePool.addLiquidityWithETH(PAIR_GLM_ETH, GLMTokenAmountDesired, { from: user1, value: ETHAmountMin });
        });

        it("Check a pair (GLM-ETH) balance", async () => {
            const uniswapV2Pair = await UniswapV2Pair.at(PAIR_GLM_ETH, { from: user1 });
            let _pairBalance = await uniswapV2Pair.balanceOf(user1, { from: user1 });
            let pairBalance = parseFloat(web3.utils.fromWei(_pairBalance));
            console.log(`\n=== pair (GLM-ETH) balance of user1 (after addLiquidityETH): ${ pairBalance } UNI-V2 (GLM-ETH) ===`);

            // assert.equal();
        });
    });

    describe("Stake UNI-LP tokens (GLM/ERC20 or GLM/ETH)", () => {
        let STAKED_UNI_LP_TOKENS_AMOUNT;

        it("Stake UNI-LP tokens (GLM/ERC20)", async () => {
            /// [Todo]: Add code next time
        });

        it("Stake UNI-LP tokens (GLM/ETH)", async () => {
            const uniswapV2Pair = await UniswapV2Pair.at(PAIR_GLM_ETH, { from: user1 });

            const lpTokenAmount = web3.utils.toWei(`${ 5 * 1e17 }`, 'wei');  /// 0.5 that is amount of LP token (GLM/ETH)
            await uniswapV2Pair.approve(GLM_STAKE_POOL, lpTokenAmount, { from: user1 });
            await glmStakePool.stakeLPToken(PAIR_GLM_ETH, lpTokenAmount, { from: user1 });

            STAKED_UNI_LP_TOKENS_AMOUNT = parseFloat(web3.utils.fromWei(lpTokenAmount));
        });

        it("Check the Golem Farming LP Token balance (after user1 stake UNI-LP tokens)", async () => {
            let _golemFarmingLPTokenBalance = await golemFarmingLPToken.balanceOf(user1, { from: user1 });
            let golemFarmingLPTokenBalance = parseFloat(web3.utils.fromWei(_golemFarmingLPTokenBalance));
            console.log(`\n=== Golem Farming LP Token balance of user1: ${ golemFarmingLPTokenBalance } GFLP ===`);

            assert.equal(
                golemFarmingLPTokenBalance,
                STAKED_UNI_LP_TOKENS_AMOUNT,
                "Golem Farming LP Token balance of user1 should be 0.5"
            );
        });        
    });

    describe("Update pool status weekly (every week)", () => {
        it("Pool status should be updated", async () => {
            await glmStakePool.weeklyPoolStatusUpdate({ from: user1 });
        });
    });

    describe("Withdraw only earned rewards", () => {
        it("Check reserves of staked UNI-LP tokens (GLM-ETH)", async () => {
            const uniswapV2Pair = await UniswapV2Pair.at(PAIR_GLM_ETH, { from: user1 });

            const _totalSupply = await uniswapV2Pair.totalSupply();            
            const totalSupply = parseFloat(web3.utils.fromWei(`${ _totalSupply }`));
            console.log(`\n=== totalSupply: ${ totalSupply } UNI-V2 (GLM-ETH) ===`);

            const reserves = await uniswapV2Pair.getReserves({ from: user1 }); /// [Note]: Returned value is array
            const _reserve0 = reserves[0];
            const _reserve1 = reserves[1];
            const _blockTimestampLast = reserves[2];

            const reserve0 = parseFloat(web3.utils.fromWei(_reserve0));
            const reserve1 = parseFloat(web3.utils.fromWei(_reserve1));
            const blockTimestampLast = parseFloat(web3.utils.fromWei(_blockTimestampLast));
            console.log(`\n=== reserve0: ${ reserve0 } GLM ===`);
            console.log(`\n=== reserve1: ${ reserve1 } ETH ===`);
            console.log('=== blockTimestampLast ===', blockTimestampLast);
        });

        it("Check the total staked LPToken amount", async () => {
            let _totalStakedLPTokenAmount = await glmStakePool.getTotalStakedLPTokenAmount({ from: user1 });
            let totalStakedLPTokenAmount = parseFloat(web3.utils.fromWei(_totalStakedLPTokenAmount));
            console.log(`\n=== totalStakedLPTokenAmount: ${ totalStakedLPTokenAmount } UNI-V2 (GLM-ETH) ===`);
        });

        it("Check the total individual staked LPToken amount", async () => {
            const stakeId = 1;
            let _totalIndividualStakedLPTokenAmount = await glmStakePool.getTotalIndividualStakedLPTokenAmount(stakeId, { from: user1 });
            let totalIndividualStakedLPTokenAmount = parseFloat(web3.utils.fromWei(_totalIndividualStakedLPTokenAmount));
            console.log(`\n=== totalIndividualStakedLPTokenAmount: ${ totalIndividualStakedLPTokenAmount } UNI-V2 (GLM-ETH) ===`);
        });

        it("Claim rewards (Then, user1 will receive the Golem Governance Token as rewards)", async () => {
            await glmStakePool.claimEarnedReward(PAIR_GLM_ETH, { from: user1 });
        });

        it("Check received rewards (Golem Governance Token) balance of user1", async () => {
            let _golemGovernanceTokenBalance = await golemGovernanceToken.balanceOf(user1, { from: user1 });
            let golemGovernanceTokenBalance = parseFloat(web3.utils.fromWei(_golemGovernanceTokenBalance));
            console.log(`\n=== Received rewards (Golem Governance Token) balance of user1: ${ golemGovernanceTokenBalance } GGC ===`);
        });
    });

    describe("Un-Stake UNI-LP tokens (Withdraw UNI-LP tokens with earned rewards)", () => {
        it("Stake UNI-LP tokens (GLM/ETH)", async () => {
            const uniswapV2Pair = await UniswapV2Pair.at(PAIR_GLM_ETH, { from: user1 });

            const lpTokenAmount = web3.utils.toWei(`${ 5 * 1e17 }`, 'wei');  /// 0.5 that is amount of LP token (GLM/ETH)
            await uniswapV2Pair.approve(GLM_STAKE_POOL, lpTokenAmount, { from: user1 });
            await glmStakePool.stakeLPToken(PAIR_GLM_ETH, lpTokenAmount, { from: user1 });

            STAKED_UNI_LP_TOKENS_AMOUNT = parseFloat(web3.utils.fromWei(lpTokenAmount));
        });

        it("Un-stake LP tokens (GLM/ETH) with earned rewards (Golem Governance Token)", async () => {
            const unStakedLpTokenAmount = web3.utils.toWei(`${ 5 * 1e17 }`, 'wei');  /// 0.5
            await glmStakePool.unStakeLPToken(PAIR_GLM_ETH, unStakedLpTokenAmount, { from: user1 });
        });

        it("Check received rewards (Golem Governance Token) balance and un-staked UNI-LP tokens of user1", async () => {
            let _golemGovernanceTokenBalance = await golemGovernanceToken.balanceOf(user1, { from: user1 });
            let golemGovernanceTokenBalance = parseFloat(web3.utils.fromWei(_golemGovernanceTokenBalance));
            console.log(`\n=== Received rewards (Golem Governance Token) balance of user1: ${ golemGovernanceTokenBalance } GGC ===`);

            const uniswapV2Pair = await UniswapV2Pair.at(PAIR_GLM_ETH, { from: user1 });
            let _pairBalance = await uniswapV2Pair.balanceOf(user1, { from: user1 });
            let pairBalance = parseFloat(web3.utils.fromWei(_pairBalance));
            console.log(`\n=== pair (GLM-ETH) balance of user1: ${ pairBalance } UNI-V2 (GLM-ETH) ===`);
        });
    });


});
