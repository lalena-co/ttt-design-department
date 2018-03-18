pragma solidity ^0.4.18;

import './AttributeMaker.sol';

contract ValueMaker is AttributeMaker {
    event ValueAdded(string _module, string _attribute, string _value, address _by);
    event ValueRemoved(string _module, string _attribute, string _value, address _by);

    uint256[] public valueIndex;
    struct Value {
        address designer;
        string name;
        uint256 attribute;
        uint256 index;
        bool isValue;
    }
    mapping (uint256 => Value) public values;

    modifier isUniqueValue(string _module, string _attribute, string _name) {
        require(keccak256(_name) != keccak256(""));
        require(keccak256(_attribute) != keccak256(""));
        require(keccak256(_module) != keccak256(""));
        require(!valueExists(_module, _attribute, _name));
        _;
    }

    modifier isValue(string _module, string _attribute, string _name) {
        require(valueExists(_module, _attribute, _name));
        _;
    }

    modifier onlyValueDesignerOrDirector(string _module, string _attribute, string _name) {
        if (msg.sender == valueDesigner(_module, _attribute, _name)) {
            require(designerExists(msg.sender));
        } else {
            require(isDirector());
        }
        _;
    }

    function valueExists(string _module, string _attribute, string _name) isAttribute(_module, _attribute) view public returns(bool) {
        if (attributeValueCount(_module, _attribute) == 0) return false;

        uint256 attributeId = modules[nameToModuleId[_module]].nameToAttributeId[_attribute];
        uint256 valueId = attributes[attributeId].nameToValueId[_name];
        return values[valueId].isValue;
    }

    function addValue(string _module, string _attribute, string _name) onlyAuthorized isAttribute(_module, _attribute) isUniqueValue(_module, _attribute, _name) public returns(bool) {
        uint256 id = nextBitKey;
        Value memory newValue;
        newValue.name = _name;
        newValue.designer = msg.sender;
        newValue.attribute = attributeId(_module, _attribute);
        newValue.index = valueCount();
        newValue.isValue = true;
        values[id] = newValue;
        valueIndex.push(id);

        Attribute storage attribute = attributes[attributeId(_module, _attribute)];
        attribute.valuePointers[id] = attribute.values.push(id) - 1;
        attribute.nameToValueId[_name] = id;
        emit ValueAdded(_module, _attribute, _name, msg.sender);
        _increaseBitKey();
        return true;
    }

    function removeValue(string _module, string _attribute, string _name) onlyValueDesignerOrDirector(_module, _attribute, _name) public returns(bool) {
        uint256 rowToDelete;
        uint256 keyToMove;
        uint256 valueIdToDelete = valueId(_module, _attribute, _name);

        if (valueCount() > 1) {
            rowToDelete = values[valueIdToDelete].index;
            keyToMove = valueIndex[valueCount() - 1];
            valueIndex[rowToDelete] = keyToMove;
            values[valueIdToDelete].index = rowToDelete;
        }
        valueIndex.length--;

        Attribute storage attribute = attributes[attributeId(_module, _attribute)];
        if (attributeValueCount(_module, _attribute) > 1) {
            rowToDelete = attribute.valuePointers[valueIdToDelete];
            keyToMove = attribute.values[attributeValueCount(_module, _attribute) - 1];
            attribute.values[rowToDelete] = keyToMove;
            attribute.valuePointers[keyToMove] = rowToDelete;
        } else {
            delete attribute.valuePointers[valueIdToDelete];
        }
        attribute.values.length--;
        delete attribute.nameToValueId[_name];

        emit ValueRemoved(_module, _attribute, _name, msg.sender);
        return true;
    }

    function valueCount() view public returns(uint256) {
        return valueIndex.length;
    }

    function valueId(string _module, string _attribute, string _name) isValue(_module, _attribute, _name) view public returns(uint256) {
        return attributes[attributeId(_module, _attribute)].nameToValueId[_name];
    }

    function valueDesigner(string _module, string _attribute, string _name) view public returns(address) {
        return values[valueId(_module, _attribute, _name)].designer;
    }
}
