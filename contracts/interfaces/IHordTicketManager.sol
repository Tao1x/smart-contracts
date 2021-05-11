pragma solidity ^0.6.12;

/**
 * IHordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 11.5.21.
 * Github: madjarevicn
 */
interface IHordTicketManager {
    function getNumberOfChampions() external view returns (uint256);
    function createHPoolAndTokenStakingRules(uint tokenId, uint championId, uint256 championNftGen,
        uint256 purchaseStakeTime, uint256 purchaseStakeAmount) external;
}
