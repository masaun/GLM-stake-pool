pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2ERC20 } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2ERC20.sol";


contract GLMStakePool {
    using SafeMath for uint;

    NewGolemNetworkToken public GLMToken;
    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GLM_TOKEN;
    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    constructor(NewGolemNetworkToken _GLMToken, IWETH _wETH, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GLMToken = _GLMToken;
        wETH = _wETH;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GLM_TOKEN = address(_GLMToken);
        WETH_TOKEN = address(_wETH);
        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
    }


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
    function createPairWithETH() public returns (bool) {}


    ///----------------------------
    /// Add liquidity with ERC20
    ///----------------------------

    /***
     * @notice - Add Liquidity for a pair (LP token) between the GLM tokens and another ERC20 tokens
     *         - e.g). GLM/DAI, GLM/USDC, etc...
     **/
    function addLiquidityWithERC20(
        IERC20 erc20,
        uint GLMTokenAmountDesired,
        uint ERC20AmountDesired
    ) public returns (bool) {
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


    ///----------------------------
    /// Add liquidity with ETH
    ///----------------------------  

    /***
     * @notice - Add Liquidity for a pair (LP token) between the GLM tokens and ETH 
     *         - e.g). GLM/ETH
     **/
    function addLiquidityWithETH(
        uint GLMTokenAmountDesired
    ) public payable returns (bool) {
        /// Transfer GLM tokens and ETH from a user
        GLMToken.transferFrom(msg.sender, address(this), GLMTokenAmountDesired);
        uint ETHAmountDesired = msg.value;

        /// [Todo]: Convert ETH (msg.value) to WETH (ERC20)
        wETH.deposit();

        /// Approve each tokens for UniswapV2Routor02
        GLMToken.approve(UNISWAP_V2_ROUTOR_02, GLMTokenAmountDesired);

        /// Add liquidity and pair
        uint GLMTokenAmount;
        uint ETHAmount;
        uint liquidity;
        (GLMTokenAmount, ETHAmount, liquidity) = _addLiquidityWithETH(GLMTokenAmountDesired, ETHAmountDesired);        
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

}
