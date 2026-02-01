// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC5564Announcer} from "../src/ERC5564Announcer.sol";
import {IERC5564Announcer} from "../src/interfaces/IERC5564Announcer.sol";

contract ERC5564AnnouncerTest is Test {
    ERC5564Announcer public announcer;

    event Announcement(
        uint256 indexed schemeId,
        address indexed stealthAddress,
        address indexed caller,
        bytes ephemeralPubKey,
        bytes metadata
    );

    function setUp() public {
        announcer = new ERC5564Announcer();
    }

    function test_Announce_EmitsEvent() public {
        uint256 schemeId = 1;
        address stealthAddress = address(0x1234);
        bytes memory ephemeralPubKey = hex"02abcdef";
        bytes memory metadata = hex"deadbeef";

        vm.expectEmit(true, true, true, true);
        emit Announcement(schemeId, stealthAddress, address(this), ephemeralPubKey, metadata);

        announcer.announce(schemeId, stealthAddress, ephemeralPubKey, metadata);
    }

    function test_Announce_MultipleAnnouncements() public {
        for (uint256 i = 0; i < 5; i++) {
            address stealthAddress = address(uint160(0x1000 + i));
            announcer.announce(1, stealthAddress, hex"02", hex"");
        }
    }
}
