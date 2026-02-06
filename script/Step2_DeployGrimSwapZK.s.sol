// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {GrimSwapZK} from "../src/zk/GrimSwapZK.sol";
import {IGrimPool} from "../src/zk/interfaces/IGrimPool.sol";
import {IGroth16Verifier} from "../src/zk/interfaces/IGroth16Verifier.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

interface IHookDeployer {
    function deploy(bytes32 salt, IPoolManager poolManager, IGroth16Verifier verifier, IGrimPool grimPool) external returns (GrimSwapZK);
}

contract Step2_DeployGrimSwapZK is Script {
    address constant HOOK_DEPLOYER = 0x04502BD20b6Aa2672c14fa18a192d45D3b98c43C;
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GROTH16_VERIFIER = 0xF7D14b744935cE34a210D7513471a8E6d6e696a0;
    address constant GRIM_POOL = 0xEAB5E7B4e715A22E8c114B7476eeC15770B582bb;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG);
        
        bytes memory creationCode = type(GrimSwapZK).creationCode;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            IGroth16Verifier(GROTH16_VERIFIER),
            IGrimPool(GRIM_POOL)
        );
        
        (address hookAddress, bytes32 salt) = HookMiner.find(HOOK_DEPLOYER, flags, creationCode, constructorArgs);
        console.log("Expected hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));
        
        vm.startBroadcast(pk);
        GrimSwapZK hook = IHookDeployer(HOOK_DEPLOYER).deploy(
            salt,
            IPoolManager(POOL_MANAGER),
            IGroth16Verifier(GROTH16_VERIFIER),
            IGrimPool(GRIM_POOL)
        );
        console.log("GrimSwapZK deployed at:", address(hook));
        vm.stopBroadcast();
    }
}
