// SPDX-License-Identifier: MIT

import "./access/AccessControl.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./utils/Address.sol";
import "./utils/Strings.sol";

pragma solidity ^0.8.0;

contract Ticket is AccessControl, IERC721 {
    using Address for address;
    using Strings for uint256;

    struct TicketInfo {
        bytes32 section;
        uint16 row;
        uint16 seat;
        uint256 buyDate;
        string receipt;
    }

    bytes32 private _name;
    bytes32 private _eventKey;
    bytes32 private _imageUrl;

    // Mapping from ticket ID to owner address
    mapping(bytes32 => address) private _owners;
    // Mapping from ticket ID to Ticket info
    mapping(bytes32 => TicketInfo) private ticketInfo;
    // Mapping owner address to ticket count
    mapping(address => uint256) private _balances;
    // Mapping from ticket ID to approved address
    mapping(bytes32 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(bytes32 name_, bytes32 eventKey_, bytes32 imageUrl_) {
        _name = name_;
        _eventKey = eventKey_;
        _imageUrl = imageUrl_;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(bytes32 ticketId) public view override returns (address) {
        address owner = _ownerOf(ticketId);
        require(owner != address(0), "Invalid ticket ID");
        return owner;
    }

    function name() public view returns (bytes32) {
        return _name;
    }

    function eventKey() public view returns (bytes32) {
        return _eventKey;
    }

    function imageUrl() public view returns (bytes32) {
        return _imageUrl;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, bytes32 ticketId)
        public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), ticketId), "Caller is not token owner or approved");

        _transfer(from, to, ticketId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, bytes32 ticketId) 
        public override {
        safeTransferFrom(from, to, ticketId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, bytes32 ticketId, bytes memory data) 
        public override {
        require(_isApprovedOrOwner(_msgSender(), ticketId), "Caller is not token owner or approved");
        _safeTransfer(from, to, ticketId, data);
    }

    function approve(address to, bytes32 ticketId) public override {
        address owner = Ticket.ownerOf(ticketId);
        require(to != owner, "Approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Approve caller is not token owner or approved for all"
        );

        _approve(to, ticketId);
    }

    function setApprovalForAll(address operator, bool _approved) public override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function getApproved(bytes32 ticketId) public view override returns (address operator) {
        _requireMinted(ticketId);

        return _tokenApprovals[ticketId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Safely transfers `ticketId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `ticketId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, bytes32 ticketId, bytes memory data) 
        internal {
        _transfer(from, to, ticketId);
        require(_checkOnERC721Received(from, to, ticketId, data), "Transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `ticketId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(bytes32 ticketId) internal view returns (address) {
        return _owners[ticketId];
    }

    /**
     * @dev Returns whether `ticketId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(bytes32 ticketId) internal view returns (bool) {
        return _ownerOf(ticketId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `ticketId`.
     *
     * Requirements:
     *
     * - `ticketId` must exist.
     */
    function _isApprovedOrOwner(address spender, bytes32 ticketId) 
        internal view returns (bool) {
        address owner = Ticket.ownerOf(ticketId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(ticketId) == spender);
    }

    /**
     * @dev Safely mints `ticketId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `ticketId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to,
        bytes32 ticketId,
        bytes32 section,
        uint16 row,
        uint16 seat,
        uint256 buyDate,
        string memory receipt) internal {
        _safeMint(to, ticketId, "");
        ticketInfo[ticketId].section = section;
        ticketInfo[ticketId].row = row;
        ticketInfo[ticketId].seat = seat;
        ticketInfo[ticketId].buyDate = buyDate;
        ticketInfo[ticketId].receipt = receipt;
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, bytes32 ticketId, bytes memory data)
        internal {
        _mint(to, ticketId);
        require(
            _checkOnERC721Received(address(0), to, ticketId, data),
            "Transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `ticketId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `ticketId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, bytes32 ticketId) internal {
        require(to != address(0), "Mint to the zero address");
        require(!_exists(ticketId), "Token already minted");

        _beforeTokenTransfer(address(0), to, ticketId, 1);

        // Check that ticketId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(ticketId), "Token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[ticketId] = to;

        emit Transfer(address(0), to, ticketId);

        _afterTokenTransfer(address(0), to, ticketId, 1);
    }

    /**
     * @dev Destroys `ticketId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `ticketId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(bytes32 ticketId) internal {
        address owner = Ticket.ownerOf(ticketId);

        _beforeTokenTransfer(owner, address(0), ticketId, 1);

        // Update ownership in case ticketId was transferred by `_beforeTokenTransfer` hook
        owner = Ticket.ownerOf(ticketId);

        // Clear approvals
        delete _tokenApprovals[ticketId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[ticketId];

        emit Transfer(owner, address(0), ticketId);

        _afterTokenTransfer(owner, address(0), ticketId, 1);
    }

    /**
     * @dev Transfers `ticketId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `ticketId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        bytes32 ticketId
    ) internal {
        require(
            Ticket.ownerOf(ticketId) == from,
            "Transfer from incorrect owner"
        );
        require(to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(from, to, ticketId, 1);

        // Check that ticketId was not transferred by `_beforeTokenTransfer` hook
        require(
            Ticket.ownerOf(ticketId) == from,
            "Transfer from incorrect owner"
        );

        // Clear approvals from the previous owner
        delete _tokenApprovals[ticketId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[ticketId] = to;

        emit Transfer(from, to, ticketId);

        _afterTokenTransfer(from, to, ticketId, 1);
    }

    /**
     * @dev Approve `to` to operate on `ticketId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, bytes32 ticketId) internal {
        _tokenApprovals[ticketId] = to;
        emit Approval(Ticket.ownerOf(ticketId), to, ticketId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "Approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `ticketId` has not been minted yet.
     */
    function _requireMinted(bytes32 ticketId) internal view {
        require(_exists(ticketId), "Invalid ticket ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param ticketId ticket ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, bytes32 ticketId, bytes memory data) 
        private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    ticketId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "Transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, bytes32,/* firstticketId */ uint256 batchSize)
        internal {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        bytes32 firstTicketId,
        uint256 batchSize
    ) internal {}

    function _getBuyDate(bytes32 ticketId_) internal view returns (uint256) {
        return ticketInfo[ticketId_].buyDate;
    }
}