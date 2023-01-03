const hre = require("hardhat");

async function main() {
    /** Monster */
  const Monster = await hre.ethers.getContractFactory("Monster");
  const monster = await Monster.deploy();
  await monster.deployed();
  console.log("monster deployed to:", monster.address);

   // 初始化数据
   var erc20Token = "0x0a2231B33152d059454FF43F616E4434Afb6Cc64";
   // var nftToken = nft.address;
   var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
   var priceRoter = "0x62b3681D7d8C9c2C2D490a5785E7D0aE12864201";
  /** Monster */
  const setMonsterSetGameTx = await monster.setGame("0x79C25969Fe76faED352c91DE9BC993e769DE446e");
  await setMonsterSetGameTx.wait();
  const setMonstersetBADHERoTx = await monster.setBADHero("0x456F3250687514717e2f43AAD8D5fc2B42d3b128");
  await setMonstersetBADHERoTx.wait();
 
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });