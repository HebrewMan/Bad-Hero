// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IHero.sol";
import "./interfaces/IGame.sol";
import "./NFT.sol";
contract Box is Ownable, ReentrancyGuard{

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 _boxId;
    uint256 boxPrice=1*10**18;
    uint256 _lockTime = 12*3600;
    uint256 _temNum = 5;
    uint256 public discountNumerator = 7000;
    uint256 public discountDenominator = 10000;
    address public bank = 0xca4cA3B126154b8952d3068Eb3498CdE8be1B025; // ====================== change

    IGame public Game;
    IHero public Hero = IHero(0xCDdB3Df2ecEa4A23ddf36644B82920677be3FFB2);
    NFT public Nft = NFT(0x03960BF2C1074c915a86618433f1E580C3cbfA59);

    mapping(uint256 => address) _boxByUser;
    mapping(address => EnumerableSet.UintSet) _userBoxs;
    mapping(address => uint256)public userBoughtBoxs;
    mapping(address => bool) public whiteList;

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
    
    function buyBox() public nonReentrant payable{
        uint256 price = boxPrice;
        //test network 3 main network should be 10.
        require(msg.value >= boxPrice,"Msg.value Insufficient funds");
        if(whiteList[msg.sender] && userBoughtBoxs[msg.sender] < 10) {
            price = boxPrice * discountNumerator / discountDenominator;
            uint backEth = boxPrice - price;
            payable(msg.sender).transfer(backEth);
        }
        payable(bank).transfer(price);
        userBoughtBoxs[msg.sender]++;
        _boxByUser[_boxId]= msg.sender;
        _userBoxs[msg.sender].add(_boxId);
        _boxId += 1;

        Hero.initHeroEq(msg.sender);
        emit BuyBox(1,uint256(boxPrice),msg.sender);
    }

    function buyBoxBatch(uint256 amount) public payable {
        require(amount<=10,"Box:Max 10");
        for(uint256 i = 0; i < amount; ++i) {
            buyBox();
        }
    }
    
    function openBox(uint32 _index)  public {
        require(_boxByUser[_index] == msg.sender,"Insufficient permissions");
        require(_userBoxs[msg.sender].contains(_index), "Box:current index id does not exist.");
        uint256 tokenId;
        uint256 nftKindId;
        uint256 monsterId;
        monsterInfo memory _monster;
        (nftKindId,monsterId,_monster.ce,_monster.armor,_monster.luk,_monster.name) = Hero.getMonsterType();
        tokenId = Nft.safeMint(msg.sender);
        Game.createCard(tokenId,_monster.ce,_monster.armor,_monster.luk,_lockTime, nftKindId,_monster.name,_temNum,msg.sender);
        
        _userBoxs[msg.sender].remove(_index);
        emit OpenBox(nftKindId,tokenId,monsterId,msg.sender);
        
    }

    function openBoxBatch(uint32[] memory indexs) public {
        for(uint256 i = 0; i < indexs.length; ++i) {
            openBox(indexs[i]);
        }
    }

    //set box price
    function setBoxPrice(uint256 _boxPrice) public onlyOwner{
        boxPrice = _boxPrice;
    }

    function setGame(address payable _addr) public onlyOwner{
        Game = IGame(_addr);
    }

    function setRate(uint256 _discountNumerator, uint256 _discountDenominator) public onlyOwner {
        discountNumerator = _discountNumerator;
        discountDenominator = _discountDenominator;
    }

    function setHero(address _tokenAddress)public onlyOwner{
        Hero = IHero(_tokenAddress);
    }
    function setNftToken(address _NFTToken)  public onlyOwner {
        Nft = NFT(_NFTToken);
    }

    function getBoxPrice() public view returns(uint256){
        return boxPrice;
    }

    function getUserBoxs(address sender)public view  returns(uint256[] memory){
        return _userBoxs[sender].values();
    }
 
}
