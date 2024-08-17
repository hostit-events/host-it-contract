// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "lib/forge-std/src/Script.sol";

import {DiamondInit} from "../../contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {AccessControlFacet} from "../../contracts/facets/AccessControlFacet.sol";
import {W3LC2024Facet} from "../../contracts/facets/W3LC2024Facet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "../../contracts/interfaces/IDiamondCut.sol";
import {IDiamondInit} from "../../contracts/interfaces/IDiamondInit.sol";
import {IDiamondLoupe} from "../../contracts/interfaces/IDiamondLoupe.sol";
import {IAccessControl} from "../../contracts/interfaces/IAccessControl.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {IERC165} from "../../contracts/interfaces/IERC165.sol";

import {LibDiamond, DiamondArgs} from "../../contracts/libraries/LibDiamond.sol";

import {HostIT} from "../../contracts/HostIT.sol";
import {W3LC2024Upgradeable} from "../../contracts/w3lc2024/W3LC2024Upgradeable.sol";

contract DeployHostIT is Script {
    function run() external {
        uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // Start by deploying the DiamonInit contract.
        DiamondInit diamondInit = new DiamondInit();
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupeFacet = new DiamondLoupeFacet();
        AccessControlFacet accessControlFacet = new AccessControlFacet();
        W3LC2024Facet w3lc2024Facet = new W3LC2024Facet();

        FacetCut[] memory initCut = new FacetCut[](1);

        bytes4[] memory initCutSelectors = new bytes4[](1);
        initCutSelectors[0] = IDiamondCut.diamondCut.selector;

        initCut[0] = FacetCut({facetAddress: address(diamondCutFacet), action: FacetCutAction.Add, functionSelectors: initCutSelectors});

        // Build the DiamondArgs.
        DiamondArgs memory initDiamondArgs = DiamondArgs({
            init: address(diamondInit),
            // NOTE: "interfaceId" can be used since "init" is the only function in IDiamondInit.
            initCalldata: abi.encode(type(IDiamondInit).interfaceId)
        });

        // Deploy the diamond.
        console.log("Message sender", msg.sender);
        HostIT diamond = new HostIT(msg.sender, initCut, initDiamondArgs);
        console.log("Diamond address: ", address(diamond));
        console.log("DiamondInit address: ", address(diamondInit));

        // Create the `cuts` array. (Already cut DiamondCut during diamond deployment)
        FacetCut[] memory cuts = new FacetCut[](3);

        // Get function selectors for facets for `cuts` array.
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = IERC165.supportsInterface.selector;

        bytes4[] memory accessControlSelectors = new bytes4[](6);
        accessControlSelectors[0] = IAccessControl.hasRole.selector;
        accessControlSelectors[1] = IAccessControl.getRoleAdmin.selector;
        accessControlSelectors[2] = IAccessControl.grantRole.selector;
        accessControlSelectors[3] = IAccessControl.revokeRole.selector;
        accessControlSelectors[4] = IAccessControl.renounceRole.selector;
        accessControlSelectors[5] = AccessControlFacet.setRoleAdmin.selector;

        bytes4[] memory w3lc2024Selectors = new bytes4[](2);
        // w3lc2024Selectors[0] = W3LC2024Facet.setW3LC32024NFT.selector;
        w3lc2024Selectors[1] = W3LC2024Facet.w3lc2024__verifyAttendance.selector;

        // Populate the `cuts` array with the needed data.
        cuts[0] = FacetCut({facetAddress: address(diamondLoupeFacet), action: FacetCutAction.Add, functionSelectors: loupeSelectors});

        cuts[1] = FacetCut({facetAddress: address(accessControlFacet), action: FacetCutAction.Add, functionSelectors: accessControlSelectors});

        cuts[2] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Add, functionSelectors: w3lc2024Selectors});

        // Upgrade our diamond with the remaining facets by making the cuts. Must be owner!
        IDiamondCut(address(diamond)).diamondCut(cuts, address(diamondInit), abi.encodeWithSignature("init()"));

        // console.log("Diamond cuts complete. Owner of Diamond:", IAccessControl(address(diamond)).getRoleAdmin(LibDiamond.DIAMOND_ADMIN_ROLE));

        vm.stopBroadcast();
    }
}



contract UpdateW3LC2024Facet is Script {
    function run() external {
        
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // uint256 hostItAddress = vm.envUint("HOST_IT_ADDRESS");
        vm.startBroadcast(privateKey);

        W3LC2024Facet w3lc2024Facet = new W3LC2024Facet();

        FacetCut[] memory cuts = new FacetCut[](2);

        bytes4[] memory removeW3lc2024Selectors = new bytes4[](2);
        removeW3lc2024Selectors[0] = 0xe76592f7; // W3LC2024Facet.w3lc2024__verifyAttendance.selector
        removeW3lc2024Selectors[1] = 0xcd695221; // W3LC2024Facet.setW3LC32024NFT.selector;

        bytes4[] memory addW3lc2024Selectors = new bytes4[](7);
        addW3lc2024Selectors[0] = W3LC2024Facet.setW3LC2024NFT.selector;
        addW3lc2024Selectors[1] = W3LC2024Facet.w3lc2024__setDayActive.selector;
        addW3lc2024Selectors[2] = W3LC2024Facet.w3lc2024__setDayInactive.selector;
        addW3lc2024Selectors[3] = W3LC2024Facet.w3lc2024__markAttendance.selector;
        addW3lc2024Selectors[4] = W3LC2024Facet.w3lc2024__verifyAttendance.selector;
        addW3lc2024Selectors[5] = W3LC2024Facet.w3lc2024__returnAttendance.selector;
        addW3lc2024Selectors[6] = W3LC2024Facet.w3lc2024__isDayActive.selector;

        cuts[0] = FacetCut({facetAddress: address(0), action: FacetCutAction.Remove, functionSelectors: removeW3lc2024Selectors});
        cuts[1] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Add, functionSelectors: addW3lc2024Selectors});

        IDiamondCut(address(0x734328C180Ef236a6CB7737132Fe2B6a96201592)).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();
    }
}

contract SetW3LC2024 is Script{
    function run() external {
        uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        HostIT diamond;

        vm.stopBroadcast();
    }
}
