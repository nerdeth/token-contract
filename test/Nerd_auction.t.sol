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
import "../src/Factory.sol";
import "./UniswapV2Deployer.sol";

contract NerdStakeTest is UniswapV2Deployer {
    Nerd public nerd;
    IERC20 public nerdSR;
    IUniswapV2Pair public mainPair;

    function setUp() public {
        Factory factory = new Factory{value: 1 ether}();
        nerd = Nerd(factory.nerd());
        nerdSR = IERC20(nerd.SR());

        mainPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.getPair(address(nerd), address(WETH)));
    }

    function testFail_BidWithLowAmount() public {
        nerd.bid(100 ether, type(uint256).max);
        skip(5 minutes);
        nerd.bid(101 ether, type(uint256).max);
    }

    function test_BidShouldExtendDeadline() public {
        nerd.bid(1 ether, type(uint256).max);
        (,, uint40 firstDeadline) = nerd.auction();

        vm.warp(firstDeadline - 10 seconds);
        nerd.bid(2 ether, type(uint256).max);
        (,, uint40 secondDeadline) = nerd.auction();
        assertEq(secondDeadline, block.timestamp + 20 minutes);
    }

    function test_BidShouldNotExtendDeadline() public {
        nerd.bid(1 ether, type(uint256).max);
        (,, uint40 firstDeadline) = nerd.auction();
        assertEq(firstDeadline, block.timestamp + 12 hours);

        // Deadline should be only extended if deadline is <20min from block.timestamp
        vm.warp(firstDeadline - 1 hours);
        nerd.bid(2 ether, type(uint256).max);
        (,, uint40 secondDeadline) = nerd.auction();
        assertEq(firstDeadline, secondDeadline);
    }

    function test_NewBidShouldReturnPreviousAmount() public {
        nerd.transfer(address(1), 100 ether);
        nerd.transfer(address(2), 100 ether);

        vm.prank(address(1));
        nerd.bid(1 ether, type(uint256).max);
        assertEq(99 ether, nerd.balanceOf(address(1)));

        vm.prank(address(2));
        nerd.bid(2 ether, type(uint256).max);

        assertEq(100 ether, nerd.balanceOf(address(1)));
        assertEq(98 ether, nerd.balanceOf(address(2)));
    }

    function testFail_BidWithNotEnoughBalance() public {
        vm.prank(address(3));
        nerd.bid(1 ether, type(uint256).max);
    }

    function testFail_BidWithDeadlineInThePast() public {
        vm.warp(100 seconds);
        nerd.bid(1 ether, 99 seconds);
    }

    function test_WinningAuction() public {
        winAuctionWith(1 ether);

        (uint128 bidAmount, uint128 mintAmount, address winner) = nerd.previousAuction();
        assertEq(1 ether, bidAmount);
        assertEq(0, mintAmount);
        assertEq(address(this), winner);
    }

    function testFail_WinnerMintWithDifferenteAddress() public {
        winAuctionWith(1 ether);
        vm.prank(address(1));
        nerd.winnerMintSR(1 ether);
    }

    function test_WinnerMint() public {
        uint256 beforeBalanceSR = nerdSR.balanceOf(address(this));
        winAuctionWith(1 ether);

        uint256 beforeBalance = nerd.balanceOf(address(this));
        nerd.winnerMintSR(1 ether);
        uint256 nerdCost = beforeBalance - nerd.balanceOf(address(this));
        assertEq((1 ether / 10) + 1, nerdCost);
        assertEq(1 ether + beforeBalanceSR, nerdSR.balanceOf(address(this)));
    }

    function test_WinnerMintSmallAmount() public {
        uint256 beforeBalanceSR = nerdSR.balanceOf(address(this));
        winAuctionWith(1 ether);

        uint256 beforeBalance = nerd.balanceOf(address(this));
        nerd.winnerMintSR(1);
        uint256 nerdCost = beforeBalance - nerd.balanceOf(address(this));
        assertEq(1, nerdCost);
        assertEq(1 + beforeBalanceSR, nerdSR.balanceOf(address(this)));
    }

    function test_WinnerMintZeroAmount() public {
        uint256 beforeBalanceSR = nerdSR.balanceOf(address(this));
        winAuctionWith(1 ether);

        uint256 beforeBalance = nerd.balanceOf(address(this));
        nerd.winnerMintSR(0);
        uint256 nerdCost = beforeBalance - nerd.balanceOf(address(this));
        assertEq(1, nerdCost);
        assertEq(0 + beforeBalanceSR, nerdSR.balanceOf(address(this)));
    }

    function test_AuctionWinnerAirdrop() public {
        WETH.deposit{value: 1 ether}();
        uint256 lpBalanceBefore = IERC20(nerd.mainPool()).balanceOf(address(nerd));
        uint256 expectedPoolAmount = (_swap(address(WETH), address(nerd), address(0), 1 ether) / 2);
        assertEq(expectedPoolAmount, nerd.auctionPoolAmount());

        winAuctionWith(1 ether);

        assertEq(expectedPoolAmount / 10, nerdSR.balanceOf(address(this)));
        assertEq(lpBalanceBefore / 2000, IERC20(nerd.mainPool()).balanceOf(address(this)));
    }

    function testFail_WinnerBurnWithDifferenteAddress() public {
        winAuctionWith(1 ether);
        vm.prank(address(1));
        nerd.winnerBurnSR(1 ether);
    }

    function testFail_WinnerBurnForUsedMintAmount() public {
        winAuctionWith(10 ether);

        nerd.winnerMintSR(1 ether);
        nerd.winnerBurnSR(10 ether);
    }

    function test_BurnSR() public {
        _swap(address(nerd), address(nerdSR), address(this), 100 ether);
        uint256 balanceBefore = nerd.balanceOf(address(this));
        uint256 balanceBeforeSR = nerdSR.balanceOf(address(this));

        nerd.burnSR(1);
        assertEq(balanceBefore, nerd.balanceOf(address(this)));
        assertEq(balanceBeforeSR - 1, nerdSR.balanceOf(address(this)));

        nerd.burnSR(39);
        assertEq(balanceBefore, nerd.balanceOf(address(this)));
        assertEq(balanceBeforeSR - 40, nerdSR.balanceOf(address(this)));

        nerd.burnSR(40 ether);
        assertEq(balanceBefore + 1 ether, nerd.balanceOf(address(this)));
        assertEq(balanceBeforeSR - (40 + 40 ether), nerdSR.balanceOf(address(this)));
    }

    function test_BurnSRFailOnLowAmount() public {
        _swap(address(nerd), address(nerdSR), address(this), 10 ether);
        uint256 balanceBeforeSR = nerdSR.balanceOf(address(this));

        nerd.burnSR(1);
        try nerd.burnSR(balanceBeforeSR) {
            fail();
        } catch {}
    }

    function testFail_AddLiquidityWithoutWinningAuction() public {
        nerd.airdrop{value: 10 ether}();
        nerd.winnerAddLiquidity();
    }

    function testFail_AddLiquidityDifferentAddress() public {
        nerd.airdrop{value: 10 ether}();
        winAuctionWith(1 ether);

        vm.prank(address(3));
        nerd.winnerAddLiquidity();
    }

    function test_SwapAndAddLiquiditySameTimestampFail() public {
        nerd.airdrop{value: 10 ether}();
        winAuctionWith(1 ether);

        _swap(address(nerd), address(nerdSR), address(this), 1 ether);
        _swap(address(nerd), address(WETH), address(this), 1 ether);

        try nerd.winnerAddLiquidity() {
            fail();
        } catch {}
    }

    function test_WinnerAddLiquidityOver100Eth() public {
        address pairAddr = address(mainPair);
        IERC20 WETH_ERC20 = IERC20(address(WETH));
        nerd.airdrop{value: 210 ether}();
        uint256 beforeBalance = WETH_ERC20.balanceOf(pairAddr);

        winAuctionWith(1 ether);
        nerd.winnerAddLiquidity();
        assertEq(beforeBalance + 100 ether, WETH_ERC20.balanceOf(pairAddr));

        winAuctionWith(1 ether);
        nerd.winnerAddLiquidity();
        assertEq(beforeBalance + 200 ether, WETH_ERC20.balanceOf(pairAddr));

        winAuctionWith(1 ether);
        nerd.winnerAddLiquidity();
        assertEq(beforeBalance + 210 ether, WETH_ERC20.balanceOf(pairAddr));
    }

    function test_WinnerAddLiquidityTwicePerAuction() public {
        nerd.airdrop{value: 210 ether}();
        winAuctionWith(1 ether);

        nerd.winnerAddLiquidity();
        skip(1 hours);
        try nerd.winnerAddLiquidity() {
            fail();
        } catch {}
    }

    function winAuctionWith(uint256 amount) internal {
        nerd.bid(amount, type(uint256).max);
        skip(13 hours);
        nerd.bid(1, type(uint256).max); // starting new auction is required to roll winner
    }
}
