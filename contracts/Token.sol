// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    address immutable game = 0xB4BA18e928b5C166cD99b15A2B75370D2EE07735;
    address immutable comAddr = 0xb6e436c8124602Dac77fb097623947023D6337Fc;
    constructor() ERC20("MetaWarRior", "MWR") {
         _mint(msg.sender, 100000000*10**18);
    }
    mapping(address=>bool) public feeAddr;
    uint256 public rate=1;
    uint256 public ratePool=9;
    uint256 public collPool=2;

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 at = burnFee(_msgSender(),recipient,amount);
        _transfer(_msgSender(), recipient, at);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 at = burnFee(sender,recipient,amount);
        _transfer(sender, recipient, at);
        return true;
    }
    function burnFee(address sender,address recipient,uint256 amount) internal returns(uint256){
        uint256 at = amount;
         if(feeAddr[sender] || feeAddr[recipient]){
            uint fee = at*rate/100;
            uint pool = at*ratePool/100;
            uint compool = at*collPool/100;
            at = at - fee - pool - compool;
            _burn(sender, fee);
            _transfer(sender, game, pool);
            _transfer(sender, comAddr, compool);
            return at;
        }
       
       return amount;
    }
    function setFeeAddr(address addr) public onlyOwner{
        feeAddr[addr] = true;
    }
    

    function rempveFeeAddr(address addr) public onlyOwner{
        feeAddr[addr] = false;
    }

    function getFeeAddrStatus(address addr) public view returns(bool){
        return feeAddr[addr];
    }
}