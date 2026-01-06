// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DiplomaCertification {

    // --- STRUCTURES DE DONNÉES ---

    struct School {
        string name;
        bool isAuthorized; // Si TRUE = l'école peut émettre. Si FALSE = elle est bloquée.
        bool exists;       // Pour vérifier si l'école est enregistrée
    }

    struct Diploma {
        string studentName;
        string degreeLabel; // Ex: "Master 2 Informatique"
        uint256 dateOfIssue;
        address issuer;     // L'adresse de l'école qui a émis le diplôme
        bool isValid;       // Si le diplôme est révoqué (triche), passe à FALSE
    }

    // --- STOCKAGE (Base de données) ---

    address public admin; // Le Ministère / L'autorité suprême
    
    // Liste des écoles (Adresse wallet => Infos École)
    mapping(address => School) public schools;

    // Liste des diplômes (Code Unique ID => Infos Diplôme)
    mapping(bytes32 => Diploma) public diplomas;

    // --- ÉVÉNEMENTS (Pour les logs) ---
    event SchoolStatusChanged(address indexed schoolAddress, bool isAuthorized);
    event DiplomaIssued(bytes32 indexed diplomaId, address indexed school, string student);
    event DiplomaRevoked(bytes32 indexed diplomaId, string reason);

    // --- CONSTRUCTEUR ---
    constructor() {
        admin = msg.sender; // Celui qui déploie le contrat devient l'Admin
    }

    // --- MODIFIERS (Sécurité) ---
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Seul l'Admin peut faire ca");
        _;
    }

    modifier onlyAuthorizedSchool() {
        require(schools[msg.sender].isAuthorized == true, "Ecole non autorisee ou revoquee");
        _;
    }

    // --- FONCTIONS ADMIN (Gouvernement) ---

    // 1. Ajouter ou Réactiver une école
    function addSchool(address _schoolAddress, string memory _name) public onlyAdmin {
        schools[_schoolAddress] = School(_name, true, true);
        emit SchoolStatusChanged(_schoolAddress, true);
    }

    // 2. Désactiver une école (Elle ne pourra plus émettre, mais ses anciens diplômes restent)
    function deactivateSchool(address _schoolAddress) public onlyAdmin {
        require(schools[_schoolAddress].exists, "L'ecole n'existe pas");
        schools[_schoolAddress].isAuthorized = false; 
        // On ne supprime PAS l'école, on change juste son statut.
        emit SchoolStatusChanged(_schoolAddress, false);
    }

    // --- FONCTIONS ÉCOLE ---

    // 3. Créer un diplôme
    // C'est ici que le CODE est généré pour l'étudiant
    function issueDiploma(string memory _studentName, string memory _degreeLabel) public onlyAuthorizedSchool returns (bytes32) {
        
        // Création d'un ID unique (Hash) basé sur les infos + le temps actuel
        bytes32 diplomaId = keccak256(abi.encodePacked(msg.sender, _studentName, _degreeLabel, block.timestamp));

        diplomas[diplomaId] = Diploma({
            studentName: _studentName,
            degreeLabel: _degreeLabel,
            dateOfIssue: block.timestamp,
            issuer: msg.sender,
            isValid: true
        });

        emit DiplomaIssued(diplomaId, msg.sender, _studentName);
        
        return diplomaId; // C'est ce CODE que l'école donne à l'étudiant
    }

    // 4. Révoquer un diplôme spécifique (ex: triche)
    function revokeDiploma(bytes32 _diplomaId) public {
        Diploma storage d = diplomas[_diplomaId];
        
        // Seule l'école qui a émis le diplôme peut le révoquer
        require(d.issuer == msg.sender, "Ce n'est pas votre diplome");
        
        d.isValid = false;
        emit DiplomaRevoked(_diplomaId, "Diplome revoque par l'ecole");
    }

    // --- FONCTION PUBLIQUE (Vérification) ---

    // 5. Vérifier un diplôme avec son CODE
    function verifyDiploma(bytes32 _diplomaId) public view returns (
        string memory student, 
        string memory degree, 
        uint256 date, 
        string memory schoolName, 
        bool isDiplomaValid, 
        bool isSchoolStillAuthorized
    ) {
        Diploma memory d = diplomas[_diplomaId];
        require(d.issuer != address(0), "Diplome introuvable");

        return (
            d.studentName,
            d.degreeLabel,
            d.dateOfIssue,
            schools[d.issuer].name, // On récupère le nom de l'école
            d.isValid,              // Le diplôme est-il valide ?
            schools[d.issuer].isAuthorized // L'école existe-t-elle encore aujourd'hui ?
        );
    }
}