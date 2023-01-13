// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

 struct CardDetails{
        uint32 genre;
        uint256 tokenId;
        uint256 hp;
        uint256 level;
        uint256 xp;
        uint256 ce;
        uint256 armor;
        uint256 luk;
        uint256 unLockTime;
        uint256 rgTime;
        uint256 nftKindId; 
        string name; 
}
interface IGame {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function DisReward(address rewardAddr,uint256 reward)external;
    function addTokenReward(address user,uint256 reward) external;
    function setTokenDetailGenre(uint256 tokenId,uint32 genre) external;
    function addBack(uint256 tokenId,address sender) external;
    function editCardDetails(uint256 tokenId,address addr)  external;
    function moveBack(uint256 tokenId,address sender) external;
    function isBack(uint256 tokenId,address sender) external view returns(bool);
    function getTokenDetail(uint256 tokenId)external view returns(uint256 level,uint256 ce,uint256 xp,uint256 armor,uint256 luk,uint256 rgTime);
    function getTokenDetails(uint256 tokenId)external view returns(CardDetails memory);
    function getUserAddress(uint256 tokenId)external view returns(address);
    function createCard(uint256 tokenId,uint256 ce,uint256 armor,uint256 luk,uint256 unLockTime,uint256 nftKindId,string memory name,uint256 maxNum,address _userAddress) external returns(uint256);
}
