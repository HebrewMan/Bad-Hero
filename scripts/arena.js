const hre = require("hardhat");

async function main() {
    /** Arena */
  const Arena = await hre.ethers.getContractFactory("Arena");
  const arena = await Arena.deploy();
  await arena.deployed();
  console.log("Arena deployed to:", arena.address);

   // 初始化数据
   var erc20Token = "0x0a2231B33152d059454FF43F616E4434Afb6Cc64";
   // var nftToken = nft.address;
   var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
   var priceRoter = "0x62b3681D7d8C9c2C2D490a5785E7D0aE12864201";
  /** Arena */
  const setArenasetGameTx = await arena.setGame("0x79C25969Fe76faED352c91DE9BC993e769DE446e");
  await setArenasetGameTx.wait();
  const setArenasetErc20Tx = await arena.setErc20(erc20Token);
  await setArenasetErc20Tx.wait();
  const setArenasetsetBadHerox = await arena.setBadHero("0x456F3250687514717e2f43AAD8D5fc2B42d3b128");
  await setArenasetsetBadHerox.wait();
  // TODO 设置game arena role  
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });