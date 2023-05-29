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
import "../src/interfaces/IWETH.sol";
import "../src/interfaces/IUniswapV2Router01.sol";
import "../src/interfaces/IUniswapV2Factory.sol";
import "../src/interfaces/IUniswapV2Pair.sol";

contract UniswapV2Deployer is Test {

    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory public constant UNISWAP_V2_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Router01 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);


    constructor() {
        vm.etch(address(WETH), vm.parseBytes(vm.readFile("./test/bytecode/WETH.txt")));
        vm.etch(address(UNISWAP_V2_FACTORY), vm.parseBytes(vm.readFile("./test/bytecode/UniswapV2Factory.txt")));
        vm.etch(address(UNISWAP_V2_ROUTER), vm.parseBytes(vm.readFile("./test/bytecode/UniswapV2Router.txt")));
    }

    function _swap(address token0, address token1, address to, uint256 amount) internal returns (uint256 outAmount) {
        IERC20(token0).approve(address(UNISWAP_V2_ROUTER), amount);
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        uint256[] memory amounts = UNISWAP_V2_ROUTER.swapExactTokensForTokens(amount, 0, path, to, type(uint256).max);
        outAmount = amounts[1];
    }

}