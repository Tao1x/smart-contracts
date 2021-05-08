pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "./system/HordUpgradable.sol";

/**
 * HordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordTicketManager is HordUpgradable, ERC1155Pausable {

    // Initially set roles with special permissions
    constructor(address _hordCongress, address _maintainersRegistry, string memory _uri) ERC1155(_uri)
    public
    {
        // Set hord congress and maintainers registry contract
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
    }
}
