pragma solidity ^0.6.12;

/**
 * IHordCongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 21.3.21.
 * Github: madjarevicn
 */
interface IHordCongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}
