pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import { ERC20Mintable } from "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/***
 * @title - GLM Pool Token contract
 **/
contract GLMPoolToken is ERC20Detailed, ERC20Mintable, ERC20Burnable {

    constructor() public ERC20Detailed("GLM Pool Token", "GLMP", 18) {}

    function mint(address to, uint mintAmount) public returns (bool) {
        _mint(to, mintAmount);
    }

}
