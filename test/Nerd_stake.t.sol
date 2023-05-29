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

contract NerdStakeTest is Test {
    Nerd public nerd;
    IERC20 public nerdSR;
    uint256 public initialNerdBalance;

    function setUp() public {
        nerd = new Nerd(address(this));
        initialNerdBalance = nerd.balanceOf(address(this));

        nerdSR = IERC20(nerd.SR());
        nerdSR.transfer(address(0), nerdSR.balanceOf(address(this)));
    }

    function test_StakeUnstakeSameBlock() public {
        nerd.stake(1 ether);
        assertEq(initialNerdBalance - 1 ether, nerd.balanceOf(address(this)));
        nerd.unstake(1 ether);
        assertEq(initialNerdBalance, nerd.balanceOf(address(this)));
        assertEq(IERC20(nerd.SR()).balanceOf(address(this)), 0);
    }

    function testFuzz_StakeUnstakeSameBlock(uint128 _amount) public {
        uint256 amount = bound(_amount, 0, initialNerdBalance);
        nerd.stake(amount);
        assertEq(nerd.balanceOf(address(this)), initialNerdBalance - amount);
        nerd.unstake(amount);
        assertEq(nerd.balanceOf(address(this)), initialNerdBalance);
        assertEq(IERC20(nerd.SR()).balanceOf(address(this)), 0);
    }

    function testFailFuzz_UnstakeWithoutStakeBefore(uint128 amount) public {
        vm.assume(amount > 0);
        nerd.unstake(amount);
    }

    function test_StakeUnstakeSameAmount() public {
        nerd.stake(1 ether);
        skip(500 days);
        nerd.unstake(1 ether);

        try nerd.unstake(1) {
            fail();
        } catch {}
    }

    function test_StakeUnstake1Second() public {
        nerd.stake(1 ether);
        assertEq(nerd.totalStaked(), 1 ether);

        skip(1 seconds);

        nerd.unstake(1 ether);
        assertEq(initialNerdBalance, nerd.balanceOf(address(this)));
        assertEq(0, nerdSR.balanceOf(address(this)));
        assertEq(0, nerd.totalStaked());
    }

    function test_Stake1Year() public {
        // 1 year is 256% rate
        uint256 expectedReward = 2559999999999998692;

        nerd.stake(1 ether);
        assertEq(initialNerdBalance - 1 ether, nerd.balanceOf(address(this)));

        skip(365 days);

        nerd.unstake(1 ether);
        assertEq(initialNerdBalance, nerd.balanceOf(address(this)));
        assertEq(expectedReward, nerdSR.balanceOf(address(this)));
    }

    function test_Stake64Days() public {
        // 64 days is max rate => 256%*(64/365) ~= 0,448
        uint256 expectedReward = 448876712328766894;

        nerd.stake(1 ether);
        skip(64 days);
        nerd.unstake(1 ether);

        assertEq(expectedReward, nerdSR.balanceOf(address(this)));
    }

    function test_Stake32Days() public {
        // 32 days is half warmup period = half rate => 128%*(32/365) ~= 0,112
        uint256 expectedReward = 112219178082191585;

        nerd.stake(1 ether);
        skip(32 days);
        nerd.unstake(1 ether);

        assertEq(expectedReward, nerdSR.balanceOf(address(this)));
    }

    function test_Stake7Days() public {
        // 2.56*(7/64)*(7/365) ~= 0,005369
        uint256 expectedReward = 5369863013698579;

        nerd.stake(1 ether);
        skip(7 days);
        assertEq(expectedReward, nerd.stakeRewardOf(address(this)));
        nerd.stake(0);
        assertEq(expectedReward, nerdSR.balanceOf(address(this)));

        nerd.unstake(1 ether);
        assertEq(expectedReward, nerdSR.balanceOf(address(this)));
    }

    function test_StakeRewardOfMissingStake() public {
        assertEq(0, nerd.stakeRewardOf(address(8)));
    }
}
