// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {DiamondInit} from "../../contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {AccessControlFacet} from "../../contracts/facets/AccessControlFacet.sol";
import {W3LC2024Facet} from "../../contracts/facets/W3LC2024Facet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "../../contracts/interfaces/IDiamondCut.sol";
import {IDiamondInit} from "../../contracts/interfaces/IDiamondInit.sol";
import {IDiamondLoupe} from "../../contracts/interfaces/IDiamondLoupe.sol";
import {IAccessControl} from "../../contracts/interfaces/IAccessControl.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import {IERC165} from "../../contracts/interfaces/IERC165.sol";

import {LibDiamond, DiamondArgs} from "../../contracts/libraries/LibDiamond.sol";

import {HostIT} from "../../contracts/HostIT.sol";
import {W3LC2024} from "contracts/w3lc2024/W3LC2024.sol";

contract DeployHostIT is Script {
    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    AccessControlFacet accessControlFacet;
    W3LC2024Facet w3lc2024Facet;
    HostIT diamond;

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant w3lcNFT = 0xFE907A3Eb44782A5f96AAf345ed48877bCC080e7;
    // roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant DIAMOND_ADMIN_ROLE = keccak256("DIAMOND_ADMIN_ROLE");
    bytes32 constant W3LC3_ADMIN_ROLE = keccak256("W3LC3_ADMIN_ROLE");

    
    function setSetW3LC2024NFT() internal {
        // Set W3LC2024 NFT
        W3LC2024Facet(address(diamond)).setW3LC2024NFT(w3lcNFT);
    }

    function grantDiamondAdminRole() internal {
        // Grant diamond W3LC2024 NFT admin role
        W3LC2024(w3lcNFT).grantRole(DEFAULT_ADMIN_ROLE, address(diamond));
    }

    function grantBackendAdminRole() internal {
        // Grant backend W3LC2024 NFT admin role
        IAccessControl(address(w3lcNFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer W3LC2024 NFT admin role
        IAccessControl(address(w3lcNFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend W3LC2024 Facet admin role
        IAccessControl(address(diamond)).grantRole(W3LC3_ADMIN_ROLE, backendAddr);

        // Grant deployer W3LC2024 Facet admin role
        IAccessControl(address(diamond)).grantRole(W3LC3_ADMIN_ROLE, msg.sender);
    }

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

        // Start by deploying the DiamonInit contract.
        diamondInit = new DiamondInit();
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        accessControlFacet = new AccessControlFacet();
        w3lc2024Facet = new W3LC2024Facet();

        FacetCut[] memory initCut = new FacetCut[](4);

        // Get function selectors for facets for `cuts` array.
        bytes4[] memory initCutSelectors = new bytes4[](1);
        initCutSelectors[0] = IDiamondCut.diamondCut.selector;

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

        bytes4[] memory addW3lc2024Selectors = new bytes4[](7);
        addW3lc2024Selectors[0] = W3LC2024Facet.setW3LC2024NFT.selector;
        addW3lc2024Selectors[1] = W3LC2024Facet.w3lc2024__setDayActive.selector;
        addW3lc2024Selectors[2] = W3LC2024Facet.w3lc2024__setDayInactive.selector;
        addW3lc2024Selectors[3] = W3LC2024Facet.w3lc2024__markAttendance.selector;
        addW3lc2024Selectors[4] = W3LC2024Facet.w3lc2024__verifyAttendance.selector;
        addW3lc2024Selectors[5] = W3LC2024Facet.w3lc2024__returnAttendance.selector;
        addW3lc2024Selectors[6] = W3LC2024Facet.w3lc2024__isDayActive.selector;

        // Populate the `cuts` array with the needed data.
        initCut[0] = FacetCut({facetAddress: address(diamondCutFacet), action: FacetCutAction.Add, functionSelectors: initCutSelectors});

        initCut[1] = FacetCut({facetAddress: address(diamondLoupeFacet), action: FacetCutAction.Add, functionSelectors: loupeSelectors});

        initCut[2] = FacetCut({facetAddress: address(accessControlFacet), action: FacetCutAction.Add, functionSelectors: accessControlSelectors});

        initCut[3] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Add, functionSelectors: addW3lc2024Selectors});

        // Build the DiamondArgs.
        DiamondArgs memory initDiamondArgs = DiamondArgs({
            init: address(diamondInit),
            // NOTE: "interfaceId" can be used since "init" is the only function in IDiamondInit.
            initCalldata: abi.encode(type(IDiamondInit).interfaceId)
        });

        // Deploy the diamond.
        console.log("Message sender", msg.sender);
        diamond = new HostIT(msg.sender, initCut, initDiamondArgs);
        console.log("HostIT address: ", address(diamond));
        console.log("DiamondInit address: ", address(diamondInit));

        grantDiamondAdminRole();

        grantBackendAdminRole();

        setSetW3LC2024NFT();

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

contract ReplaceW3LC2024Facet is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // uint256 hostItAddress = vm.envUint("HOST_IT_ADDRESS");
        vm.startBroadcast(privateKey);

        W3LC2024Facet w3lc2024Facet = new W3LC2024Facet();

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory replaceW3lc2024Selectors = new bytes4[](1);
        replaceW3lc2024Selectors[0] = W3LC2024Facet.w3lc2024__markAttendance.selector;

        cuts[0] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Replace, functionSelectors: replaceW3lc2024Selectors});

        IDiamondCut(address(0x734328C180Ef236a6CB7737132Fe2B6a96201592)).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();
    }
}

contract Replace2W3LC2024Facet is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // uint256 hostItAddress = vm.envUint("HOST_IT_ADDRESS");
        vm.startBroadcast(privateKey);

        W3LC2024Facet w3lc2024Facet = new W3LC2024Facet();

        FacetCut[] memory cuts = new FacetCut[](3);

        bytes4[] memory removeW3lc2024Selectors = new bytes4[](6);
        removeW3lc2024Selectors[0] = 0x059fa3e5;
        removeW3lc2024Selectors[1] = 0xb7af5e31;
        removeW3lc2024Selectors[2] = 0xce715db4;
        removeW3lc2024Selectors[3] = 0xf5f03e46;
        removeW3lc2024Selectors[4] = 0x3d3a0188;
        removeW3lc2024Selectors[5] = 0x6f1537fb;

        bytes4[] memory remove2W3lc2024Selectors = new bytes4[](1);
        remove2W3lc2024Selectors[0] = W3LC2024Facet.w3lc2024__markAttendance.selector;

        bytes4[] memory addW3lc2024Selectors = new bytes4[](7);
        addW3lc2024Selectors[0] = W3LC2024Facet.setW3LC2024NFT.selector;
        addW3lc2024Selectors[1] = W3LC2024Facet.w3lc2024__setDayActive.selector;
        addW3lc2024Selectors[2] = W3LC2024Facet.w3lc2024__setDayInactive.selector;
        addW3lc2024Selectors[3] = W3LC2024Facet.w3lc2024__markAttendance.selector;
        addW3lc2024Selectors[4] = W3LC2024Facet.w3lc2024__verifyAttendance.selector;
        addW3lc2024Selectors[5] = W3LC2024Facet.w3lc2024__returnAttendance.selector;
        addW3lc2024Selectors[6] = W3LC2024Facet.w3lc2024__isDayActive.selector;

        cuts[0] = FacetCut({facetAddress: address(0), action: FacetCutAction.Remove, functionSelectors: removeW3lc2024Selectors});
        cuts[1] = FacetCut({facetAddress: address(0), action: FacetCutAction.Remove, functionSelectors: remove2W3lc2024Selectors});
        cuts[2] = FacetCut({facetAddress: address(w3lc2024Facet), action: FacetCutAction.Add, functionSelectors: addW3lc2024Selectors});

        IDiamondCut(address(0x734328C180Ef236a6CB7737132Fe2B6a96201592)).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();
    }
}

contract SetW3LC2024 is Script {
    function run() external {
        uint256 privateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        HostIT diamond;

        vm.stopBroadcast();
    }
}
