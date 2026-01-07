// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DiplomaCertification {

    // --- CONFIGURATION ---
    uint public constant CONFIRMATIONS_REQUIRED = 2; // Il faut 2 votes pour valider une école

    // --- STRUCTURES ---
    struct SchoolProposal {
        string name;
        uint voteCount;
        bool executed;
        mapping(address => bool) hasVoted; // Qui a déjà voté ?
    }

    struct School {
        string name;
        bool isAuthorized;
    }

    struct Diploma {
        uint256 dateOfIssue;
        address issuer; // Quelle école a émis ce hash ?
        bool isValid;
    }

    // --- STOCKAGE ---
    address[] public admins;
    mapping(address => bool) public isAdmin;
    
    // GESTION ÉCOLES (Propositions et Validations)
    mapping(address => SchoolProposal) public proposals; 
    mapping(address => School) public schools;

    // GESTION DIPLÔMES (RGPD : Clé = HASH du diplôme)
    mapping(bytes32 => Diploma) public diplomas;

    // --- ÉVÉNEMENTS ---
    event ProposalCreated(address indexed school, string name, address indexed proposer);
    event Voted(address indexed school, address indexed voter, uint currentVotes);
    event SchoolAuthorized(address indexed school, string name);
    event SchoolRevoked(address indexed school);
    event DiplomaIssued(bytes32 indexed dataHash, address indexed issuer);

    // --- CONSTRUCTEUR ---
    // On définit la liste des admins dès le début
    constructor(address[] memory _admins) {
        require(_admins.length >= CONFIRMATIONS_REQUIRED, "Pas assez d'admins !");
        
        for (uint i = 0; i < _admins.length; i++) {
            address adminAddr = _admins[i];
            require(adminAddr != address(0), "Adresse invalide");
            require(!isAdmin[adminAddr], "Admin en double");

            isAdmin[adminAddr] = true;
            admins.push(adminAddr);
        }
    }

    // --- MODIFIERS ---
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Acces refuse : Vous n'etes pas Admin");
        _;
    }

    modifier onlyAuthorizedSchool() {
        require(schools[msg.sender].isAuthorized, "Ecole non autorisee");
        _;
    }

    // --- 1. GOUVERNANCE (MULTI-SIG) ---

    // Étape A : Un admin propose une école (ou vote pour elle si elle existe déjà)
    function voteForSchool(address _school, string memory _name) public onlyAdmin {
        SchoolProposal storage p = proposals[_school];

        // Si c'est la première fois qu'on en parle, on crée la proposition
        if (bytes(p.name).length == 0) {
            p.name = _name;
            emit ProposalCreated(_school, _name, msg.sender);
        }

        require(!p.executed, "Cette ecole est deja traitee");
        require(!p.hasVoted[msg.sender], "Vous avez deja vote pour cette ecole");

        // On enregistre le vote
        p.hasVoted[msg.sender] = true;
        p.voteCount += 1;

        emit Voted(_school, msg.sender, p.voteCount);

        // Si on atteint le seuil (2 votes), on valide l'école !
        if (p.voteCount >= CONFIRMATIONS_REQUIRED) {
            p.executed = true;
            schools[_school] = School(_name, true);
            emit SchoolAuthorized(_school, _name);
        }
    }

    // Fonction de sécurité pour révoquer d'urgence (1 seul admin suffit pour bloquer, par sécurité)
    function revokeSchool(address _school) public onlyAdmin {
        require(schools[_school].isAuthorized, "Ecole deja inactive");
        schools[_school].isAuthorized = false;
        // On reset la proposition pour forcer un re-vote si on veut la remettre
        delete proposals[_school]; 
        emit SchoolRevoked(_school);
    }

    // --- 2. ÉMISSION DIPLÔME (RGPD - HASH ONLY) ---

    // L'école envoie UNIQUEMENT le Hash (Calculé en JS : Nom + Diplôme + Secret)
    function issueDiploma(bytes32 _dataHash) public onlyAuthorizedSchool {
        require(diplomas[_dataHash].dateOfIssue == 0, "Ce diplome existe deja !");

        diplomas[_dataHash] = Diploma({
            dateOfIssue: block.timestamp,
            issuer: msg.sender,
            isValid: true
        });

        emit DiplomaIssued(_dataHash, msg.sender);
    }

    // --- 3. VÉRIFICATION ---

    function verifyDiploma(bytes32 _hashToVerify) public view returns (
        bool isValid,
        uint256 date,
        string memory schoolName,
        bool isSchoolActive
    ) {
        Diploma memory d = diplomas[_hashToVerify];
        
        // Si date == 0, le diplôme n'existe pas
        if (d.dateOfIssue == 0) {
            return (false, 0, "", false);
        }

        return (
            d.isValid,
            d.dateOfIssue,
            schools[d.issuer].name,
            schools[d.issuer].isAuthorized
        );
    }
}