const hre = require("hardhat");

async function main() {
    // await verifyContract("contracts/Token.sol:Token", "0x28ba88F74c4257e044d426a1e9E586024AA90c17");
    // await verifyContract("contracts/GetFee.sol:GetFee", "0xA2251370247E75E93bfc34ECe6b1e82Ba50B5452");
    await verifyContract("contracts/NFT.sol:NFT", "0x667B74052BBCe155cd6Bf248D8FD10DB25B1D100");
    await verifyContract("contracts/Box.sol:Box", "0x471dCe6964044c527721dfFc4a9A9a4233e5DBe2");
    await verifyContract("contracts/Game.sol:Game", "0x329B9b82D8CCFde6C6104e517e50fEa6a0c6a967");
    await verifyContract("contracts/Monster.sol:Monster", "0x10d199C5891F51D869A0dA037B0CE73010F0a408");
    await verifyContract("contracts/Arena.sol:Arena", "0x6F0f3c55dA3175f8e8E8a4BaBbD25371697B486c");
    await verifyContract("contracts/Market.sol:Market","0x2E553C37F713013Dd5c7437314846CA7beB445BB");
    await verifyContract("contracts/Hero.sol:Hero", "0x38fC00bB893A0DD23E95660129B66bB3407fFfb6");
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