// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Game = await hre.ethers.getContractFactory("Game");
  const game = await Game.deploy("0x62b3681D7d8C9c2C2D490a5785E7D0aE12864201");
  await game.deployed();
  console.log("Game deployed to:", game.address);


  // 初始化数据
  var erc20Token = "0x0a2231B33152d059454FF43F616E4434Afb6Cc64";
  // var nftToken = nft.address;
  var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
  var priceRoter = "0x62b3681D7d8C9c2C2D490a5785E7D0aE12864201";

  /** game */
  const setGameRouterAddressTx = await game.setRouterAddress(priceRoter);
  await setGameRouterAddressTx.wait();
  const setGameerc20TokenTx = await game.setErc20(erc20Token);
  await setGameerc20TokenTx.wait();
  const setsetMonsterTx = await game.setMonster("0x992b34C9E1287AE65FB70c153187bCBcE795Cc81");
  await setsetMonsterTx.wait();
  const setGameRoloBoxTx = await game.setRole("0x5b2387a2d4985593fb85aCC71FB31B18b3a72589");
  await setGameRoloBoxTx.wait();
  const setGameRoloMarketTx = await game.setRole("0x1E382e29e15967301F87b3F67fe190AC28b2428b");
  await setGameRoloMarketTx.wait();
  const setGameRoloArenaTx = await game.setRole("0x3261bF23a459304d750E66BB57988A0526752E78");
  await setGameRoloArenaTx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
