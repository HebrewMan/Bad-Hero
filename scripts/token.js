const hre = require("hardhat");

async function main() {
    /** Token */
  const Token = await hre.ethers.getContractFactory("Token");
  const token = await Token.deploy();
  await token.deployed();
  console.log("Token deployed to:", token.address);
  await verifyContract("contracts/Token.sol:Token", token.address);
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