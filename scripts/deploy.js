const hre = require("hardhat");

async function main() {
  // On récupère les 20 comptes de test de Hardhat
  const accounts = await hre.ethers.getSigners();

  // On décide que les 3 premiers comptes seront les Admins du Ministère
  const admin1 = accounts[0]; // Toi (par défaut)
  const admin2 = accounts[1];
  const admin3 = accounts[2];

  console.log("------------------------------------------------");
  console.log("👮 Admin 1 :", admin1.address);
  console.log("👮 Admin 2 :", admin2.address);
  console.log("👮 Admin 3 :", admin3.address);
  console.log("------------------------------------------------");

  // On déploie le contrat en lui donnant la liste des admins
  const DiplomaCertification = await hre.ethers.getContractFactory("DiplomaCertification");
  
  // PASSAGE DES ARGUMENTS AU CONSTRUCTEUR
  const diplomaContract = await DiplomaCertification.deploy([
      admin1.address, 
      admin2.address, 
      admin3.address
  ]);

  await diplomaContract.waitForDeployment();
  const address = await diplomaContract.getAddress();

  console.log("✅ Contrat V3 (Multi-Sig + Hash) déployé à :", address);
  console.log("------------------------------------------------");
  console.log("⚠️  N'oublie pas de copier cette adresse dans tes fichiers HTML !");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});