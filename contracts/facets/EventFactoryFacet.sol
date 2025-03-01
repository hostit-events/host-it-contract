// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {EventERC721A} from "contracts/nfts/EventERC721A.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

import {IEventFactory} from "contracts/interfaces/IEventFactory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibDiamond} from "contracts/libraries/LibDiamond.sol";
import {LibEvent} from "contracts/libraries/LibEvent.sol";
import {Logs} from "contracts/libraries/constants/Logs.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import "contracts/libraries/constants/Types.sol";
import "contracts/libraries/constants/Tokens.sol";

/**
 * @title EventFactoryFacet
 * @dev Facet contract for creating and managing events with ERC721A-based tickets.
 * Handles event creation, ticket purchasing, attendee check-ins, and event data management.
 * Integrates with AccessControl for role-based permissions and uses ReentrancyGuard for security.
 */
contract EventFactoryFacet is IEventFactory, ReentrancyGuard {
    bytes32 private constant HOST_IT_EVENT = keccak256("HOST_IT_EVENT");

    /**
     * @notice Creates a new event with ERC721A-based tickets
     * @dev Initializes a new EventERC721A contract, grants organizer role, and stores event metadata
     * @param _name Event name for NFT tickets
     * @param _symbol Event symbol for NFT tickets
     * @param _uri Base URI for NFT metadata
     * @param _startTime Unix timestamp for event start
     * @param _endTime Unix timestamp for event end
     * @param _totalTickets Maximum number of tickets available
     * @param _freeEvent Whether the event requires payment
     * @param _payFeeIn Currency type for payments (if not free)
     * @param _fee Ticket price in specified currency (if not free)
     * @return Address of the created ERC721A ticket contract
     * @custom:error Event__AddressZeroOrganizer if organizer address is zero
     */
    function createEvent(
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalTickets,
        bool _freeEvent,
        PayFeeIn _payFeeIn,
        uint256 _fee
    ) external returns (address) {
        address organizer = msg.sender;
        if (organizer == address(0)) revert Errors.Event__AddressZeroOrganizer();

        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        uint256 eventId = es.eventCount + 1;
        bytes32 eventHash = keccak256(abi.encode(HOST_IT_EVENT, eventId));
        LibDiamond._grantRole(eventHash, organizer);

        EventERC721A eventNFT = new EventERC721A{salt: eventHash}();

        // only diamond can access the Event Ticket NFT contract
        eventNFT.initialize(address(this), _name, _symbol);
        eventNFT.setBaseURI(_uri);
        // eventNFT.mintMultipe(address(this), _totalTickets);

        EventData memory eventData = EventData({
            id: eventId,
            organizer: organizer,
            ticketAddress: address(eventNFT),
            freeEvent: _freeEvent,
            createdAt: block.timestamp,
            updatedAt: 0,
            startTime: _startTime,
            endTime: _endTime,
            totalTickets: _totalTickets
        });

        if (!_freeEvent) _setEventFee(eventId, _payFeeIn, _fee);

        es.eventById[eventId] = eventData;
        es.allEvents.push(eventData);

        emit Logs.EventCreated(eventId, eventData);

        return address(eventNFT);
    }

    /**
     * @notice Sets payment details for a non-free event
     * @dev Can only be called by event organizer
     * @param _eventId ID of the event to configure
     * @param _payFeeIn Currency type for payments
     * @param _fee Ticket price in specified currency
     * @custom:error AccessControlUnauthorizedAccount if caller lacks organizer role
     */
    function setEventFee(uint256 _eventId, PayFeeIn _payFeeIn, uint256 _fee) external {
        bytes32 eventHash = keccak256(abi.encode(HOST_IT_EVENT, _eventId));
        LibDiamond._checkRole(eventHash);

        _setEventFee(_eventId, _payFeeIn, _fee);
    }

    /**
     * @dev Internal function to store payment configuration
     * @param _eventId ID of the event to configure
     * @param _payFeeIn Currency type for payments
     * @param _fee Ticket price in specified currency
     */
    function _setEventFee(uint256 _eventId, PayFeeIn _payFeeIn, uint256 _fee) internal {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        if (es.eventById[_eventId].freeEvent) revert Errors.Event__FreeEventNoFee();

        es.payEventFeeIn[_eventId][_payFeeIn] = true;
        es.eventTicketPrice[_eventId][_payFeeIn] = _fee;

        emit Logs.EventFeeSet(_eventId, _payFeeIn, _fee);
    }

    /**
     * @notice Updates event metadata and configuration
     * @dev Can only be called by event organizer. Updates NFT contract metadata.
     * @param _eventId ID of the event to update
     * @param _name New event name for NFT tickets
     * @param _symbol New event symbol for NFT tickets
     * @param _uri New base URI for NFT metadata
     * @param _startTime New event start time
     * @param _endTime New event end time
     * @param _totalTickets New total ticket count
     * @return Address of the updated ERC721A ticket contract
     * @custom:error AccessControlUnauthorizedAccount if caller lacks organizer role
     */
    function updateEvent(
        uint256 _eventId,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalTickets,
        bool _freeEvent
    ) external nonReentrant returns (address) {
        bytes32 eventHash = keccak256(abi.encode(HOST_IT_EVENT, _eventId));
        LibDiamond._checkRole(eventHash);

        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        EventData memory eventData = es.eventById[_eventId];
        EventERC721A eventNFT = EventERC721A(eventData.ticketAddress);

        // only diamond can access the Event NFT contract
        eventNFT.setNameAndSymbol(_name, _symbol);
        eventNFT.setBaseURI(_uri);
        // eventNFT.mintMultipe(address(this), eventData.totalTickets);
        eventData.startTime = _startTime;
        eventData.endTime = _endTime;
        eventData.totalTickets = _totalTickets;
        eventData.freeEvent = _freeEvent;
        eventData.updatedAt = block.timestamp;

        emit Logs.EventUpdated(_eventId, eventData);

        return address(eventNFT);
    }

    /**
     * @notice Purchases a ticket for the specified event
     * @dev Handles both native ETH and ERC20 payments. Transfers ticket NFT to buyer.
     * @param eventId ID of the event to purchase from
     * @param _payFeeIn Currency type to use for payment
     * @custom:error Event__InvalidPaymentMethod if unsupported currency used
     * @custom:error Event__InsufficientFunds if payment amount is insufficient
     * @custom:error Event__PaymentTransferFailed if ERC20 transfer fails
     */
    function purchaseTicket(uint256 eventId, PayFeeIn _payFeeIn) external payable nonReentrant {
        address attendee = msg.sender;
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        if (!es.payEventFeeIn[eventId][_payFeeIn]) revert Errors.Event__InvalidPaymentMethod();

        if (_payFeeIn == PayFeeIn.USDT) {
            uint256 ticketPrice = es.eventTicketPrice[eventId][PayFeeIn.USDT];
            if (IERC20(USDT).balanceOf(msg.sender) < ticketPrice) revert Errors.Event__InsufficientFunds();
            if (!IERC20(USDT).transferFrom(msg.sender, address(this), ticketPrice)) revert Errors.Event__PaymentTransferFailed();
        } else if (_payFeeIn == PayFeeIn.USDCe) {
            uint256 ticketPrice = es.eventTicketPrice[eventId][PayFeeIn.USDCe];
            if (IERC20(USDCe).balanceOf(msg.sender) < ticketPrice) revert Errors.Event__InsufficientFunds();
            if (!IERC20(USDCe).transferFrom(msg.sender, address(this), ticketPrice)) revert Errors.Event__PaymentTransferFailed();
        } else if (_payFeeIn == PayFeeIn.LSK) {
            uint256 ticketPrice = es.eventTicketPrice[eventId][PayFeeIn.LSK];
            if (IERC20(LSK).balanceOf(msg.sender) < ticketPrice) revert Errors.Event__InsufficientFunds();
            if (!IERC20(LSK).transferFrom(msg.sender, address(this), ticketPrice)) revert Errors.Event__PaymentTransferFailed();
        } else {
            if (msg.value < es.eventTicketPrice[eventId][PayFeeIn.ETH]) revert Errors.Event__InsufficientFunds();
        }

        EventERC721A(es.eventById[eventId].ticketAddress).safeTransferFrom(address(this), attendee, 1);

        emit Logs.AttendeeRegistered(eventId, attendee);
    }

    /**
     * @notice Checks in an attendee for a specific event day
     * @dev Requires attendee to hold at least 1 ticket NFT
     * @param eventId ID of the event
     * @param attendee Address to check in
     * @param day Day number of the event (0-indexed)
     * @custom:error Event__NoTicketBalance if attendee has no tickets
     * @custom:error Event__AlreadyAttendedDay if attendee already checked in for this day
     */
    function checkInAttendee(uint256 eventId, address attendee, uint8 day) external {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        EventData memory eventData = es.eventById[eventId];

        if (EventERC721A(eventData.ticketAddress).balanceOf(attendee) < 1) revert Errors.Event__NoTicketBalance(eventId);

        if (es.attendancePerDay[eventId][day][attendee]) revert Errors.Event__AlreadyAttendedDay(eventId, day);
        es.attendancePerDay[eventId][day][attendee] = true;
        es.eventAttendeesByDay[eventId][day].push(attendee);

        if (!es.attendedAtLeastOnce[eventId][attendee]) {
            es.attendedAtLeastOnce[eventId][attendee] = true;
            es.eventAttendees[eventId].push(attendee);
        }

        emit Logs.AttendeeCheckedIn(eventId, attendee);
    }

    /**
     * @notice Retrieves event data by ID
     * @param eventId ID of the event to query
     * @return EventData struct containing all event details
     */
    function getEventById(uint256 eventId) external view returns (EventData memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.eventById[eventId];
    }

    /**
     * @notice Retrieves all created events
     * @return Array of EventData structs for all events
     */
    function getAllEvents() external view returns (EventData[] memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.allEvents;
    }

    /**
     * @notice Gets list of attendees for an event
     * @param eventId ID of the event to query
     * @return Array of attendee addresses
     */
    function getAttendees(uint256 eventId) external view returns (address[] memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.eventAttendees[eventId];
    }
}
