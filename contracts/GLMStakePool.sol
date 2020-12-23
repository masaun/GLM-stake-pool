pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GLMStakePoolStorages } from "./glm-stake-pool/commons/GLMStakePoolStorages.sol";

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// GLM Token
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";

/// GLM Pool Token
import { GLMPoolToken } from "./GLMPoolToken.sol";

/// GRT (Golem Reward Token)
import { GolemRewardToken } from "./GolemRewardToken.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";


contract GLMStakePool is GLMStakePoolStorages {
    using SafeMath for uint;

    NewGolemNetworkToken public GLMToken;
    GLMPoolToken public glmPoolToken;
    GolemRewardToken public  GRTToken;
    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GLM_TOKEN;
    address GLM_POOL_TOKEN;
    address GRT_TOKEN;
    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    uint8 public currentStakeId;

    constructor(NewGolemNetworkToken _GLMToken, GLMPoolToken _glmPoolToken, GolemRewardToken _GRTToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GLMToken = _GLMToken;
        glmPoolToken = _glmPoolToken;
        GRTToken = _GRTToken;
        wETH = IWETH(uniswapV2Router02.WETH());
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GLM_TOKEN = address(_GLMToken);
        GLM_POOL_TOKEN = address(_glmPoolToken);
        GRT_TOKEN = address(_GRTToken);
        WETH_TOKEN = address(uniswapV2Router02.WETH());
        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
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
     * @notice - Add Liquidity" for a pair (LP token) between the GLM tokens and another ERC20 tokens (GLM/DAI, GLM/USDC, etc...)
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
        glmPoolToken.mint(msg.sender, liquidity);

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

        /// Define each minimum amounts (range of slippage)
        uint GLMTokenMin = GLMTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GLM desired
        uint ERC20AmountMin = ERC20AmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 DAI desired 

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
        uint ETHAmountDesired = msg.value;

        /// Convert ETH (msg.value) to WETH (ERC20) 
        /// [Note]: Converted amountETH is equal to "msg.value"
        wETH.deposit();

        /// Approve each tokens for UniswapV2Routor02
        GLMToken.approve(UNISWAP_V2_ROUTOR_02, GLMTokenAmountDesired);
        //wETH.approve(UNISWAP_V2_ROUTOR_02, ETHAmountDesired);

        /// Add liquidity and pair
        uint GLMTokenAmount;
        uint ETHAmount;
        uint liquidity;
        (GLMTokenAmount, ETHAmount, liquidity) = _addLiquidityWithETH(GLMTokenAmountDesired, ETHAmountDesired);

        /// [Todo]: Refund leftover ETH to a staker (Need to identify how much leftover ETH of a staker) 
        //msg.sender.call.value(address(this).balance)("");

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);
    }

    function _addLiquidityWithETH(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        uint GLMTokenAmountDesired,
        uint ETHAmountDesired
    ) internal returns (uint _GLMTokenAmount, uint _ETHAmount, uint _liquidity) {
        uint GLMTokenAmount;
        uint ETHAmount;
        uint liquidity;

        /// Define each minimum amounts (range of slippage)
        uint GLMTokenMin = GLMTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GLM desired
        uint ETHAmountMin = ETHAmountDesired.sub(1 * 1e18);      /// Slippage is allowed until -1 DAI desired 

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ETHAmount, liquidity) = uniswapV2Router02.addLiquidityETH(GLM_TOKEN,
                                                                                   GLMTokenAmountDesired,
                                                                                   GLMTokenMin,
                                                                                   ETHAmountMin,
                                                                                   to,
                                                                                   deadline);

        return (GLMTokenAmount, ETHAmount, liquidity);
    }


    ///--------------------------------------------------------
    /// Stake LP tokens of GLM/ERC20 or GLM/ETH into GLM pool
    ///--------------------------------------------------------

    /***
     * @notice - Stake LP tokens (GLM/ERC20 or GLM/ETH)
     **/
    function stakeLPToken(IUniswapV2Pair pair, uint lpTokenAmount) public returns (bool) {
        /// Stake LP tokens into this pool contract
        pair.transferFrom(msg.sender, address(this), lpTokenAmount);

        /// Register staker's data
        uint8 newStakeId = getNextStakeId();
        currentStakeId++;        
        StakeData storage stakeData = stakeDatas[newStakeId];
        stakeData.staker = msg.sender;
        stakeData.lpToken = pair;
        stakeData.stakedLPTokenAmount = lpTokenAmount;
    }


    ///--------------------------------------------------------
    /// GRT (Golem Reward Token) is given to stakers
    ///--------------------------------------------------------

    /***
     * @notice - Compute GRT (Golem Reward Token) as rewards
     * @dev - Reward is given to each stakers every block (every 15 seconds)
     **/
    function _computeReward(address to, uint mintAmount) internal returns (bool) {
        GRTToken.mint(to, mintAmount);
    }
    


    ///---------------------------------------------------
    /// Withdraw LP tokens with earned rewards
    ///---------------------------------------------------

    /***
     * @notice - Withdraw LP tokens with earned rewards
     * @dev - Caller is a staker (msg.sender)
     **/
    function withdrawWithReward(IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) public returns (bool) {
        address PAIR = address(pair);

        /// Caluculate earned rewards amount (Unit is "GLMP" (GLM Pool Token))
        // uint earnedRewardsAmount;   /// [Todo]: Add the calculation logic <-- This is fees calculation of UniswapV2
        // uint totalLPTokenAmountWithdrawn = lpTokenAmountWithdrawn.add(earnedRewardsAmount);

        if (pair.token0() == WETH_TOKEN || pair.token1() == WETH_TOKEN) {
            /// Burn GLM Pool Token and Transfer GLM token and ETH + fees earned (into a staker)
            _redeemWithETH(msg.sender, pair, lpTokenAmountWithdrawn);
        } else {
            /// Burn GLM Pool Token and Transfer GLM token and ERC20 + fees earned (into a staker)
            _redeemWithERC20(msg.sender, pair, lpTokenAmountWithdrawn);
        }
    }

    function _redeemWithERC20(address staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GLM Pool Token
        glmPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GLMTokenAmount;
        uint ERC20Amount;
        uint GLMTokenMin = 0;
        uint ERC20AmountMin = 0;
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ERC20Amount) = uniswapV2Router02.removeLiquidity(GLM_TOKEN, 
                                                                          pair.token1(), 
                                                                          lpTokenAmountWithdrawn,
                                                                          GLMTokenMin,
                                                                          ERC20AmountMin,
                                                                          to,
                                                                          deadline);

        /// Transfer GLM token and ERC20 + fees earned (into a staker)
        GLMToken.transfer(staker, GLMTokenAmount); 
        IERC20(pair.token1()).transfer(staker, ERC20Amount);       
    }

    function _redeemWithETH(address payable staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GLM Pool Token
        glmPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GLMTokenAmount;
        uint ETHAmount;         /// WETH
        uint GLMTokenMin = 0;
        uint ETHAmountMin = 0;  /// WETH
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GLMTokenAmount, ETHAmount) = uniswapV2Router02.removeLiquidityETH(GLM_TOKEN, 
                                                                           lpTokenAmountWithdrawn, 
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


    ///-------------------
    /// Private methods
    ///--------------------

    function getNextStakeId() private view returns (uint8 nextStakeId) {
        return currentStakeId + 1;
    }

}
