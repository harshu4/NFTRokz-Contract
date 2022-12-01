const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main () {
    // We get the contract to deploy
    const MyCnontract = await hre.ethers.getContractFactory("Gateway");
    const bridge = await MyCnontract.attach(
      "0xcDAa2Db7F970058cd373d5E68c10136ebAcF4160" // The deployed contract address
    );
    const Mycontract2 = await hre.ethers.getContractFactory("FakeErc721");
    const bridgenft = await Mycontract2.attach(
      "0x62FE9900068F495272EE1B92cCb2Ba6116817a65" // The deployed contract address
    );
    const { deployer } = await hre.getNamedAccounts();
	
//await bridgenft.mint(deployer,1);
// await bridgenft.approve(bridge.address,15);
let x =    await bridge.bridgeToStarknet(bridgenft.address,15,"0x070f8E809C6Cc1Ba7b1dfB721541D1227aBC19BcF0A7b85D6A13EBb3a3ee7Df4",hre.ethers.BigNumber.from('10000000000000000'),"0x5a643907b9a4bc6a55e9069c4fd5fd1f5c79a22470690f75556c4736e34426",{value:hre.ethers.BigNumber.from('30000000000000000')})
 
//console.log(x)
  //  await bridge.changegateway("0x0293db72cad0f062c08005ad1d10178c2646345bfeeaf845366ac84a56b8dd2f");

  }

  main()