// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IssuerRegistry {
    enum Status { NONE, ACTIVE, REVOKED }

    struct Issuer {
        string name;
        Status status;
        uint256 registeredAt;
    }

    mapping(address => Issuer) private issuers;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Admin seulement");
        _;
    }

    function addIssuer(address _issuerAddress, string calldata _name) external onlyOwner {
        require(issuers[_issuerAddress].status == Status.NONE, "Deja existant");
        issuers[_issuerAddress] = Issuer(_name, Status.ACTIVE, block.timestamp);
    }

    function revokeIssuer(address _issuerAddress) external onlyOwner {
        require(issuers[_issuerAddress].status != Status.NONE, "Inconnu");
        issuers[_issuerAddress].status = Status.REVOKED;
    }

    function getIssuer(address _issuerAddress) external view returns (string memory name, Status status, uint256 date) {
        return (issuers[_issuerAddress].name, issuers[_issuerAddress].status, issuers[_issuerAddress].registeredAt);
    }

    function isValidIssuer(address _issuerAddress) external view returns (bool) {
        return issuers[_issuerAddress].status == Status.ACTIVE;
    }
}