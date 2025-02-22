// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {AccessControlFacet} from "contracts/facets/AccessControlFacet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "contracts/interfaces/IDiamondCut.sol";

import {HostIT} from "contracts/HostIT.sol";

contract ReplaceAccessControlFacet is Script {
    AccessControlFacet accessControlFacet;

    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function run(address hostItAddress) external broadcast {
        accessControlFacet = new AccessControlFacet();

        FacetCut[] memory cut = new FacetCut[](1);

        bytes4[] memory accessControlSelectors = new bytes4[](6);
        accessControlSelectors[0] = AccessControlFacet.getRoleAdmin.selector;
        accessControlSelectors[1] = AccessControlFacet.grantRole.selector;
        accessControlSelectors[2] = AccessControlFacet.hasRole.selector;
        accessControlSelectors[3] = AccessControlFacet.renounceRole.selector;
        accessControlSelectors[4] = AccessControlFacet.revokeRole.selector;
        accessControlSelectors[5] = AccessControlFacet.setRoleAdmin.selector;

        cut[0] = FacetCut({facetAddress: address(accessControlFacet), action: FacetCutAction.Replace, functionSelectors: accessControlSelectors});

        IDiamondCut(hostItAddress).diamondCut(cut, address(0), "");
    }
}
