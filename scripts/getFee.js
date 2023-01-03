const hre = require("hardhat");

async function main() {
    /** Arena */
  const GetFee = await hre.ethers.getContractFactory("GetFee");
  const getFee = await GetFee.deploy();
  await getFee.deployed();
  console.log("GetFee deployed to:", getFee.address);

  /** Arena */
  const setRotuerTx = await getFee.setIpaddress("0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3");
  await setRotuerTx.wait();
  const setWbnbTx = await getFee.setWbnbddress("0xae13d989dac2f0debff460ac112a837c89baa7cd");
  await setWbnbTx.wait();
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