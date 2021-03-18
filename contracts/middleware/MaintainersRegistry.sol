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

    address [] maintainers;
    mapping(address => bool) isMaintainer;

    modifier onlyMaintainer {
        require(isMaintainer[msg.sender] == true);
        _;
    }

    /**
     * @notice  Function to set maintainers initially
     * @param   _maintainers is the array of initial maintainer addresses
     */
    function initialize(address [] memory _maintainers) public initializer {

        for(uint i = 0; i < _maintainers.length; i++) {
            address _maintainer = _maintainers[i];
            maintainers.push(_maintainer);
            isMaintainer[_maintainer] = true;
        }
    }

    function addMaintainers(address [] memory _maintainers) public onlyMaintainer {
        for(uint i=0; i < _maintainers.length; i++) {
            address _maintainer = _maintainers[i];
            if(!isMaintainer[_maintainer]) {
                maintainers.push(_maintainers[i]);
                isMaintainer[_maintainers[i]] = true;
            }
        }
    }

    function removeMaintainers(address [] memory _maintainers) public onlyMaintainer {
        //TODO
    }
}
