// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

 struct nftKind{
        uint32 start;
        uint32 end;
        uint64 atRate;
        string ranking;
        string rankingName;
        string url;
    }
interface IHero {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getCombatOdds(uint256 tokenId,address addr) external view returns(uint256,uint256,uint256,uint256,uint256,uint256);
    function initHeroEq(address _addr)external;
    function getMonsterType() external view returns(uint256 ,uint256,uint256,uint256,uint256,string memory);
    function getNftKind(uint256 index) external view returns(nftKind memory);
    
}
