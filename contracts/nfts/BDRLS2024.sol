// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721AUpgradeable} from "./ERC721AUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";

/**
 * @title BDRLS2024
 * @author HostIT (David Dada, Manoah Luka, Olorunsogo Banwo, and Oluwakemi Atoyebi)
 *
 * NFT Contract to mint B<>der/ess 3.0 tickets to attendees
 */
contract BDRLS2024 is ERC721AUpgradeable, AccessControlUpgradeable {
    // =============================================================
    //                       INITIALIZER LOGIC
    // =============================================================

    function initialize(address _admin) public initializerERC721A initializer {
        __ERC721A_init("B<>der/ess 3.0", "BRDLS2024");
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // =============================================================
    //                       BDRLS2024 METADATA
    // =============================================================

    /**
     * @dev Sets the Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function setBaseURI(string memory uri) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _setBaseURI(uri);
    }

    // =============================================================
    //                         MINT FUNCTIONS
    // =============================================================

    /**
     * @dev Mints `1` token of the current tokenId and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mintSingle(address to) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _mint(to, 1);
    }

    /**
     * @dev Mints `1` token of the current tokenId and transfers them to `to` of `tos`.
     * Ids for each mint is gotten from startTokenId
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event for each mint.
     */
    function batchMint(address[] calldata tos) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        uint256 tosLength = tos.length;
        for (uint256 i; i < tosLength; ) {
            _mint(tos[i], 1);
            unchecked {++i;}
        }
    }

    /**
     * @dev Transfers `tokenIds` from its current owner to `tos`.
     * Assuming `msg.sender` has the total and balanceOf is equal to `tos.length`
     *
     * Emits a {Transfer} event.
     */
    function batchTransfer(address[] calldata tos) external {
        _checkRole(DEFAULT_ADMIN_ROLE);
        uint256 tosLength = tos.length;
        for (uint256 i; i < tosLength; ) {
            transferFrom(_msgSenderERC721A(), tos[i], i);
            unchecked {++i;}
        }
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, AccessControlUpgradeable) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IAccessControl).interfaceId || // ERC165 interface ID for AccessControl.
            super.supportsInterface(interfaceId);
    }
}

// t>6cXt+Y=JccMMiM~'i:tJcNXi'.'~''~:::::::::::::~:~~~~~~~~~~~~~~~~~~~~'~''
// +>+>+>i+: '+MM5+      'YDc:.~~~~~::::;;:;;::::~:::::~~~~'.          .'~~
// iiiiiiii+~.>KMMH+':!+=JD6=''~~~~:::::::::::::::~:~:~~'.                '
// ccci===i=; .iMMMMMMMMMMQc: ~;!:::::::::::::::;:::::~'   '>=+;!>++>!:
// ijcii==++>~ ~jMMMMMMMNSi~ .;!;:::;;;;:;;;;:;;;;;::~'  '>j5YYY565YYYJj+~
// cjjci===++!~ .;+icccc+~   ~;;:;;;;!!!!!;!;!!;;;:::'. ~=Y66665Y5665YY55j;
// cJttii=+>>>>;~.         '::;;!!!;;!!!!!!;;;;;;;;:~. '+Y665Yt>  :=J55666c
// cJJttcc=>>!!!;;:~''~::;;;;;:;;;;!;!!!!!!!!;;!;;;:~. :i5S556t!   '=Y566St
// =jYYJJti=+!!;;::;!!>!!;;::;;;;;:;;;;;;;;;;;;;;;;:~  :=5S55Yj>  .+t55SSt;
// =jY6S6Ytci>;;;::::~~~~:::;:::::::;;!:;;;;:;;;;;;::'  !tXS666Jtt5SDDSJ+
// +itSNQSYji+>;;;;;;::::::::~::;;;;;;;!!;!;!;;;;!;;;:'  :=JSDKQKKQQ5j!.
// !+=jDMQtji>;;;;:::;:::::~:~~::::::;;;;;;;;!!!;;!;:::'    .:!++>;~     .~
// !;;;=MMMNti+>!;;;:;;::~:~~~~~~~::::::::;;;;;!!!!;;!;;::'            ':::
// >;;~':iMMMM5j=>;:::::::::~~~~~~~:~~:::::::;;;;;;;;;;;:;:::~;!!>>>;;:::::
// +!;:~.  ~MMMM6Jc=>;;:;;:::::::::::~~~::::::::;;;:;::;:::::::::~:::::::::
// c+!;:~~  ;MMMMMSi+;;:;;;;;;;:::::::::::::;;;:::::;;;::;;::::::::::::::::
// Yc+!;::~   iMMMMMMMc!:;;!!;;!;;;;;:;:::::::::;;;;::;::;:;:::::::::::::::
// QJc+!::~''   >MMMMMMMKYc++==+>!!;;;;;;;;::::::::;;;:;;:;;:::::::::::::::
// MM6j=!::~''.     '=tXNHSYJJYt==+!!;!;:::::::::::::;:;;;;:;::::::::::::::
// MMMXc=!:~~''''          ':!+===>+>!!;::::::~::::~::::::::::::::::;::::~:
// MMMMMt>::~~~~''.    .~:'    ':;;!!;;!!;;;::::~~~~~~~~~~:~::::::::~~:::::
// MMMMMMJ!:::~~~''.   .~;!>>:.    :;:::~:;;;;;;;:::::~~''''''~~~~~~:~~::::
// MMMMMMMc::~~''''..     .':!!;'''                            '''''~~~~~::
// MMMMMMMM>~~::~~''...         .::;!!!;:.                    .'''~~:~::;;;
// MMMMMMMMM:~~~~~~''''....                              ...''''~~::::;::;:
// MMMMMMMMMN~~~~'''''''''....  .               . .    ..'''''~~::::;:::;::
// MMMMMMMMMMX'~::~~~~'~~~~'''''''..........'''''.....'~~~:::;;;;;;;;;:;;;;
// MMMMMMMMMMMN!;::~~~'''~~~~''~~~~~'''''''''''..'''~~::;;;;;:;;;;;:;;;:;;;
/////////////////////////////THANKS FOR COMING/////////////////////////////
