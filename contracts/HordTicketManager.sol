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
    struct TokenStakingRules {
        uint256 timeToStake;
        uint256 amountToStake;
    }

    // Mapping token ID to initial supply
    mapping (uint256 => uint256) tokenIDToInitialSupply;

    mapping (uint256 => TokenStakingRules) public tokenIdToStakingRules;
    // Mapping champion handle to all HPools
    mapping (string => HPool[]) championHandleToHPools;

    /// Users stake
    struct UserStake {
        uint256 tokenId;
        uint256 amountStaked;
        uint256 amountOfTicketsGetting;
        uint256 unlockingTime;
        bool isWithdrawn;
    }

    // Mapping user address to his stake
    mapping(address => mapping(uint => UserStake[])) public addressToTokenIdToStakes;
    mapping(uint256 => uint256) public tokenIdToNumberOfTicketsReserved;

    /// Emit every time someone stakes token
    event TokensStaked(
        address user,
        uint amountStaked,
        uint inFavorOfTokenId,
        uint numberOfTicketsReserved,
        uint unlockingTime
    );

    event NFTsClaimed(
        address beneficiary,
        uint256 amountUnstaked,
        uint256 amountTicketsClaimed,
        uint tokenId
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
        require(championId == numberOfChampions.add(1), "RegisterChampion: Champion ID is not in order.");
        // Take current handle (shouldn't exist)
        string memory currentHandle = championIdToHandle[championId];
        require(keccak256(abi.encodePacked(currentHandle)) == keccak256(abi.encodePacked("")), "RegisterChampion: Champion Handle already exists.");

        // Store champion handle
        championIdToHandle[championId] = handle;
        // Increase number of registered champions
        numberOfChampions++;
    }

    /// Function where maintainer can expand token supply
    function addTokenSupply(
        uint256 tokenId,
        uint256 supplyToAdd
    )
    public
    onlyMaintainer
    {
        require(tokenIDToInitialSupply[tokenId] > 0, "AddTokenSupply: Firstly MINT token, then expand supply.");
        _mint(address(this), tokenId, supplyToAdd, "0x0");
    }

    /**
     *
     */
    function mintNewHPoolNFT(
        uint256 tokenId,
        uint256 initialSupply,
        uint256 championId,
        uint256 championNftGen,
        uint256 purchaseStakeTime,
        uint256 purchaseStakeAmount
    )
    public
    onlyMaintainer
    {
        require(initialSupply <= maxFungibleTicketsPerPool, "MintNewHPoolNFT: Initial supply overflow.");
        require(tokenId == lastMintedTokenId.add(1), "MintNewHPoolNFT: Token ID is wrong.");
        require(championId < numberOfChampions, "MintNewHPoolNFT: Champion ID does not exist.");

        // Set initial supply
        tokenIDToInitialSupply[tokenId] = initialSupply;

        // Mint tokens and store them on contract itself
        _mint(address(this), tokenId, initialSupply, "0x0");

        // Create hPool structure
        HPool memory hPool = HPool(
            championId,
            tokenId,
            championNftGen
        );

        // Fetch champion handle
        string memory championHandle = championIdToHandle[championId];

        // Map pool to champion handle
        championHandleToHPools[championHandle].push(hPool);

        // Create staking rules for token
        TokenStakingRules memory tokenIdStakingRules = TokenStakingRules(
            purchaseStakeTime,
            purchaseStakeAmount
        );

        // Map staking rules to token id
        tokenIdToStakingRules[tokenId] = tokenIdStakingRules;

        // Store always last minted token id.
        lastMintedTokenId = tokenId;
    }

    function stakeAndReserveNFTs(
        uint tokenId,
        uint numberOfTickets
    )
    public
    {
        // Get number of reserved tickets
        uint256 numberOfTicketsReserved = tokenIdToNumberOfTicketsReserved[tokenId];
        // Check there's enough tickets to get
        require(numberOfTicketsReserved.add(numberOfTickets)<= tokenIDToInitialSupply[tokenId], "Not enough tickets to sell.");

        TokenStakingRules memory tsr = tokenIdToStakingRules[tokenId];

        // Fixed stake per ticket
        uint amountOfTokensToStake = tsr.amountToStake.mul(numberOfTickets);

        // Transfer tokens from user
        stakingToken.transferFrom(
            msg.sender,
            address(this),
            amountOfTokensToStake
        );

        UserStake memory userStake = UserStake({
            tokenId: tokenId,
            amountStaked: amountOfTokensToStake,
            amountOfTicketsGetting: numberOfTickets,
            unlockingTime: tsr.timeToStake.add(block.timestamp),
            isWithdrawn: false
        });

        addressToTokenIdToStakes[msg.sender][tokenId].push(userStake);

        // Increase number of tickets reserved
        tokenIdToNumberOfTicketsReserved[tokenId] = numberOfTicketsReserved + numberOfTickets;

        emit TokensStaked(
            msg.sender,
            amountOfTokensToStake,
            tokenId,
            numberOfTickets,
            userStake.unlockingTime
        );
    }

    /// Function to claim NFTs
    function claimNFTs(
        uint tokenId
    )
    public
    {
        UserStake [] storage userStakesForNft = addressToTokenIdToStakes[msg.sender][tokenId];

        uint256 totalStakeToWithdraw;
        uint256 ticketsToWithdraw;

        uint256 i = 0;
        while (i < userStakesForNft.length) {
            UserStake storage stake = userStakesForNft[i];

            if(stake.isWithdrawn || stake.unlockingTime > block.timestamp) {
                continue;
            }

            totalStakeToWithdraw = stake.amountStaked;
            ticketsToWithdraw = stake.amountOfTicketsGetting;

            stake.isWithdrawn = true;
        }

        // Transfer staking tokens
        stakingToken.transfer(msg.sender, totalStakeToWithdraw);

        // Transfer NFTs
        safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            ticketsToWithdraw,
            "0x0"
        );

        // Emit event
        emit NFTsClaimed(
            msg.sender,
            totalStakeToWithdraw,
            ticketsToWithdraw,
            tokenId
        );
    }


    /// Function to return amount of specific NFTs claimed from contract
    function getAmountOfTokensClaimed(uint tokenId)
    external
    view
    returns (uint256)
    {
        return tokenIDToInitialSupply[tokenId].sub(balanceOf(address(this), tokenId));
    }



}
