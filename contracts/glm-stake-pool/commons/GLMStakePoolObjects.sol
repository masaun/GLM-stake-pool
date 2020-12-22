pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract GLMStakePoolObjects {

    struct CheckPoint {    /// [Key]: stake ID
        address staker; 
        uint32 blockTimestamp;  /// Block number when a user was staked
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

}
