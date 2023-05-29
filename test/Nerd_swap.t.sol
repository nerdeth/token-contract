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
    Factory public factory;
    Nerd public nerd;
    IERC20 public nerdSR;
    IUniswapV2Pair public mainPair;
    IUniswapV2Pair public srPair;

    function setUp() public {
        factory = new Factory{value: 1 ether}();
        nerd = Nerd(factory.nerd());
        nerdSR = IERC20(nerd.SR());

        mainPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.getPair(address(nerd), address(WETH)));
        srPair = IUniswapV2Pair(UNISWAP_V2_FACTORY.getPair(address(nerd), address(nerdSR)));
    }

    function test_FactoryDeploy() public {
        assertEq(64_000_000 ether, nerd.totalSupply());

        // Factory should have empty balance
        assertEq(0, address(factory).balance);
        assertEq(0, nerd.balanceOf(address(factory)));
        assertEq(0, nerdSR.balanceOf(address(factory)));

        // Deployer should not receive SR airdrop
        assertEq(6_400_000 ether, nerd.balanceOf(address(this)));
        assertEq(0, nerdSR.balanceOf(address(this)));

        // Main NERD/WETH_A pool
        assertEq(10_000 ether, nerd.balanceOf(address(mainPair)));
        assertEq(1 ether, IERC20(address(WETH)).balanceOf(address(mainPair)));

        // Main NERDs/NERD pool
        assertEq(6_400_000 ether, nerd.balanceOf(address(srPair)));
        assertEq(6_400_000 ether * 4, nerdSR.balanceOf(address(srPair)));
    }

    function test_SwapSRPool_ToSR() public {
        nerd.transfer(address(1), 10 ether);
        vm.startPrank(address(1));
        assertEq(0, nerdSR.balanceOf(address(1)));

        uint256 expectedOutAmount1 = _swap(address(nerd), address(nerdSR), address(1), 1 ether);
        assertEq(expectedOutAmount1, nerdSR.balanceOf(address(1)));
        assertEq(9 ether, nerd.balanceOf(address(1)));

        uint256 expectedOutAmount2 = _swap(address(nerd), address(nerdSR), address(1), 1 ether);
        assertEq(expectedOutAmount1 + expectedOutAmount2, nerdSR.balanceOf(address(1)));
        assertEq(8 ether, nerd.balanceOf(address(1)));
    }

    function test_SwapSRPool_FromSR() public {
        nerd.transfer(address(1), 10 ether);
        vm.startPrank(address(1));
        _swap(address(nerd), address(nerdSR), address(1), 10 ether);
        uint256 beforeSRBalance = nerdSR.balanceOf(address(1));

        uint256 expectedOutAmount1 = _swap(address(nerdSR), address(nerd), address(1), 10 ether);
        assertEq(expectedOutAmount1, nerd.balanceOf(address(1)));
        assertEq(beforeSRBalance - 10 ether, nerdSR.balanceOf(address(1)));

        uint256 expectedOutAmount2 = _swap(address(nerdSR), address(nerd), address(1), 10 ether);
        assertEq(expectedOutAmount1 + expectedOutAmount2, nerd.balanceOf(address(1)));
        assertEq(beforeSRBalance - 20 ether, nerdSR.balanceOf(address(1)));
    }

    function test_SwapBuyShouldAirdropSR() public {
        WETH.deposit{value: 2 ether}();
        uint256 beforeNerdBalance = nerd.balanceOf(address(this));
        uint256 beforeSRBalance = nerdSR.balanceOf(address(this));

        uint256 expectedOutAmount1 = _swap(address(WETH), address(nerd), address(this), 1 ether);
        assertEq(beforeNerdBalance + expectedOutAmount1, nerd.balanceOf(address(this)));
        assertEq(beforeSRBalance + (expectedOutAmount1 / 2), nerdSR.balanceOf(address(this)));

        uint256 expectedOutAmount2 = _swap(address(WETH), address(nerd), address(this), 1 ether);
        assertEq(beforeNerdBalance + expectedOutAmount1 + expectedOutAmount2, nerd.balanceOf(address(this)));
        assertEq(beforeSRBalance + (expectedOutAmount1 / 2) + (expectedOutAmount2 / 2), nerdSR.balanceOf(address(this)));
    }

    function test_SwapSellShouldFailWithoutSR() public {
        assertTrue(nerd.balanceOf(address(this)) > 1 ether);
        assertEq(0, nerdSR.balanceOf(address(this)));

        nerd.approve(address(UNISWAP_V2_ROUTER), 1 ether);
        address[] memory path = new address[](2);
        path[0] = address(nerd);
        path[1] = address(WETH);

        try UNISWAP_V2_ROUTER.swapExactTokensForTokens(1 ether, 0, path, address(this), type(uint256).max) {
            fail();
        } catch {}
    }

    function test_SwapSellShouldBurnSR() public {
        _swap(address(nerd), address(nerdSR), address(this), 10 ether);
        nerd.transfer(address(1), 10 ether);
        nerdSR.transfer(address(1), 10 ether);
        vm.startPrank(address(1));

        _swap(address(nerd), address(WETH), address(1), 1 ether);
        assertEq(9 ether, nerd.balanceOf(address(1)));
        assertEq(9 ether, nerdSR.balanceOf(address(1)));

        _swap(address(nerd), address(WETH), address(1), 9 ether);
        assertEq(0, nerd.balanceOf(address(1)));
        assertEq(0, nerdSR.balanceOf(address(1)));
    }
}
