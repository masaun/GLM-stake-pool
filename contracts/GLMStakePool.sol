pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import { NewGolemNetworkToken } from "./golem/GNT2/NewGolemNetworkToken.sol";


contract GLMStakePool {

    NewGolemNetworkToken public GLMToken;

    constructor(NewGolemNetworkToken _GLMToken) public {
        GLMToken = _GLMToken;
    }

    function something() public returns (bool) {}

}
