pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

/***
 * @title - GLM Pool Token contract
 **/
contract GLMPoolToken is ERC20Detailed {

    constructor() public ERC20Detailed("GLM Pool Token", "GLMP", 18) {}

}
