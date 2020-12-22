pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GLMStakePoolObjects  } from "./GLMStakePoolObjects.sol";


contract GLMStakePoolStorages is GLMStakePoolObjects {

    mapping (uint => CheckPoint) checkPoints;  /// [Key]: stake ID

    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;  /// [Key]: Pool ID -> user address

    // Info of each pool.
    PoolInfo[] public poolInfo;

}
