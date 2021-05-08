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

    // Champion structure
    struct Champion {
        string handle;
        uint256 nftGen;
        uint256 tokenId;
    }
    // Mapping user address to champion
    mapping(address => Champion) public addressToChampion;
    // All champions
    address [] public champions;

    // Stake structure
    struct Stake {
        uint tokenId;
        uint amountStaked;
        uint amountOfTicketsGetting;
    }

    // Mapping user address to his stake
    mapping(address => Stake) public addressToStake;


    mapping(uint256 => uint256) public tokenIdToNumberOfTicketsReserved;

    // Emit every time someone stakes token
    event TokensStaked(address user, uint amountStaked, uint inFavorOfTokenId);

    constructor(
        address _hordCongress,
        address _maintainersRegistry,
        address _stakingToken,
        string memory _uri
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

    /**
     *
     */
    function mintNewHPoolNFT(
        uint256 tokenId,
        uint256 initialSupply,
        address championAddress,
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
    }

    //TODO
    function claimTickets(
        uint tokenId
    )
    public
    {

    }

}
