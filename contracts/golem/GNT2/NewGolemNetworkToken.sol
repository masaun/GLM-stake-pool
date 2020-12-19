pragma solidity ^0.5.10;

import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";

contract NewGolemNetworkToken is ERC20Mintable {
    string public name = "Golem Network Token";
    string public symbol = "GLM";
    uint8 public decimals = 18;
    string public constant version = "1";
    mapping(address => uint) public nonces;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(address _migrationAgent, uint256 _chainId) public {
        addMinter(_migrationAgent);
        renounceMinter();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (sender != msg.sender && allowance(sender, msg.sender) != uint(-1)) {
            _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    // --- Approve by signature ---
    function permit(
        address holder, address spender, uint256 nonce, uint256 expiry,
        bool allowed, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        holder,
                        spender,
                        nonce,
                        expiry,
                        allowed
                    )
                )
            )
        );

        require(holder != address(0), "Ngnt/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Ngnt/invalid-permit");
        require(expiry == 0 || now <= expiry, "Ngnt/permit-expired");
        require(nonce == nonces[holder]++, "Ngnt/invalid-nonce");
        uint wad = allowed ? uint(- 1) : 0;
        _approve(holder, spender, wad);
    }
}
