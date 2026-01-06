const hre = require("hardhat");

async function main() {
  const IssuerRegistry = await hre.ethers.getContractFactory("IssuerRegistry");
  const registry = await IssuerRegistry.deploy();
  await registry.waitForDeployment();
  const address = await registry.getAddress();
  
  console.log("----------------------------------------------------");
  console.log("ADRESSE DU CONTRAT : " + address);
  console.log("----------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});