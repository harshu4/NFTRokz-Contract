import 'hardhat-deploy';
import "@nomiclabs/hardhat-etherscan";
import "hardhat-prettier";
import '@nomiclabs/hardhat-ethers';

import { HardhatUserConfig } from 'hardhat/types';


interface ExtendedHardhatUserConfig extends HardhatUserConfig {
  namedAccounts: { [key: string]: string };
}

const ehhuc: ExtendedHardhatUserConfig = {
  solidity: "0.8.4",
  networks: {
    goerli: {
      live: true,
      saveDeployments: true,
      url: "https://rpc.ankr.com/eth_goerli",
      accounts: ["be21a2f0725e5618a8754614cc9bedd226504ddf88affa4ed7ac6d8862718537"]
    }
  },
  namedAccounts: {
    deployer: "0xfb46D77E67a59Cf985d56aF1aF19c51cEB6206ea"
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY as string || ''
  }
};

export default ehhuc;
