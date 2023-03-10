// SPDX-License-Identifier: MIT

import "./access/AccessControl.sol";

pragma solidity ^0.8.0;

interface IEvent {
    function name() external view returns (bytes32);
}

contract TicketingSystem is AccessControl {
    struct IndexInfo {
        bool exists;
        uint256 index;
    }

    address[] eventList;
    mapping(bytes32 => address[]) eventCategory;
    mapping(address => IndexInfo) eventIndex;
    bytes32[] categoryList;
    mapping(bytes32 => IndexInfo) category;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor () {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function addEvent(address eventAddress) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(!eventIndex[eventAddress].exists, "Event already exists");
        require(eventAddress != address(0), "Invalid address");

        _addEventList(eventAddress);
    }

    function removeEvent(address eventAddress) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(eventList.length > 0, 'Empty list');
        require(!eventIndex[eventAddress].exists, 'Event does not exists');

        _removeEventList(eventAddress);
    }

    function addCategory(bytes32 categoryName) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(!category[categoryName].exists, "Category already exists");

        _addCategoryList(categoryName);
    }

    function removeCategory(bytes32 categoryName) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        require(categoryList.length > 0, 'Empty list');
        require(!category[categoryName].exists, 'Category does not exists');
        
        _removeCategoryList(categoryName);
    }

    function getEvents() external view returns (address[] memory) {
        return eventList;
    }

    function getEventsByCategory(bytes32 categoryName) external view returns (address[] memory) {
        require(category[categoryName].exists, "Category does not exists");

        return eventCategory[categoryName];
    }

    function getEventsByVenue(bytes32 venue) external view returns (address[] memory) {

    }

    function getEventInfo(address eventAddress) external view returns (bytes32, bytes32, bytes32,
        bytes32, string memory, bytes32, uint, uint, uint, uint, bytes32[] memory, uint) {
        
    }

    function _addEventList(address eventAddress) internal {
        eventList.push(eventAddress);

        eventIndex[eventAddress].exists = true;
        eventIndex[eventAddress].index = eventList.length - 1;
    }

    function _removeEventList(address eventAddress) internal {
        IndexInfo storage indexInfo = eventIndex[eventAddress];

        address lastItem = eventList[eventList.length - 1];
        eventList[indexInfo.index] = lastItem;
        eventIndex[lastItem].index = indexInfo.index;
        indexInfo.exists = false;
        eventList.pop();
    }

    function _addCategoryList(bytes32 categoryName) internal {
        categoryList.push(categoryName);

        category[categoryName].exists = true;
        category[categoryName].index = categoryList.length - 1;
    }

    function _removeCategoryList(bytes32 categoryName) internal {
        IndexInfo storage indexInfo = category[categoryName];

        bytes32 lastItem = categoryList[categoryList.length - 1];
        categoryList[indexInfo.index] = lastItem;
        category[lastItem].index = indexInfo.index;
        indexInfo.exists = false;
        categoryList.pop();
    }
}