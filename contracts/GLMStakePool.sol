pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2ERC20 } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2ERC20.sol";


contract GLMStakePool {
    using SafeMath for uint;

    NewGolemNetworkToken public GLMToken;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address GLM_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    constructor(NewGolemNetworkToken _GLMToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GLMToken = _GLMToken;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GLM_TOKEN = address(_GLMToken);
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


    /***
     * @notice - Add Liquidity for a pair (LP token) between the GLM tokens and another ERC20 tokens by using Uniswap-V2
     *         - e.g). GLM/ETH, GLM/DAI, GLM/USDC
     **/
    function addLiquidityWithERC20(
        IERC20 erc20,
        uint GLMTokenAmountDesired,
        uint ERC20AmountDesired
    ) public returns (bool) {
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

    function _addLiquidityWithERC20(
        IERC20 erc20,
        uint GLMTokenAmountDesired,
        uint ERC20AmountDesired
    ) internal returns (uint _GLMTokenAmount, uint _ERC20Amount, uint _liquidity) {
        uint GLMTokenAmount;
        uint ERC20Amount;
        uint liquidity;

        /// [Todo]: Calculate each amountMin
        uint GLMTokenMin;
        uint ERC20AmountMin;

        address to = msg.sender;
        uint deadline = now.add(10 minutes);
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
    

}