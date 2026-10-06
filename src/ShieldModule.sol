// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success);
}

/// @notice Draft v0. Belum diaudit. Hanya untuk demo di fork lokal.
contract ShieldModule {
    ISafe public immutable safe;

    address public agent;
    address public allowedToken;
    uint256 public maxPerTx;
    uint256 public expiresAt;
    mapping(address => bool) public allowedRecipient;

    error NotSafe();
    error NotAgent();
    error Expired();
    error AmountTooHigh();
    error RecipientNotAllowed();
    error ExecutionFailed();
    error ZeroAddress();

    event PolicySet(address agent, address token, uint256 maxPerTx, uint256 expiresAt);
    event RecipientSet(address indexed who, bool ok);
    event Executed(address indexed to, uint256 amount);

    constructor(address _safe) {
        if (_safe == address(0)) revert ZeroAddress();
        safe = ISafe(_safe);
    }

    modifier onlySafe() {
        if (msg.sender != address(safe)) revert NotSafe();
        _;
    }

    function setPolicy(
        address _agent,
        address _token,
        uint256 _maxPerTx,
        uint256 _expiresAt
    ) external onlySafe {
        if (_agent == address(0) || _token == address(0)) revert ZeroAddress();
        agent = _agent;
        allowedToken = _token;
        maxPerTx = _maxPerTx;
        expiresAt = _expiresAt;
        emit PolicySet(_agent, _token, _maxPerTx, _expiresAt);
    }

    function setRecipient(address who, bool ok) external onlySafe {
        allowedRecipient[who] = ok;
        emit RecipientSet(who, ok);
    }

    // Satu-satunya jalan agen untuk menggerakkan dana Safe.
    function transferToken(address to, uint256 amount) external {
        if (msg.sender != agent) revert NotAgent();
        if (block.timestamp > expiresAt) revert Expired();
        if (amount > maxPerTx) revert AmountTooHigh();
        if (!allowedRecipient[to]) revert RecipientNotAllowed();

        emit Executed(to, amount);

        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
        bool ok = safe.execTransactionFromModule(allowedToken, 0, data, 0);
        if (!ok) revert ExecutionFailed();
    }
}
