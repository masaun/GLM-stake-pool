pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/// Openzeppelin v2.5.1
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Uniswap-v2
import { IUniswapV2Pair } from "../../uniswap-v2/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";


contract GRTStakePoolObjects {

    // Info of each staker
    struct Staker {      /// [Key]: LP token address -> staker address
        uint amount;     // How many LP tokens the user has provided.
        uint rewardDebt; // Reward debt. See explanation below.
        uint32 blockTimestamp;  /// Block number when a user was staked
    }

    /// Info of stake
    struct StakeData {   ///  [Key]: Stake ID
        address staker;
        IUniswapV2Pair lpToken;  // Address of LP token contract.
        uint stakedLPTokenAmount;     // How many LP tokens the user has provided.
        uint allocPoint;         // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint lastRewardBlock;    // Last block number that SUSHIs distribution occurs.
        uint accSushiPerShare;   // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // Info of each pool. (GRT/ETH, GRT/ERC20)
    struct Pool {       /// [Key]: LP token address
        IUniswapV2Pair lpToken;  // Address of LP token contract.
        uint allocPoint;         // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint lastRewardBlock;    // Last block number that SUSHIs distribution occurs.
        uint accSushiPerShare;   // Accumulated SUSHIs per share, times 1e12. See below.
    }

}
