pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

/// Golem
import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";

/// Uniswap-v2
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2ERC20 } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2ERC20.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";


contract GLMStakePool {
    using SafeMath for uint;

    NewGolemNetworkToken public GLMToken;

    constructor(NewGolemNetworkToken _GLMToken) public {
        GLMToken = _GLMToken;
    }

    /***
     * @notice - Create a pair (LP token) between the GLM tokens and another ERC20 tokens by using Uniswap-V2
     *         - e.g). GLM/ETH, GLM/DAI, GLM/USDC
     **/
    function createLPToken() public returns (bool) {
        /// Add liquidity and pair
    }

}
