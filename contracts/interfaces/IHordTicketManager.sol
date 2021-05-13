pragma solidity ^0.6.12;

/**
 * IHordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 11.5.21.
 * Github: madjarevicn
 */
interface IHordTicketManager {
    function getNumberOfChampions() external view returns (uint256);
    function addNewTokenIdForChampion(uint tokenId, uint championId) external;
}
