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

contract EventFactoryFacet is IEventFactory, ReentrancyGuard {
    bytes32 private constant HOST_IT_EVENT = keccak256("HOST_IT_EVENT");

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

    function setEventFee(uint256 _eventId, PayFeeIn _payFeeIn, uint256 _fee) external {
        bytes32 eventHash = keccak256(abi.encode(HOST_IT_EVENT, _eventId));
        LibDiamond._checkRole(eventHash);

        _setEventFee(_eventId, _payFeeIn, _fee);
    }

    function _setEventFee(uint256 _eventId, PayFeeIn _payFeeIn, uint256 _fee) internal {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        es.payEventFeeIn[_eventId][_payFeeIn] = true;
        es.eventTicketPrice[_eventId][_payFeeIn] = _fee;
    }

    function updateEvent(
        uint256 _eventId,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _totalTickets
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
        eventData.updatedAt = block.timestamp;

        emit Logs.EventUpdated(_eventId, eventData);

        return address(eventNFT);
    }

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

    function getEventById(uint256 eventId) external view returns (EventData memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.eventById[eventId];
    }

    function getAllEvents() external view returns (EventData[] memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.allEvents;
    }

    function getAttendees(uint256 eventId) external view returns (address[] memory) {
        LibEvent.EventStorage storage es = LibEvent.eventStorage();

        return es.eventAttendees[eventId];
    }
}
