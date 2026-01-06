// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  // 1. On récupère ton compte (le compte "deployer")
  const [deployer] = await hre.ethers.getSigners();
  console.log("------------------------------------------------");
  console.log("Déploiement avec le compte :", deployer.address);

  // 2. On déploie le contrat
  const DiplomaCertification = await hre.ethers.getContractFactory("DiplomaCertification");
  const diplomaContract = await DiplomaCertification.deploy();
  
  // Attendre que le déploiement soit confirmé
  await diplomaContract.waitForDeployment();
  const address = await diplomaContract.getAddress();

  console.log("✅ Contrat déployé à l'adresse :", address);

  // 3. LA CORRECTION : On t'ajoute comme école tout de suite !
  console.log("Inscription de l'admin en tant qu'école...");
  
  const tx = await diplomaContract.addSchool(deployer.address, "Mon Ecole (Admin)");
  await tx.wait(); // On attend la validation

  console.log("🎉 SUCCÈS : Tu es maintenant autorisé à créer des diplômes !");
  console.log("------------------------------------------------");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});