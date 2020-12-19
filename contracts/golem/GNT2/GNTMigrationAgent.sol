pragma solidity ^0.5.10;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface MigrationAgent {
    function migrateFrom(address _from, uint256 _value) external;
}

contract GNTMigrationAgent is MigrationAgent, Ownable {
    using SafeMath for uint;

    ERC20Mintable public target;
    address public oldToken;

    mapping (address => uint256) public migratedForHolder;

    event TargetChanged (ERC20Mintable previousTarget, ERC20Mintable changedTarget);
    event Migrated (address from, ERC20Mintable target, uint256 value);

    constructor(address _oldToken) public {
        require(_oldToken != address(0), "Ngnt/migration-invalid-old-token");
        oldToken = _oldToken;
    }

    function migrateFrom(address _from, uint256 _value) public {
        require(msg.sender == address(oldToken), "Ngnt/migration-non-token-call");
        require(address(target) != address(0), "Ngnt/migration-target-not-set");

        migratedForHolder[_from] = migratedForHolder[_from].add(_value);
        target.mint(_from, _value);
        emit Migrated(_from, target, _value);
    }

    function setTarget(ERC20Mintable _target) public onlyOwner {
        emit TargetChanged(target, _target);
        target = _target;
    }

}
