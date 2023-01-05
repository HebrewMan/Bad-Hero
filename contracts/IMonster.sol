// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMonster {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function fighting(uint256 tokenId,uint256 enemyId) external view returns (bool,uint256,uint256);

    function DoTask(uint256 tokenId,uint256 odds,uint256 basicReward )  external view returns(bool,uint256,uint256);
}
