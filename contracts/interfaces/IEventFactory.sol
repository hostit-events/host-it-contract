// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import "contracts/libraries/constants/Types.sol";

interface IEventFactory {
    function createEvent(
        string calldata name,
        string calldata symbol,
        string calldata uri,
        uint256 startDate,
        uint256 endDate,
        uint256 totalTickets,
        bool freeEvent,
        PayFeeIn payFeeIn,
        uint256 fee
    ) external returns (address);

    function purchaseTicket(uint256 eventId, PayFeeIn _payFeeIn) external payable;

    // function checkInAttendee(uint256 eventId, address attendee, uint8 day) external;

    function getEventById(uint256 eventId) external view returns (EventData memory);

    function getAllEvents() external view returns (EventData[] memory);

    function getAttendees(uint256 eventId) external view returns (address[] memory);
}
