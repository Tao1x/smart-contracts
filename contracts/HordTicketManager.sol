pragma solidity ^0.6.12;

import "./interfaces/IERC20.sol";
import "./system/HordUpgradable.sol";
import "./interfaces/IHordTicketFactory.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "./libraries/SafeMath.sol";

/**
 * HordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 11.5.21.
 * Github: madjarevicn
 */
contract HordTicketManager is HordUpgradable, ERC1155Holder {

    using SafeMath for *;

    // Mapping champion ID to handle
    mapping (uint256 => string) championIdToHandle;
    // Number of champions registered
    uint256 internal numberOfChampions;
    // Token being staked
    IERC20 stakingToken;
    // Factory of Hord tickets
    IHordTicketFactory public hordTicketFactory;

    // HPool Information
    struct HPool {
        uint256 championId;
        uint256 tokenId;
        uint256 nftGen;
    }

    // Token ID rules for getting tickets with this ID
    struct TokenStakingRules {
        uint256 timeToStake;
        uint256 amountToStake;
    }

    /// @dev Mapping tokenId to staking rules for that token (class)
    mapping (uint256 => TokenStakingRules) public tokenIdToStakingRules;

    /// @dev Mapping champion handle to all HPools
    mapping (string => HPool[]) public championHandleToHPools;

    // Users stake
    struct UserStake {
        uint256 amountStaked;
        uint256 amountOfTicketsGetting;
        uint256 unlockingTime;
        bool isWithdrawn;
    }

    /// @dev Mapping user address to tokenId to stakes for that token
    mapping(address => mapping(uint => UserStake[])) public addressToTokenIdToStakes;

    // Count number of reserved tickets for tokenId
    mapping(uint256 => uint256) internal tokenIdToNumberOfTicketsReserved;

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
        address _stakingToken
    ) public {
        // Set hord congress and maintainers registry
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
        // Set staking token
        stakingToken = IERC20(_stakingToken);
    }


    /**
     * @notice  Set hord ticket factory contract. After set first time,
     *  can be changed only by HordCongress
     * @param _hordTicketFactory is the address of HordTicketFactory contract
     */
    function setHordTicketFactory(address _hordTicketFactory) public {
        // Initial setting is allowed during deployment, after that only congress can change it
        if(address(hordTicketFactory) != address(0)) {
            require(msg.sender == hordCongress);
        }
        // Set hord ticket factory
        hordTicketFactory = IHordTicketFactory(_hordTicketFactory);
    }

    /**
     * @notice  Register champion, store handle and ID
     * @param   championId is the ID of that champion
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

    /**
     * @notice  Create HPools nd token staking rules. Executed every time maintainer mints new series of NFTs
     * @param   tokenId is the ID of the token (representing token class / series)
     * @param   championId is the ID of the champion
     * @param   championNftGen ...thi
     * @param   purchaseStakeTime is time user has to stake tokens in order to claim the NFTs
     * @param   purchaseStakeAmount is amount of tokens user has to stake in order to claim the NFTs
     */
    function createHPoolAndTokenStakingRules(
        uint tokenId,
        uint championId,
        uint256 championNftGen,
        uint256 purchaseStakeTime,
        uint256 purchaseStakeAmount
    )
    external
    {
        require(msg.sender == address(hordTicketFactory), "Only Hord Ticket factory can issue a call to this function");

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
    }

    /**
     * @notice  Stake and reserve NFTs, per specific staking rules
     * @param   tokenId is the ID of the token being staked (class == series)
     * @param   numberOfTickets is representing how many NFTs of same series user wants to get
     */
    function stakeAndReserveNFTs(
        uint tokenId,
        uint numberOfTickets
    )
    public
    {
        // Get number of reserved tickets
        uint256 numberOfTicketsReserved = tokenIdToNumberOfTicketsReserved[tokenId];
        // Check there's enough tickets to get
        require(numberOfTicketsReserved.add(numberOfTickets)<= hordTicketFactory.getTokenSupply(tokenId),
            "Not enough tickets to sell.");

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
            amountStaked: amountOfTokensToStake,
            amountOfTicketsGetting: numberOfTickets,
            unlockingTime: tsr.timeToStake.add(block.timestamp),
            isWithdrawn: false
        });

        addressToTokenIdToStakes[msg.sender][tokenId].push(userStake);

        // Increase number of tickets reserved
        tokenIdToNumberOfTicketsReserved[tokenId] = numberOfTicketsReserved.add(numberOfTickets);

        emit TokensStaked(
            msg.sender,
            amountOfTokensToStake,
            tokenId,
            numberOfTickets,
            userStake.unlockingTime
        );
    }

    /**
     * @notice  Function to claim NFTs and withdraw tokens staked for that NFTs
     * @param   tokenId is representing token class for which user has performed stake
     */
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

        if(totalStakeToWithdraw > 0 && ticketsToWithdraw > 0) {

            // Transfer staking tokens
            stakingToken.transfer(msg.sender, totalStakeToWithdraw);

            // Transfer NFTs
            hordTicketFactory.safeTransferFrom(
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
    }

    /**
     * @notice  Get number of registered champions
     */
    function getNumberOfChampions()
    external
    view
    returns (uint256)
    {
        return numberOfChampions;
    }

    /**
     * @notice  Get number of specific tokens claimed
     */
    function getAmountOfTokensClaimed(uint tokenId)
    external
    view
    returns (uint256)
    {
        uint mintedSupply = hordTicketFactory.getTokenSupply(tokenId);
        return mintedSupply.sub(hordTicketFactory.balanceOf(address(this), tokenId));
    }

    /**
     * @notice  Get amount of tickets reserved for selected tokenId
     */
    function getAmountOfTicketsReserved(uint tokenId)
    external
    view
    returns (uint256)
    {
        return tokenIdToNumberOfTicketsReserved[tokenId];
    }

    /**
     * @notice  Get account stakes for specified token Id
     * @param   account is user address
     * @param   tokenId is the id of the token in favor of which stake is made.
     */
    function getUserStakesForTokenId(
        address account,
        uint tokenId
    )
    external
    view
    returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        bool[] memory
    )
    {
        UserStake [] memory userStakes = addressToTokenIdToStakes[account][tokenId];

        uint numberOfStakes = userStakes.length;

        uint256[] memory amountsStaked = new uint256[](numberOfStakes);
        uint256[] memory ticketsBought = new uint256[](numberOfStakes);
        uint256[] memory unlockingTimes = new uint256[](numberOfStakes);
        bool[] memory isWithdrawn = new bool[](numberOfStakes);

        for(uint i = 0; i < numberOfStakes; i++) {
            // Fulfill arrays with stake information
            amountsStaked[i] = userStakes[i].amountStaked;
            ticketsBought[i] = userStakes[i].amountOfTicketsGetting;
            unlockingTimes[i] = userStakes[i].unlockingTime;
            isWithdrawn[i] = userStakes[i].isWithdrawn;
        }

        return (amountsStaked, ticketsBought, unlockingTimes, isWithdrawn);
    }
}
