pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";


contract GLMStakePool {

    NewGolemNetworkToken public GLMToken;

    constructor(NewGolemNetworkToken _GLMToken) public {
        GLMToken = _GLMToken;
    }

    /***
     * @notice - Create a pair (LP token) between the GLM tokens and another ERC20 tokens
     *         - e.g). GLM/ETH, GLM/DAI, GLM/USDC
     **/
    function createLPToken() public returns (bool) {
        /// Add liquidity and pair
    }

}
