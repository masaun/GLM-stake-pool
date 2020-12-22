pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GolemRewardToken } from "./GolemRewardToken.sol";

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";



/***
 * @title - Golem Reward Token Pool contract
 **/
contract GolemRewardTokenPool {

    GolemRewardToken public golemRewardToken;

    constructor(GolemRewardToken _golemRewardToken) public {
        golemRewardToken = _golemRewardToken;
    }


    ///---------------------------------------------------
    /// Create a pair address (of LP tokens)
    ///---------------------------------------------------

    /***
     * @notice - Create a pair (LP token) between the GRT tokens and another ERC20 tokens
     *         - e.g). GRT/DAI, GRT/USDC
     * @param erc20 - e.g). DAI, USDC, etc...
     **/
    function createPairWithERC20(IERC20 erc20) public returns (IUniswapV2Pair pair) {}

    /***
     * @notice - Create a pair (LP token) between the GRT tokens and ETH (GLM/ETH)
     **/
    function createPairWithETH() public returns (IUniswapV2Pair pair) {}
    

    ///---------------------------------------------------
    /// Add Liquidity
    ///---------------------------------------------------

    function addLiquidityWithERC20() public returns (bool) {}

    function addLiquidityWithETH() public returns (bool) {}


    ///---------------------------------------------------
    /// Stake LP tokens of GRT/ERC20 or GRT/ETH into pool
    ///---------------------------------------------------

    function stakeLPToken(IUniswapV2Pair pair, uint lpTokenAmount) public returns (bool) {}


    ///---------------------------------------------------
    /// Withdraw LP tokens with earned rewards
    ///---------------------------------------------------

    function withdrawWithReward(IUniswapV2Pair pair, uint lpTokenAmountWithdrawn) public returns (bool) {}


}
