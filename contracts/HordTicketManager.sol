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

    //TODO each champion will have one tokenId per pool, each tokenId will have a gen, and they can have as many gens as they have pools
    //TODO for champion struct - data is champion_id, champion_handle
    //TODO for hpool_nft struct - token_id, champion_id, champion_handle, nft_gen
    // Champion structure
    struct Champion {
        string handle;
        uint256 nftGen;
        uint256 tokenId;
    }

    //TODO add getters from champion id to their tokens and champion handle to their tokens

    //TODO we won't have champion address
    // Mapping user address to champion
    mapping(address => Champion) public addressToChampion;
    // All champions
    address [] public champions;

    //TODO when minting a new token_id, set the required amount of tokens and time to purchase/get 1 (default to defaults for hord)
    //TODO create a token_staking_rules/structs structure should map from token_id to time_to_get_1 amount_to_get_1

    //TODO rename to UserStake, add created_at for time computes
    // Stake structure
    struct Stake {
        uint tokenId;
        uint amountStaked;
        uint amountOfTicketsGetting;
    }

    //TODO support multiple stakes per user
    // Mapping user address to his stake
    mapping(address => Stake) public addressToStake;


    mapping(uint256 => uint256) public tokenIdToNumberOfTicketsReserved;

    //TODO add n_tickets_reserved, unlocking_time
    // Emit every time someone stakes token
    event TokensStaked(address user, uint amountStaked, uint inFavorOfTokenId);

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

    // Pause contract
    function pause()
    public
    onlyHordCongress
    {
        _pause();
    }

    // UnPause contract
    function unpause()
    public
    onlyHordCongress
    {
        _unpause();
    }

    function burnTickets(
        bytes signature,
        uint tokenId,
        uint amountToBurn
    )
    public
    onlyMaintainer
    {
        //TODO: Validate signature
//        _burn
    }

    //TODO add function for maintainer to add supply to a specific token id

    /**
     *
     */
    function mintNewHPoolNFT(
        uint256 tokenId,
        uint256 initialSupply,   //make sure backend sends as main units not wei
        address championAddress, //TODO to champion_id
        string memory championHandle,
        uint256 championNftGen,
        bytes memory data
    )
    public
    onlyMaintainer
    {
        require(initialSupply <= maxFungibleTicketsPerPool, "MintNewHPoolNFT: Initial supply overflow.");
        require(tokenId == lastMintedTokenId.add(1), "MintNewHPoolNFT: Token ID is wrong.");
        // Mint tokens and store them on contract itself
        _mint(address(this), tokenId, initialSupply, data);

        Champion memory c = Champion({
            handle: championHandle,
            nftGen: championNftGen,
            tokenId: tokenId
        });

        //TODO: Discuss with eiTan

        // Map address to champion
        addressToChampion[championAddress] = c;
        champions.push(championAddress);

        // Store always last minted token id.
        lastMintedTokenId = tokenId;
    }

    //TODO rename to stakeAndReserveNFTs
    function stakeHordTokens(
        uint tokenId,
        uint numberOfTickets
    )
    public
    {
        //TODO: Can user enter to this function for same tokenId multiple times??

        // Get number of reserved tickets
        uint256 numberOfTicketsReserved = tokenIdToNumberOfTicketsReserved[tokenId];
        // Check there's enough tickets to get

        //TODO work with actual supply per the token id not the max supply
        require(numberOfTicketsReserved + numberOfTickets <= maxFungibleTicketsPerPool, "Not enough tickets to sell.");

        // Fixed stake per ticket
        uint amountOfTokensToStake = stakeAmountPerTicket.mul(numberOfTickets);

        // Transfer tokens from user
        stakingToken.transferFrom(
            msg.sender,
            address(this),
            amountOfTokensToStake
        );

        Stake memory s = Stake({
            tokenId: tokenId,
            amountStaked: amountOfTokensToStake,
            amountOfTicketsGetting: numberOfTickets
        });

        // Map this address to stake
        addressToStake[msg.sender] = s;

        // Increase number of tickets reserved
        tokenIdToNumberOfTicketsReserved[tokenId] = numberOfTicketsReserved + numberOfTickets;

        //TODO emit an event TokensStaked


    }

    //TODO add getter for how many tokens claimed per token id (supply for that token minus the balance of this contract)

    //TODO rename to claimNFTs
    function claimTickets(
        uint tokenId
    )
    public
    {
        //TODO emit NFTsClaimed event:    address, n_tokens_unstaked, n_tickets_claimed, token_id


    }

}
