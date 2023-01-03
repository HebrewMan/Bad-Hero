// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NFT.sol";
import "./Game.sol";

contract Hero is Ownable{
    constructor() {
        initStart();
    }
    
    IERC20 public erc20;
    
    uint256 _upEqCost = 1000*10**18;     
    mapping(address=>heroAttribute[]) _userHero; 
    mapping(uint64=>monsterInfo[]) _monsters;
    mapping(uint256=> nftKind) _nftKinds;
    mapping(uint32=>eqAttribute[]) _equipment; 
    mapping(uint32=>string) _equipmentInfo; 

    Game  public  _game;
    struct heroAttribute{
        uint32 eqType;
        uint32 level;
        uint256 bonus;
    }
    struct monsterInfo{
        uint256 rarity;
        uint256 ce;
        uint256 armor;
        uint256 luk;
        string name; 
    }
    struct nftKind{
        uint32 start;
        uint32 end;
        uint64 atRate;
        string ranking;
        string rankingName;
        string url;
    }
     
    struct eqAttribute{
        uint32 level;
        uint32 reward;
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

    event UpHeroEq(uint256 indexed eqType,uint256 indexed level,uint256 amount,address sender);
    event Withdrawal(uint256 indexed amount,address indexed sender);
   
    function upEquipment(uint32 _eqType) public{
        heroAttribute[] storage heroEqs =  _userHero[msg.sender];
        uint256 level ;
        for (uint256 index = 0; index < heroEqs.length; index++) {
            if(heroEqs[index].eqType == _eqType){
                level = heroEqs[index].level +1;
                require(level<=3,"Level cap");
                heroEqs[index].level = uint32(level);
                heroEqs[index].bonus = getBonus(uint32(index),level);
                erc20.transferFrom(msg.sender, address(this), _upEqCost);
                break;
            }
        }
        emit UpHeroEq(_eqType,level,_upEqCost,msg.sender);
    }
     function getBonus(uint32 index,uint256 level) view public returns(uint256){
        eqAttribute[] memory attr = _equipment[index];
        uint256 reward;
        for (uint256 i = 0; i < attr.length; i++) {
            if(attr[i].level==level){
                reward = attr[i].reward;
                break;
            }
        }
        return reward;
    }
    function initStart()public {
        initEq();
        _setNftKind();
        _setMonsterInfo();
    }
    
    function initEq() internal{
        uint256[6] memory reward= [uint256(1),3,10,10,10,10]; 
        for(uint32 j=0;j<=5;j++){
            for (uint32 i=0;i<=3;i++){
                uint256 rw = reward[j] * i;
                _equipment[j].push(eqAttribute(i,uint32(rw)));
            }
        }
        _equipmentInfo[0] = "Cornucopia";
        _equipmentInfo[1] = "Life Fountain";
        _equipmentInfo[2] = "Wisdom literature";
        _equipmentInfo[3] = "Demon Sword";
        _equipmentInfo[4] = "Warrior Armor";
        _equipmentInfo[5] = "angel bless";
    }
    
    function randNftByType(uint32 _index) view internal returns(monsterInfo memory,uint64 _length){
        monsterInfo[] memory _monsterInfo = _monsters[_index];
        _length =uint64(rand(_monsterInfo.length));
        monsterInfo memory _monster = _monsterInfo[_length];
        return (_monster,_length);
    }
    function rand(uint256 _length) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return (random%_length);
    }

    function _setNftKind() internal  {
        _nftKinds[0] = nftKind(49,100,70,"N","Normal","");
        _nftKinds[1] = nftKind(19,49,75,"R","Rare","");
        _nftKinds[2] = nftKind(5,19,80,"SR","Super Rare","");
        _nftKinds[3] = nftKind(1,5,85,"SSR","Super Super Rare","");
        _nftKinds[4] = nftKind(0,1,90,"UR","Ultra Rare","");
        
    }

    function _setMonsterInfo()  internal{
        _monsters[0].push(monsterInfo(0,150,150,150,"Geryon"));
        _monsters[0].push(monsterInfo(0,50,200,200,"Agrius"));
        _monsters[0].push(monsterInfo(0,300,50,100,"Grindylow"));
        _monsters[0].push(monsterInfo(0,100,50,300,"Harpy"));
        _monsters[0].push(monsterInfo(0,50,350,50,"Alistar"));

        _monsters[1].push(monsterInfo(1,250,200,200,"Conqueror"));
        _monsters[1].push(monsterInfo(1,200,250,200,"Alterac"));
        _monsters[1].push(monsterInfo(1,200,200,250,"Shyvana"));
        _monsters[1].push(monsterInfo(1,0,0,650,"Okypete"));

        _monsters[2].push(monsterInfo(2,600,100,100,"Charybdis"));
        _monsters[2].push(monsterInfo(2,300,250,250,"Fenris"));
        _monsters[2].push(monsterInfo(2,250,350,200,"Kargath"));

        _monsters[3].push(monsterInfo(3,550,350,150,"Zuluhed"));
        _monsters[3].push(monsterInfo(3,350,200,500,"Kassadin"));
        _monsters[4].push(monsterInfo(4,550,350,400,"Vladimir"));
    }
 
    function initHeroEq(address _addr) public{
        if(_userHero[_addr].length == 0){
            _userHero[_addr].push(heroAttribute(0,0,0)) ;
            _userHero[_addr].push(heroAttribute(1,0,0)) ;
            _userHero[_addr].push(heroAttribute(2,0,0)) ;
            _userHero[_addr].push(heroAttribute(3,0,0)) ;
            _userHero[_addr].push(heroAttribute(4,0,0)) ;
            _userHero[_addr].push(heroAttribute(5,0,0)) ;
        }
    }
    

    function getMonsterInfo(uint64 _index) view public returns(monsterInfo[] memory){
        return _monsters[_index];
    }
    
    function getNftKind(uint256 index) view public returns(nftKind memory){
        return _nftKinds[index];
    }

    function getMonsterType() view public returns(uint256 ,uint256,uint256,uint256,uint256,string memory){
        uint256 num = 5;
        uint256 nftKindId;
        uint256 monsterId;
        uint256 random=rand(100);
        monsterInfo memory _monster ;
        for (uint256 i=0;i<num;i++){
            if (_nftKinds[i].start <=random && random < _nftKinds[i].end){
                nftKindId = i;
               (_monster,monsterId )= randNftByType(uint32(i));
                break;
            }
        }
        return (nftKindId,monsterId,_monster.ce,_monster.armor,_monster.luk,_monster.name);
    }
    
    // modifier isUser(uint256 tokenId){
    //    require(_game.getUserAddress(tokenId)!=msg.sender,"Have no legal power");
    //     _;
    // }
   

    function getHeroEq(address _addr) public view  returns(heroAttribute[] memory){
        // if (_userHero[_addr].length == 0){
        //     initHeroEq(_addr);
        // }
        return _userHero[_addr];
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
  
    function getCombatOdds(uint256 tokenId,address addr) view public returns(uint256,uint256,uint256,uint256,uint256,uint256){
        heroAttribute[] memory _attrs = _userHero[addr];
        combatOdds memory _combatOdds;
        for (uint256 i = 0; i < _attrs.length; i++) {
            if(_attrs[i].eqType==0){
                _combatOdds.addReward = _attrs[i].bonus;
            }
            if(_attrs[i].eqType==1){
                _combatOdds.addHp = (_attrs[i].bonus*200/100)*10**8;
            }
            if(_attrs[i].eqType==2){
                _combatOdds.addXp = _attrs[i].bonus;
            }
            if(_attrs[i].eqType==3){
                _combatOdds.addPower = _attrs[i].bonus;
            }
            if(_attrs[i].eqType==4){
                _combatOdds.addDefens = _attrs[i].bonus;
            }
            if(_attrs[i].eqType==5){
                _combatOdds.addLuk = _attrs[i].bonus;
            }
            
        }
        cardDetails memory _cardDetails;
        (,_cardDetails.ce,_cardDetails.xp,_cardDetails.armor,_cardDetails.luk,) =  _game.getTokenDetail(tokenId);
        _combatOdds.addPower += _cardDetails.ce;
        _combatOdds.addDefens += _cardDetails.armor;
        // _combatOdds.addXp += _cardDetails.xp;
        _combatOdds.addLuk += _cardDetails.luk;
        _combatOdds.injury = (_combatOdds.addDefens/10)*10**8+_combatOdds.addHp;

        // return _combatOdds;
        return (_combatOdds.addPower,_combatOdds.addDefens,_combatOdds.addXp,_combatOdds.addLuk,_combatOdds.injury,_combatOdds.addReward);
    }

    function setGame(address payable _gameAddress) public onlyOwner{
        _game = Game(_gameAddress);
    }
   
   function setToken(address _tokenAddress) public onlyOwner{
        erc20 = IERC20(_tokenAddress);
    }

    function withdrawalToken(address addr,uint256 amount) public onlyOwner {
        erc20.transfer(addr, amount);
        emit Withdrawal(amount,addr);
    }
}