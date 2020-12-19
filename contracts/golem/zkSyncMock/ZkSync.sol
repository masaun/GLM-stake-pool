pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./SafeMathUInt128.sol";
import "./SafeCast.sol";
import "./Utils.sol";

import "./Events.sol";
import "./Operations.sol";

/* solium-disable */

contract ZkSync is Events {

    using SafeMath for uint256;
    using SafeMathUInt128 for uint128;

    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _franklinAddr Receiver Layer 2 address
    function depositERC20(IERC20 _token, uint104 _amount, address _franklinAddr) external {
        uint16 tokenId = 16;
        uint256 balance_before = _token.balanceOf(address(this));
        require(Utils.transferFromERC20(_token, msg.sender, address(this), SafeCast.toUint128(_amount)), "fd012"); // token transfer failed deposit
        uint256 balance_after = _token.balanceOf(address(this));
        uint128 deposit_amount = SafeCast.toUint128(balance_after.sub(balance_before));

        registerDeposit(tokenId, deposit_amount, _franklinAddr);
    }

    /// @param _token Token address
    /// @param _amount amount to withdraw
    /// @param _addr Address to withdraw to
    function withdrawERC20(IERC20 _token, uint128 _amount, address _addr) external {
        require(Utils.sendERC20(_token, _addr, _amount), "wtg11");
    }

    /// @param _tokenId Token by id
    /// @param _amount Token amount
    /// @param _owner Receiver
    function registerDeposit(
        uint16 _tokenId,
        uint128 _amount,
        address _owner
    ) internal {
        Operations.Deposit memory op = Operations.Deposit({
            accountId:  0, // unknown at this point
            owner:      _owner,
            tokenId:    _tokenId,
            amount:     _amount
            });
        bytes memory pubData = Operations.writeDepositPubdata(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData);

        emit OnchainDeposit(
            msg.sender,
            _tokenId,
            _amount,
            _owner
        );
    }

    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(
        Operations.OpType _opType,
        bytes memory _pubData
    ) internal {
        uint256 expirationBlock = 0;
        uint64 nextPriorityRequestId = 0;

        emit NewPriorityRequest(
            msg.sender,
            nextPriorityRequestId,
            _opType,
            _pubData,
            expirationBlock
        );

    }
}
