pragma solidity ^0.6.12;

/**
 * ConfigurationManager contract to hold all system-accessible configuration parameters
 * @author Nikola Madjarevic
 * Date created: 7.4.21.
 * Github: madjarevicn
 */
contract ConfigurationManager {
    // Array storing all 'names' of configuration things saved
    string [] configurationsStored;

    // Mapping configuration param name and it's value
    mapping(string => uint) configurationName2Value;

}
