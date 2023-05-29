// SPDX-License-Identifier: MIT

// Project: NERD Token
//
// Website: http://nerd.vip
// Twitter: @nerdoneth
//
// Note: The coin is completely useless and intended solely for entertainment and educational purposes. Please do not expect any financial returns.

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/interfaces/IERC20.sol";
import "../src/Nerd.sol";

contract NerdAirdropTest is Test {
    Nerd public nerd;
    IERC20 public nerdSR;

    function setUp() public {
        nerd = new Nerd(address(this));
        nerdSR = IERC20(nerd.SR());
        nerdSR.transfer(address(0), nerdSR.balanceOf(address(this)));
        nerd.transfer(address(nerd), nerd.balanceOf(address(this)));
    }

    function test_Airdrop() public {
        uint256 contractETHBalanceBefore = address(nerd).balance;
        uint256 contractTokenBalanceBefore = nerd.balanceOf(address(nerd));

        nerd.airdrop{value: 1 ether}();

        assertEq(contractETHBalanceBefore + 1 ether, address(nerd).balance);
        assertEq(contractTokenBalanceBefore - 10_000 ether, nerd.balanceOf(address(nerd)));
        assertEq(10_000 ether, nerd.balanceOf(address(this)));
        assertEq(0, nerdSR.balanceOf(address(this)));
    }

    function test_AirdropZero() public {
        nerd.airdrop{value: 0}();
        assertEq(0, nerd.balanceOf(address(this)));
    }

    function test_AirdropWithStake() public {
        uint256 contractTokenBalanceBefore = nerd.balanceOf(address(nerd));

        nerd.airdrop{value: 1 ether}();
        nerd.stake(10_000 ether);
        nerd.airdrop{value: 1 ether}();
        nerd.stake(10_000 ether);

        assertEq(2 ether, address(nerd).balance);
        assertEq(contractTokenBalanceBefore, nerd.balanceOf(address(nerd)));
        assertEq(20_000 ether, nerd.totalStaked());
    }

    function test_AirdropWithStakeShouldFail() public {
        // empty NERD balance from contract
        nerd.airdrop{value:(nerd.balanceOf(address(nerd)) / 10_000)}();
        assertEq(0, nerd.balanceOf(address(nerd)));

        nerd.stake(100_000 ether);
        assertEq(100_000 ether, nerd.balanceOf(address(nerd)));

        // contract have enough balance to return NERD but should account for staked amount & fail
        try nerd.airdrop{value: 1 ether}() {
            fail();
        } catch {}
    }
}
