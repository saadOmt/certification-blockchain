const { ethers } = require("hardhat");

async function main() {
  console.log("\n🎬 --- DÉBUT DU SCÉNARIO DE TEST --- 🎬\n");

  // --- 1. CONFIGURATION (On déploie la BBC) ---
  const [admin, ecoleValide, ecolePirate, etudiant] = await ethers.getSigners();
  
  // On déploie le registre (la "BBC")
  const Registry = await ethers.getContractFactory("IssuerRegistry");
  const registry = await Registry.deploy();
  await registry.waitForDeployment();
  console.log("✅ Système BBC déployé.");

  // L'Admin ajoute une vraie école (ex: Sorbonne)
  await registry.addIssuer(ecoleValide.address, "Sorbonne Université");
  console.log(`✅ L'école 'Sorbonne' (${ecoleValide.address}) est ajoutée au registre.`);

  // --- TEST 1 : LE CAS PARFAIT (Vrai diplôme) ---
  console.log("\n--- 🧪 TEST 1 : Vrai Diplôme ---");
  
  // L'étudiant a un diplôme (Hash du PDF)
  const hashDiplome = ethers.id("Diplome_Ingenieur_2024_Jean_Dupont");
  
  // La Sorbonne signe ce hash (C'est le tampon numérique)
  const signatureValide = await ecoleValide.signMessage(ethers.getBytes(hashDiplome));

  // VÉRIFICATION :
  // A. Qui a signé ?
  const signataireTrouve = ethers.verifyMessage(ethers.getBytes(hashDiplome), signatureValide);
  
  // B. Est-ce que ce signataire est une école valide ?
  const infoEcole = await registry.getIssuer(signataireTrouve);

  if (signataireTrouve === ecoleValide.address && infoEcole.status == 1) {
      console.log("✅ SUCCÈS : Le diplôme est authentique et vient de la Sorbonne !");
  } else {
      console.log("❌ ÉCHEC : Quelque chose cloche.");
  }


  // --- TEST 2 : L'ÉCOLE PIRATE (Fausse école) ---
  console.log("\n--- 🧪 TEST 2 : Fausse École (Pirate) ---");
  
  // Le pirate crée un faux diplôme
  const hashFaux = ethers.id("Diplome_Harvard_Faux");
  // Le pirate signe avec SA clé (il n'a pas la clé de la Sorbonne)
  const signaturePirate = await ecolePirate.signMessage(ethers.getBytes(hashFaux));

  // VÉRIFICATION :
  const signatairePirate = ethers.verifyMessage(ethers.getBytes(hashFaux), signaturePirate);
  const infoPirate = await registry.getIssuer(signatairePirate);

  console.log(`🔎 Signataire trouvé : ${signatairePirate} (C'est le Pirate)`);
  
  if (infoPirate.status == 1) {
      console.log("❌ AÏE : Le pirate a réussi à passer !");
  } else {
      console.log("✅ SÉCURITÉ OK : Ce diplôme est rejeté car l'école n'est pas dans la liste.");
  }


  // --- TEST 3 : LE DIPLÔME MODIFIÉ (Triche étudiant) ---
  console.log("\n--- 🧪 TEST 3 : Diplôme Modifié (Triche) ---");
  
  // La Sorbonne a signé "Mention BIEN"
  const hashOriginal = ethers.id("Mention BIEN");
  const signatureOriginale = await ecoleValide.signMessage(ethers.getBytes(hashOriginal));

  // L'étudiant essaie de présenter le hash "Mention TRÈS BIEN" avec l'ancienne signature
  const hashTriche = ethers.id("Mention TRES BIEN");
  
  // VÉRIFICATION :
  const signataireBizarre = ethers.verifyMessage(ethers.getBytes(hashTriche), signatureOriginale);

  console.log(`🔎 L'adresse qui correspond mathématiquement est : ${signataireBizarre}`);
  
  if (signataireBizarre !== ecoleValide.address) {
      console.log("✅ SÉCURITÉ OK : La signature ne correspond plus au fichier. Fraude détectée !");
  }

  console.log("\n🎬 --- FIN DES TESTS --- 🎬");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});