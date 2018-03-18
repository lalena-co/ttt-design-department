pragma solidity ^0.4.18;

import './ModuleMaker.sol';

contract AttributeMaker is ModuleMaker {
    event AttributeAdded(string _module, string _name, address _by);
    event AttributeRemoved(string _module, string _name, address _by);

    uint256[] public attributeIndex;
    struct Attribute {
        address designer;
        string name;
        uint256 module;
        uint256 index;
        uint256[] values;
        mapping (string => uint256) nameToValueId;
        mapping (uint256 => uint256) valuePointers;
        bool isAttribute;
    }
    mapping (uint256 => Attribute) public attributes;

    modifier isUniqueAttribute(string _module, string _name) {
        require(keccak256(_name) != keccak256(""));
        require(keccak256(_module) != keccak256(""));
        require(!attributeExists(_module, _name));
        _;
    }

    modifier isAttribute(string _module, string _name) {
        require(attributeExists(_module, _name));
        _;
    }

    modifier onlyAttributeDesignerOrDirector(string _module, string _name) {
        if (msg.sender == attributeDesigner(_module, _name)) {
            require(designerExists(msg.sender));
        } else {
            require(isDirector());
        }
        _;
    }

    function attributeExists(string _module, string _name) view public returns(bool) {
        if (moduleAttributeCount(_module) == 0) return false;
        uint256 attributeId = modules[moduleId(_module)].nameToAttributeId[_name];
        return attributes[attributeId].isAttribute;
    }

    function addAttribute(string _module, string _name) onlyAuthorized isModule(_module) isUniqueAttribute(_module, _name) public returns(bool) {
        uint256 id = nextBitKey;
        Attribute memory newAttribute;
        newAttribute.name = _name;
        newAttribute.designer = msg.sender;
        newAttribute.module = moduleId(_module);
        newAttribute.index = attributeCount();
        newAttribute.isAttribute = true;
        attributes[id] = newAttribute;
        attributeIndex.push(id);

        Module storage module = modules[moduleId(_module)];
        module.attributePointers[id] = module.attributes.push(id) - 1;
        module.nameToAttributeId[_name] = id;
        emit AttributeAdded(_module, _name, msg.sender);
        _increaseBitKey();
        return true;
    }

    function removeAttribute(string _module, string _name) onlyAttributeDesignerOrDirector(_module, _name) isAttribute(_module, _name) public returns(bool) {
        require(attributeValueCount(_module, _name) == 0);
        uint256 rowToDelete;
        uint256 keyToMove;
        uint256 attributeIdToDelete = attributeId(_module, _name);

        if (attributeCount() > 1) {
            rowToDelete = attributes[attributeIdToDelete].index;
            keyToMove = attributeIndex[attributeCount() - 1];
            attributeIndex[rowToDelete] = keyToMove;
            attributes[attributeIdToDelete].index = rowToDelete;
        }
        attributeIndex.length--;

        Module storage module = modules[moduleId(_module)];
        if (moduleAttributeCount(_module) > 1) {
            rowToDelete = module.attributePointers[attributeIdToDelete];
            keyToMove = module.attributes[moduleAttributeCount(_module) - 1];
            module.attributes[rowToDelete] = keyToMove;
            module.attributePointers[keyToMove] = rowToDelete;
        } else {
            delete module.attributePointers[attributeIdToDelete];
        }
        module.attributes.length--;

        delete module.nameToAttributeId[_name];

        emit AttributeRemoved(_module, _name, msg.sender);
        return true;
    }

    function attributeCount() view public returns(uint256) {
        return attributeIndex.length;
    }

    function attributeId(string _module, string _name) isAttribute(_module, _name) view public returns(uint256) {
        return modules[moduleId(_module)].nameToAttributeId[_name];
    }

    function attributeValueCount(string _module, string _attribute) view public returns(uint256) {
        return attributes[attributeId(_module, _attribute)].values.length;
    }

    function getAttributeValueAtIndex(string _module, string _attribute, uint _row) public constant returns(uint256) {
        return attributes[attributeId(_module, _attribute)].values[_row];
    }

    function attributeDesigner(string _module, string _name) view public returns(address) {
        return attributes[attributeId(_module, _name)].designer;
    }
}
