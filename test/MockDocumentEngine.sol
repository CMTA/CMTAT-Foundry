//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.20;

import "CMTAT/interfaces/tokenization/draft-IERC1643.sol";

contract MockDocumentEngine is IERC1643 {
    mapping(string => Document) internal documents;
    string[] internal names;
    mapping(string => bool) internal exists;

    function setDocument(string memory name, string memory uri, bytes32 documentHash, uint256 lastModified) external {
        if (!exists[name]) {
            names.push(name);
            exists[name] = true;
        }
        documents[name] = Document({uri: uri, documentHash: documentHash, lastModified: lastModified});
    }

    function getDocument(string memory name) external view returns (Document memory document) {
        return documents[name];
    }

    function getAllDocuments() external view returns (string[] memory documentNames_) {
        return names;
    }
}
