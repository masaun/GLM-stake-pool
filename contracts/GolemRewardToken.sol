pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


/***
 * @title - Golem Reward Token contract
 **/
contract GolemRewardToken is ERC20, ERC20Detailed {

    constructor() public ERC20Detailed("Golem Reward Token", "GRT", 18) {}

}
