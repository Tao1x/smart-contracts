//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "./system/HordUpgradable.sol";
import "./interfaces/IERC20.sol";

/**
 * HordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordTicketManager is HordUpgradable, ERC1155Holder, ERC1155Pausable {

    // Minimal amount to stake in order to reserve ticket
    uint256 public minStakeDaysAccessTicket;
    // Maximal number of fungible tickets per Pool
    uint256 public maxFungibleTicketsPerPool;
    // Period how long tokens are locked after staked
    uint256 public stakeLockPeriod;
    // Stake amount per ticket
    uint256 public stakeAmountPerTicket;
    // Store always last ID minted
    uint256 public  lastMintedTokenId;
    // Token being staked
    IERC20 stakingToken;
    // Mapping champion ID to handle
    mapping (uint256 => string) championIdToHandle;

    // Number of champions registered
    uint256 public numberOfChampions;

    /// HPool Information
    struct HPool {
        uint256 championId;
        uint256 tokenId;
        uint256 nftGen;
    }

    /// Token ID rules for getting tickets with this ID
    struct TokenIdStakingRules {
        uint256 timeToStake;
        uint256 amountToStake;
    }

    // Mapping champion handle to all HPools
    mapping (string => HPool[]) championIdToHPools;

    /// Users stake
    struct UserStake {
        uint256 tokenId;
        uint256 amountStaked;
        uint256 amountOfTicketsGetting;
        uint256 unlockingTime;
        bool isWithdrawn;
    }

    // Mapping user address to his stake
    mapping(address => UserStake[]) public addressToStakes;
    mapping(uint256 => uint256) public tokenIdToNumberOfTicketsReserved;

    /// Emit every time someone stakes token
    event TokensStaked(
        address user,
        uint amountStaked,
        uint inFavorOfTokenId,
        uint numberOfTicketsReserved,
        uint unlockingTime
    );

    constructor(
        address _hordCongress,
        address _maintainersRegistry,
        address _stakingToken,
        string memory _uri   // https://api.hord.app/metadata/ticket_manager  (for test: https://test-api.hord.app/metadata/ticket_manager)
    )
    ERC1155(_uri)
    public
    {
        // Set hord congress and maintainers registry contract
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
        // Set staking token
        stakingToken = IERC20(_stakingToken);
    }

    /**
     * @notice  Function allowing congress to pause the smart-contract
     * @dev     Can be only called by HordCongress
     */
    function pause()
    public
    onlyHordCongress
    {
        _pause();
    }

    /**
     * @notice  Function allowing congress to unpause the smart-contract
     * @dev     Can be only called by HordCongress
     */
    function unpause()
    public
    onlyHordCongress
    {
        _unpause();
    }


    function burnTickets(
        bytes memory signature,
        uint tokenId,
        uint amountToBurn
    )
    public
    onlyMaintainer
    {
        //TODO: Validate signature
//        _burn
    }

    /**
     * @notice  Register champion, store handle and ID
     * @param   championId is going to be the ID of that champion
     * @param   handle is the handle to which ID is mapped.
     */
    function registerChampion(
        uint championId,
        string memory handle
    )
    public
    onlyMaintainer
    {
        require(championId == numberOfChampions.add(1), "registerChampion: Champion ID is not in order.");
        // Take current handle (shouldn't exist)
        string memory currentHandle = championIdToHandle[championId];
        require(keccak256(abi.encodePacked(currentHandle)) == keccak256(abi.encodePacked("")), "registerChampion: Champion Handle already exists.");

        // Store champion handle
        championIdToHandle[championId] = handle;
        // Increase number of registered champions
        numberOfChampions++;
    }

//    //TODO add function for maintainer to add supply to a specific token id
//    //TODO when minting a new token_id, set the required amount of tokens and time to purchase/get 1 (default to defaults for hord)
//    /**
//     *
//     */
//    function mintNewHPoolNFT(
//        uint256 tokenId,
//        uint256 initialSupply,
//        address championId,
//        string memory championHandle,
//        uint256 championNftGen,
//        bytes memory data
//    )
//    public
//    onlyMaintainer
//    {
//        require(initialSupply <= maxFungibleTicketsPerPool, "MintNewHPoolNFT: Initial supply overflow.");
//        require(tokenId == lastMintedTokenId.add(1), "MintNewHPoolNFT: Token ID is wrong.");
//        // Mint tokens and store them on contract itself
//        _mint(address(this), tokenId, initialSupply, data);
//
//        Champion memory c = Champion({
//            handle: championHandle,
//            nftGen: championNftGen,
//            tokenId: tokenId
//        });
//
//        //TODO: Discuss with eiTan
//
//        // Map address to champion
//        addressToChampion[championAddress] = c;
//        champions.push(championAddress);
//
//        // Store always last minted token id.
//        lastMintedTokenId = tokenId;
//    }
//
//    //TODO rename to stakeAndReserveNFTs
//    function stakeHordTokens(
//        uint tokenId,
//        uint numberOfTickets
//    )
//    public
//    {
//        //TODO: Can user enter to this function for same tokenId multiple times??
//
//        // Get number of reserved tickets
//        uint256 numberOfTicketsReserved = tokenIdToNumberOfTicketsReserved[tokenId];
//        // Check there's enough tickets to get
//
//        //TODO work with actual supply per the token id not the max supply
//        require(numberOfTicketsReserved + numberOfTickets <= maxFungibleTicketsPerPool, "Not enough tickets to sell.");
//
//        // Fixed stake per ticket
//        uint amountOfTokensToStake = stakeAmountPerTicket.mul(numberOfTickets);
//
//        // Transfer tokens from user
//        stakingToken.transferFrom(
//            msg.sender,
//            address(this),
//            amountOfTokensToStake
//        );
//
//        Stake memory s = Stake({
//            tokenId: tokenId,
//            amountStaked: amountOfTokensToStake,
//            amountOfTicketsGetting: numberOfTickets
//        });
//
//        // Map this address to stake
//        addressToStake[msg.sender] = s;
//
//        // Increase number of tickets reserved
//        tokenIdToNumberOfTicketsReserved[tokenId] = numberOfTicketsReserved + numberOfTickets;
//
//        //TODO emit an event TokensStaked
//
//
//    }
//
//    //TODO add getter for how many tokens claimed per token id (supply for that token minus the balance of this contract)
//
//    //TODO rename to claimNFTs
//    function claimTickets(
//        uint tokenId
//    )
//    public
//    {
//        //TODO emit NFTsClaimed event:    address, n_tokens_unstaked, n_tickets_claimed, token_id
//
//
//    }

}
