// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {GrimSwapZK} from "../src/zk/GrimSwapZK.sol";
import {IGrimPool} from "../src/zk/interfaces/IGrimPool.sol";
import {IGroth16Verifier} from "../src/zk/interfaces/IGroth16Verifier.sol";

contract HookDeployer {
    function deploy(
        bytes32 salt,
        IPoolManager poolManager,
        IGroth16Verifier verifier,
        IGrimPool grimPool
    ) external returns (GrimSwapZK) {
        return new GrimSwapZK{salt: salt}(poolManager, verifier, grimPool);
    }
}

contract Step1_DeployHookDeployer is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        HookDeployer hd = new HookDeployer();
        console.log("HookDeployer:", address(hd));
        vm.stopBroadcast();
    }
}
