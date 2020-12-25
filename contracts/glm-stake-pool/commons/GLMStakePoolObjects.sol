pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Uniswap-v2
import { IUniswapV2Pair } from "../../uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";


contract GLMStakePoolObjects {

    // Info of each staker
    struct Staker {      /// [Key]: stake's address
        uint8[] stakeIds;  /// Stake IDs which this staker was staked are stored into this array 

        uint amount;     // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. See explanation below.
        uint32 blockTimestamp;  /// Block number when a user was staked
    }

    /// Info of stake
    struct StakeData {   ///  [Key]: Stake ID
        address staker;
        IUniswapV2Pair lpToken;  // Address of LP token contract.
        uint stakedLPTokenAmount;     // How many LP tokens the user has provided.
        uint startBlock;  /// Start block (block.number) when a starker staked
        uint shareOfPool; /// Share of pool (%)

        uint allocPoint;         // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint lastRewardBlock;    // Last block number that SUSHIs distribution occurs.
        uint accSushiPerShare;   // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // Info of each pool. (GLM/ETH, GLM/ERC20)
    struct Pool {       /// [Key]: LP token address
        IUniswapV2Pair lpToken;  // Address of LP token contract.
        uint allocPoint;         // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint lastRewardBlock;    // Last block number that SUSHIs distribution occurs.
        uint accSushiPerShare;   // Accumulated SUSHIs per share, times 1e12. See below.
    }

}
