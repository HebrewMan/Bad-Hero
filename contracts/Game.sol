// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IMonster.sol";
contract Game is AccessControl,Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint32 public enemyNum = 0;
    uint256 basicHp = 200*10**8;
    uint256 _unlockTime = 86400;
    uint256 public bnbPool; 

    IERC20 public erc20;
    IMonster public _monster;

     // gameInfo private _gameInfo = gameInfo(12*3600,5,10*10**18,100,10,25,2000*10**18); //==================== change
    gameInfo private _gameInfo = gameInfo(1800,5,10*10**18,100,10,25,2000*10**18);
    receiveInfo _receiveInfo = receiveInfo(2*_unlockTime,3,7);
    
    mapping(address=>EnumerableSet.UintSet) _userTem;
    mapping(address=>EnumerableSet.UintSet) _userBackpack;
    mapping(uint256=>address) _tokenUser;
    mapping(uint256=>CardDetails) _tokenDetail;
    mapping(uint256=>mapping(uint256=>uint256)) _tokenLevel; 
    mapping(address=>rewardPool) public userBnbPool;
    mapping(address=>rewardPool) public userTokenPool;

    enemyInfo[] public specialTask;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        pushTask();
    }

    event SpeedTraining(uint256 indexed tokenId,address indexed sender,uint256 needFee);
    event MoveCard(uint256 indexed tokenId,address indexed sender,uint256 mvType);
    event UpMonster(uint256 indexed tokenId,uint256 indexed level,uint256 amount,address sender);
    event Fighting(bool isSuccess,uint256 indexed fightType,uint256 indexed sHp,uint256  addXp,uint256 indexed reward,uint256 tokenId,address sender);
    event DrawReward(uint256 indexed rewardType,uint256 indexed reward,uint256 rate,address sender);
    event MoveBack(uint256 indexed tokenId,address indexed sender,uint256 mvType);
    event Withdrawal(uint256 indexed amount,address indexed sender);

    // struct tokenEarnings{
    //     uint256 level; 
    //     uint256 income; 
    // }

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
   
    struct gameInfo{
        uint32 enlistTime; 
        uint32 temNum;      
        uint256 speedMoney;      
        uint256 maxLevel;      
        uint256 addAttr;      
        uint256 upAttrCost;      
        uint256 upEqCost;      
    }
    
    
    struct enemyInfo{
        uint32 id;
        uint256 odds;
        uint256 basicReward;
        uint256 basicXp;
        uint256 basicHp;
        string  name;
        string  pic;
    }

    
    struct rewardPool{
        uint256 reward; 
        uint256 validTime; 
        uint256 unLockTime;  
        bool isVaild;  
    }

   
    struct receiveInfo{
        uint256 lockTime; 
        uint256 fee;   
        uint256 freeDay; 
    }

    struct FightingEndInfo{
        bool suc;
        uint32 fgType;
        uint256 reward;
        uint256 hp;
        uint256 xp;
        uint256 unLkTime;
   }

   modifier isteam(uint256 tokenId,address sender){
        require(_userTem[sender].contains(tokenId) == true, "It's not no team");
        _;
    }

   function setUnlockTime(uint256 unlockTime) public onlyOwner {
       _unlockTime = unlockTime;
       _receiveInfo = receiveInfo(2*_unlockTime,3,7);
   }

    // function setGameInfo(uint32 enlistTime,uint32 temNum,uint256 speedMoney,uint256 maxLevel,  
    //         uint256 addAttr,uint256 upAttrCost,uint256 upEqCost) public onlyOwner {
    //     _gameInfo = gameInfo(enlistTime,temNum,speedMoney,maxLevel,addAttr,upAttrCost,upEqCost);
    // }

    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.number,block.difficulty, block.timestamp)));
        return random%_length;
    }
 
    function createCard(uint256 tokenId,uint256 ce,uint256 armor,uint256 luk,uint256 unLockTime,uint256 nftKindId,string memory name,uint256 maxNum,address _userAddress) public onlyRole(MINTER_ROLE) returns(uint256){
        
        CardDetails memory _carDetails = CardDetails(0,tokenId,basicHp,1,0,ce,armor,luk,block.timestamp+unLockTime,0,nftKindId,name);
        
        if(_userTem[_userAddress].length()<maxNum){
            _userTem[_userAddress].add(tokenId);
        }else{
            _userBackpack[_userAddress].add(tokenId);
        }
        _tokenUser[tokenId] = _userAddress;
        _tokenDetail[tokenId] = _carDetails;

        return tokenId;
    }

   
    function adRecruit(uint256 tokenId)  public{
        require(_tokenUser[tokenId]==msg.sender,"Have no legal power");
        CardDetails storage _carDetail = _tokenDetail[tokenId] ;
        uint256 needFee = 0;
        require(_carDetail.unLockTime > block.timestamp,"No need to accelerate");
        uint256 needTime = _carDetail.unLockTime - block.timestamp ;
        needFee = speedFee(needTime);
        erc20.transferFrom(msg.sender, address(this), needFee);
        _tokenDetail[tokenId].unLockTime = 0;
        emit SpeedTraining(tokenId,msg.sender,needFee);
    }

    
    function moveToBack(uint256 tokenId) public {
        require(_tokenUser[tokenId]==msg.sender,"Have no legal power");
        require(_userTem[msg.sender].contains(tokenId) == true, "It's already decompressed");
        _userBackpack[msg.sender].add(tokenId);
        _userTem[msg.sender].remove(tokenId);
        
        emit MoveCard(tokenId,msg.sender,1);
    }

   
    function moveToTem(uint256 tokenId) public {
        require(_tokenUser[tokenId]==msg.sender,"Have no legal power");
        require(_userBackpack[msg.sender].contains(tokenId) == true, "It's already decompressed");
        _userTem[msg.sender].add(tokenId);
        _userBackpack[msg.sender].remove(tokenId);
        emit MoveCard(tokenId,msg.sender,2);
    }
    
   
    function moveBack(uint256 tokenId,address sender) public onlyRole(MINTER_ROLE){
        require(_tokenUser[tokenId]==sender,"Have no legal power");
        require(_userBackpack[sender].contains(tokenId) == true, "It's already decompressed");
        _userBackpack[sender].remove(tokenId);
        emit MoveBack(tokenId,sender,1);
    }

   
    function addBack(uint256 tokenId,address sender) public onlyRole(MINTER_ROLE){
        require(_tokenUser[tokenId]==sender,"Have no legal power");
        require(_userBackpack[sender].contains(tokenId) == false, "It's already decompressed");
        _userBackpack[sender].add(tokenId);
        emit MoveBack(tokenId,sender,2);
    }
   
    function setErc20(address addr) public onlyOwner{
        erc20 = IERC20(addr);
    }
    function setMonster(address addr) public onlyOwner{
        _monster = IMonster(addr);
    }
    function setRole(address upAddress)public onlyOwner{
        _grantRole(MINTER_ROLE, upAddress);
    }
    
   
    function speedFee(uint256 remainTime) view public returns(uint256){
        if (remainTime<=0){
            return 0;
        }
        uint256 amounts = _gameInfo.speedMoney;
        uint256 const = remainTime*(amounts/_gameInfo.enlistTime);
        return const;
    }
  
  
    function addUpReward(address user,uint256 reward,uint256 addType) internal{
        if(addType==1){
            if(userBnbPool[user].isVaild){
                if(userBnbPool[user].reward ==0){
                    userBnbPool[user].validTime =  block.timestamp+_receiveInfo.lockTime;
                    userBnbPool[user].unLockTime = block.timestamp+_receiveInfo.lockTime+_receiveInfo.freeDay*_unlockTime;
                }
            }else{
                userBnbPool[user].validTime =  block.timestamp+_receiveInfo.lockTime;
                userBnbPool[user].unLockTime = block.timestamp+_receiveInfo.lockTime+_receiveInfo.freeDay*_unlockTime;
                userBnbPool[user].isVaild=true;
            }
            userBnbPool[user].reward = userBnbPool[user].reward+reward;
        }else{
            if(userTokenPool[user].isVaild){ 
                if(userTokenPool[user].reward ==0){
                    userTokenPool[user].validTime =  block.timestamp+_receiveInfo.lockTime;
                    userTokenPool[user].unLockTime = block.timestamp+_receiveInfo.lockTime+_receiveInfo.freeDay*_unlockTime;
                }
            }else{
                userTokenPool[user].validTime =  block.timestamp+_receiveInfo.lockTime;
                userTokenPool[user].unLockTime = block.timestamp+_receiveInfo.lockTime+_receiveInfo.freeDay*_unlockTime;
                userTokenPool[user].isVaild=true;
            }
            userTokenPool[user].reward = userTokenPool[user].reward+reward;
        }
    }

    function addTokenReward(address user,uint256 reward) public onlyRole(MINTER_ROLE){
       addUpReward(user,reward,2);
    }
  
  
    function fighting(uint256 tokenId,uint256 enemyId) public isUnlock(tokenId) isteam(tokenId,msg.sender) returns(FightingEndInfo memory fig){
        (fig.suc,fig.reward,fig.hp,fig.xp,fig.unLkTime) = _monster.fighting(tokenId,enemyId,msg.sender);
        if(fig.suc == true){
            addUpReward(msg.sender,fig.reward,1);
            _tokenLevel[tokenId][_tokenDetail[tokenId].level] +=fig.reward;
            _tokenDetail[tokenId].hp =  fig.hp;
            uint256 totalXp = _tokenDetail[tokenId].xp + fig.xp ;
            uint256 limitXp = _tokenDetail[tokenId].level*100-1;
            if (totalXp>limitXp){
                _tokenDetail[tokenId].xp = limitXp;
            }else{
                _tokenDetail[tokenId].xp += fig.xp;
            }
            
            _tokenDetail[tokenId].rgTime = fig.unLkTime;
        }else{
            _tokenDetail[tokenId].hp = 0;
            _tokenDetail[tokenId].rgTime = block.timestamp + _unlockTime;
        }
        fig.fgType = 1;
        emit Fighting(fig.suc,1,fig.hp,fig.xp,fig.reward,tokenId,msg.sender);

        return fig;
        
    }
   
    function DoTask(uint256 tokenId,uint256 enemyId) public isUnlock(tokenId) isteam(tokenId,msg.sender) returns(FightingEndInfo memory fig) {
        enemyInfo memory _task =getTaskById(enemyId);
        (fig.suc,fig.reward,fig.hp, fig.unLkTime) = _monster.DoTask(tokenId,_task.odds,_task.basicReward,msg.sender);
        if(fig.suc == true){
            addUpReward(msg.sender,fig.reward,1);
            _tokenDetail[tokenId].hp = fig.hp;
            _tokenDetail[tokenId].rgTime = fig.unLkTime;
        }else{
            _tokenDetail[tokenId].hp = 0;
            _tokenDetail[tokenId].rgTime = block.timestamp + _unlockTime;
        }
        fig.fgType = 2;
        emit Fighting(fig.suc,2,fig.hp,0,fig.reward,tokenId,msg.sender);
        return fig;
    }

    function DisReward(address rewardAddr,uint256 reward) public onlyRole(MINTER_ROLE) {
        addUpReward(rewardAddr,reward,2);
    }

    function upLevel(uint256 _tokenId) public{
        require(_tokenUser[_tokenId]==msg.sender,"Have no legal power");
        require(_tokenDetail[_tokenId].level < _gameInfo.maxLevel,"_gameInfo.maxLevel");
        uint256 needXp = _tokenDetail[_tokenId].level *_gameInfo.maxLevel -1;
        require(_tokenDetail[_tokenId].xp >= needXp,"xp is lack");
        uint256 amount ;
        amount = getUpConst(_tokenId);
        erc20.transferFrom(msg.sender, address(this), amount);
        _tokenDetail[_tokenId].xp = needXp;
        _tokenDetail[_tokenId].level = _tokenDetail[_tokenId].level+1;
        _tokenDetail[_tokenId].ce += _gameInfo.addAttr;
        _tokenDetail[_tokenId].armor += _gameInfo.addAttr;
        _tokenDetail[_tokenId].luk += _gameInfo.addAttr;
        emit UpMonster(_tokenId,_tokenDetail[_tokenId].level,amount,msg.sender);
    }

    function drawReward(uint256 index) public returns(bool){
        uint256 rateFee ;
        uint256 rallReward;
        bool success;
        if(index==1){
            require(userBnbPool[msg.sender].validTime < block.timestamp,"The unlock time is not reached");
            if(userBnbPool[msg.sender].unLockTime<=block.timestamp){
                rallReward = userBnbPool[msg.sender].reward;
            }else{
                rateFee = getFee(userBnbPool[msg.sender].unLockTime-block.timestamp);
                rallReward = userBnbPool[msg.sender].reward - userBnbPool[msg.sender].reward*rateFee/100;
            }
            require(bnbPool>=rallReward,"Insufficient contract balance");
            userBnbPool[msg.sender].reward = 0;
            (success, ) = msg.sender.call{value: rallReward}(new bytes(0));
            bnbPool = bnbPool-rallReward;
        }else if(index==2){
            require(userTokenPool[msg.sender].validTime < block.timestamp,"The unlock time is not reached");
            if(userTokenPool[msg.sender].unLockTime<=block.timestamp){
                rallReward = userTokenPool[msg.sender].reward;
            }else{
                rateFee = getFee(userTokenPool[msg.sender].unLockTime-block.timestamp);
                rallReward = userTokenPool[msg.sender].reward - userTokenPool[msg.sender].reward*rateFee/100;
            }
            userTokenPool[msg.sender].reward =0;
            erc20.transferFrom(address(this), msg.sender, rallReward);
        }
        
        emit DrawReward(index,rallReward,rateFee,msg.sender);
        return success;
    }

    function getFee(uint256 difTime) view public returns(uint256){
        if(difTime == 0){
            return 0;
        }
        uint256 needDay = difTime/_unlockTime;
        if (needDay*_unlockTime<difTime){
            needDay +=1;
        }
        return needDay *_receiveInfo.fee;
    }

    function getTaskById(uint256 enemyId) view  public returns(enemyInfo memory){
        enemyInfo memory task ;
        for (uint256 i = 0; i < specialTask.length; i++) {
            if(specialTask[i].id == enemyId){
                task =  specialTask[i];
            }
        }
        return task;
    }

    function getTasks() view  public returns(enemyInfo[] memory tasks){
        for (uint256 i = 0; i < specialTask.length; i++) {
            tasks[i]=specialTask[i];
        }
        return tasks;
    }

    

    function isBack(uint256 tokenId,address sender) public view returns(bool) {
        require(_userBackpack[sender].contains(tokenId) == true, "It's not to back");
        return true;
    }

    modifier isUnlock(uint256 tokenId){
       CardDetails memory cards = _tokenDetail[tokenId];
        require(cards.unLockTime<block.timestamp,"unLock time");
        _;
    }
 
    function addTask(uint256 odds,uint256 reward,uint256 xp,uint256 hp,string memory name,string memory pic) public onlyOwner{
        specialTask.push(enemyInfo(enemyNum,odds,reward,xp,hp,name,pic));
        enemyNum +=1;
    }
    function pushTask() internal{
        addTask(18,1*10**17,0,20*10**8,"zcdq","");
        addTask(10,2*10**17,0,20*10**8,"gdrz","");
    }

    function getSpecialTask() public view returns(enemyInfo[] memory){
        return specialTask;
    }
    
    function getUpConst(uint256 tokenId) public view returns(uint256){
        uint256 reward = _tokenLevel[tokenId][_tokenDetail[tokenId].level];
        if (reward<=0){
            return 0;
        }
        uint256 incomeByToken = reward;
        uint256 amount ;
        amount = incomeByToken * _gameInfo.upAttrCost /100;
        return amount;
    }

    function getRewardByLevel(uint256 tokenId) public view returns(uint256){
       return _tokenLevel[tokenId][_tokenDetail[tokenId].level];
    }

    function getTokenDetail(uint256 tokenId) view public returns(uint256 level,uint256 ce,uint256 xp,uint256 armor,uint256 luk,uint256 rgTime){
        return (_tokenDetail[tokenId].level,_tokenDetail[tokenId].ce,_tokenDetail[tokenId].xp,_tokenDetail[tokenId].armor,_tokenDetail[tokenId].luk,_tokenDetail[tokenId].rgTime);
    }
    function getTokenDetails(uint256 tokenId) view public returns(CardDetails memory){
        return _tokenDetail[tokenId];
    }

    function setTokenDetailGenre(uint256 tokenId,uint32 genre)  public onlyRole(MINTER_ROLE) {
        _tokenDetail[tokenId].genre = genre;
    }

    function getTokenDetailGenre(uint256 tokenId) view  public returns(uint256) {
        return _tokenDetail[tokenId].genre;
    }

    function getUserAddress(uint256 tokenId) view public returns(address){
        return _tokenUser[tokenId];
    }

    function editCardDetails(uint256 tokenId,address addr)  public onlyRole(MINTER_ROLE) {
        _tokenUser[tokenId] = addr;
    }
    
    function getUserTesmCards(address sender) view public returns(uint256[]  memory){
        return _userTem[sender].values();
    }

    function getUserBkCards(address sender) view public returns(uint256[]  memory){
        return _userBackpack[sender].values();
    }
   
    receive() external payable { 
    	bnbPool += msg.value;
	}

    // function getBalance() public view returns(uint256){
    //     return address(this).balance;
    // }

    // function rechargeBnb() payable public{
    //     bnbPool += msg.value;
    //     payable(msg.sender).transfer(msg.value);
    // }

     function withdrawal(address addr,uint256 amount) public onlyOwner returns(bool){
        bnbPool = bnbPool - amount;
        (bool success, ) = addr.call{value: amount}(new bytes(0));
        emit Withdrawal(amount,addr);
        return success;
    }

    function withdrawalToken(address addr,uint256 amount) public onlyOwner {
        erc20.transfer(addr, amount);
        emit Withdrawal(amount,addr);
    }
    
}