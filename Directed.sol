pragma solidity ^0.4.18;

import './Ownable.sol';

contract Directed is Ownable {
    event DirectorHired(address _directorHired, address _by);
    event DirectorFired(address _directorFired, address _by);

    address public director;

    modifier onlyDirector() {
        if (director == 0x0) {
            require(msg.sender == owner);
        } else {
            require(msg.sender == director);
        }
        _;
    }

    function hireDirector(address _director) onlyOwner public returns(bool) {
        director = _director;
        emit DirectorHired(director, msg.sender);
        return true;
    }

    function fireDirector() onlyOwner public returns(bool) {
        require(director != 0x0);
        // :-(
        address unfortunateSoul = director;
        delete director;
        emit DirectorFired(unfortunateSoul, msg.sender);
    }

    function isDirector() onlyDirector view public returns(bool) {
        return true;
    }
}
