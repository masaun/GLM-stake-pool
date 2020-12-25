pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GGTStakePoolStorages } from "./ggt-stake-pool/commons/GGTStakePoolStorages.sol";

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem Governance Token
import { GolemGovernanceToken } from "./GolemGovernanceToken.sol";

/// GGT Pool Token
import { GGTPoolToken } from "./GGTPoolToken.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";



/***
 * @title - GGT (Golem Reward Token) Stake Pool contract
 **/
contract GGTStakePool is GGTStakePoolStorages {
    using SafeMath for uint;

    GolemGovernanceToken public GGTToken;
    GGTPoolToken public ggtPoolToken;
    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GGT_TOKEN;
    address GGT_POOL_TOKEN;    
    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    uint8 public currentStakeId;

    constructor(GolemGovernanceToken _GGTToken, GGTPoolToken _ggtPoolToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GGTToken = _GGTToken;
        ggtPoolToken = _ggtPoolToken;
        wETH = IWETH(uniswapV2Router02.WETH());
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GGT_TOKEN = address(_GGTToken);
        GGT_POOL_TOKEN = address(_ggtPoolToken);
        WETH_TOKEN = address(uniswapV2Router02.WETH());
        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
    }


    ///---------------------------------------------------
    /// Create a pair address (of LP tokens)
    ///---------------------------------------------------

    /***
     * @notice - Create a pair (LP token) between the GGT tokens and another ERC20 tokens
     *         - e.g). GGT/DAI, GGT/USDC
     * @param erc20 - e.g). DAI, USDC, etc...
     **/
    function createPairWithERC20(IERC20 erc20) public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GGT_TOKEN, address(erc20)); 
        return IUniswapV2Pair(pair);
    }

    /***
     * @notice - Create a pair (LP token) between the GGT tokens and ETH (GGT/ETH)
     **/
    function createPairWithETH() public returns (IUniswapV2Pair pair) {
        address pair = uniswapV2Factory.createPair(GGT_TOKEN, WETH_TOKEN);  /// [Note]: WETH is treated as ETH 
        return IUniswapV2Pair(pair);        
    }
    

    ///------------------------------------------------------------------------------
    /// Add liquidity GGT tokens with ERC20 tokens (GGT/DAI, GGT/USDC, etc...)
    ///------------------------------------------------------------------------------

    /***
     * @notice - Add Liquidity" for a pair (LP token) between the GGT tokens and another ERC20 tokens (GGT/DAI, GGT/USDC, etc...)
     **/

    function addLiquidityWithERC20(
        IUniswapV2Pair pair,
        uint GGTTokenAmountDesired,
        uint ERC20AmountDesired
    ) public returns (bool) {
        IERC20 erc20 = IERC20(pair.token1());

        /// Transfer each sourse tokens from a user
        GGTToken.transferFrom(msg.sender, address(this), GGTTokenAmountDesired);
        erc20.transferFrom(msg.sender, address(this), ERC20AmountDesired);

        /// Check whether a pair contract exists or not
        address pairAddress = uniswapV2Factory.getPair(GGT_TOKEN, address(erc20)); 
        require (pairAddress > address(0), "This pair contract has not existed yet");

        /// Check whether liquidity of a pair contract is enough or not
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(UNISWAP_V2_FACTORY, GGT_TOKEN, address(erc20)));
        uint totalSupply = pair.totalSupply();
        require (totalSupply > 0, "This pair's totalSupply is still 0. Please add liquidity at first");        

        /// Approve each tokens for UniswapV2Routor02
        GGTToken.approve(UNISWAP_V2_ROUTOR_02, GGTTokenAmountDesired);
        erc20.approve(UNISWAP_V2_ROUTOR_02, ERC20AmountDesired);

        /// Add liquidity and pair
        uint GGTTokenAmount;
        uint ERC20Amount;
        uint liquidity;
        (GGTTokenAmount, ERC20Amount, liquidity) = _addLiquidityWithERC20(erc20,
                                                                          GGTTokenAmountDesired,
                                                                          ERC20AmountDesired);

        /// Mint amount that is equal to staked LP tokens to a staker
        ggtPoolToken.mint(msg.sender, liquidity);

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);
    }

    function _addLiquidityWithERC20(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        IERC20 erc20,
        uint GGTTokenAmountDesired,
        uint ERC20AmountDesired
    ) internal returns (uint _GGTTokenAmount, uint _ERC20Amount, uint _liquidity) {
        uint GGTTokenAmount;
        uint ERC20Amount;
        uint liquidity;

        /// Define each minimum amounts (range of slippage)
        uint GGTTokenMin = GGTTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GGT desired
        uint ERC20AmountMin = ERC20AmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 DAI desired 

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GGTTokenAmount, ERC20Amount, liquidity) = uniswapV2Router02.addLiquidity(GGT_TOKEN,
                                                                                  address(erc20),
                                                                                  GGTTokenAmountDesired,
                                                                                  ERC20AmountDesired,
                                                                                  GGTTokenMin,
                                                                                  ERC20AmountMin,
                                                                                  to,
                                                                                  deadline);

        return (GGTTokenAmount, ERC20Amount, liquidity);
    }


    ///-------------------------------------------------------------------
    /// Add Liquidity GGT tokens with ETH (GGT/ETH)
    ///-------------------------------------------------------------------

    /***
     * @notice - Add Liquidity for a pair (LP token) between the GGT tokens and ETH (GGT/ETH)
     **/

    function addLiquidityWithETH(
        IUniswapV2Pair pair,
        uint GGTTokenAmountDesired
    ) public payable returns (bool) {
        /// Transfer GGT tokens and ETH from a user
        GGTToken.transferFrom(msg.sender, address(this), GGTTokenAmountDesired);
        uint ETHAmountDesired = msg.value;

        /// Convert ETH (msg.value) to WETH (ERC20) 
        /// [Note]: Converted amountETH is equal to "msg.value"
        wETH.deposit();

        /// Approve each tokens for UniswapV2Routor02
        GGTToken.approve(UNISWAP_V2_ROUTOR_02, GGTTokenAmountDesired);
        //wETH.approve(UNISWAP_V2_ROUTOR_02, ETHAmountDesired);

        /// Add liquidity and pair
        uint GGTTokenAmount;
        uint ETHAmount;
        uint liquidity;
        (GGTTokenAmount, ETHAmount, liquidity) = _addLiquidityWithETH(GGTTokenAmountDesired, ETHAmountDesired);

        /// [Todo]: Refund leftover ETH to a staker (Need to identify how much leftover ETH of a staker) 
        //msg.sender.call.value(address(this).balance)("");

        /// Back LPtoken to a staker
        pair.transfer(msg.sender, liquidity);        
    }

    function _addLiquidityWithETH(   /// [Note]: This internal method is added for avoiding "Stack too deep" 
        uint GGTTokenAmountDesired,
        uint ETHAmountDesired
    ) internal returns (uint _GGTTokenAmount, uint _ETHAmount, uint _liquidity) {
        uint GGTTokenAmount;
        uint ETHAmount;
        uint liquidity;

        /// Define each minimum amounts (range of slippage)
        uint GGTTokenMin = GGTTokenAmountDesired.sub(1 * 1e18);  /// Slippage is allowed until -1 GGT desired
        uint ETHAmountMin = ETHAmountDesired.sub(1 * 1e18);      /// Slippage is allowed until -1 DAI desired 

        address to = msg.sender;
        uint deadline = now.add(15 seconds);
        (GGTTokenAmount, ETHAmount, liquidity) = uniswapV2Router02.addLiquidityETH(GGT_TOKEN,
                                                                                   GGTTokenAmountDesired,
                                                                                   GGTTokenMin,
                                                                                   ETHAmountMin,
                                                                                   to,
                                                                                   deadline);

        return (GGTTokenAmount, ETHAmount, liquidity);
    }


    ///-------------------------------------------------------------
    /// Stake LP tokens of GGT/ERC20 or GGT/ETH into the GGT pool
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
            /// Transfer GGT token and ETH + fees earned (into a staker)
            _redeemWithETH(msg.sender, pair, lpTokenAmountWithdrawn);
        } else {
            /// Transfer GGT token and ERC20 + fees earned (into a staker)
            _redeemWithERC20(msg.sender, pair, lpTokenAmountWithdrawn);
        }
    }

    function _redeemWithERC20(address staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GGT Pool Token
        ggtPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GGTTokenAmount;
        uint ERC20Amount;
        uint GGTTokenMin = 0;
        uint ERC20AmountMin = 0;
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GGTTokenAmount, ERC20Amount) = uniswapV2Router02.removeLiquidity(GGT_TOKEN, 
                                                                          pair.token1(), 
                                                                          lpTokenAmountWithdrawn,
                                                                          GGTTokenMin,
                                                                          ERC20AmountMin,
                                                                          to,
                                                                          deadline);

        /// Transfer GGT token and ERC20 + fees earned (into a staker)
        GGTToken.transfer(staker, GGTTokenAmount); 
        IERC20(pair.token1()).transfer(staker, ERC20Amount);       
    }

    function _redeemWithETH(address payable staker, IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) internal returns (bool) {
        address PAIR = address(pair);

        /// Burn GGT Pool Token
        ggtPoolToken.burn(staker, lpTokenAmountWithdrawn);

        /// Remove liquidity that a staker was staked
        uint GGTTokenAmount;
        uint ETHAmount;         /// WETH
        uint GGTTokenMin = 0;
        uint ETHAmountMin = 0;  /// WETH
        address to = staker;
        uint deadline = now.add(15 seconds);
        (GGTTokenAmount, ETHAmount) = uniswapV2Router02.removeLiquidityETH(GGT_TOKEN, 
                                                                           lpTokenAmountWithdrawn, 
                                                                           GGTTokenMin, 
                                                                           ETHAmountMin, 
                                                                           to, 
                                                                           deadline);

        /// Convert WETH to ETH
        wETH.withdraw(ETHAmount);

        /// Transfer GGT token and ETH + fees earned (into a staker)
        GGTToken.transfer(staker, GGTTokenAmount); 
        staker.transfer(ETHAmount);       
    }


    ///-------------------
    /// Private methods
    ///--------------------

    function getNextStakeId() private view returns (uint8 nextStakeId) {
        return currentStakeId + 1;
    }

}
