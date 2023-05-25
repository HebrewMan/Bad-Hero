
const hre = require("hardhat");

import { ethers } from "hardhat";

// The Contract interface
let abi = [
    "function publicMint(uint8 amount) ",
];

// Connect to the network
let privateKey = "0x23121";
let wallet = new ethers.Wallet(privateKey);

// Connect a wallet to mainnet
let provider = ethers.getDefaultProvider();
let walletWithProvider = new ethers.Wallet(privateKey, provider);

// 地址来自上面部署的合约
let contractAddress = "0xcde8f5008c313820b558addfcd8628e20cc1c2fe";

// 使用Provider 连接合约，将只有对合约的可读权限
let contract = new ethers.Contract(contractAddress, abi, walletWithProvider);

async function buyQzuki (){
    const options = {
        value: "10000000000000000",
    }

    try {
        
        const res = await contract.publicMint(1);
        console.log('============ success =============')
        console.log(res.hash)
    } catch (error) {
        console.log('============ error =============')
        console.log(error);
    }
    
}

buyQzuki();

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
