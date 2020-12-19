pragma solidity ^0.5.10;

import "./NewGolemNetworkToken.sol";

contract BatchingSidecar {
    NewGolemNetworkToken public ngnt;

    constructor(NewGolemNetworkToken _ngnt) public {
        require(address(_ngnt) != address(0), "Invalid ngnt address");
        ngnt = _ngnt;
    }

    // A new version of batchTransfer inspired by GolemNetworkTokenBatching.sol
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(recipients.length == amounts.length, "Incompatible array lengths");
        require(recipients.length > 0, "Empty list of payments");

        for (uint i = 0; i < recipients.length; ++i) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            require(ngnt.transferFrom(msg.sender, recipient, amount), "TransferFrom unsuccessfull");
        }
    }
}
