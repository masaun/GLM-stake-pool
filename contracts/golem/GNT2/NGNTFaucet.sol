pragma solidity ^0.5.10;

import "./NewGolemNetworkToken.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract NGNTFaucet is Ownable {
    NewGolemNetworkToken public token;

    function setNGNT (address _token) external onlyOwner {
        // can be called only once
        require(address(token) == address(0), "Function can be invoked only once");

        // validate address
        require(_token != address(0), "Invalid token contract address");

        token = NewGolemNetworkToken(_token);
    }

    function create() external {
        require(address(token) != address(0), "Token contract has not been set");
        uint256 tokens = 1000 * 10 ** uint256(token.decimals());
        if (token.balanceOf(msg.sender) >= tokens) revert("Cannot acquire more funds");
        require(token.mint(msg.sender, tokens), "Failed to create funds");
    }
}