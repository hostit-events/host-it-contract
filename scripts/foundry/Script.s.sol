// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {DiamondInit} from "../../contracts/upgradeInitializers/DiamondInit.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {AccessControlFacet} from "../../contracts/facets/AccessControlFacet.sol";
import {W3LC2024Facet} from "../../contracts/facets/W3LC2024Facet.sol";
import {AW3C2024Facet} from "../../contracts/facets/AW3C2024Facet.sol";
import {BDRLS2024Facet} from "../../contracts/facets/BDRLS2024Facet.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "../../contracts/interfaces/IDiamondCut.sol";
import {IDiamondInit} from "../../contracts/interfaces/IDiamondInit.sol";
import {IDiamondLoupe} from "../../contracts/interfaces/IDiamondLoupe.sol";
import {IAccessControl} from "../../contracts/interfaces/IAccessControl.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

import {IERC165} from "../../contracts/interfaces/IERC165.sol";

import {LibDiamond, DiamondArgs} from "../../contracts/libraries/LibDiamond.sol";

import {HostIT} from "../../contracts/HostIT.sol";
import {W3LC2024} from "contracts/nfts/W3LC2024.sol";
import {AW3C2024} from "contracts/nfts/AW3C2024.sol";
import {BDRLS2024} from "contracts/nfts/BDRLS2024.sol";

contract DeployHostIT is Script {
    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    AccessControlFacet accessControlFacet;
    W3LC2024Facet w3lc2024Facet;
    HostIT diamond;

    AW3C2024Facet aw3c2024Facet;
    AW3C2024 aw3c2024NFT;

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant w3lcNFT = 0x8f0F53c9b6aCC81c9b0020Ac3E15E6E306Beb295;
    // roles
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant DIAMOND_ADMIN_ROLE = keccak256("DIAMOND_ADMIN_ROLE");
    bytes32 constant W3LC3_ADMIN_ROLE = keccak256("W3LC3_ADMIN_ROLE");
    bytes32 constant AW3C_ADMIN_ROLE = keccak256("AW3C_ADMIN_ROLE");

    
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

    function setSetAW3C2024NFT(address d_diamond) internal {
        // Set AW3C2024 NFT
        AW3C2024Facet(address(d_diamond)).setAW3C2024NFT(w3lcNFT);
    }

    function grantDiamondAW3CAdminRole() internal {
        // Grant diamond AW3C2024 NFT admin role
        AW3C2024(aw3c2024NFT).grantRole(DEFAULT_ADMIN_ROLE, address(diamond));
    }

    function grantBackendAW3CAdminRole(address d_diamond) internal {
        // Grant backend AW3C2024 NFT admin role
        IAccessControl(address(aw3c2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 NFT admin role
        IAccessControl(address(aw3c2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(AW3C_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(AW3C_ADMIN_ROLE, msg.sender);
    }
    
    function addAW3CFacet() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address hostItAddress = vm.envAddress("HOST_IT_ADDRESS");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

        aw3c2024NFT = new AW3C2024();
        aw3c2024Facet = new AW3C2024Facet();

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory addAw3c2024Selectors = new bytes4[](4);
        addAw3c2024Selectors[0] = AW3C2024Facet.setAW3C2024NFT.selector;
        addAw3c2024Selectors[1] = AW3C2024Facet.aw3c2024__markAttendance.selector;
        addAw3c2024Selectors[2] = AW3C2024Facet.aw3c2024__verifyAttendance.selector;
        addAw3c2024Selectors[3] = AW3C2024Facet.aw3c2024__returnAttendance.selector;

        cuts[0] = FacetCut({facetAddress: address(aw3c2024Facet), action: FacetCutAction.Add, functionSelectors: addAw3c2024Selectors});

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

        grantDiamondAW3CAdminRole();

        grantBackendAW3CAdminRole(hostItAddress);

        setSetAW3C2024NFT(hostItAddress);

        vm.stopBroadcast();
    }
}

contract UpdateW3LC2024Facet is Script {
    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address hostItAddress = vm.envAddress("HOST_IT_ADDRESS");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

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

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

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

contract AddAW3CFacet is Script {
    AW3C2024Facet aw3c2024Facet;
    AW3C2024 aw3c2024NFT;

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant AW3C_ADMIN_ROLE = keccak256("AW3C_ADMIN_ROLE");

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant hostItAddress = 0xe639110D69ec5b5C4ECa926271fa2f82Ee94A2D3;

    function setSetAW3C2024NFT(address d_diamond) internal {
        // Set AW3C2024 NFT
        AW3C2024Facet(address(d_diamond)).setAW3C2024NFT(address(aw3c2024NFT));
    }

    function grantDiamondAW3CAdminRole(address d_diamond) internal {
        // Grant diamond AW3C2024 NFT admin role
        AW3C2024(aw3c2024NFT).grantRole(DEFAULT_ADMIN_ROLE, address(d_diamond));
    }

    function grantBackendAW3CAdminRole(address d_diamond) internal {
        // Grant backend AW3C2024 NFT admin role
        IAccessControl(address(aw3c2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 NFT admin role
        IAccessControl(address(aw3c2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(AW3C_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(AW3C_ADMIN_ROLE, msg.sender);
    }

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

        aw3c2024Facet = new AW3C2024Facet();
        aw3c2024NFT = new AW3C2024();
        // 0x6CFEc75C163d2c37ef1ee26005D7c018c42844DD Mainnet: 0x95486422705a7F8F6cD35aBc1c4CE5c11e150AdD

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory addW3lc2024Selectors = new bytes4[](4);
        addW3lc2024Selectors[0] = AW3C2024Facet.setAW3C2024NFT.selector;
        addW3lc2024Selectors[1] = AW3C2024Facet.aw3c2024__markAttendance.selector;
        addW3lc2024Selectors[2] = AW3C2024Facet.aw3c2024__verifyAttendance.selector;
        addW3lc2024Selectors[3] = AW3C2024Facet.aw3c2024__returnAttendance.selector;

        cuts[0] = FacetCut({facetAddress: address(aw3c2024Facet), action: FacetCutAction.Add, functionSelectors: addW3lc2024Selectors});

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

        AW3C2024(aw3c2024NFT).initialize(msg.sender);

        AW3C2024(aw3c2024NFT).setBaseURI("ipfs://QmS8XSfzc5ajyVwrxBgnyBHKw1349ixRGoDPNpXFvspNJV");

        grantDiamondAW3CAdminRole(hostItAddress);

        grantBackendAW3CAdminRole(hostItAddress);

        setSetAW3C2024NFT(hostItAddress);

        vm.stopBroadcast();
    }
}

contract AddBDRLSFacet is Script {
    BDRLS2024Facet bdrls2024Facet;
    BDRLS2024 bdrls2024NFT;

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant BDRLS_ADMIN_ROLE = keccak256("BDRLS_ADMIN_ROLE");

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant hostItAddress = 0xe639110D69ec5b5C4ECa926271fa2f82Ee94A2D3;

    function setSetAW3C2024NFT(address d_diamond) internal {
        // Set BDRLS2024 NFT
        BDRLS2024Facet(address(d_diamond)).setBDRLS2024NFT(address(bdrls2024NFT));
    }

    function grantDiamondAW3CAdminRole(address d_diamond) internal {
        // Grant diamond BDRLS2024 NFT admin role
        BDRLS2024(bdrls2024NFT).grantRole(DEFAULT_ADMIN_ROLE, address(d_diamond));
    }

    function grantBackendAW3CAdminRole(address d_diamond) internal {
        // Grant backend AW3C2024 NFT admin role
        IAccessControl(address(bdrls2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 NFT admin role
        IAccessControl(address(bdrls2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(BDRLS_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(BDRLS_ADMIN_ROLE, msg.sender);
    }

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

        bdrls2024Facet = new BDRLS2024Facet();
        bdrls2024NFT = new BDRLS2024();
        // 0xBC8bD8fc78C6FF84cd80359E04Df13e5eA0f89d1 Mainnet: 0x18eBFCa1075285708F911818655d22C21572D433

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory addBdrls2024Selectors = new bytes4[](7);
        addBdrls2024Selectors[0] = BDRLS2024Facet.setBDRLS2024NFT.selector;
        addBdrls2024Selectors[1] = BDRLS2024Facet.bdrls2024__setDayActive.selector;
        addBdrls2024Selectors[2] = BDRLS2024Facet.bdrls2024__setDayInactive.selector;
        addBdrls2024Selectors[3] = BDRLS2024Facet.bdrls2024__markAttendance.selector;
        addBdrls2024Selectors[4] = BDRLS2024Facet.bdrls2024__verifyAttendance.selector;
        addBdrls2024Selectors[5] = BDRLS2024Facet.bdrls2024__returnAttendance.selector;
        addBdrls2024Selectors[6] = BDRLS2024Facet.bdrls2024__isDayActive.selector;

        cuts[0] = FacetCut({facetAddress: address(bdrls2024Facet), action: FacetCutAction.Add, functionSelectors: addBdrls2024Selectors});

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

        BDRLS2024(bdrls2024NFT).initialize(msg.sender);

        BDRLS2024(bdrls2024NFT).setBaseURI("ipfs://QmZm5ZFrYCaLsqjccShtPjq4DuEyvmm6qgu2W9NFs9giw1");

        grantDiamondAW3CAdminRole(hostItAddress);

        grantBackendAW3CAdminRole(hostItAddress);

        setSetAW3C2024NFT(hostItAddress);

        vm.stopBroadcast();
    }
}

contract RemoveW3LC2024Facet is Script {
    BDRLS2024Facet bdrls2024Facet;
    BDRLS2024 bdrls2024NFT;

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant BDRLS_ADMIN_ROLE = keccak256("BDRLS_ADMIN_ROLE");

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant hostItAddress = 0xfa8c40CF7EAC88A9da6D002C44C284BE844B020c;

    function setSetAW3C2024NFT(address d_diamond) internal {
        // Set BDRLS2024 NFT
        BDRLS2024Facet(address(d_diamond)).setBDRLS2024NFT(address(bdrls2024NFT));
    }

    function grantDiamondAW3CAdminRole(address d_diamond) internal {
        // Grant diamond BDRLS2024 NFT admin role
        BDRLS2024(bdrls2024NFT).grantRole(DEFAULT_ADMIN_ROLE, address(d_diamond));
    }

    function grantBackendAW3CAdminRole(address d_diamond) internal {
        // Grant backend AW3C2024 NFT admin role
        IAccessControl(address(bdrls2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 NFT admin role
        IAccessControl(address(bdrls2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(BDRLS_ADMIN_ROLE, backendAddr);

        // Grant deployer AW3C2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(BDRLS_ADMIN_ROLE, msg.sender);
    }

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

        bdrls2024Facet = new BDRLS2024Facet();
        bdrls2024NFT = new BDRLS2024();
        // 0xBC8bD8fc78C6FF84cd80359E04Df13e5eA0f89d1

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory addBdrls2024Selectors = new bytes4[](7);
        addBdrls2024Selectors[0] = BDRLS2024Facet.setBDRLS2024NFT.selector;
        addBdrls2024Selectors[1] = BDRLS2024Facet.bdrls2024__setDayActive.selector;
        addBdrls2024Selectors[2] = BDRLS2024Facet.bdrls2024__setDayInactive.selector;
        addBdrls2024Selectors[3] = BDRLS2024Facet.bdrls2024__markAttendance.selector;
        addBdrls2024Selectors[4] = BDRLS2024Facet.bdrls2024__verifyAttendance.selector;
        addBdrls2024Selectors[5] = BDRLS2024Facet.bdrls2024__returnAttendance.selector;
        addBdrls2024Selectors[6] = BDRLS2024Facet.bdrls2024__isDayActive.selector;

        cuts[0] = FacetCut({facetAddress: address(bdrls2024Facet), action: FacetCutAction.Add, functionSelectors: addBdrls2024Selectors});

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

        BDRLS2024(bdrls2024NFT).initialize(msg.sender);

        grantDiamondAW3CAdminRole(hostItAddress);

        grantBackendAW3CAdminRole(hostItAddress);

        setSetAW3C2024NFT(hostItAddress);

        vm.stopBroadcast();
    }
}
