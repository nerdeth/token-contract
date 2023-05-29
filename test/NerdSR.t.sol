// SPDX-License-Identifier: MIT

// Project: NERD Token
//
// Website: http://nerd.vip
// Twitter: @nerdoneth
//
// Note: The coin is completely useless and intended solely for entertainment and educational purposes. Please do not expect any financial returns.

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/NerdSR.sol";

contract NerdSRTest is Test {
    NerdSR public nerdSR;

    function setUp() public {
        nerdSR = new NerdSR();
        nerdSR.mint(address(1), 10 ether);
    }

    function testFail_MintAsNotOwner() public {
        vm.prank(address(1));
        nerdSR.mint(address(1), 1 ether);
    }

    function testFail_BurnAsNotOwner() public {
        vm.prank(address(1));
        nerdSR.burn(address(1), 1 ether);
    }
}