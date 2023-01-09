// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IHero.sol";
import "./interfaces/IGame.sol";

contract Monster is Ownable  {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    constructor()  {
        initEney();
    }

    enemyInfo[] public enemys;
    uint32 enemyNum;
    uint256 basicHp = 200*10**8;
    IHero public _hero;
    IGame public _game;
    // uint256 _unlockTime = 86400;
    uint256 _unlockTime = 3600;

   
    event Fighting(bool isSuccess,uint256 indexed fightType,uint256 indexed sHp,uint256  addXp,uint256 indexed reward);
    event Test(bool isSuccess,uint256 indexed number,uint256 indexed suc);
    
    struct enemyInfo{
        uint32 id;
        uint256 odds;
        uint256 basicReward;
        uint256 basicXp;
        uint256 basicHp;
        string  name;
        string  pic;
    }
    struct combatOdds{
            uint256 addReward;
            uint256 addHp;
            uint256 addXp;
            uint256 addPower;
            uint256 addDefens;
            uint256 addLuk;
            uint256 injury;
        } 
    struct figInfo{
        uint256 succesRate;
        uint256 totalSuc;
        uint256 reward;
        uint256 addXp;
        uint256 sHp;
        bool isSuccess;
    }
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
    
    struct rewardPool{
        uint32 id; 
        uint32 rewardType; 
        uint256 tokenId;
        uint256 reward;
        uint256 addTime;
        uint256 unLockTime;
    }
    struct addXpInfo{
        uint256 totalXp;
        uint256 validXp;
    } 
    // struct tokenEarnings{
    //         uint256 level; 
    //         uint256 income; 
    // }

    modifier isFullHp(uint256 tokenId){
        uint256 tokenHp= getHp(tokenId);
        require(tokenHp >= basicHp," Hp Is no full");
        _;
    }
    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random%_length+1;
    }
    
    function fighting(uint256 tkId,uint256 enemyId,address addr) public view  isFullHp(tkId) returns(bool,uint256,uint256,uint256,uint256){
        combatOdds memory _combatOdds;
        
        (_combatOdds.addPower,_combatOdds.addDefens,_combatOdds.addXp,_combatOdds.addLuk,_combatOdds.injury,_combatOdds.addReward) = _hero.getCombatOdds(tkId,addr);
        figInfo memory _figInfo ;
        _figInfo.succesRate = _combatOdds.addPower/100;
        enemyInfo memory _enemy =getEnemyById(enemyId);
        _figInfo.totalSuc = _enemy.odds + _figInfo.succesRate;
        CardDetails memory _carDetail;
        (_carDetail.level,_carDetail.ce,,_carDetail.armor,_carDetail.luk,) = _game.getTokenDetail(tkId);
        uint256 randNumber = rand(100);
        
        if (randNumber>_figInfo.totalSuc){
            _carDetail.hp = 0;
            _carDetail.unLockTime = block.timestamp + _unlockTime;
            _figInfo.sHp= basicHp;
            _figInfo.isSuccess = false;
        }else{
            _figInfo.sHp = basicHp - _combatOdds.injury;
            _carDetail.hp = _combatOdds.addHp;
            _carDetail.unLockTime = block.timestamp + getRgTime(_figInfo.sHp);
            uint256 totalReward = _enemy.basicReward + _combatOdds.addLuk *_enemy.basicReward/1000;
            _figInfo.reward = totalReward + totalReward*_combatOdds.addReward/100;
            _figInfo.addXp =_enemy.basicXp + _combatOdds.addXp;
            addXpInfo memory _addXpInfo;
            _addXpInfo.totalXp =  _enemy.basicXp + _combatOdds.addXp;
            _addXpInfo.validXp = _carDetail.level * 100 -1;
            if(_addXpInfo.totalXp>=_addXpInfo.validXp){
                _carDetail.xp = _addXpInfo.validXp;
            }else{
                _carDetail.xp = _addXpInfo.totalXp;
            }
            _figInfo.isSuccess = true;
        }
        return (_figInfo.isSuccess,_figInfo.reward,_figInfo.sHp,_carDetail.xp,_carDetail.unLockTime);
        
    }
    

    function DoTask(uint256 tokenId,uint256 odds,uint256 basicReward,address addr ) public view isFullHp(tokenId)  returns(bool,uint256,uint256,uint256){
        combatOdds memory _combatOdds;
        (_combatOdds.addPower,_combatOdds.addDefens,_combatOdds.addXp,_combatOdds.addLuk,_combatOdds.injury,_combatOdds.addReward)  = _hero.getCombatOdds(tokenId,addr);
        figInfo memory _figInfo ;
        _figInfo.succesRate = _combatOdds.addPower/100;
        _figInfo.totalSuc = odds + _figInfo.succesRate;
        CardDetails memory _carDetail;
        (_carDetail.level,_carDetail.ce,_carDetail.xp,_carDetail.armor,_carDetail.luk,) = _game.getTokenDetail(tokenId);
        
        
        if (rand(100)>=_figInfo.totalSuc){
            _carDetail.hp = 0;
            _carDetail.unLockTime = block.timestamp + _unlockTime;
            _figInfo.sHp= basicHp;
        }else{
            _figInfo.sHp = basicHp - _combatOdds.injury;
            _carDetail.hp = _combatOdds.addHp;
            _carDetail.unLockTime = block.timestamp + getRgTime(_figInfo.sHp);
            uint256 totalReward = basicReward + _combatOdds.addLuk*basicReward/1000;
            _figInfo.reward = totalReward + totalReward*_combatOdds.addReward/100;
            _figInfo.isSuccess = true;
        }
        return (_figInfo.isSuccess,_figInfo.reward,_figInfo.sHp,_carDetail.unLockTime);
    }
    
    function getEnemyById(uint256 enemyId) view  public returns(enemyInfo memory){
        enemyInfo memory enemy ;
        for (uint256 i = 0; i < enemys.length; i++) {
            if(enemys[i].id == enemyId){
                enemy =  enemys[i];
                break;
            }
        }
        return enemy;
    }

   
    function addEnemy(uint256 odds,uint256 reward,uint256 xp,uint256 hp,string memory name,string memory pic) public onlyOwner{
        enemys.push(enemyInfo(enemyNum,odds,reward,xp,hp,name,pic));
        enemyNum +=1;
    }

    function initEney() internal{
        if(enemys.length ==0 ){
            addEnemy(80,2*10**16,20,200*10**8,"Gabriel","");
            addEnemy(50,3*10**16,20,200*10**8,"Horace","");
            addEnemy(25,4*10**16,25,200*10**8,"Rufio","");
            addEnemy(20,5*10**16,25,200*10**8,"Hadrea","");
            addEnemy(15,6*10**16,30,200*10**8,"Sirius","");
        }
    }

    function getEnemys() view public returns(enemyInfo[] memory){
        return enemys;
    }

    function delEnemy(uint256 id) public onlyOwner{
        for(uint256 i=0;i<enemys.length;i++){
            if(enemys[i].id == id){
               delete(enemys[i]);
               break;
            }
        }
    }
    function editEnemy(uint256 id,uint256 odds,uint256 reward,uint256 xp,uint256 hp,string memory name) public onlyOwner{
        for(uint256 i=0;i<enemys.length;i++){
            if(enemys[i].id == id){
                enemys[i].odds = odds;
                enemys[i].basicReward = reward;
                enemys[i].basicXp = xp;
                enemys[i].basicHp = hp;
                enemys[i].name = name;
                break;
            }
        }
    }


    function getHp(uint256 tokenId) view public returns(uint256){
        CardDetails memory _carDetail;
        (_carDetail.level,_carDetail.ce,_carDetail.xp,_carDetail.armor,_carDetail.luk,_carDetail.rgTime) = _game.getTokenDetail(tokenId);
        if(_carDetail.rgTime ==0){
            return basicHp ;
        }else{
            if (_carDetail.rgTime<=block.timestamp){
                return basicHp;
            }else{
                uint256  useTime = _carDetail.rgTime - block.timestamp;
                return _carDetail.hp + rgHp(useTime) ;
            }
        }
    }

    function getRgTime(uint256 hp) view internal returns(uint256){
        return hp*_unlockTime/basicHp; // ===================change
    }
    
   
    function rgHp(uint256 useTime)public view returns(uint256 hp){
        uint256 rate = basicHp/_unlockTime;
        return basicHp - rate*useTime;
    }
    function setGame(address payable _token) public onlyOwner{
        _game = IGame(_token);
    }
    function setHero(address _token) public onlyOwner{
        _hero = IHero(_token);
    }
}