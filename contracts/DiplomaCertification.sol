// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DiplomaCertification {

    uint public constant CONFIRMATIONS_REQUIRED = 2;

    struct SchoolProposal {
        string name;
        uint voteCount;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    struct School {
        string name;
        bool isAuthorized;
    }

    struct Diploma {
        uint256 dateOfIssue;
        address issuer;
        bool isValid;
    }

    struct TempAccess {
        bytes32 diplomaHash;
        uint256 expirationTime;
        bool isValid;
    }

    address[] public admins;
    mapping(address => bool) public isAdmin;
    
    mapping(address => SchoolProposal) public proposals; 
    mapping(address => School) public schools;
    mapping(bytes32 => Diploma) public diplomas;
    mapping(bytes32 => TempAccess) public accessTokens;

    event SchoolAuthorized(address indexed school, string name);
    event SchoolRevoked(address indexed school);
    event DiplomaIssued(bytes32 indexed dataHash, address indexed issuer);
    event AccessGranted(bytes32 indexed tempToken, uint256 expiration);

    constructor(address[] memory _admins) {
        require(_admins.length >= CONFIRMATIONS_REQUIRED, "Pas assez d'admins");
        for (uint i = 0; i < _admins.length; i++) {
            isAdmin[_admins[i]] = true;
            admins.push(_admins[i]);
        }
    }

    modifier onlyAdmin() { require(isAdmin[msg.sender], "Admin only"); _; }
    modifier onlyAuthorizedSchool() { require(schools[msg.sender].isAuthorized, "Ecole non autorisee"); _; }

    function voteForSchool(address _school, string memory _name) public onlyAdmin {
        SchoolProposal storage p = proposals[_school];
        if (bytes(p.name).length == 0) p.name = _name;
        require(!p.executed, "Deja traitee");
        require(!p.hasVoted[msg.sender], "Deja vote");

        p.hasVoted[msg.sender] = true;
        p.voteCount += 1;

        if (p.voteCount >= CONFIRMATIONS_REQUIRED) {
            p.executed = true;
            schools[_school] = School(_name, true);
            emit SchoolAuthorized(_school, _name);
        }
    }

    function revokeSchool(address _school) public onlyAdmin {
        schools[_school].isAuthorized = false;
        delete proposals[_school];
        emit SchoolRevoked(_school);
    }

    function issueDiploma(bytes32 _dataHash) public onlyAuthorizedSchool {
        require(diplomas[_dataHash].dateOfIssue == 0, "Diplome deja existant");
        diplomas[_dataHash] = Diploma({
            dateOfIssue: block.timestamp,
            issuer: msg.sender,
            isValid: true
        });
        emit DiplomaIssued(_dataHash, msg.sender);
    }

    function createTempAccess(bytes32 _diplomaHash, uint256 _durationSeconds) public returns (bytes32) {
        require(diplomas[_diplomaHash].dateOfIssue > 0, "Diplome inconnu");
        
        bytes32 tempToken = keccak256(abi.encodePacked(msg.sender, _diplomaHash, block.timestamp));
        
        accessTokens[tempToken] = TempAccess({
            diplomaHash: _diplomaHash,
            expirationTime: block.timestamp + _durationSeconds,
            isValid: true
        });

        emit AccessGranted(tempToken, block.timestamp + _durationSeconds);
        return tempToken;
    }

    function verifyWithToken(bytes32 _tempToken) public view returns (bool, string memory, uint256, bool) {
        TempAccess memory access = accessTokens[_tempToken];
        
        if (!access.isValid || block.timestamp > access.expirationTime) {
            return (false, "Token expire ou invalide", 0, false);
        }

        Diploma memory d = diplomas[access.diplomaHash];
        bool isSchoolActive = schools[d.issuer].isAuthorized;

        return (true, schools[d.issuer].name, d.dateOfIssue, isSchoolActive);
    }
}