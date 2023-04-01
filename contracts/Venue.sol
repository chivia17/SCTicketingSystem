// SPDX-License-Identifier: MIT

import "./access/AccessControl.sol";

pragma solidity ^0.8.0;

contract Venue is AccessControl {
    struct IndexInfo {
        bool exists;
        uint256 index;
    }

    struct VenueInfo {
        bytes32 name;
        string venueAddress;
        uint256 capacity;
        string phone;
        string description;
        string website;
        string email;
    }

    bytes32[] public venueList;
    mapping(bytes32 => IndexInfo) venue;
    mapping(bytes32 => VenueInfo) venueInfo;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor () {
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function addVenue(bytes32 name, string memory venueAddress, uint256 capacity, string memory phone,
        string memory description, string memory website, string memory email) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(!venue[name].exists, 'Venue already exists'); 

        venueInfo[name].name = name;
        venueInfo[name].venueAddress = venueAddress;
        venueInfo[name].capacity = capacity;
        venueInfo[name].phone = phone;
        venueInfo[name].description = description;
        venueInfo[name].website = website;
        venueInfo[name].email = email;

        _addVenueList(name);
    }

    function getVenue(bytes32 name) public view returns (bytes32, string memory,uint256, string memory,
        string memory, string memory, string memory) {
        require(!venue[name].exists, 'Venue does not exists'); 

        return (venueInfo[name].name,
            venueInfo[name].venueAddress,
            venueInfo[name].capacity,
            venueInfo[name].phone,
            venueInfo[name].description,
            venueInfo[name].website,
            venueInfo[name].email);
    }

    function venueExists(bytes32 name) public view returns (bool) {
        return venue[name].exists;
    }

    function getVenues() public view returns (bytes32[] memory) {
        return venueList;
    }

    function removeVenue(bytes32 name) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(venueList.length > 0, 'Empty list');
        require(!venue[name].exists, 'Venue does not exists');

        _removeVenueList(name);
    }

    function _addVenueList(bytes32 name) internal {
        venueList.push(name);

        venue[name].exists = true;
        venue[name].index = venueList.length - 1;
    }

    function _removeVenueList(bytes32 name) internal {
        IndexInfo storage indexInfo = venue[name];

        bytes32 lastItem = venueList[venueList.length - 1];
        venueList[indexInfo.index] = lastItem;
        venue[lastItem].index = indexInfo.index;
        indexInfo.exists = false;
        venueList.pop();
    }
}