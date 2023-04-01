// SPDX-License-Identifier: MIT

import "./Ticket.sol";

pragma solidity ^0.8.0;

contract Event is Ticket {
    struct IndexInfo {
        bool exists;
        uint256 index;
    }

    struct SectionInfo {
        bytes32 name;
        uint24 capacity;
        uint24 remaining;
        uint8 status;
    }

    struct Section {
        bytes32 name;
        uint24 capacity;
        uint256 price;
        uint8 status;
        mapping (bytes32 => IndexInfo) rowSection;
        bytes32[] rowSectionList;
        mapping(bytes32 => SectionInfo) rowSectionInfo;
    }

    bytes32 private _venue;
    string private _description;
    bytes32 private _category;
    uint256 private _date;
    uint256 private _startTime;
    uint256 private _endTime;
    address private _owner;
    uint8 private _minAge;
    mapping (bytes32 => IndexInfo) private _section;
    bytes32[] private _sectionList;
    mapping (bytes32 => Section) private _sectionInfo;
    uint8 private _status;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROMOTER_ROLE = keccak256("PROMOTER_ROLE");


    constructor(bytes32 name_, bytes32 eventKey_, bytes32 imageUrl_, bytes32 venue_, string memory description_,
        bytes32 category_, uint256 date_, uint256 startTime_, uint256 endTime_, uint8 minAge_, address admin_) 
        Ticket(name_, eventKey_, imageUrl_) {
        _venue = venue_;
        _description = description_;
        _category = category_;
        _date = date_;
        _startTime = startTime_;
        _endTime = endTime_;
        _owner = _msgSender();
        _minAge = minAge_;
        _status = 1;
        _setupRole(ADMIN_ROLE, admin_);
        _setupRole(PROMOTER_ROLE, _msgSender());
    }

    function venue() public view returns (bytes32) {
        return _venue;
    }

    function description() public view returns (string memory) {
        return _description;
    }

    function category() public view returns (bytes32) {
        return _category;
    }

    function date() public view returns (uint256) {
        return _date;
    }

    function startTime() public view returns (uint256) {
        return _startTime;
    }

    function endtime() public view returns (uint256) {
        return _endTime;
    }

    function minAge() public view returns (uint8) {
        return _minAge;
    }

    function addSection(bytes32 name_, uint24 capacity_, uint256 price_, uint8 status_) external {
        require(hasRole(PROMOTER_ROLE, msg.sender), "Caller is not promoter");
        require(!_section[name_].exists, 'Section already exists');

        _addSectionInfo(name_, capacity_, price_, status_);
    }

    function addSections(bytes32[] calldata name_, uint24[] calldata capacity_, uint256[] calldata price_, uint8 status_) 
        external {
        require(hasRole(PROMOTER_ROLE, msg.sender), "Caller is not promoter");

        uint arrayLen = name_.length;

        for (uint24 i = 0; i < arrayLen; ++i) {
            _addSectionInfo(name_[i], capacity_[i], price_[i], status_);
        }
    }

    function addRowSection(bytes32 sectionName_, bytes32 name_, uint24 capacity_, uint8 status_) 
        external {
        require(hasRole(PROMOTER_ROLE, msg.sender), "Caller is not promoter");
        require(_section[sectionName_].exists, 'Section does not exists');
        require(!_sectionInfo[sectionName_].rowSection[name_].exists, 'Row already exists');

        _addRowSectionInfo(sectionName_, name_, capacity_, status_);
    }

    function addRowsSection(bytes32 sectionName_, bytes32[] calldata name_, uint24[] calldata capacity_, uint8 status_) external {
        require(hasRole(PROMOTER_ROLE, msg.sender), "Caller is not promoter");
        require(_section[sectionName_].exists, 'Section does not exists');

        uint arrayLen = name_.length;

        for (uint24 i = 0; i < arrayLen; ++i) {
            _addRowSectionInfo(sectionName_, name_[i], capacity_[i], status_);
        }
    }

    function buyTicket(bytes32 ticketId,
        bytes32 section,
        uint16 row,
        uint16 seat,
        uint256 buyDate) external payable {
        address buyer = msg.sender;
        uint256 payedPrice = msg.value;
        
        require(_validatePrice(section, payedPrice), "Payment not enough");

        _safeMint(buyer, ticketId, section, row, seat, buyDate, "");
    }

    function buyTicketWithFiat(address to,
        bytes32 ticketId,
        bytes32 section,
        uint16 row,
        uint16 seat,
        uint256 buyDate,
        string memory transaction) external {
        require(hasRole(ADMIN_ROLE, msg.sender) || hasRole(PROMOTER_ROLE, msg.sender), "Caller is not admin or promoter");
        _safeMint(to, ticketId, section, row, seat, buyDate, transaction);
    }

    function refundTicket(bytes32 tokenId) external {

    }

    function withdrawFunds(address payable receiver) external onlyRole(PROMOTER_ROLE) {
        uint256 amount = address(this).balance;

        receiver.transfer(amount);
    }

    function validateTicket(bytes32 ticketId_) external view returns (uint8) {
        uint256 buyDate_= _getBuyDate(ticketId_);

         if(buyDate_ == 0) {
            return 0;
         } else if(buyDate_ > 0 && msg.sender != ownerOf(ticketId_)) {
            return 2;
         } else {
            return 1;
         }
    }

    function _addSectionInfo(bytes32 name_, uint24 capacity_, uint256 price_, uint8 status_) internal {
        _sectionInfo[name_].name = name_;
        _sectionInfo[name_].capacity = capacity_;
        _sectionInfo[name_].price = price_;
        _sectionInfo[name_].status = status_;

        _addSectionList(name_);
    }

    function _addSectionList(bytes32 name_) internal {
        _sectionList.push(name_);

        _section[name_].exists = true;
        _section[name_].index = _sectionList.length - 1;
    }

    function _addRowSectionInfo(bytes32 sectionName_, bytes32 name_, uint24 capacity_, uint8 status_) internal {
        _sectionInfo[sectionName_].rowSectionInfo[name_].name = name_;
        _sectionInfo[sectionName_].rowSectionInfo[name_].capacity = capacity_;
        _sectionInfo[sectionName_].rowSectionInfo[name_].remaining = capacity_;
        _sectionInfo[sectionName_].rowSectionInfo[name_].status = status_;

        _addRowSectionList(sectionName_, name_);
    }

    function _addRowSectionList(bytes32 sectionName_, bytes32 name_) internal {
        _sectionInfo[sectionName_].rowSectionList.push(name_);

        _sectionInfo[sectionName_].rowSection[name_].exists = true;
        _sectionInfo[sectionName_].rowSection[name_].index = _sectionInfo[sectionName_].rowSectionList.length;
    }

    function _validatePrice(bytes32 sectionName_, uint256 price_) internal view returns (bool) {
        return _sectionInfo[sectionName_].price >= price_;
    }
}
