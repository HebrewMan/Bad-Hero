// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFT.sol";
import "./Game.sol";
import "./Hero.sol";
contract Arena is Ownable{
    uint256 public arenaPool = 0; 
    uint256 public arenaNumb; 
    uint256 public arenaOpneTime ; 
    uint256 public weekOpenTime; 
    uint256 public weekCyle =  7*86400; 
    uint256 public arenaCyle =  86400; 
    uint256 public weekRound=0; 

    mapping(uint256=>uint256) _tokenIdType; 
    mapping(uint256=>arenaInfo) _arenaInfo; 
    mapping(uint256=>address[]) _weekFightUsers;
    mapping(uint256=>tokenArena[]) _tokenArenas;
    mapping(uint256=>weekLottery) public wkLottory;
    mapping(uint256=>mapping(uint256=>RinKInfo)) public rinkInfo;
  
    arRewardSet[] public _arRewardSet;
    nftKind[] public _nftKinds;

    arenaSet _arenaSet = arenaSet(7,100*10**18,15); 
    weekFighting _weekFighting = weekFighting(0,5,100,10);  

    IERC20 public erc20 = IERC20(0x0a2231B33152d059454FF43F616E4434Afb6Cc64);
    Game public _game;
    Hero public _hero;

    constructor() {
        initArRewardSet();
        arenaOpneTime = 1673002049;
        weekOpenTime = 1673002049 + weekCyle;
    }
   
    event JoinArena(uint256 indexed tokenId,uint256 indexed nper,uint256 indexed wins,address sender);
    event DisCompetitiveReward(uint256 indexed arenaNumb,uint256 indexed rink,uint256 tokenId,address sender,uint256 reward);
    event DisArenaReward(uint256 indexed arenaNumb,uint256 indexed rink,uint256 tokenId,address sender,uint256 reward);
    event DoWeekTask(uint256 indexed weekRound,address sender);
    event OpenWeekTask(uint256 indexed weekRound,uint256 startTime);

    struct weekFighting{
        uint256 round; 
        uint256 successRate; 
        uint256 parame;  
        uint256 parameRate;  
    }
     struct nftKind{
        uint32 start;
        uint32 end;
        uint64 atRate;
        string ranking;
        string rankingName;
        string url;
    }

    struct arenaInfo{
        uint256 cycle; 
        uint256 price; 
        uint256 createTime; 
        uint256 endTime; 
    }

    struct tokenArena{
        uint256 tokenId; 
        uint256 wins; 
        address sender; 
    }
    
    struct arenaSet{
        uint256 cycle; 
        uint256 price; 
        uint256 scNum; 
    }
    struct arRewardSet{
        uint256 rewards; 
        uint256 start; 
        uint256 end; 
    }
    
    struct weekLottery{
        uint256 round; 
        uint256 rate; 
        bool success; 
        uint256 openTime;
    }
    struct RinKInfo{
        uint256 rink; 
        uint256 tokenId;
        uint256 reward; 
        address  win;
        bool isOk; 
        bool isIssue; 
    }
    
    function athletics(uint256 tokenId)  public isUser(tokenId) returns(uint256){
        require(arenaOpneTime>=block.timestamp,"This issue is over, please wait for the next issue");
        
        uint256 wins = getSucNum(_hero.getNftKind(_game.getTokenDetails(tokenId).nftKindId).atRate);
        arenaPool += _arenaSet.price;
        erc20.transferFrom(msg.sender, address(this),_arenaSet.price);
        _tokenArenas[arenaNumb].push(tokenArena(tokenId,wins,msg.sender));
        
        emit JoinArena(tokenId,arenaNumb, wins, msg.sender);
        return wins;
    }

    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length+1;
    }
    
    function getSucNum(uint256 baseNum) view internal returns(uint256){
        uint256 roundOne = rand(20);
        uint256 roundTow = rand(20);
        uint256 roundTree = rand(20);
        uint256 stateNum = baseNum-10;
        uint256 avg  = (roundOne + roundTow + roundTree)/3;
        return stateNum+avg;
    }
    modifier isUser(uint256 tokenId){
       require(_game.getUserAddress(tokenId)==msg.sender,"Have no legal power");
        _;
    }
    
    function doWeeklyTasks() public{
        require(isJoinWkTask(weekRound,msg.sender) == false,"Have attended");
        require(weekOpenTime>=block.timestamp,"The assignment for this week is over");
        _weekFightUsers[weekRound].push(msg.sender);
        emit  DoWeekTask(weekRound,msg.sender);
    }

    function isJoinWkTask(uint256 wkRound,address sender)public view returns(bool){
       address[] memory addrs =  _weekFightUsers[wkRound];
       bool isJoin;
       for (uint256 i = 0; i < addrs.length; i++) {
           if(addrs[i] == sender){
               isJoin = true;
               break;
           }
       }
       return isJoin;
    }

    
    function getWeekRound() public view returns(uint256){
        return weekRound;
    }

     function initArRewardSet() public onlyOwner{
        _arRewardSet.push(arRewardSet(30,0,1));
        _arRewardSet.push(arRewardSet(17,1,2));
        _arRewardSet.push(arRewardSet(10,2,3));
        _arRewardSet.push(arRewardSet(4,3,10));
        _arRewardSet.push(arRewardSet(3,10,15));
    }
    
    function openWeeklyTasks() public onlyOwner{
        uint256 joins = _weekFightUsers[weekRound].length;
        bool isSuccess = false;
        
        require(weekOpenTime<block.timestamp, "open Week lottery Time is not");
        if(_weekFighting.parame<=joins){
            _weekFighting.parame += _weekFighting.parame*_weekFighting.parameRate/100;
            isSuccess = true;
        }else{
            _weekFighting.parame -= _weekFighting.parame*_weekFighting.parameRate/100;
        }
        wkLottory[weekRound] = weekLottery(weekRound,_weekFighting.successRate,isSuccess,weekOpenTime);
        weekRound +=1;
        weekOpenTime += weekCyle;
        emit OpenWeekTask(weekRound,weekOpenTime);
    }
    
    
    function disCompetitiveReward(uint256 _arenaNumb,uint256 ranking,address sender,uint256 tokenId,uint256 reward)public onlyOwner{
        require(rinkInfo[_arenaNumb][ranking].isOk ==false,"The rewards have already been handed out");
        rinkInfo[_arenaNumb][ranking].rink = ranking;
        rinkInfo[_arenaNumb][ranking].win = sender;
        rinkInfo[_arenaNumb][ranking].reward = reward;
        rinkInfo[_arenaNumb][ranking].tokenId = tokenId;
        rinkInfo[_arenaNumb][ranking].isOk = true;
        emit DisCompetitiveReward(_arenaNumb,ranking,tokenId,sender,reward);
    }

    function upArenaTime() public onlyOwner{
        require(arenaOpneTime<block.timestamp, "open Week lottery Time is not");
        for(uint256 i=0;i<15;i++){
            if(rinkInfo[arenaNumb][i].isOk && rinkInfo[arenaNumb][i].isIssue==false){
               _game.DisReward(rinkInfo[arenaNumb][i].win,rinkInfo[arenaNumb][i].reward);
               arenaPool = arenaPool - rinkInfo[arenaNumb][i].reward;
                rinkInfo[arenaNumb][i].isIssue = true;
               emit DisArenaReward(arenaNumb,i+1,rinkInfo[arenaNumb][i].tokenId,rinkInfo[arenaNumb][i].win,rinkInfo[arenaNumb][i].reward);
            }
        }
        arenaOpneTime += arenaCyle;
        arenaNumb = arenaNumb+1;
    }

    function getArenaPool() public view returns(uint256) {
        return arenaPool;
    }
    function getRangk(uint256 _arenaNumb,uint256 ranking) public view returns(RinKInfo memory){
        return rinkInfo[_arenaNumb][ranking];
    }
    function setGame(address payable _gameAddress) public onlyOwner{
        _game = Game(_gameAddress);
    }

    function setErc20(address _erc20Address) public onlyOwner{
        erc20 = IERC20(_erc20Address);
    }

    function setHero(address _Address) public onlyOwner{
        _hero = Hero(_Address);
    }

}