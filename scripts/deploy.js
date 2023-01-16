// import * as addresses from '../common/whitelist.js';
const {whitelist1,whitelist2,whitelist3,whitelist4,whitelist5,whitelist6} = require("../common/whitelist");

const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  /** nft */
  const NFT = await hre.ethers.getContractFactory("NFT");
  const nft = await NFT.deploy();
  console.log("nft_contract:", nft.address);
  /** box */
  // We get the contract to deploy
  const Box = await hre.ethers.getContractFactory("Box");
  const box = await Box.deploy();
  console.log("box_contract:", box.address);
  /** game */
  const Game = await hre.ethers.getContractFactory("Game");
  const game = await Game.deploy();
  console.log("game_contract:", game.address);
  /** monster */
  const Monster = await hre.ethers.getContractFactory("Monster");
  const monster = await Monster.deploy();
  // await monster.deployed();
  console.log("monster_contract:", monster.address);
  /** Arena */
  const Arena = await hre.ethers.getContractFactory("Arena");
  const arena = await Arena.deploy();
  // await arena.deployed();
  console.log("arena_contract:", arena.address);
  /** Market */
  const Market = await hre.ethers.getContractFactory("Market");
  const market = await Market.deploy();
  console.log("market_contract:", market.address);
  /** Hero */
  const Hero = await hre.ethers.getContractFactory("Hero");
  const hero = await Hero.deploy();
  console.log("hero_contract:", hero.address);

  // 初始化数据
  var erc20Token = "0x5439D37489Eef432979734e8ca7a36A826Cc1b58";
  var nftToken = nft.address;
  // var erc20Token = "0x28ba88F74c4257e044d426a1e9E586024AA90c17";
  // var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
  // var priceRoter = "0xC9d4412910DBB03F7fF854cE3F1a9c1f3ebCAf85";

  /**nft */
  // const setBoxsetRoletx = await nft.setRole(box.address);
  // await setBoxsetRoletx.wait();
  // console.log("setnft success");
  /** Token */
  // const setGameTokenTx = await box.setGame(game.address);
  // await setGameTokenTx.wait();
  
  /**box */
 
  const setBoxNftTx = await box.setNftToken(nftToken);
  await setBoxNftTx.wait();
  const setBoxsetHeroTx = await box.setHero(hero.address);
  await setBoxsetHeroTx.wait();
  const setBoxSetGameTx = await box.setGame(game.address);
  await setBoxSetGameTx.wait();
  console.log("setBox success");
  /** game */
  const setGameerc20TokenTx = await game.setErc20(erc20Token);
  await setGameerc20TokenTx.wait();
  const setsetMonsterTx = await game.setMonster(monster.address);
  await setsetMonsterTx.wait();
  const setGameRoloBoxTx = await game.setRole(box.address);
  await setGameRoloBoxTx.wait();
  const setGameRoloMarketTx = await game.setRole(market.address);
  await setGameRoloMarketTx.wait();
  const setGameRoloArenaTx = await game.setRole(arena.address);
  await setGameRoloArenaTx.wait();
  console.log("setGame success");

  /** monster */
  const setMonsterSetGameTx = await monster.setGame(game.address);
  await setMonsterSetGameTx.wait();
  const setMonstersetHERoTx = await monster.setHero(hero.address);
  await setMonstersetHERoTx.wait();
  console.log("setMonsterset success");

  /** Arena */
  const setArenasetGameTx = await arena.setGame(game.address);
  await setArenasetGameTx.wait();
  const setArenasetErc20Tx = await arena.setErc20(erc20Token);
  await setArenasetErc20Tx.wait();
  const setArenasetsetHerox = await arena.setHero(hero.address);
  await setArenasetsetHerox.wait();
  console.log("setArenaset success");

  /** Market */
  const setMarksetErc20AddrTx = await market.setErc20Addr(erc20Token);
  await setMarksetErc20AddrTx.wait();
  const setMarksetNFTAddrTx = await market.setNFTAddr(nftToken);
  await setMarksetNFTAddrTx.wait();
  const setMarksetGameTx = await market.setGame(game.address);
  await setMarksetGameTx.wait();
  console.log("setMarkset success");

  /** Hero */
  const setHerosetGameTx = await hero.setGame(game.address);
  await setHerosetGameTx.wait();
  const setHerosetERC20Tx = await hero.setToken(erc20Token);
  await setHerosetERC20Tx.wait();
  console.log("setHeroset success");


  /** Test 测试专用配置*/

  // const setUnlockTimeTx = await market.setUnStakeTime(1800);
  // await setUnlockTimeTx.wait();



  //whitelist addresses
  // let arr100 = [' 0xA1aeA46Fff687c1C28bE57489a4A3B2DFDaE89CE','0xE7ef279506848cc6efDe70fd4E4aFac7573FE471'];
  // arr100 = arr100.map(item=>item= item.trim())

  const _whitelist1 = whitelist1.map(item=>item= item.trim())
  const _whitelist2 = whitelist2.map(item=>item= item.trim())
  const _whitelist3 = whitelist3.map(item=>item= item.trim())
  const _whitelist4 = whitelist4.map(item=>item= item.trim())
  const _whitelist5 = whitelist5.map(item=>item= item.trim())
  const _whitelist6 = whitelist6.map(item=>item= item.trim())
  
  const addWhiteListTx1 = await box.addWhiteListBatch(_whitelist1, true);
  await addWhiteListTx1.wait();

  const addWhiteListTx2 = await box.addWhiteListBatch(_whitelist2, true);
  await addWhiteListTx2.wait();

  const addWhiteListTx3 = await box.addWhiteListBatch(_whitelist3, true);
  await addWhiteListTx3.wait();

  const addWhiteListTx4 = await box.addWhiteListBatch(_whitelist4, true);
  await addWhiteListTx4.wait();

  const addWhiteListTx5 = await box.addWhiteListBatch(_whitelist5, true);
  await addWhiteListTx5.wait();

  const addWhiteListTx6 = await box.addWhiteListBatch(_whitelist6, true);
  await addWhiteListTx6.wait();

  console.log('set whitelist success')


  // const setUnlockTimeTx2 = await game.setUnlockTime(3600);
  // await setUnlockTimeTx2.wait();

  // const setGameInfoTx =  game.setGameInfo(12*3600,5,10*10**18,100,10,25,2000*10**18);
  // await setGameInfoTx.wait();

  // console.log("Test config success");

  // await verifyContract("contracts/Token.sol:Token", token.address);
  // await verifyContract("contracts/GetFee.sol:GetFee", getFee.address);
  // await verifyContract("contracts/NFT.sol:NFT", nft.address);
  // await verifyContract("contracts/Box.sol:Box", box.address);
  // await verifyContract("contracts/Game.sol:Game", game.address);
  // await verifyContract("contracts/Monster.sol:Monster", monster.address);
  // await verifyContract("contracts/Arena.sol:Arena", arena.address);
  // await verifyContract("contracts/Market.sol:Market", market.address);
  // await verifyContract("contracts/Hero.sol:Hero", hero.address);
}
async function verifyContract(contractName, contractAddress, args) {
  try {
      console.log("Verifying contract...");
      await hre.run("verify:verify", {
          contract: contractName, address: contractAddress, constructorArguments: args
      });
      console.log('Verification Completed')
      console.log("\n");
  } catch (err) {
      console.log('Already Verified')
      console.log("\n");
      console.log(err)
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });