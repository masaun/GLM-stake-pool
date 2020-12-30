pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Detailed } from "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


/***
 * @title - GLM Mock Token contract
 * @notice - This is mock token of the NewGolemNetworkToken.sol (GLM)
 **/
contract GLMMockToken is ERC20, ERC20Detailed {

    constructor() public ERC20Detailed("Golem Network Mock Token", "GLM", 18) {}

    function mint(address to, uint mintAmount) public returns (bool) {
        _mint(to, mintAmount);
    }

}
