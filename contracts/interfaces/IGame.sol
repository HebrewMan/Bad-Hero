// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IGame {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getTokenDetail(uint256 tokenId)external view returns(uint256 level,uint256 ce,uint256 xp,uint256 armor,uint256 luk,uint256 rgTime);
    function createCard(uint256 tokenId,uint256 ce,uint256 armor,uint256 luk,uint256 unLockTime,uint256 nftKindId,string memory name,uint256 maxNum,address _userAddress) external returns(uint256);
}
