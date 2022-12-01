import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const L1_STARKNET_CORE = '0xde29d060D45901Fb19ED6C6e959EB22d8626708e';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {

	const { deployer } = await hre.getNamedAccounts();
	
	const gatewayAddress ="0x06f910b32963816cc5b8b9c8ca23c3296c69d5944ed86cff92e2b4d76b4d232e";
	if (hre.network.name) {
		
		try{
		var FERC721Deployment = await hre.deployments.deploy('FakeErc721', {
			from: deployer,
			args: [],
			log: true
		})
		
	}catch(err){
		console.log("i am in the erro")
		console.log(err);
	}



		if (FERC721Deployment.newlyDeployed) {
	
			console.log(`Sleeping 60sec before etherscan verification`);
			//await new Promise(ok => setTimeout(ok, 60000));
			
			
		}
	}

	const GatewayDeployment = await hre.deployments.deploy('Gateway', {
		from: deployer,
		args: [
			L1_STARKNET_CORE,
			gatewayAddress
		],
		log: true,
		skipIfAlreadyDeployed: false
	})
	
	if (GatewayDeployment.newlyDeployed) {
		console.log(`Sleeping 120sec before etherscan verification`);
	//	await new Promise(ok => setTimeout(ok, 120000));
	
		
	}


};
export default func;
