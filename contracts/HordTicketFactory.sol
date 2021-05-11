//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155Pausable.sol";
import "./system/HordUpgradable.sol";
import "./interfaces/IHordTicketManager.sol";

/**
 * HordTicketManager contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordTicketFactory is HordUpgradable, ERC1155Pausable {

    // Store always last ID minted
    uint256 public lastMintedTokenId;
    // Maximal number of fungible tickets per Pool
    uint256 public maxFungibleTicketsPerPool;
    // Mapping token ID to minted supply
    mapping (uint256 => uint256) tokenIdToMintedSupply;

    // Manager contract handling tickets
    IHordTicketManager public hordTicketManager;

    constructor(
        address _hordCongress,
        address _maintainersRegistry,
        address _hordTicketManager,
        uint256 _maxFungibleTicketsPerPool,
        string memory _uri   // https://api.hord.app/metadata/ticket_manager  (for test: https://test-api.hord.app/metadata/ticket_manager)
    )
    ERC1155(_uri)
    public
    {
        // Set hord congress and maintainers registry contract
        setCongressAndMaintainers(_hordCongress, _maintainersRegistry);
        // Set hord ticket manager contract
        hordTicketManager = IHordTicketManager(_hordTicketManager);
        // Set max fungible tickets allowed to mint per pool
        maxFungibleTicketsPerPool = _maxFungibleTicketsPerPool;
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

    /**
     * @notice Set maximal fungible tickets possible to mint per pool (pool == class == tokenId)
     */
    function setMaxFungibleTicketsPerPool(
        uint _maxFungibleTicketsPerPool
    )
    external
    onlyHordCongress
    {
        require(_maxFungibleTicketsPerPool > 0);
        maxFungibleTicketsPerPool = _maxFungibleTicketsPerPool;
    }

    /**
     * @notice Mint new HPool NFT token.
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
        require(championId < hordTicketManager.getNumberOfChampions(), "MintNewHPoolNFT: Champion ID does not exist.");

        // Set initial supply
        tokenIdToMintedSupply[tokenId] = initialSupply;

        // Mint tokens and store them on contract itself
        _mint(address(hordTicketManager), tokenId, initialSupply, "0x0");

        // Create new HPool and TokenStakingRules struct
        hordTicketManager.createHPoolAndTokenStakingRules(tokenId, championId, championNftGen,
            purchaseStakeTime, purchaseStakeAmount);

        // Store always last minted token id.
        lastMintedTokenId = tokenId;
    }


    /**
     * @notice  Add supply to existing token
     */
    function addTokenSupply(
        uint256 tokenId,
        uint256 supplyToAdd
    )
    public
    onlyMaintainer
    {
        require(tokenIdToMintedSupply[tokenId] > 0, "AddTokenSupply: Firstly MINT token, then expand supply.");
        require(tokenIdToMintedSupply[tokenId].add(supplyToAdd) <= maxFungibleTicketsPerPool, "More than allowed.");

        _mint(address(hordTicketManager), tokenId, supplyToAdd, "0x0");
    }


    /**
     * @notice  Get total supply minted for tokenId
     */
    function getTokenSupply(
        uint tokenId
    )
    external
    view
    returns (uint256)
    {
        return tokenIdToMintedSupply[tokenId];
    }
}
