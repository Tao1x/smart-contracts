//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/proxy/Initializable.sol";

/**
 * MaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 18.3.21.
 * Github: madjarevicn
 */
contract MaintainersRegistry is Initializable {

    // Address of HordCongress contract
    address hordCongress;
    // Array holding addresses of all maintainers
    address [] maintainers;
    // Mapping representing if specific address is a maintainer
    mapping(address => bool) isMaintainer;

    // Modifier restricting calls only to HordCongress
    modifier onlyHordCongress {
        require(msg.sender == hordCongress);
        _;
    }

    /**
     * @notice  Function to set maintainers initially
     * @param   _maintainers is the array of initial maintainer addresses
     * @param   _hordCongress is the address of HordCongress contract
     */
    function initialize(address [] memory _maintainers, address _hordCongress) public initializer {
        for(uint i = 0; i < _maintainers.length; i++) {
            address _maintainer = _maintainers[i];
            maintainers.push(_maintainer);
            isMaintainer[_maintainer] = true;
        }

        // Set the congress address
        hordCongress = _hordCongress;
    }

    /**
     * @notice  Function to add array of maintainers
     * @param   _maintainers is the array of maintainers to add
     */
    function addMaintainers(address [] memory _maintainers) public onlyHordCongress {
        for(uint i=0; i < _maintainers.length; i++) {
            address _maintainer = _maintainers[i];
            // Skip if maintainer is already present
            if(!isMaintainer[_maintainer]) {
                maintainers.push(_maintainers[i]);
                isMaintainer[_maintainers[i]] = true;
            }
        }
    }

    /**
     * @notice  Function to remove array of maintainers
     * @param   _maintainers is the array of maintainers to remove
     */
    function removeMaintainers(address [] memory _maintainers) public onlyHordCongress {
        for(uint i = 0; i < _maintainers.length; i++) {
            removeMaintainer(_maintainers[i]);
        }
    }

    /**
     * @dev Internal handling removing maintainers
     */
    function removeMaintainer(address _maintainer) internal {
        // Maintainer has to exist
        require(isMaintainer[_maintainer] == true);
        uint i = 0;
        // Find the index position of the maintainer
        while(maintainers[i] != _maintainer) {
            if(i == maintainers.length) {
                revert("Passed maintainer address does not exist");
            }
        }
        // Copy the last admin position to the current index
        maintainers[i] = maintainers[maintainers.length-1];
        // Change maintainer status
        isMaintainer[_maintainer] = false;
        // Remove the last admin, since it's double present
        maintainers.pop();
    }

    /**
     * @notice  Function to get all maintainers, no need for allowing query by start and end index
     *          since array of maintainers will be controlled and never will exceed block gas limit.
     */
    function getMaintainers()
    external
    view
    returns (address [] memory)
    {
        return maintainers;
    }
}
