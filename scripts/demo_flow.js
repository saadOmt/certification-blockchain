const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  // --- 1. SETUP DES ACTEURS ---
  // Hardhat nous donne des fausses adresses pour tester
  const [admin, school, student, company] = await ethers.getSigners();
  
  console.log("--- ACTEURS ---");
  console.log("Admin (Gouvernance):", admin.address);
  console.log("Ecole (Emetteur):   ", school.address);
  console.log("Etudiant (Holder):  ", student.address);
  console.log("-------------------------------------------\n");

  // --- 2. DEPLOIEMENT DU REGISTRE ---
  console.log(">>> 1. Deploiement du Smart Contract...");
  const IssuerRegistry = await hre.ethers.getContractFactory("IssuerRegistry");
  const registry = await IssuerRegistry.deploy();
  await registry.waitForDeployment();
  const registryAddress = await registry.getAddress();
  console.log("IssuerRegistry deploye a :", registryAddress);

  // --- 3. ONBOARDING (Inclusion de l'école) ---
  console.log("\n>>> 2. Onboarding de l'ecole (Admin -> Registry)...");
  // L'admin ajoute l'école "ESGI"
  const tx = await registry.connect(admin).addIssuer(school.address, "ESGI");
  await tx.wait();
  console.log("L'ecole 'ESGI' a ete ajoutee au registre par l'Admin.");

  // --- 4. EMISSION DU DIPLOME (VC) ---
  console.log("\n>>> 3. Creation du VC (Ecole -> Etudiant)...");
  
  // Les données du diplôme (JSON simplifié)
  const diplomaData = {
    studentID: "ETU-12345",
    degree: "Master Blockchain",
    year: 2025,
    schoolName: "ESGI"
  };

  // HACHAGE : On transforme les données en une empreinte unique
  // On utilise solidityPackedKeccak256 pour simuler ce qui se passe en crypto
  const diplomaHash = ethers.solidityPackedKeccak256(
    ["string", "string", "uint256", "string"],
    [diplomaData.studentID, diplomaData.degree, diplomaData.year, diplomaData.schoolName]
  );
  console.log("Hash du diplome:", diplomaHash);

  // SIGNATURE ECOLE : L'école signe le hash avec sa clé privée
  // C'est ça le "Verifiable Credential" (Data + Signature)
  const schoolSignature = await school.signMessage(ethers.getBytes(diplomaHash));
  console.log("Signature Ecole (VC):", schoolSignature.substring(0, 50) + "...");

  // --- 5. CHALLENGE & PRESENTATION (VP) ---
  console.log("\n>>> 4. Creation du VP (Etudiant -> Entreprise)...");
  
  // L'entreprise envoie un nombre aléatoire (Nonce) pour éviter le rejeu
  const nonce = 987654321; 
  console.log("Challenge recu (Nonce):", nonce);

  // L'étudiant crée le VP : Il signe (VC + Nonce)
  // Cela prouve qu'il possède le diplôme ET qu'il répond au challenge maintenant
  const vpHash = ethers.solidityPackedKeccak256(
    ["bytes32", "uint256"], // On mixe le hash du diplôme et le nonce
    [diplomaHash, nonce]
  );
  
  const studentSignature = await student.signMessage(ethers.getBytes(vpHash));
  console.log("Signature Etudiant (VP):", studentSignature.substring(0, 50) + "...");

  // --- 6. VERIFICATION (Entreprise) ---
  console.log("\n>>> 5. Verification par l'Entreprise...");

  // A. Vérifier la signature de l'étudiant
  const recoveredStudent = ethers.verifyMessage(ethers.getBytes(vpHash), studentSignature);
  console.log("1. Signataire du VP recupere :", recoveredStudent);
  if (recoveredStudent === student.address) {
    console.log("   -> SUCCES : C'est bien l'etudiant qui a repondu.");
  } else {
    console.log("   -> ECHEC : Usurpation d'identite !");
  }

  // B. Vérifier la signature de l'école (sur le diplôme original)
  const recoveredSchool = ethers.verifyMessage(ethers.getBytes(diplomaHash), schoolSignature);
  console.log("2. Signataire du Diplome recupere :", recoveredSchool);

  // C. Vérifier que cette école est bien dans le Registre (Blockchain)
  const schoolInfo = await registry.getIssuer(recoveredSchool);
  console.log(`3. Verification Blockchain pour ${recoveredSchool}...`);
  console.log(`   -> Nom: ${schoolInfo[0]}`);
  console.log(`   -> Statut: ${schoolInfo[1] == 1 ? "ACTIF" : "INACTIF"}`);

  if (schoolInfo[1] == 1) { // 1 = ACTIVE
     console.log("\n✅ VERIFICATION REUSSIE : Le diplome est authentique et l'ecole est certifiee.");
  } else {
     console.log("\n❌ ECHEC : L'ecole n'est pas reconnue.");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});