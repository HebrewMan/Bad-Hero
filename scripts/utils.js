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