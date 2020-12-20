pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";

/// Uniswap-v2
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

    constructor(NewGolemNetworkToken _GLMToken, IUniswapV2Factory _uniswapV2Factory, IUniswapV2Router02 _uniswapV2Router02) public {
        GLMToken = _GLMToken;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;

        GLM_TOKEN = address(_GLMToken);
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
    function addLiquidity() public returns (bool) {
        /// Add liquidity and pair
    }    


}
