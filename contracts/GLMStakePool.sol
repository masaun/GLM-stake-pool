pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GLMStakePoolStorages } from "./glm-stake-pool/commons/GLMStakePoolStorages.sol";

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// GLM Token
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";
import { GLMMockToken } from "./GLMMockToken/GLMMockToken.sol";  /// [Note]: This is mock token of the NewGolemNetworkToken (GLM token)

/// GLM Pool Token
import { GolemFarmingLPToken } from "./GolemFarmingLPToken.sol";

/// Golem Governance Token
import { GolemGovernanceToken } from "./GolemGovernanceToken.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";


contract GLMStakePool is GLMStakePoolStorages {
    using SafeMath for uint;

    //NewGolemNetworkToken public GLMToken;
    GLMMockToken public GLMToken;  /// [Note]: This is mock token of the NewGolemNetworkToken (GLM token)
    GolemFarmingLPToken public golemFarmingLPToken;
    GolemGovernanceToken public golemGovernanceToken;
    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GLM_TOKEN;
    address GOLEM_FARMING_LP_TOKEN;
    address GOLEM_GOVERNANCE_TOKEN;
    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    uint8 public currentStakeId;

    uint totalStakedLPTokenAmount;        /// Total staked UNI-LP tokens (GLM-ETH) amount during whole period
    uint lastTotalStakedLPTokenAmount;    /// Total staked UNI-LP tokens (GLM-ETH) amount until last week
    uint weeklyTotalStakedLPTokenAmount;  /// Total staked UNI-LP tokens (GLM-ETH) amount during recent week

    uint public startBlock;
    uint public lastBlock;
    uint public nextBlock;

    /// [Note]: Current rewards rate is accept the fixed-rate that is set up by admin
    uint REWARD_RATE = 10;  /// Default fixed-rewards-rate is 10%


    constructor(
        GLMMockToken _GLMToken,             /// [Note]: Mock token of GLM token
        //NewGolemNetworkToken _GLMToken,   /// [Note]: Original GLM Token
        GolemFarmingLPToken _golemFarmingLPToken, 
        GolemGovernanceToken _golemGovernanceToken, 
        IUniswapV2Factory _uniswapV2Factory, 
        IUniswapV2Router02 _uniswapV2Router02
    ) public {
        GLMToken = _GLMToken;
        golemFarmingLPToken = _golemFarmingLPToken;
        golemGovernanceToken = _golemGovernanceToken;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;
        wETH = IWETH(uniswapV2Router02.WETH());

        GLM_TOKEN = address(_GLMToken);
        GOLEM_FARMING_LP_TOKEN = address(_golemFarmingLPToken);
        GOLEM_GOVERNANCE_TOKEN = address(_golemGovernanceToken);
        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
        WETH_TOKEN = address(uniswapV2Router02.WETH());

        startBlock = block.number;
        lastBlock = block.number;
    }


    ///---------------------------------------------------
    /// Create a pair address (of LP tokens)
    ///---------------------------------------------------

    /***
     * @notice - Create a pair (LP token) between the GLM tokens and another ERC20 tokens
     *         - e.g). GLM/DAI, GLM/USDC
     * @param erc20 - e.g). DAI, USDC, etc...
     **/
    function createPairWithERC20(IERC20 erc20) public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GLM_TOKEN, address(erc20)); 
        return IUniswapV2Pair(pair);
    }

    /***
     * @notice - Create a pair (LP token) between the GLM tokens and ETH (GLM/ETH)
     **/
    function createPairWithETH() public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GLM_TOKEN, WETH_TOKEN);  /// [Note]: WETH is treated as ETH 
        return IUniswapV2Pair(pair); 
    }


    ///------------------------------------------------------------------------------
    /// Add liquidity GLM tokens with ERC20 tokens (GLM/DAI, GLM/USDC, etc...)
    ///------------------------------------------------------------------------------

    /***
     * @notice - Add Liquidity" for a pair (LP token) between the GLM tokens and another ERC20 tokens 
     *         - e.g. GLM/DAI, GLM/USDC, etc...
     **/
    function addLiquidityWithERC20(
        IUniswapV2Pair pair,
        uint GLMTokenAmountDesired,
        uint ERC20AmountDesired
    ) public returns (bool) {
        IERC20 erc20 = IERC20(pair.token1());

        /// Transfer each sourse tokens from a user
        GLMToken.transferFrom(msg.sender, address(this), GLMTokenAmountDesired);
        erc20.transferFrom(msg.sender, address(this), ERC20AmountDesired);

        /// Check whether a pair contract exists or not
        address pairAddress = uniswapV2Factory.getPair(GLM_TOKEN, address(erc20)); 
        require (pairAddress > address(0), "This pair contract has not existed yet");

        /// Check whether liquidity of a pair contract is enough or not
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_V2_FACTORY, GLM_TOKEN, address(erc20)));
        uint totalSupply = pair.totalSupply();
        require (totalSupply > 0, "This pair's totalSupply is still 0. Please add liquidity at first");        

        /// Approve each tokens for UniswapV2Routor02
        GLMToken.approve(UNISWAP_V2_ROUTOR_02, GLMTokenAmountDesired);
        erc20.approve(UNISWAP_V2_ROUTOR_02, ERC20AmountDesired);

        /// Add liquidity and pair
        uint GLMTokenAmount;
        uint ERC20Amount;
        uint liquidity;
        (GLMTokenAmount, ERC20Amount, liquidity) = _addLiquidityWithERC20(erc20,
                                                                          GLMTokenAmountDesired,
                                                                          ERC20AmountDesired);

        /// Mint amount that is equal to staked LP tokens to a staker
        golemFarmingLPToken.mint(msg.sender, liquidity);

        /// Save stake data
        // CheckPoint storage checkPoint = checkPoints[newStakeId];
        // checkPoint.staker = msg.sender;
        // checkPoint.blockTimestamp = now;

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);
    }

    function _addLiquidityWithERC20(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        IERC20 erc20,
        uint GLMTokenAmountDesired,
        uint ERC20AmountDesired
    ) internal returns (uint _GLMTokenAmount, uint _ERC20Amount, uint _liquidity) {
        uint GLMTokenAmount;
        uint ERC20Amount;
        uint liquidity;

        /// Define each minimum amounts
        uint GLMTokenMin;
        uint ERC20AmountMin;

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ERC20Amount, liquidity) = uniswapV2Router02.addLiquidity(GLM_TOKEN,
                                                                                  address(erc20),
                                                                                  GLMTokenAmountDesired,
                                                                                  ERC20AmountDesired,
                                                                                  GLMTokenMin,
                                                                                  ERC20AmountMin,
                                                                                  to,
                                                                                  deadline);

        return (GLMTokenAmount, ERC20Amount, liquidity);
    }


    ///-------------------------------------------------------------------
    /// Add Liquidity GLM tokens with ETH (GLM/ETH)
    ///-------------------------------------------------------------------

    /***
     * @notice - Add Liquidity for a pair (LP token) between the GLM tokens and ETH (GLM/ETH)
     **/
    function addLiquidityWithETH(
        IUniswapV2Pair pair,
        uint GLMTokenAmountDesired
    ) public payable returns (bool) {
        /// Transfer GLM tokens and ETH from a user
        GLMToken.transferFrom(msg.sender, address(this), GLMTokenAmountDesired);
        uint ETHAmountMin = msg.value;

        /// Convert ETH (msg.value) to WETH (ERC20) 
        /// [Note]: Converted amountETH is equal to "msg.value"
        wETH.deposit();

        /// Approve each tokens for UniswapV2Routor02
        GLMToken.approve(UNISWAP_V2_ROUTOR_02, GLMTokenAmountDesired);
        //wETH.approve(UNISWAP_V2_ROUTOR_02, ETHAmountMin);

        /// Add liquidity and pair
        uint GLMTokenAmount;
        uint ETHAmount;
        uint liquidity;
        (GLMTokenAmount, ETHAmount, liquidity) = _addLiquidityWithETH(GLMTokenAmountDesired, ETHAmountMin);

        /// [Todo]: Refund leftover ETH to a staker (Need to identify how much leftover ETH of a staker) 
        //msg.sender.call.value(address(this).balance)("");

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);
    }

    function _addLiquidityWithETH(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        uint GLMTokenAmountDesired,
        uint ETHAmountMin
    ) internal returns (uint _GLMTokenAmount, uint _ETHAmount, uint _liquidity) {
        uint GLMTokenAmount;
        uint ETHAmount;
        uint liquidity;

        /// Define each minimum amounts
        uint GLMTokenMin = GLMTokenAmountDesired;  /// [Note]: 5 GLM will be set as the initial addLiquidity.

        address to = msg.sender;
        uint deadline = now.add(300 seconds);
        (GLMTokenAmount, ETHAmount, liquidity) = uniswapV2Router02.addLiquidityETH(GLM_TOKEN,
                                                                                   GLMTokenAmountDesired,
                                                                                   GLMTokenMin,
                                                                                   ETHAmountMin,
                                                                                   to,
                                                                                   deadline);

        return (GLMTokenAmount, ETHAmount, liquidity);
    }



    ///------------------------------------------------------------------------------
    /// Remove liquidity GLM tokens with ERC20 tokens (GLM/DAI, GLM/USDC, etc...)
    ///------------------------------------------------------------------------------

    /***
     * @notice - Remove liquidity" for a pair (LP token) between the GLM tokens and another ERC20 tokens 
     *         - e.g. GLM/DAI, GLM/USDC, etc...
     **/
    function removeLiquidityWithERC20(address staker, IUniswapV2Pair pair, uint lpTokenAmountUnStaked) internal returns (bool) {
        /// Remove liquidity that a staker was staked
        uint GLMTokenAmount;
        uint ERC20Amount;
        uint GLMTokenMin = 0;
        uint ERC20AmountMin = 0;
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ERC20Amount) = uniswapV2Router02.removeLiquidity(GLM_TOKEN, 
                                                                          pair.token1(), 
                                                                          lpTokenAmountUnStaked,
                                                                          GLMTokenMin,
                                                                          ERC20AmountMin,
                                                                          to,
                                                                          deadline);

        /// Transfer GLM token and ERC20 + fees earned (into a staker)
        GLMToken.transfer(staker, GLMTokenAmount); 
        IERC20(pair.token1()).transfer(staker, ERC20Amount);       
    }


    ///-------------------------------------------------------------------
    /// Remove Liquidity GLM tokens with ETH (GLM/ETH)
    ///-------------------------------------------------------------------

    /***
     * @notice - Remove liquidity for a pair (LP token) between the GLM tokens and ETH (GLM/ETH)
     **/
    function removeLiquidityWithETH(address payable staker, IUniswapV2Pair pair, uint lpTokenAmountUnStaked) public returns (bool) {
        /// Remove liquidity that a staker was staked
        uint GLMTokenAmount;
        uint ETHAmount;         /// WETH
        uint GLMTokenMin = 0;
        uint ETHAmountMin = 0;  /// WETH
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ETHAmount) = uniswapV2Router02.removeLiquidityETH(GLM_TOKEN, 
                                                                           lpTokenAmountUnStaked, 
                                                                           GLMTokenMin, 
                                                                           ETHAmountMin, 
                                                                           to, 
                                                                           deadline);

        /// Convert WETH to ETH
        wETH.withdraw(ETHAmount);

        /// Transfer GLM token and ETH + fees earned (into a staker)
        GLMToken.transfer(staker, GLMTokenAmount); 
        staker.transfer(ETHAmount);       
    }


    ///--------------------------------------------------------
    /// Stake UNI-LP tokens of GLM/ERC20 or GLM/ETH into GLM pool
    ///--------------------------------------------------------

    /***
     * @notice - Stake UNI-LP tokens (GLM/ERC20 or GLM/ETH)
     * @param pair - Staked UNI-LP token
     * @param lpTokenAmount - Staked UNI-LP tokens amount
     **/
    function stakeLPToken(IUniswapV2Pair pair, uint lpTokenAmount) public returns (bool) {
        /// Stake LP tokens into this pool contract
        pair.transferFrom(msg.sender, address(this), lpTokenAmount);

        /// Mint the Golem Farming LP tokens
        golemFarmingLPToken.mint(msg.sender, lpTokenAmount);

        /// Add new staked UNI-LP token amount to the total staked UNI-LP token amount
        totalStakedLPTokenAmount += lpTokenAmount;

        /// Register staker's data
        uint8 newStakeId = getNextStakeId();
        currentStakeId++;        
        StakeData storage stakeData = stakeDatas[newStakeId];
        stakeData.staker = msg.sender;
        stakeData.lpToken = pair;
        stakeData.stakedLPTokenAmount = lpTokenAmount;
        stakeData.startBlock = block.number;

        /// Staker is added into stakers list
        stakersList.push(msg.sender);

        /// Save stake ID
        Staker storage staker = stakers[msg.sender];
        staker.stakeIds.push(newStakeId);
    }


    ///---------------------------------------------------
    /// Regular update of pool status
    ///---------------------------------------------------

    /***
     * @notice - Update pool status weekly (every week)
     **/
    function weeklyPoolStatusUpdate() public returns (bool) {
        uint currentBlock = block.number;

        if (currentBlock > nextBlock) {
            require (currentBlock > lastBlock, "Block number is still in the last period");

            /// Update both blocks (the last block and the next block)
            lastBlock = currentBlock;
            nextBlock = currentBlock.add(604800);  /// Plus 1 week (604800 seconds)

            /// Update total staked amount until last week
            _updateLastTotalStakedLPTokenAmount();
        }

    }


    ///---------------------------------------------------
    /// Withdraw only earned rewards
    ///---------------------------------------------------

    /***
     * @notice - Claim rewards (Do not un-stake LP tokens (GLM-ETH)
     * @dev - Caller (msg.sender) is a staker
     **/
    function claimEarnedReward(IUniswapV2Pair pair) public returns (bool res) {
        /// Compute earned rewards (GolemGovernanceToken) and Distribute them into a staker
        uint earnedReward = _computeEarnedReward(pair);

        /// Mint GolemGovernanceToken as rewards for a staker
        golemGovernanceToken.mint(msg.sender, earnedReward);
    }


    ///---------------------------------------------------
    /// Withdraw UNI-LP tokens with earned rewards
    ///---------------------------------------------------
    
    /***
     * @notice - un-stake LP tokens with earned rewards (GolemGovernanceToken)
     * @dev - Caller (msg.sender) is a staker
     **/
    function unStakeLPToken(IUniswapV2Pair pair, uint unStakedLpTokenAmount) public returns (bool) {
        address PAIR = address(pair);

        /// Burn the Golem Farming Tokens and transfer un-staked LP tokens
        _redeemWithUnStakedLPToken(msg.sender, pair, unStakedLpTokenAmount);
        
        /// Compute earned reward (GolemGovernanceToken) and Distribute them into staker
        claimEarnedReward(pair);
    }

    function _redeemWithUnStakedLPToken(address staker, IUniswapV2Pair pair, uint unStakedLpTokenAmount) internal returns (bool) {
        /// Burn the Golem Farming LP tokens
        golemFarmingLPToken.burn(staker, unStakedLpTokenAmount);

        /// Transfer un-staked UNI-LP tokens
        pair.transfer(staker, unStakedLpTokenAmount);
    }


    ///--------------------------------------------------------
    /// Golem Governance Token is given to stakers as rewards
    ///--------------------------------------------------------

    /***
     * @notice - Compute earned rewards that is GolemGovernanceTokens
     * @dev - [idea v1]: Reward is given to each stakers every block (every 15 seconds) and depends on share of pool
     * @dev - [idea v2]: Reward is given to each stakers by using the fixed-rewards-rate (10%)
     *                   => There is the locked-period (7 days) as minimum staking-term.
     **/
    function _computeEarnedReward(IUniswapV2Pair pair) internal returns (uint _earnedReward) {
        Staker memory staker = stakers[msg.sender];
        uint8[] memory _stakeIds = staker.stakeIds;
        uint totalIndividualStakedLPTokenAmount;

        for (uint8 i=1; i < _stakeIds.length; i++) {
            uint8 stakeId = i;

            StakeData memory stakeData = stakeDatas[stakeId];
            IUniswapV2Pair _pair = stakeData.lpToken; 
            uint stakedLPTokenAmount = stakeData.stakedLPTokenAmount;

            totalIndividualStakedLPTokenAmount += stakedLPTokenAmount;
        }

        /// Identify each staker's share of pool
        uint SHARE_OF_POOL = totalIndividualStakedLPTokenAmount.div(totalStakedLPTokenAmount);

        /// Compute total staked GLM tokens amount per a week (7days)
        weeklyTotalStakedLPTokenAmount = totalStakedLPTokenAmount.sub(lastTotalStakedLPTokenAmount);

        /// Formula for computing earned rewards (GolemGovernanceTokens)
        uint earnedReward = weeklyTotalStakedLPTokenAmount.mul(REWARD_RATE).div(100).mul(SHARE_OF_POOL).div(100);

        return earnedReward;
    }

    /***
     * @notice - Update total staked amount until last week
     **/
    function _updateLastTotalStakedLPTokenAmount() internal returns (bool) {
        lastTotalStakedLPTokenAmount = totalStakedLPTokenAmount;
    }


    ///-------------------
    /// Other getter methods
    ///-------------------

    function getTotalStakedLPTokenAmount() public view returns (uint _totalStakedLPTokenAmount) {
        return totalStakedLPTokenAmount;
    }

    function getTotalIndividualStakedLPTokenAmount(uint8 stakeId) public view returns (uint _totalIndividualStakedLPTokenAmount) {
        StakeData memory stakeData = stakeDatas[stakeId];
        return stakeData.stakedLPTokenAmount;
    }


    ///-------------------
    /// Private methods
    ///-------------------

    function getNextStakeId() private view returns (uint8 nextStakeId) {
        return currentStakeId + 1;
    }

}
