pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/// WETH
import { IWETH } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IWETH.sol";

/// Uniswap-v2
import { UniswapV2Library } from "./uniswap-v2/uniswap-v2-periphery/libraries/UniswapV2Library.sol";
import { IUniswapV2Factory } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Router02 } from "./uniswap-v2/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "./uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";


/***
 * @title - UniswapV2 Helper contract
 **/
contract UniswapV2Helper {

    IWETH public wETH;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 public uniswapV2Router02;

    address WETH_TOKEN;
    address UNISWAP_V2_FACTORY;
    address UNISWAP_V2_ROUTOR_02;

    constructor(
        IUniswapV2Factory _uniswapV2Factory, 
        IUniswapV2Router02 _uniswapV2Router02
    ) public returns (bool) {
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router02 = _uniswapV2Router02;
        wETH = IWETH(uniswapV2Router02.WETH());

        UNISWAP_V2_FACTORY = address(_uniswapV2Factory);
        UNISWAP_V2_ROUTOR_02 = address(_uniswapV2Router02);
        WETH_TOKEN = address(uniswapV2Router02.WETH());
    }

    function convertEthToERC20(uint erc20Amount) public payable {
        uint deadline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        uniswapV2Router02.swapETHForExactTokens(msg.value)(erc20Amount, getPathForETHtoERC20(), address(this), deadline);
        
        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }
  
    function getEstimatedETHforERC20(uint erc20Amount) public view returns (uint[] memory) {
        return uniswapV2Router02.getAmountsIn(erc20Amount, getPathForETHtoERC20());
    }

    function getPathForETHtoERC20(IERC20 erc20) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router02.WETH();
        path[1] = address(erc20);

        return path;
    }

    // important to receive ETH
    receive() payable external {}

}
