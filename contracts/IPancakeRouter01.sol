// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPancakeSwapRouter {   
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}