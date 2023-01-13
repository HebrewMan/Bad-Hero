// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IGame.sol";

contract Market is AccessControl,Ownable{

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public unStakeTime = 86400;
    uint256 public fee = 5;
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IGame public Game;
    IERC20 public Erc20;
    IERC721 public NFT;
    stakeInfo public StakeInfo = stakeInfo(30,20*10000*10**18,100*10**18); 

    market[] markets;

    mapping(uint256=>market) _marketInfo;
    mapping(uint256=>mtStakeInfo) _tokenMtStakeInfo;
    mapping(address=>EnumerableSet.UintSet) userStakeInfo;
    mapping(address=>EnumerableSet.UintSet) userMarkets;

    constructor()  {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    event Shelves(uint256 indexed tokenId,uint256 indexed amount,uint256 indexed nftKindId,string name,address sender);
    event UnShelves(uint256 indexed tokenId,address sender);
    event BuyBft(uint256 indexed _tokenId,uint256 indexed money,address nftOwner, address msender);
    event Stake(uint256 indexed tokenId,uint256 indexed genre,address sender);
    event UnStake(uint256 indexed tokenId,uint256 indexed amount,address sender);
    
    struct stakeInfo{
        uint32 day;
        uint256 money;
        uint256 addMoney;
    }
    
    struct mtStakeInfo{
        uint256 tokenId;
        uint256 startTime; 
        uint256 endTime; 
        uint256 money;
    }
    
    struct market{
        uint256 tokenId;
        uint256 hp;
        uint256 level;
        uint256 xp;
        uint256 ce;
        uint256 armor;
        uint256 luk;
        uint256 price;
        string name; 
        address sender; 
    }
    
    struct cardDetails{
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

    function setStakeInfo(uint _reward)external onlyOwner{
        StakeInfo.money = _reward;
    }

    function setFee(uint _fee)external onlyOwner{
        fee = _fee;
    }

    function shelves(uint256 _tokenId,uint256 _money) public{
        require(Game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(Game.getTokenDetails(_tokenId).genre == 0,"Illegal 0 operation");
        cardDetails memory _nftDetails;
        (_nftDetails.level,_nftDetails.ce,_nftDetails.xp,_nftDetails.armor,_nftDetails.luk,_nftDetails.rgTime) =  Game.getTokenDetail(_tokenId);
        _marketInfo[_tokenId] = market(_tokenId,_nftDetails.hp,_nftDetails.level,_nftDetails.xp,_nftDetails.ce,_nftDetails.armor,_nftDetails.luk,_money,_nftDetails.name,msg.sender);
        Game.setTokenDetailGenre(_tokenId,2);
        Game.moveBack(_tokenId,msg.sender);
        NFT.transferFrom(msg.sender,address(this), _tokenId);
        markets.push(_marketInfo[_tokenId]);
        userMarkets[msg.sender].add(_tokenId);
        emit Shelves(_tokenId,_money, Game.getTokenDetails(_tokenId).nftKindId, Game.getTokenDetails(_tokenId).name,msg.sender);
    }
    
    function unShelves(uint256 _tokenId) public {
        require(Game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(Game.getTokenDetails(_tokenId).genre ==2,"Illegal 2 operation");
        Game.setTokenDetailGenre(_tokenId,0);
        for(uint256 i=0;i<markets.length;i++){
            if (markets[i].tokenId==_tokenId){
                markets[i] = markets[markets.length - 1];
                markets.pop();
                break;
            }
        }
        Game.addBack(_tokenId,msg.sender);
        nftTransferFrom(address(this),msg.sender,_tokenId);
        delete _marketInfo[_tokenId];
        userMarkets[msg.sender].remove(_tokenId);
        emit UnShelves(_tokenId,msg.sender);
    }
    
    function buyNft(uint256 _tokenId) public{
        address nftOwner = Game.getUserAddress(_tokenId);
        uint256 money = _marketInfo[_tokenId].price;
        require(nftOwner!=msg.sender,"You can't buy your own sale");
        nftTransferFrom(address(this),msg.sender, _tokenId);
        uint256 _fee=_marketInfo[_tokenId].price*fee/100;
        uint256 ownerMoney = _marketInfo[_tokenId].price - _fee;
        for(uint256 i=0;i<markets.length;i++){
            if (markets[i].tokenId==_tokenId){
                markets[i] = markets[markets.length - 1];
                markets.pop();
                break;
            }
        }
        Erc20.transferFrom(msg.sender, nftOwner,ownerMoney);
        Erc20.transferFrom(msg.sender, address(this),_fee);
        Game.editCardDetails(_tokenId, msg.sender);
        Game.setTokenDetailGenre(_tokenId, 0);
        Game.addBack(_tokenId,msg.sender);
        delete _marketInfo[_tokenId];
        userMarkets[nftOwner].remove(_tokenId);
        emit BuyBft(_tokenId,money,nftOwner, msg.sender);
    }

    function stake(uint256 _tokenId) public{
        require(Game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(!userStakeInfo[msg.sender].contains(_tokenId), "It's already pledged");
        require(Game.isBack(_tokenId,msg.sender),"not in back");
        require(Game.getTokenDetails(_tokenId).unLockTime<=block.timestamp,"Haven't unlock");
        require(Game.getTokenDetails(_tokenId).genre ==0,"Illegal 0 operation");
        Game.setTokenDetailGenre(_tokenId, 1);
        NFT.transferFrom(msg.sender,address(this), _tokenId);
        // nftTransferFrom(msg.sender,address(this),_tokenId);
        uint256 money = getNFTKindRewards(_tokenId);
        userStakeInfo[msg.sender].add(_tokenId);

        _tokenMtStakeInfo[_tokenId] = mtStakeInfo(_tokenId,block.timestamp,block.timestamp + StakeInfo.day*unStakeTime,StakeInfo.money+money);

        emit Stake(_tokenId, 1, msg.sender);
    }

    function unStake(uint256 _tokenId) public {
        require(_tokenMtStakeInfo[_tokenId].endTime <= block.timestamp,"Market:wrong endTime");
        require(Game.getUserAddress(_tokenId) == msg.sender,"Illegal operation");
        require(Game.getTokenDetails(_tokenId).genre == 1,"Wrong operation");
        require(userStakeInfo[msg.sender].contains(_tokenId), "It's already decompressed");
        uint256  amount = _tokenMtStakeInfo[_tokenId].money;
        // Erc20.transfer(msg.sender, amount);
        Game.setTokenDetailGenre(_tokenId, 0);
        Game.addTokenReward(msg.sender,amount);
        NFT.transferFrom(address(this),msg.sender, _tokenId);
        userStakeInfo[msg.sender].remove(_tokenId);
        emit UnStake(_tokenId,amount,msg.sender);
    }

    function setErc20Addr(address _tokenAddr) public onlyOwner{
        Erc20 = IERC20(_tokenAddr);
    }

    function setNFTAddr(address _tokenAddr) public onlyOwner{
        NFT = IERC721(_tokenAddr);
    }

    function setGame(address payable GameAddress) public onlyOwner{
        Game = IGame(GameAddress);
    }

    function setUnStakeTime(uint256 _unStakeTime) public onlyOwner {
        unStakeTime = _unStakeTime;
    }

    function getNFTKindRewards(uint256 _tokenId) public view returns(uint256){
        return (Game.getTokenDetails(_tokenId).nftKindId+1) * StakeInfo.money;
    }

    function getUserMarkets(address addr) public view returns(uint256[] memory){
        return userMarkets[addr].values();
    }
    
    function getMarkets() view public returns(market[] memory){
        return markets;
    }

    function getUnStakeInfo(uint256 _tokenId) public view returns(mtStakeInfo memory){
        return _tokenMtStakeInfo[_tokenId];
    }

    function getUserStakes(address addr) public view returns(uint256[] memory){
        return userStakeInfo[addr].values();
    }
   
    function getMarketInfo(uint256 tokenId) public view returns(market memory){
        return _marketInfo[tokenId];
    }

    function nftTransferFrom(address from,address to,uint256 _tokenId) internal{
        NFT.safeTransferFrom(from, to, _tokenId);
    }
    
    function withdrawal(address to,uint256 amount) public onlyOwner{
        payable(to).transfer(amount);
    }

    function withdrawalToken(address token,address to,uint256 amount) public onlyOwner{
        IERC20 _tokenAddr = IERC20(token);
        _tokenAddr.transfer(to, amount);
    }

    
}