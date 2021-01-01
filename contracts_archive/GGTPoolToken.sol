pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


/***
 * @title - Pool Token contract of GGT (Golem Governance Token)
 **/
contract GGTPoolToken is ERC20, ERC20Detailed {

    constructor() public ERC20Detailed("GGT Pool Token", "GGTP", 18) {}

    function mint(address to, uint mintAmount) public returns (bool) {
        _mint(to, mintAmount);
    }

    function burn(address to, uint burnAmount) public returns (bool) {
        _burn(to, burnAmount);
    }

}
