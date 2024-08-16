// SPDX-License-Identifier: MIT
/// @author HostIT (David Dada, Manoah Luka, Olorunsogo Banwo, and Oluwakemi Atoyebi)
//
//                              :-------------------------------.                                               :=+
//                           .*+:                              .-*=                                        -=+*+-#@%.
//                          .*                                    -#-                               .-====-:    .@#%@+
//                          --               ::::                  *@@=                        :-+++-.          #%##%@+
//                          --              -@##%=                 *@%@.                 .:=**+-.      .-+#    -@###%@.
//                          --               %###%                 *@#@-            -====-.      :=+*#@%%@*   .@@###@=
//                          --               .%####                *%#@-           =#      .-+#@@%%#####%@.   *@###@%
//                          --                .####%:              *%#@-           %    =%@@%#######%%@%@-   .@%###@-
//                          --                  -*%#%*=:           *%#@-          *:   -@#####%%@%*+-: .#    *%###@%
//                          --    :*+++++++++++++++#####%#*++      *%#@-         -*   .@@###@*=.       #.   :@%##%@:
//                          --    -#########################%      *%#@-        .@.   %@###@=         :#    %@###@#
//                          --    :*++++++++++++++*%####*+++=      *%#@-        %:   -@###@#      .:==#:   +@###%@.
//                          --                  -#%%%*=.           *%#@-       ==   .@%##%@...-+++=:      :@@###@+
//                          --                .####%-              *%#@-       %    %@#%%@%++-.      -=*%@%@@%#%@
//                          --               .%###*                *%#@-     .%-   +%#*=:.    .:=*#%%%%#####%@@@+
//                          --               %###%                 *%#@-     *+          :=*#@%%###########%%@@%
//                          --              -@%#%=                 *%#@-    .#      :=*#@@%###########%%@##=-.
//                          --              ....:                  *%#@-    #-:=*#%%%%##########%@%%*=-.
//                          .#.                                   -@##@-   -@@%##########%%%@#*=:.
//                           .*+:                              .:#@###@:    :@%#####%%@@#+-.
//                              +@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%###%@+       +@@%*+-:
//                                +#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.
//
//                                                                                         ..:----..
//                                                     .-=+##*=.                      .=+++-:......--+++:
//                                                  -#*+-.    :%*:                 .=+-                 :=+-
//                                              .=*+-          .@@#-             :=-                       :=+.
//                                            -#*:             -@%%@%.         :*-        ...       ..        +*.
//                                          +%+                %@###@@        -*.       -%%%%.     +%#%*       :@*.
//                                       .+#-                 *@####@@       =+         *%###%:   +%###%:       .@@+
//                                      *#:                  =@%####@=      :+           =%###%. =###%#.         :@@#
//                                    =%-                   +@%####@%       #.            .*####=%##%=            *@@%
//                                  :#=.                   #@%####@@.       #       -+==----*%#####%=----==+.      @%@+
//                                 +%:                   -@@#####@@:       =*      :@#######################@      @%%@
//                               .#+                    *@%#####@%         :*       #@%###*+*#######++*###%%+      @##@:
//                              :@=                   =%%#####%@*           #              :#####%#%*.             @##@-
//                             :%.                  -@@######@%:            +-           .*%##%= ####%=            @%#@-
//                             @:                 -%@%#####%@*               #          :%####+   #####*           @%#@-
//                           .%=               .=%@%#####%@*:                :#:        *%##%+    .%###%:          @%#@-
//                           +@              :*@%%######@%:                    *-        :=+-       ++=.           @%#@-
//                           *=           .+%@%######%@%:                       -*:                                @%#@-
//                           -@:      :-*@@%#######%@*:                           -+=.                             @%#@-
//                            :#%#*%%@@%########%@#=                                .+%*-.                         @%#@-
//                              :#@%########%%@%+:                                    :+@@@%#*++++++++++++++++++++*@%#@-
//                                .*@@%%@@@#+-.                                          :=*%@@@%%%%%%%%%%%%%%%%%%%%@@@-
//                                   ....                                                      .:----------------------.
//
//
//                                             _      __        __    ____   __
//                                            | | /| / / ___   / /   |_  /  / /  ___ _  ___ _ ___   ___
//                                            | |/ |/ / / -_) / _ \ _/_ <  / /__/ _ `/ / _ `// _ \ (_-<
//                                            |__/|__/  \__/ /_.__//____/ /____/\_,_/  \_, / \___//___/
//                                                                                    /___/
//                                              _____              ___
//                                             / ___/ ___   ___   / _/ ___   ____ ___   ___  ____ ___
//                                            / /__  / _ \ / _ \ / _/ / -_) / __// -_) / _ \/ __// -_)
//                                            \___/  \___//_//_//_/   \__/ /_/   \__/ /_//_/\__/ \__/
//
//                                                               ____     ___
//                                                              |_  /    / _ \
//                                                             _/_ <  _ / // /
//                                                            /____/ (_)\___/
//
pragma solidity ^0.8.4;

import {ERC721AUpgradeable} from "./ERC721AUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";

contract W3LC2024Upgradeable is ERC721AUpgradeable, AccessControlUpgradeable {
    function initialize(address _admin) public initializerERC721A initializer {
        __ERC721A_init("Web3Lagos Conference 2024", "W3LC2024");
        __AccessControl_init();
        require(_grantRole(DEFAULT_ADMIN_ROLE, _admin));
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

    // =============================================================
    //                       W3LC2024 METADATA
    // =============================================================

    /**
     * @dev Sets the Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
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
    function mintSingle(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, 1);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function mintMultipe(address to, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, quantity);
    }

    /**
     * @dev Mints `1` token of thecurrent tokenId and transfers them to `to` of `tos`.
     * Ids for each mint is gotten from startTokenId
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event for each mint.
     */
    function batchMint(address[] calldata tos) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < tos.length; i++) {
            _mint(tos[i], 1);
        }
    }

    /**
     * @dev Transfers `tokenIds` from its current owner to `tos`.
     * Assuming `msg.sender` has all the current balance and balanceOf is equal to `tos.length`
     *
     * Emits a {Transfer} event.
     */
    function batchTransfer(address[] calldata tos) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < tos.length; i++) {
            transferFrom(_msgSenderERC721A(), tos[i], i + 1);
        }
    }

    /**
     * @dev Transfers specific `tokenIds` from its current owner to `tos`.
     * Assuming `msg.sender` has all the current balance and balanceOf is equal to `tos.length`
     *
     * Emits a {Transfer} event.
     */
    function batchTransferWithId(address[] calldata tos, uint256[] calldata tokenIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < tos.length; i++) {
            transferFrom(_msgSenderERC721A(), tos[i], tokenIds[i]);
        }
    }
}
