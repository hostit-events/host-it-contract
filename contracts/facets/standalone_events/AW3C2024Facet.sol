// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "contracts/libraries/LibDiamond.sol";
import {LibApp} from "contracts/libraries/LibApp.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {Logs} from "contracts/libraries/constants/Logs.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {AW3C2024} from "contracts/nfts/AW3C2024.sol";

contract AW3C2024Facet {
    /**
     * @dev Sets the address for AW32024 NFT ticket to `_aw3c2024nft`.
     *
     * Requirements:
     *
     * - msg.sender must have the role `AW3C_ADMIN_ROLE`.
     */
    function setAW3C2024NFT(address _aw3c2024nft) external {
        LibDiamond._checkRole(LibDiamond.AW3C_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.AW3C2024NFT = _aw3c2024nft;
    }

    /**
     * @dev Marks the attendance of an `attendee` for the `day` to true.
     *
     * Also stores the `attendee` in an attendees array for the `day`
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `AW3C_ADMIN_ROLE`.
     * - `day` must be active.
     * - `attendee` must not be registered already for that `day`.
     * - `attendee` must have a AW3C2024 NFT ticket.
     *
     * Emits an {AttendedAW3C2024} event.
     */
    function aw3c2024__markAttendance(address attendee, LibApp.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.AW3C_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.aw3c2024_attended[attendee] == true) revert Errors.AW3C2024__AlreadyAttended(uint8(day));

        if (IERC721AUpgradeable(s.AW3C2024NFT).balanceOf(attendee) == 0) AW3C2024(s.AW3C2024NFT).mintSingle(attendee);

        s.aw3c2024_attendees.push(attendee);

        s.aw3c2024_attended[attendee] = true;

        emit Logs.AttendedAW3C2024(attendee, day, block.timestamp);
    }

    /**
     * @dev Returns if the attendance of an `attendee` for the `day` is true.
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `AW3C_ADMIN_ROLE`.
     */
    function aw3c2024__verifyAttendance(address attendee, LibApp.AttendanceDay day) public view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.aw3c2024_attended[attendee];
    }

    /**
     * @dev Returns array of marked `attendee`s for the `day`.
     *
     */
    function aw3c2024__returnAttendance() external view returns (address[] memory) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.aw3c2024_attendees;
    }
}
