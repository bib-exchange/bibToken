// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
// eslint-disable-next-line import/no-extraneous-dependencies
const hre = require("hardhat");
// import { ethers, upgrades } from 'hardhat';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
   // 1) 部署LibMath库合约
   libFactory = await ethers.getContractFactory("IterableMapping");
   libObj = await libFactory.deploy()

  // We get the contract to deploy
  const BIBToken = await hre.ethers.getContractFactory("BIBRewardToken");
  const bibToken = await BIBToken.deploy();

  await bibToken.deployed();
  console.log("BIBRewardToken deployed to:", bibToken.address);
  

//   const admin = await upgrades.admin.getInstance();
//   const impl_addr = await admin.admin.getProxyImplementation(bibToken.address);
//   await hre.run('verify:verify', {
//     address: impl_addr,
//     constructorArguments: [],
// });

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
