// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Game.sol";
import "./Hero.sol";
import "./NFT.sol";

contract Box is Ownable, ReentrancyGuard{
    constructor() {
    }
    mapping(uint256=>address) _boxByUser;
    mapping(address=>uint256[]) _userBoxs;
    uint256 _boxId = 0;
    uint256 _boxPrice=100*10**18;
    Game public  _game;
    Hero _hero = Hero(0xCDdB3Df2ecEa4A23ddf36644B82920677be3FFB2);
    NFT public _nft = NFT(0x03960BF2C1074c915a86618433f1E580C3cbfA59);
    uint256 _lockTime = 12*3600;
    uint256 _temNum=5;
    mapping(address => bool) public whiteList;
    address public bank;
    uint256 public discountNumerator = 9000;
    uint256 public discountDenominator = 10000;


    struct monsterInfo{
        uint256 rarity;
        uint256 ce;
        uint256 armor;
        uint256 luk;
        string name; 
    }
     
    event BuyBox(uint32 index,uint256 price,address sender);
    event OpenBox(uint256 indexed rarity,uint256 indexed tokenId,uint256 monsterId,address sender);
    event AddWhiteList(address indexed account, bool status);

    function addWhiteList(address account, bool status) public onlyOwner {
        whiteList[account] = status;
        emit AddWhiteList(account, status);
    }

    function addWhiteListBatch(address[] memory accounts, bool status) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; ++i) {
            whiteList[accounts[i]] = status;
            emit AddWhiteList(accounts[i], status);
        }
    }

    function setBank(address _bank) public onlyOwner {
        bank = _bank;
    }

    function setRate(uint256 _discountNumerator, uint256 _discountDenominator) public onlyOwner {
        discountNumerator = _discountNumerator;
        discountDenominator = _discountDenominator;
    }
    
    function buyBox()  public nonReentrant payable{
        uint256 price = _boxPrice;
        if(whiteList[msg.sender]) {
            price = _boxPrice * discountNumerator / discountDenominator;
        }
        payable(bank).transfer(price);
        _boxByUser[_boxId]= msg.sender;
        _userBoxs[msg.sender].push(_boxId);
        _boxId += 1;

        _hero.initHeroEq(msg.sender);
        emit BuyBox(1,uint256(_boxPrice),msg.sender);
    }

    function buyBoxBatch(uint256 amount) public payable {
        for(uint256 i = 0; i < amount; ++i) {
            buyBox();
        }
    }
    
    function openBox(uint32 _index)  public {
        require(_boxByUser[_index] == msg.sender,"Insufficient permissions");
       
        uint256 tokenId;
        uint256 nftKindId;
        uint256 monsterId;
        monsterInfo memory _monster ;
        (nftKindId,monsterId,_monster.ce,_monster.armor,_monster.luk,_monster.name) = _hero.getMonsterType();
        tokenId = _nft.safeMint(msg.sender);
        _game.createCard(tokenId,_monster.ce,_monster.armor,_monster.luk,_lockTime, nftKindId,_monster.name,_temNum,msg.sender);
        
        for(uint256 i=0;i<_userBoxs[msg.sender].length;i++){
            if(_userBoxs[msg.sender][i] == _index){
                // delete _userBoxs[msg.sender][i] ;
                // _userBoxs[msg.sender][i] = _userBoxs[msg.sender][_userBoxs[msg.sender].length - 1];
                _userBoxs[msg.sender][i] = _userBoxs[msg.sender][_userBoxs[msg.sender].length - 1];
                _userBoxs[msg.sender].pop();
            }
        }
        emit OpenBox(nftKindId,tokenId,monsterId,msg.sender);
    }

    function openBoxBatch(uint32[] memory indexs) public {
        for(uint256 i = 0; i < indexs.length; ++i) {
            openBox(indexs[i]);
        }
    }

    function getUserBoxs(address sender) view public returns(uint256[] memory){
        return _userBoxs[sender];
    }

    function setBoxPrice(uint256 boxPrice) public onlyOwner{
        _boxPrice = boxPrice;
    }

    function getBoxPrice() public view returns(uint256 amounts){
        amounts = _boxPrice;
    }

    function withdrawal(address tokenAddress,address from,address to,uint256 amount) public onlyOwner{
        IERC20(tokenAddress).transferFrom(from, to, amount);
    }

    function setGame(address payable _gameAddress) public onlyOwner{
        _game = Game(_gameAddress);
    }

    function setHero(address _tokenAddress)public onlyOwner{
        _hero = Hero(_tokenAddress);
    }
    function setNftToken(address _NFTToken)  public onlyOwner {
        _nft = NFT(_NFTToken);
    }
 
}
