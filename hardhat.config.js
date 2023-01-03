require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork:"boom",
  networks: {
    hardhat: {
    },
    bscTest: {
      url: "https://data-seed-prebsc-1-s3.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [process.env.DEPLOY_PRIVATE_KEY]
    },
    bscMainnet: {
      url: "https://bsc-dataseed.binance.org",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [process.env.DEPLOY_PRIVATE_KEY]
    },
    boom: {
      url: "http://103.214.175.186:8540",
      chainId: 352,
      gasPrice: 20000000000,
      accounts: [process.env.DEPLOY_PRIVATE_KEY]
    },
    // rinkeby: {
    //   url: "https://eth-rinkeby.alchemyapi.io/v2/123abc123abc123abc123abc123abcde",
    //   accounts: [privateKey1, privateKey2]
    // }
  },
  etherscan: {
    apiKey: {
      // bscTestnet:process.env.ETHERSCAN_API_KEY
      bsc:process.env.ETHERSCAN_API_KEY
    } 
  },
  solidity: {
    version: "0.8.11",
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
  },
  },
};
