pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GRTStakePoolStorages } from "./grt-stake-pool/commons/GRTStakePoolStorages.sol";

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem Reward Token
import { GolemRewardToken } from "./GolemRewardToken.sol";

/// GRT Pool Token
import { GRTPoolToken } from "./GRTPoolToken.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";



/***
 * @title - GRT (Golem Reward Token) Stake Pool contract
 **/
contract GRTStakePool is GRTStakePoolStorages {
    using SafeMath for uint;

    GolemRewardToken public GRTToken;
    GRTPoolToken public grtPoolToken;
    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GRT_TOKEN;
    address GRT_POOL_TOKEN;    
    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    uint8 public currentStakeId;

    constructor(GolemRewardToken _GRTToken, GRTPoolToken _grtPoolToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GRTToken = _GRTToken;
        grtPoolToken = _grtPoolToken;
        wETH = IWETH(uniswapV2Router02.WETH());
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GRT_TOKEN = address(_GRTToken);
        GRT_POOL_TOKEN = address(_grtPoolToken);
        WETH_TOKEN = address(uniswapV2Router02.WETH());
        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
    }


    ///---------------------------------------------------
    /// Create a pair address (of LP tokens)
    ///---------------------------------------------------

    /***
     * @notice - Create a pair (LP token) between the GRT tokens and another ERC20 tokens
     *         - e.g). GRT/DAI, GRT/USDC
     * @param erc20 - e.g). DAI, USDC, etc...
     **/
    function createPairWithERC20(IERC20 erc20) public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GRT_TOKEN, address(erc20)); 
        return IUniswapV2Pair(pair);
    }

    /***
     * @notice - Create a pair (LP token) between the GRT tokens and ETH (GRT/ETH)
     **/
    function createPairWithETH() public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GRT_TOKEN, WETH_TOKEN);  /// [Note]: WETH is treated as ETH 
        return IUniswapV2Pair(pair);        
    }
    

    ///------------------------------------------------------------------------------
    /// Add liquidity GRT tokens with ERC20 tokens (GRT/DAI, GRT/USDC, etc...)
    ///------------------------------------------------------------------------------

    /***
     * @notice - Add Liquidity" for a pair (LP token) between the GRT tokens and another ERC20 tokens (GRT/DAI, GRT/USDC, etc...)
     **/

    function addLiquidityWithERC20(
        IUniswapV2Pair pair,
        uint GRTTokenAmountDesired,
        uint ERC20AmountDesired
    ) public returns (bool) {
        IERC20 erc20 = IERC20(pair.token1());

        /// Transfer each sourse tokens from a user
        GRTToken.transferFrom(msg.sender, address(this), GRTTokenAmountDesired);
        erc20.transferFrom(msg.sender, address(this), ERC20AmountDesired);

        /// Check whether a pair contract exists or not
        address pairAddress = uniswapV2Factory.getPair(GRT_TOKEN, address(erc20)); 
        require (pairAddress > address(0), "This pair contract has not existed yet");

        /// Check whether liquidity of a pair contract is enough or not
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_V2_FACTORY, GRT_TOKEN, address(erc20)));
        uint totalSupply = pair.totalSupply();
        require (totalSupply > 0, "This pair's totalSupply is still 0. Please add liquidity at first");        

        /// Approve each tokens for UniswapV2Routor02
        GRTToken.approve(UNISWAP_V2_ROUTOR_02, GRTTokenAmountDesired);
        erc20.approve(UNISWAP_V2_ROUTOR_02, ERC20AmountDesired);

        /// Add liquidity and pair
        uint GRTTokenAmount;
        uint ERC20Amount;
        uint liquidity;
        (GRTTokenAmount, ERC20Amount, liquidity) = _addLiquidityWithERC20(erc20,
                                                                          GRTTokenAmountDesired,
                                                                          ERC20AmountDesired);

        /// Mint amount that is equal to staked LP tokens to a staker
        grtPoolToken.mint(msg.sender, liquidity);

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);
    }

    function _addLiquidityWithERC20(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        IERC20 erc20,
        uint GRTTokenAmountDesired,
        uint ERC20AmountDesired
    ) internal returns (uint _GRTTokenAmount, uint _ERC20Amount, uint _liquidity) {
        uint GRTTokenAmount;
        uint ERC20Amount;
        uint liquidity;

        /// Define each minimum amounts (range of slippage)
        uint GRTTokenMin = GRTTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GRT desired
        uint ERC20AmountMin = ERC20AmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 DAI desired 

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GRTTokenAmount, ERC20Amount, liquidity) = uniswapV2Router02.addLiquidity(GRT_TOKEN,
                                                                                  address(erc20),
                                                                                  GRTTokenAmountDesired,
                                                                                  ERC20AmountDesired,
                                                                                  GRTTokenMin,
                                                                                  ERC20AmountMin,
                                                                                  to,
                                                                                  deadline);

        return (GRTTokenAmount, ERC20Amount, liquidity);
    }


    ///-------------------------------------------------------------------
    /// Add Liquidity GRT tokens with ETH (GRT/ETH)
    ///-------------------------------------------------------------------

    /***
     * @notice - Add Liquidity for a pair (LP token) between the GRT tokens and ETH (GRT/ETH)
     **/

    function addLiquidityWithETH(
        IUniswapV2Pair pair,
        uint GRTTokenAmountDesired
    ) public payable returns (bool) {
        /// Transfer GRT tokens and ETH from a user
        GRTToken.transferFrom(msg.sender, address(this), GRTTokenAmountDesired);
        uint ETHAmountDesired = msg.value;

        /// Convert ETH (msg.value) to WETH (ERC20) 
        /// [Note]: Converted amountETH is equal to "msg.value"
        wETH.deposit();

        /// Approve each tokens for UniswapV2Routor02
        GRTToken.approve(UNISWAP_V2_ROUTOR_02, GRTTokenAmountDesired);
        //wETH.approve(UNISWAP_V2_ROUTOR_02, ETHAmountDesired);

        /// Add liquidity and pair
        uint GRTTokenAmount;
        uint ETHAmount;
        uint liquidity;
        (GRTTokenAmount, ETHAmount, liquidity) = _addLiquidityWithETH(GRTTokenAmountDesired, ETHAmountDesired);

        /// [Todo]: Refund leftover ETH to a staker (Need to identify how much leftover ETH of a staker) 
        //msg.sender.call.value(address(this).balance)("");

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);        
    }

    function _addLiquidityWithETH(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        uint GRTTokenAmountDesired,
        uint ETHAmountDesired
    ) internal returns (uint _GRTTokenAmount, uint _ETHAmount, uint _liquidity) {
        uint GRTTokenAmount;
        uint ETHAmount;
        uint liquidity;

        /// Define each minimum amounts (range of slippage)
        uint GRTTokenMin = GRTTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GRT desired
        uint ETHAmountMin = ETHAmountDesired.sub(1 * 1e18);      /// Slippage is allowed until -1 DAI desired 

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GRTTokenAmount, ETHAmount, liquidity) = uniswapV2Router02.addLiquidityETH(GRT_TOKEN,
                                                                                   GRTTokenAmountDesired,
                                                                                   GRTTokenMin,
                                                                                   ETHAmountMin,
                                                                                   to,
                                                                                   deadline);

        return (GRTTokenAmount, ETHAmount, liquidity);
    }


    ///-------------------------------------------------------------
    /// Stake LP tokens of GRT/ERC20 or GRT/ETH into the GRT pool
    ///-------------------------------------------------------------

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


    ///---------------------------------------------------
    /// Withdraw LP tokens with earned rewards
    ///---------------------------------------------------

    /***
     * @notice - Withdraw LP tokens with earned rewards
     * @dev - Caller is a staker (msg.sender)
     **/
    function withdrawWithReward(IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) public returns (bool) {
        address PAIR = address(pair);

        if (pair.token0() == WETH_TOKEN || pair.token1() == WETH_TOKEN) {
            /// Transfer GRT token and ETH + fees earned (into a staker)
            _redeemWithETH(msg.sender, pair, lpTokenAmountWithdrawn);
        } else {
            /// Transfer GRT token and ERC20 + fees earned (into a staker)
            _redeemWithERC20(msg.sender, pair, lpTokenAmountWithdrawn);
        }
    }

    function _redeemWithERC20(address staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GRT Pool Token
        grtPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GRTTokenAmount;
        uint ERC20Amount;
        uint GRTTokenMin = 0;
        uint ERC20AmountMin = 0;
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GRTTokenAmount, ERC20Amount) = uniswapV2Router02.removeLiquidity(GRT_TOKEN, 
                                                                          pair.token1(), 
                                                                          lpTokenAmountWithdrawn,
                                                                          GRTTokenMin,
                                                                          ERC20AmountMin,
                                                                          to,
                                                                          deadline);

        /// Transfer GRT token and ERC20 + fees earned (into a staker)
        GRTToken.transfer(staker, GRTTokenAmount); 
        IERC20(pair.token1()).transfer(staker, ERC20Amount);       
    }

    function _redeemWithETH(address payable staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GRT Pool Token
        grtPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GRTTokenAmount;
        uint ETHAmount;         /// WETH
        uint GRTTokenMin = 0;
        uint ETHAmountMin = 0;  /// WETH
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GRTTokenAmount, ETHAmount) = uniswapV2Router02.removeLiquidityETH(GRT_TOKEN, 
                                                                           lpTokenAmountWithdrawn, 
                                                                           GRTTokenMin, 
                                                                           ETHAmountMin, 
                                                                           to, 
                                                                           deadline);

        /// Convert WETH to ETH
        wETH.withdraw(ETHAmount);

        /// Transfer GRT token and ETH + fees earned (into a staker)
        GRTToken.transfer(staker, GRTTokenAmount); 
        staker.transfer(ETHAmount);       
    }


    ///-------------------
    /// Private methods
    ///--------------------

    function getNextStakeId() private view returns (uint8 nextStakeId) {
        return currentStakeId + 1;
    }

}
