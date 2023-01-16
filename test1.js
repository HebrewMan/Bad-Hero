const {whitelist2} = require("./common/whitelist");
const hre = require("hardhat");
const addr = whitelist2.forEach(item=>{
    item = item.trim();
    
    try {
        let res = hre.ethers.utils.getAddress(item);
    } catch (error) {
        console.log(88888888888888)
    }
   
})
