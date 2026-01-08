const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();
  // On configure 3 Admins
  const diplomaContract = await hre.ethers.deployContract("DiplomaCertification", [
      [accounts[0].address, accounts[1].address, accounts[2].address]
  ]);

  await diplomaContract.waitForDeployment();
  console.log("✅ Contrat V4 (W3C + Temp Token) déployé à :", await diplomaContract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});