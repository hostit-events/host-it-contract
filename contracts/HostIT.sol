// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond, DiamondArgs} from "./libraries/LibDiamond.sol";
import {FacetCut} from "./interfaces/IDiamondCut.sol";

// When no function exists for function called
error Diamond_FunctionNotFound(bytes4 _functionSelector);

contract HostIT {
    constructor(address _contractAdmin, FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
        // Grant `_contractAdmin` address the diamond admin role a.k.a default admin role
        require(LibDiamond._grantRole(LibDiamond.DIAMOND_ADMIN_ROLE, _contractAdmin));

        // Add the diamondCut external function from the diamondCutFacet
        LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        if (facet == address(0)) {
            revert Diamond_FunctionNotFound(msg.sig);
        }
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
