// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DemoToken} from "./DemoToken.sol";

/// @notice Router tiruan untuk demo. Siapa pun bisa mengubah kurs. JANGAN dipakai di jaringan asli.
contract MockRouter {
    uint256 public outPerMillionIn; // satuan token keluar per 1.000.000 satuan token masuk
    bool public honorMinOut = true; // false = meniru router buruk/jahat yang mengabaikan batas minimum

    function setRate(uint256 r) external { outPerMillionIn = r; }
    function setHonor(bool h) external { honorMinOut = h; }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut,
        address to
    ) external returns (uint256 out) {
        out = amountIn * outPerMillionIn / 1e6;
        if (honorMinOut) require(out >= minOut, "slippage");
        DemoToken(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        DemoToken(tokenOut).mint(to, out);
    }
}
