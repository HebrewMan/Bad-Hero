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
  /** Market */
  const Market = await hre.ethers.getContractFactory("Market");
  const market = await Market.deploy();
  await market.deployed();
  console.log("Market deployed to:", market.address);


  // 初始化数据
  var erc20Token = "0x0a2231B33152d059454FF43F616E4434Afb6Cc64";
  // var nftToken = nft.address;
  var nftToken = "0x03960BF2C1074c915a86618433f1E580C3cbfA59";
  var priceRoter = "0x62b3681D7d8C9c2C2D490a5785E7D0aE12864201";

  /** Market */
  const setMarksetErc20AddrTx = await market.setErc20Addr(erc20Token);
  await setMarksetErc20AddrTx.wait();
  const setMarksetRouterAddrTx = await market.setRouterAddr(priceRoter);
  await setMarksetRouterAddrTx.wait();
  const setMarksetNFTAddrTx = await market.setNFTAddr(nftToken);
  await setMarksetNFTAddrTx.wait();
  const setMarksetGameTx = await market.setGame("0x5C453391540e9b583a0486B92BEf5Fb253F86b1B");
  await setMarksetGameTx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
