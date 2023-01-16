// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IMonster.sol";
contract Game is AccessControl,Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint32 enemyNum = 0;
    uint256 basicHp = 200*10**8;
    uint256 public _unlockTime = 86400;
    uint256 public upMonsterFee = 50000*10**18;
    uint256 public bnbPool; 

    address public vault = 0x89398e9ab06dA0E5F0243eD6372bA56603867995;

    IERC20 public erc20;
    IMonster public _monster;
    gameInfo public _gameInfo = gameInfo(12*3600,5,20000*10**18,100,10,25,2000*10**18); 
    receiveInfo public _receiveInfo = receiveInfo(2*_unlockTime,3,7);
    
    mapping(address=>EnumerableSet.UintSet) _userTem;
    mapping(address=>EnumerableSet.UintSet) _userBackpack;
    mapping(uint256=>address) _tokenUser;
    mapping(uint256=>CardDetails) tokenDetail;
    mapping(uint256=>mapping(uint256=>uint256)) _tokenLevel; 
    mapping(address=>rewardPool) public userBnbPool;
    mapping(address=>rewardPool) public userTokenPool;

    enemyInfo[] _specialTask;

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
        uint32 enlistTime; //开盲盒后卡片需要冷却时间
        uint32 temNum; //队伍中允许的怪物数量  
        uint256 speedMoney;  // 提前冷却(训练加速)消耗需要支付最大金额
        uint256 maxLevel; //怪物最大升级等级
        uint256 addAttr; //升级等级增加的属性增值
        uint256 upAttrCost; //升级消耗手续费比例
        uint256 upEqCost;  //升级装备消耗 //无效
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
        uint256 rate;   
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

    modifier isTeam(uint256 tokenId,address sender){
        require(_userTem[sender].contains(tokenId) == true, "It's not no team");
        _;
    }

    modifier isUnlock(uint256 tokenId){
       CardDetails memory cards = tokenDetail[tokenId];
        require(cards.unLockTime<block.timestamp,"unLock time");
        _;
    }
    
   function setUnlockTime(uint256 unlockTime) public onlyOwner {
       _unlockTime = unlockTime;
       _receiveInfo = receiveInfo(2*_unlockTime,3,7);
   }

   function setupMonsterFee(uint _fee) external onlyOwner{
        upMonsterFee = _fee;
    }
    /*
    * @dev 加速领取收益支付费用（比例）
    * @prames _rate 比例
    */
   function setReceiveRate(uint _rate)external onlyOwner{
       _receiveInfo.rate = _rate;
   }
    /*
    * @dev set vault addrsss
    * @prames _vault address
    */
   function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    function setGameInfo(uint32 enlistTime,uint32 temNum,uint256 speedMoney,uint256 maxLevel,uint256 addAttr,uint256 upAttrCost,uint256 upEqCost) public onlyOwner {
        _gameInfo = gameInfo(enlistTime,temNum,speedMoney,maxLevel,addAttr,upAttrCost,upEqCost);
    }

    function setSpeedMoney(uint256 _speedMoney)external onlyOwner{
       _gameInfo.speedMoney = _speedMoney;
    }

      //set monster type 
    function setTokenDetailGenre(uint256 tokenId,uint32 genre)  public onlyRole(MINTER_ROLE) {
        tokenDetail[tokenId].genre = genre;
    }

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
        tokenDetail[tokenId] = _carDetails;

        return tokenId;
    }

   //加速训练
    function adRecruit(uint256 tokenId)  public{
        require(_tokenUser[tokenId]==msg.sender,"Have no legal power");
        CardDetails storage _carDetail = tokenDetail[tokenId];
        require(_carDetail.unLockTime > block.timestamp,"No need to accelerate");
        uint256 needTime = _carDetail.unLockTime - block.timestamp;
        uint256 needFee = speedFee(needTime);
        erc20.transferFrom(msg.sender, address(this), needFee);
        tokenDetail[tokenId].unLockTime = 0;
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
  
  
    function fighting(uint256 tokenId,uint256 enemyId) public isUnlock(tokenId) isTeam(tokenId,msg.sender) returns(FightingEndInfo memory fig){
        (fig.suc,fig.reward,fig.hp,fig.xp,fig.unLkTime) = _monster.fighting(tokenId,enemyId,msg.sender);
        if(fig.suc == true){
            addUpReward(msg.sender,fig.reward,1);
            _tokenLevel[tokenId][tokenDetail[tokenId].level] +=fig.reward;
            tokenDetail[tokenId].hp =  fig.hp;
            uint256 totalXp = tokenDetail[tokenId].xp + fig.xp;
            uint256 limitXp = tokenDetail[tokenId].level*100-1;
            if (totalXp>limitXp){
                tokenDetail[tokenId].xp = limitXp;
            }else{
                tokenDetail[tokenId].xp += fig.xp;
            }
            
            tokenDetail[tokenId].rgTime = fig.unLkTime;
        }else{
            tokenDetail[tokenId].hp = 0;
            tokenDetail[tokenId].rgTime = block.timestamp + _unlockTime;
        }
        fig.fgType = 1;
        emit Fighting(fig.suc,1,fig.hp,fig.xp,fig.reward,tokenId,msg.sender);

        return fig;
        
    }
   
    function DoTask(uint256 tokenId,uint256 enemyId) public isUnlock(tokenId) isTeam(tokenId,msg.sender) returns(FightingEndInfo memory fig) {
        enemyInfo memory _task =getTaskById(enemyId);
        (fig.suc,fig.reward,fig.hp, fig.unLkTime) = _monster.DoTask(tokenId,_task.odds,_task.basicReward,msg.sender);
        if(fig.suc == true){
            addUpReward(msg.sender,fig.reward,1);
            tokenDetail[tokenId].hp = fig.hp;
            tokenDetail[tokenId].rgTime = fig.unLkTime;
        }else{
            tokenDetail[tokenId].hp = 0;
            tokenDetail[tokenId].rgTime = block.timestamp + _unlockTime;
        }
        fig.fgType = 2;
        emit Fighting(fig.suc,2,fig.hp,0,fig.reward,tokenId,msg.sender);
        return fig;
    }

    function DisReward(address rewardAddr,uint256 reward) public onlyRole(MINTER_ROLE) {
        addUpReward(rewardAddr,reward,2);
    }
    /*
    *@dev up monster level
    *@params tokenid
    *怪物升级
    */
    function upLevel(uint256 _tokenId) public{
        require(_tokenUser[_tokenId]==msg.sender,"Have no legal power");
        require(tokenDetail[_tokenId].level < _gameInfo.maxLevel,"_gameInfo.maxLevel");
        uint256 needXp = tokenDetail[_tokenId].level *_gameInfo.maxLevel -1;
        require(tokenDetail[_tokenId].xp >= needXp,"xp is lack");
        // uint256 amount;
        // amount = getUpConst(_tokenId);
        erc20.transferFrom(msg.sender, address(this), upMonsterFee);
        tokenDetail[_tokenId].xp = needXp +1;
        tokenDetail[_tokenId].level = tokenDetail[_tokenId].level+1;
        tokenDetail[_tokenId].ce += _gameInfo.addAttr;
        tokenDetail[_tokenId].armor += _gameInfo.addAttr;
        tokenDetail[_tokenId].luk += _gameInfo.addAttr;
        emit UpMonster(_tokenId,tokenDetail[_tokenId].level,upMonsterFee,msg.sender);
    }

    function drawReward(uint256 index) public returns(bool){
        uint256 rateFee;
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
            erc20.transfer(msg.sender, rallReward);
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
        return needDay *_receiveInfo.rate;
    }

    function getTaskById(uint256 enemyId)public view returns(enemyInfo memory){
        enemyInfo memory task ;
        for (uint256 i = 0; i < _specialTask.length; i++) {
            if(_specialTask[i].id == enemyId){
                task =  _specialTask[i];
            }
        }
        return task;
    }

    function isBack(uint256 tokenId,address sender) public view returns(bool) {
        require(_userBackpack[sender].contains(tokenId) == true, "It's not to back");
        return true;
    }

    function addTask(uint256 odds,uint256 reward,uint256 xp,uint256 hp,string memory name,string memory pic) public onlyOwner{
        _specialTask.push(enemyInfo(enemyNum,odds,reward,xp,hp,name,pic));
        enemyNum +=1;
    }
    function pushTask() internal{
        addTask(20,1*10**17,0,20*10**8,"zcdq","");
        addTask(10,2*10**17,0,20*10**8,"gdrz","");
    }
    function editTask(uint256 _id,uint256 _odds,uint256 _reward)external onlyOwner{
        for(uint256 i=0;i<_specialTask.length;i++){
            if(_specialTask[i].id == _id){
                _specialTask[i].odds = _odds;
                _specialTask[i].basicReward = _reward;
                break;
            }
        }
    }

 
    function getSpecialTask() public view returns(enemyInfo[] memory){
        return _specialTask;
    }
    
    // function getUpConst(uint256 tokenId) public view returns(uint256){
    //     uint256 reward = getRewardByLevel(tokenId);
    //     if (reward<=0){
    //         return 0;
    //     }
    //     uint256 amount = reward * _gameInfo.upAttrCost /100;
    //     return amount;
    // }

    function getRewardByLevel(uint256 tokenId) public view returns(uint256){
       return _tokenLevel[tokenId][tokenDetail[tokenId].level];
    }

    function getTokenDetail(uint256 tokenId)public view  returns(uint256 level,uint256 ce,uint256 xp,uint256 armor,uint256 luk,uint256 rgTime){
        return (tokenDetail[tokenId].level,tokenDetail[tokenId].ce,tokenDetail[tokenId].xp,tokenDetail[tokenId].armor,tokenDetail[tokenId].luk,tokenDetail[tokenId].rgTime);
    }
    function getTokenDetails(uint256 tokenId) view public returns(CardDetails memory){
        return tokenDetail[tokenId];
    }

    function getUserAddress(uint256 tokenId) view public returns(address){
        return _tokenUser[tokenId];
    }

    function editCardDetails(uint256 tokenId,address addr)  public onlyRole(MINTER_ROLE) {
        _tokenUser[tokenId] = addr;
    }
    
    function getUserTeamCards(address sender) view public returns(uint256[]  memory){
        return _userTem[sender].values();
    }

    function getUserBkCards(address sender) view public returns(uint256[]  memory){
        return _userBackpack[sender].values();
    }
   
    receive() external payable { 
    	bnbPool += msg.value;
	}

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