// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


// import "./INFT.sol";
import "./Game.sol";

contract Market is AccessControl,Ownable{
    using EnumerableSet for EnumerableSet.UintSet;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor()  {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    IERC721 public _inft;
    mapping(uint256=>market) _markets;
    market[] public markets;
    Game private _game;
    IERC20 private _erc20;
    uint256 _unlockTime = 86400;
    mapping(uint256=>mtStakeInfo) _tokenMtStakeInfo;
    stakeInfo public _stakeInfo = stakeInfo(30,50*10**18,100*10**18); 
    mapping(address=>EnumerableSet.UintSet)  userStakeInfo;
    mapping(address=>EnumerableSet.UintSet)  userMarkets;



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

    
    function getUserMarkets(address addr) public view returns(uint256[] memory){
        return userMarkets[addr].values();
    }
    
    function getMarkets() view public returns(market[] memory){
        return markets;
    }

    function shelves(uint256 _tokenId,uint256 _money) public{
        require(_game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(_game.getTokenDetailGenre(_tokenId) ==0,"Illegal 0 operation");
        cardDetails memory _nftDetails;
        (_nftDetails.level,_nftDetails.ce,_nftDetails.xp,_nftDetails.armor,_nftDetails.luk,_nftDetails.rgTime) =  _game.getTokenDetail(_tokenId);
        _markets[_tokenId] = market(_tokenId,_nftDetails.hp,_nftDetails.level,_nftDetails.xp,_nftDetails.ce,_nftDetails.armor,_nftDetails.luk,_money,_nftDetails.name,msg.sender);
        _game.setTokenDetailGenre(_tokenId,2);
        _game.moveBack(_tokenId,msg.sender);
        _inft.transferFrom(msg.sender,address(this), _tokenId);
        markets.push(_markets[_tokenId]);
        userMarkets[msg.sender].add(_tokenId);
        emit Shelves(_tokenId,_money, _game.getTokenDetails(_tokenId).nftKindId, _game.getTokenDetails(_tokenId).name,msg.sender);
    }
    
    function unShelves(uint256 _tokenId) public {
        require(_game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(_game.getTokenDetailGenre(_tokenId) ==2,"Illegal 2 operation");
        _game.setTokenDetailGenre(_tokenId,0);
        for(uint256 i=0;i<markets.length;i++){
            if (markets[i].tokenId==_tokenId){
                markets[i] = markets[markets.length - 1];
                markets.pop();
                break;
            }
        }
        _game.addBack(_tokenId,msg.sender);
        nftTransferFrom(address(this),msg.sender,_tokenId);
        delete _markets[_tokenId];
        userMarkets[msg.sender].remove(_tokenId);
        emit UnShelves(_tokenId,msg.sender);
    }
    
    function buyNft(uint256 _tokenId) public{
        address nftOwner = _game.getUserAddress(_tokenId);
        uint256 money = _markets[_tokenId].price;
        require(nftOwner!=msg.sender,"You can't buy your own sale");
        nftTransferFrom(address(this),msg.sender, _tokenId);
        uint256 fee=_markets[_tokenId].price*5/100;
        uint256 ownerMoney = _markets[_tokenId].price - fee;
        for(uint256 i=0;i<markets.length;i++){
            if (markets[i].tokenId==_tokenId){
                markets[i] = markets[markets.length - 1];
                markets.pop();
                break;
            }
        }
        _erc20.transferFrom(msg.sender, nftOwner,ownerMoney);
        _erc20.transferFrom(msg.sender, address(this),fee);
        _game.editCardDetails(_tokenId, msg.sender);
        _game.setTokenDetailGenre(_tokenId, 0);
        _game.addBack(_tokenId,msg.sender);
        delete _markets[_tokenId];
        userMarkets[nftOwner].remove(_tokenId);
        emit BuyBft(_tokenId,money,nftOwner, msg.sender);
    }

    function stake(uint256 _tokenId) public{
        require(_game.getUserAddress(_tokenId)==msg.sender,"Illegal operation");
        require(userStakeInfo[msg.sender].contains(_tokenId) == false, "It's already pledged");
        require(_game.isBack(_tokenId,msg.sender),"not in back");
        require(_game.getTokenDetails(_tokenId).unLockTime<=block.timestamp,"Haven't unlock");
        require(_game.getTokenDetailGenre(_tokenId) ==0,"Illegal 0 operation");
        _game.setTokenDetailGenre(_tokenId, 1);
        _inft.transferFrom(msg.sender,address(this), _tokenId);
        // nftTransferFrom(msg.sender,address(this),_tokenId);
        uint256 money = (_game.getTokenDetails(_tokenId).nftKindId+1) * _stakeInfo.money;
        userStakeInfo[msg.sender].add(_tokenId);
        _tokenMtStakeInfo[_tokenId] = mtStakeInfo(_tokenId,block.timestamp,block.timestamp + _stakeInfo.day*_unlockTime,_stakeInfo.money+money);
        // _tokenMtStakeInfo[_tokenId] = mtStakeInfo(_tokenId,block.timestamp,block.timestamp + _unlockTime,money+_stakeInfo.addMoney);
        emit Stake(_tokenId, 1, msg.sender);
    }

   
    function unStake(uint256 _tokenId) public {
        require(_game.getUserAddress(_tokenId) == msg.sender,"Illegal operation");
        require(_game.getTokenDetailGenre(_tokenId) ==1,"Wrong operation");
        require(_tokenMtStakeInfo[_tokenId].endTime<block.timestamp,"The time is not up yet");
        require(userStakeInfo[msg.sender].contains(_tokenId) == true, "It's already decompressed");
        uint256  amount = _tokenMtStakeInfo[_tokenId].money;
        // _erc20.transfer(msg.sender, amount);
        _game.setTokenDetailGenre(_tokenId, 0);
        //address user,uint256 reward,uint256 addType
        _game.addTokenReward(msg.sender,amount);
        _inft.transferFrom(address(this),msg.sender, _tokenId);
        userStakeInfo[msg.sender].remove(_tokenId);
        emit UnStake(_tokenId,amount,msg.sender);
    }


    function getUnStakeInfo(uint256 _tokenId) public view returns(mtStakeInfo memory){
        return _tokenMtStakeInfo[_tokenId];
    }
   
    function getUnStakeLockTime(uint256 _tokenId) public view returns(uint256){
        return _tokenMtStakeInfo[_tokenId].endTime;
    }

   
    function getUnStakeMoney(uint256 _tokenId) public view returns(uint256){
        return _tokenMtStakeInfo[_tokenId].money;
    }

    function getUserStakes(address addr) public view returns(uint256[] memory){
        return userStakeInfo[addr].values();
    }

   
    function getMarketInfo(uint256 tokenId) public view returns(market memory){
        return _markets[tokenId];
    }

    function setErc20Addr(address _tokenAddr) public onlyOwner{
        _erc20 = IERC20(_tokenAddr);
    }


    function setNFTAddr(address _tokenAddr) public onlyOwner{
        _inft = IERC721(_tokenAddr);
    }

    
    function nftTransferFrom(address from,address to,uint256 _tokenId) internal{
        _inft.safeTransferFrom(from, to, _tokenId);
    }
    function nftTransfer(uint256 _tokenId) internal{
        _inft.safeTransferFrom(address(this),msg.sender, _tokenId);
    }

    
    function transfer(address to,uint256 amount) public onlyOwner{
        payable(to).transfer(amount);
    }

    function transferERC20(address token,address to,uint256 amount) public onlyOwner{
        IERC20  _tokenAddr = IERC20(token);
        // _tokenAddr.approve(address(this), amount);
        _tokenAddr.transfer(to, amount);
    }

    function setGame(address payable _gameAddress) public onlyOwner{
        _game = Game(_gameAddress);
    }

    function setUnlockTime(uint256 unlockTime) public onlyOwner {
        _unlockTime = unlockTime;
    }
}