pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GLMStakePoolObjects } from "./GLMStakePoolObjects.sol";


contract GLMStakePoolStorages is GLMStakePoolObjects {

    // Info of each user that stakes LP tokens.
    mapping (address => Staker) public stakers;  /// [Key]: stake's address
    address[] stakersList;

    /// Info of stake
    mapping (uint8 => StakeData) public stakeDatas;  ///  [Key]: Stake ID

    // Info of each pool.
    mapping (address => Pool) public pools;  /// [Key]: LP token address
    //Pool[] public pools;

}
