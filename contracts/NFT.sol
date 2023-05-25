// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./UserLib.sol";

contract NFT is ERC721, AccessControl,Ownable{
    using Counters for Counters.Counter;
    // using UserLib for UserLib.CardDetails;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    string public baseUri = "https://cryptohunter.stargame.io/api/metadata?TokenId=";

    constructor() ERC721("NFT", "MWR") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    function setRole(address addr) public onlyRole(DEFAULT_ADMIN_ROLE){
        _grantRole(MINTER_ROLE,addr);
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) returns(uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE){
        baseUri = uri;
    }

    function tokenURI(uint256 tokenid) view public override returns (string memory) {
        return string.concat(baseUri, Strings.toString(tokenid));
    }

}