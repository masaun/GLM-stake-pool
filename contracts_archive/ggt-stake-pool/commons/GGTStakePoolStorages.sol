pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { GGTStakePoolObjects } from "./GGTStakePoolObjects.sol";


contract GGTStakePoolStorages is GGTStakePoolObjects {

    // Info of each user that stakes LP tokens.
    mapping (uint8 => Staker) public stakers;  /// [Key]: stake ID

    /// Info of stake
    mapping (uint8 => StakeData) public stakeDatas;  ///  [Key]: Stake ID

    // Info of each pool.
    mapping (address => Pool) public pools;  /// [Key]: LP token address
    //Pool[] public pools;

}
