pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GolemRewardToken } from "./GolemRewardToken.sol";


/***
 * @title - Golem Reward Token Pool contract
 **/
contract GolemRewardTokenPool {

    GolemRewardToken public golemRewardToken;

    constructor(GolemRewardToken _golemRewardToken) public {
        golemRewardToken = _golemRewardToken;
    }

    function something() public returns (bool) {}
    

}
