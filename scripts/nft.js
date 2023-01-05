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
  await nft.deployed();
  console.log("NFT deployed to:", nft.address);

  /** box */
  // We get the contract to deploy
  const Box = await hre.ethers.getContractFactory("Box");
  const box = await Box.deploy();
  await box.deployed();
  console.log("Box deployed to:", box.address);
  /** game */
  const Game = await hre.ethers.getContractFactory("Game");
  const game = await Game.deploy();
  await game.deployed();
  console.log("Game deployed to:", game.address);
  /** monster */
  const Monster = await hre.ethers.getContractFactory("Monster");
  const monster = await Monster.deploy();
  await monster.deployed();
  console.log("Monster deployed to:", monster.address);
  /** Arena */
  const Arena = await hre.ethers.getContractFactory("Arena");
  const arena = await Arena.deploy();
  await arena.deployed();
  console.log("Arena deployed to:", arena.address);
  /** Market */
  const Market = await hre.ethers.getContractFactory("Market");
  const market = await Market.deploy();
  await market.deployed();
  console.log("Market deployed to:", market.address);
  /** Hero */
  const Hero = await hre.ethers.getContractFactory("Hero");
  const hero = await Hero.deploy();
  await hero.deployed();
  console.log("Hero deployed to:", hero.address);

  // 初始化数据
  var erc20Token = "0x2fC0eBefDD68134809Ee359BBC8A5576c3788120";
  var nftToken = nft.address;
  // var erc20Token = "0x28ba88F74c4257e044d426a1e9E586024AA90c17";
  // var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
  // var priceRoter = "0xC9d4412910DBB03F7fF854cE3F1a9c1f3ebCAf85";

  /**nft */
  const setBoxsetRoletx = await nft.setRole(box.address);
  await setBoxsetRoletx.wait();
  console.log("setnft success");
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
  const setUnlockTimeTx = await market.setUnlockTime(1800);
  await setUnlockTimeTx.wait();

  const addWhiteListTx1 = await box.addWhiteList("0x511673a05De8e6CdFf5464e3490d294f21666242", true);
  await addWhiteListTx1.wait();

  const addWhiteListTx2 = await box.addWhiteList("0xA1152FC97d76a8Db0e530f0202B31e9C54801349", true);
  await addWhiteListTx2.wait();

  const setUnlockTimeTx2 = await game.setUnlockTime(600);
  await setUnlockTimeTx2.wait();

  // const setGameInfoTx =  game.setGameInfo(12*3600,5,10*10**18,100,10,25,2000*10**18);
  // await setGameInfoTx.wait();

  console.log("Test config success");

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