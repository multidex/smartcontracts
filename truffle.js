require("dotenv").config();
const HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          process.env.MNEMONIC,
          `https://rinkeby.infura.io/v3/${process.env.INFURA_TOKEN}`
        );
      },
      network_id: 0x4, // 4
      from: process.env.FROM
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(
          process.env.MNEMONIC,
          `https://ropsten.infura.io/v3/${process.env.INFURA_TOKEN}`
        );
      },
      network_id: 0x3, // 3
      from: process.env.FROM
    }
  },
  compilers: {
    solc: {
      version: "0.4.18"
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    },
    evmVersion: "byzantium"
  }
};
