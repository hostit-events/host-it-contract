// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Types {
    struct EventData {
        address organizer;
        address eventNFT;
        uint8 duration; // in days 
        uint256 id;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 registrationStart;
        uint256 registrationEnd;
        uint256 startDate;
        uint256 endDate;
        uint256 attendeeLimit;
        uint256 registrationFee;
        PayFeeIn payFeeIn;
        // mapping(PayFeeIn => uint256) registrationFee3;
    }

    enum PayFeeIn {
        ETH,
        USDT
    }

    enum AttendanceDay {
        Null,
        Day1,
        Day2,
        Day3
    }

    // struct EventMetadata {
    //     bool isPaid;
    //     EventType eventType;
    //     uint256 startDate;
    //     uint256 endDate;
    //     string location;
    //     string image;
    // }
}

// TODO
// Event Name
// Event Description
// Event Image
// Event Location
// Event Start date
// Event End date
// Event type (virtual/ physical)
// Paid event?
// If (yes) {
//   Ticket types && prices && number of tickets;
//   Include POAP?
//     If (yes) {
//       Pay for POAP
//     }
// }
// Else{
//   Include Number of tickets;
//   If (yes) {
//       Pay for POAP
//     }
// }

// type Event = {
//     id: string;                     // Unique identifier for the event
//     title: string;                  // Title of the event
//     description: string;            // Brief description of the event
//     organizer: string;              // Name or ID of the organizer
//     date: Date;                     // Date and time of the event
//     location: string;               // Physical or virtual location URL
//     tags: string[];                 // Array of tags or keywords related to the event
//     attendeesLimit: number;         // Maximum number of attendees allowed
//     registrationFee: number;        // Registration fee for the event, if any (in tokens)
//     blockchainAddress: string;      // Wallet address to receive funds (if applicable)
//     createdAt: Date;                // Timestamp of when the event was created
//     updatedAt?: Date;               // Timestamp of the last update (optional)
//     status: 'upcoming' | 'past' | 'cancelled'; // Current status of the event
//     isOnline: boolean;              // Indicates if the event is online or in-person
//     RSVPList?: string[];            // List of wallet addresses or IDs of users who RSVP'd
//     metadata?: {                    // Optional metadata for additional info
//         imageUrl?: string;          // URL for event banner/image
//         contactEmail?: string;      // Contact email for queries
//         externalLinks?: string[];   // Array of links related to the event
//         socialMedia?: {             // Social media links (if any)
//             twitter?: string;
//             telegram?: string;
//             discord?: string;
//         }
//     };
// }
