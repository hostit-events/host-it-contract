// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {IDiamondCut, FacetCut, FacetCutAction} from "contracts/interfaces/IDiamondCut.sol";
import {IAccessControl} from "contracts/interfaces/IAccessControl.sol";

import {ITC2024Facet} from "contracts/facets/past_events/ITC2024Facet.sol";
import {ITC2024} from "contracts/nfts/ITC2024.sol";

contract AddITCFacet is Script {
    ITC2024Facet itc2024Facet;
    ITC2024 itc2024NFT;

    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 constant ITC_ADMIN_ROLE = keccak256("ITC_ADMIN_ROLE");

    address constant backendAddr = 0xc408235a9A01767d70B41C98d92F2dC7B0d959f4;
    address constant hostItAddress = 0xe639110D69ec5b5C4ECa926271fa2f82Ee94A2D3;//0xfa8c40CF7EAC88A9da6D002C44C284BE844B020c;

    function setITC2024NFT(address d_diamond) internal {
        // Set ITC2024 NFT
        ITC2024Facet(address(d_diamond)).setITC2024NFT(address(itc2024NFT));
    }

    function grantDiamondITCAdminRole(address d_diamond) internal {
        // Grant diamond ITC2024 NFT admin role
        ITC2024(itc2024NFT).grantRole(DEFAULT_ADMIN_ROLE, address(d_diamond));
    }

    function grantBackendITCAdminRole(address d_diamond) internal {
        // Grant backend ITC2024 NFT admin role
        IAccessControl(address(itc2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, backendAddr);

        // Grant deployer ITC2024 NFT admin role
        IAccessControl(address(itc2024NFT)).grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant backend ITC2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(ITC_ADMIN_ROLE, backendAddr);

        // Grant deployer ITC2024 Facet admin role
        IAccessControl(address(d_diamond)).grantRole(ITC_ADMIN_ROLE, msg.sender);
    }

    function run() external {
        // uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // vm.startBroadcast(privateKey);
        vm.startBroadcast();

        itc2024Facet = new ITC2024Facet();
        itc2024NFT = new ITC2024();
        // 0x6CFEc75C163d2c37ef1ee26005D7c018c42844DD Mainnet: 0x95486422705a7F8F6cD35aBc1c4CE5c11e150AdD

        FacetCut[] memory cuts = new FacetCut[](1);

        bytes4[] memory addITC2024Selectors = new bytes4[](4);
        addITC2024Selectors[0] = ITC2024Facet.setITC2024NFT.selector;
        addITC2024Selectors[1] = ITC2024Facet.itc2024__markAttendance.selector;
        addITC2024Selectors[2] = ITC2024Facet.itc2024__verifyAttendance.selector;
        addITC2024Selectors[3] = ITC2024Facet.itc2024__returnAttendance.selector;

        cuts[0] = FacetCut({facetAddress: address(itc2024Facet), action: FacetCutAction.Add, functionSelectors: addITC2024Selectors});

        IDiamondCut(hostItAddress).diamondCut(cuts, address(0), "");

        ITC2024(itc2024NFT).initialize(msg.sender);

        ITC2024(itc2024NFT).setBaseURI("ipfs://QmSzgWzExrs4qfW7Ea5HjgUEyibANWcmoCHHhRvcz3nDrc");

        grantDiamondITCAdminRole(hostItAddress);

        grantBackendITCAdminRole(hostItAddress);

        setITC2024NFT(hostItAddress);

        vm.stopBroadcast();
    }
}