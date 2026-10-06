// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Safe} from "../lib/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "../lib/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Enum} from "../lib/safe-smart-account/contracts/libraries/Enum.sol";
import {ShieldModule} from "../src/ShieldModule.sol";
import {DemoUSDC} from "../src/DemoUSDC.sol";

contract Deploy is Script {
    function run() external {
        uint256 ownerPk = vm.envUint("OWNER_PK");
        address owner = vm.addr(ownerPk);
        address agent = vm.envAddress("AGENT");
        address friend = vm.envAddress("FRIEND");

        vm.startBroadcast(ownerPk);

        Safe singleton = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();

        address[] memory owners = new address[](1);
        owners[0] = owner;
        bytes memory init = abi.encodeWithSelector(
            Safe.setup.selector,
            owners, 1, address(0), bytes(""), address(0), address(0), 0, address(0)
        );
        Safe safe = Safe(payable(address(factory.createProxyWithNonce(address(singleton), init, 1))));

        DemoUSDC usdc = new DemoUSDC();
        usdc.mint(address(safe), 10_000e6);

        ShieldModule module = new ShieldModule(address(safe));

        _exec(safe, owner, address(safe), abi.encodeWithSignature("enableModule(address)", address(module)));
        _exec(safe, owner, address(module), abi.encodeWithSelector(
            ShieldModule.setPolicy.selector, agent, address(usdc), 500e6, block.timestamp + 1 days
        ));
        _exec(safe, owner, address(module), abi.encodeWithSelector(ShieldModule.setRecipient.selector, friend, true));

        vm.stopBroadcast();

        console.log("SAFE   =", address(safe));
        console.log("MODULE =", address(module));
        console.log("USDC   =", address(usdc));
    }

    function _exec(Safe safe, address owner, address to, bytes memory data) internal {
        bytes memory sig = abi.encodePacked(bytes32(uint256(uint160(owner))), bytes32(0), uint8(1));
        safe.execTransaction(to, 0, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), sig);
    }
}
