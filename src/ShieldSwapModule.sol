// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISafeS {
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, uint8 operation)
        external returns (bool success);
}

interface IERC20Min {
    function balanceOf(address) external view returns (uint256);
}

/// @notice Draft v0. Belum diaudit. Hanya untuk demo di blockchain lokal.
contract ShieldSwapModule {
    ISafeS public immutable safe;

    address public agent;
    address public router;
    address public tokenIn;
    address public tokenOut;
    uint256 public maxAmountIn;
    uint256 public minOutPerMillionIn;
    uint256 public expiresAt;
    bool private locked;

    error NotSafe();
    error NotAgent();
    error Expired();
    error AmountTooHigh();
    error OutputTooLow();
    error CallFailed();
    error ZeroAddress();
    error Reentrancy();

    event PolicySet(address agent, address router, address tokenIn, address tokenOut);
    event Swapped(uint256 amountIn, uint256 received);

    constructor(address _safe) {
        if (_safe == address(0)) revert ZeroAddress();
        safe = ISafeS(_safe);
    }

    modifier onlySafe() {
        if (msg.sender != address(safe)) revert NotSafe();
        _;
    }

    function setPolicy(
        address _agent,
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxAmountIn,
        uint256 _minOutPerMillionIn,
        uint256 _expiresAt
    ) external onlySafe {
        if (_agent == address(0) || _router == address(0) || _tokenIn == address(0) || _tokenOut == address(0)) {
            revert ZeroAddress();
        }
        agent = _agent;
        router = _router;
        tokenIn = _tokenIn;
        tokenOut = _tokenOut;
        maxAmountIn = _maxAmountIn;
        minOutPerMillionIn = _minOutPerMillionIn;
        expiresAt = _expiresAt;
        emit PolicySet(_agent, _router, _tokenIn, _tokenOut);
    }

    function swap(uint256 amountIn) external {
        if (locked) revert Reentrancy();
        locked = true;

        if (msg.sender != agent) revert NotAgent();
        if (block.timestamp > expiresAt) revert Expired();
        if (amountIn == 0 || amountIn > maxAmountIn) revert AmountTooHigh();

        // Batas minimum dihitung dari aturan pemilik, bukan dari agen.
        uint256 requiredMin = amountIn * minOutPerMillionIn / 1e6;
        uint256 before = IERC20Min(tokenOut).balanceOf(address(safe));

        _call(tokenIn, abi.encodeWithSignature("approve(address,uint256)", router, amountIn));
        _call(
            router,
            abi.encodeWithSignature(
                "swap(address,address,uint256,uint256,address)",
                tokenIn, tokenOut, amountIn, requiredMin, address(safe)
            )
        );
        _call(tokenIn, abi.encodeWithSignature("approve(address,uint256)", router, 0));

        // Pemeriksaan hasil akhir: berlaku bahkan jika router mengabaikan batas minimum.
        uint256 received = IERC20Min(tokenOut).balanceOf(address(safe)) - before;
        if (received < requiredMin) revert OutputTooLow();

        emit Swapped(amountIn, received);
        locked = false;
    }

    function _call(address to, bytes memory data) internal {
        bool ok = safe.execTransactionFromModule(to, 0, data, 0);
        if (!ok) revert CallFailed();
    }
}
