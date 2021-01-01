pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


/***
 * @title - Golem Farming LP Token contract
 **/
contract GolemFarmingLPToken is ERC20, ERC20Detailed {

    constructor() public ERC20Detailed("Golem Farming Liquidity Provider Token", "GFLP", 18) {}

    function mint(address to, uint mintAmount) public returns (bool) {
        _mint(to, mintAmount);
    }

    function burn(address to, uint burnAmount) public returns (bool) {
        _burn(to, burnAmount);
    }

}
