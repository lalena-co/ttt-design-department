pragma solidity ^0.4.18;

import './Directed.sol';

contract DesignDepartment is Directed {
    event DesignerHired(address _designer, address by);
    event DesignerFired(address _designer, address by);

    struct Designer {
        uint256 index;
        bool isDesigner;
    }
    mapping (address => Designer) public designers;
    address[] public designerIndex;

    modifier isUniqueDesigner(address _designer) {
        require(!designers[_designer].isDesigner);
        _;
    }

    modifier isDesigner(address _designer) {
        require(designers[_designer].isDesigner);
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == owner ||
            msg.sender == director ||
            designers[msg.sender].isDesigner
        );
        _;
    }

    function addDesigner(address _designer) onlyDirector isUniqueDesigner(_designer) public returns(bool) {
        Designer memory newDesigner;
        newDesigner.index = designerCount();
        newDesigner.isDesigner = true;
        designers[_designer] = newDesigner;
        designerIndex.push(_designer);

        emit DesignerHired(_designer, msg.sender);
        return true;
    }

    function removeDesigner(address _designer) onlyDirector isDesigner(_designer) public returns(bool) {
        if (designerCount() > 1) {
            uint256 rowToDelete = designers[_designer].index;
            address keyToMove = designerIndex[designerCount() - 1];
            designerIndex[rowToDelete] = keyToMove;
            designers[keyToMove].index = rowToDelete;
        }
        designerIndex.length--;
        emit DesignerFired(_designer, msg.sender);
        return true;
    }

    function designerCount() view public returns(uint256) {
        return designerIndex.length;
    }

    function designerExists(address _designer) isDesigner(_designer) view public returns(bool) {
        return true;
    }
}
