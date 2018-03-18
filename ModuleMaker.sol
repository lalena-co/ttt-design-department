pragma solidity ^0.4.18;

import './DesignDepartment.sol';
import './SafeMath.sol';

contract ModuleMaker is DesignDepartment {
    using SafeMath for uint256;

    event ModuleAdded(uint256 _id, string _name, address _by);
    event ModuleRemoved(uint256 _id, string _name, address _by);
    event BitKeyIncreased(uint256 _to, uint256 _from, address _by);

    uint256[] public moduleIndex;
    string[] public moduleNameIndex;
    struct Module {
        address designer;
        string name;
        uint256 index;
        uint256[] attributes;
        mapping (string => uint256) nameToAttributeId;
        mapping (uint256 => uint256) attributePointers;
        bool isModule;
    }
    mapping (uint256 => Module) public modules;
    mapping (string => uint256) nameToModuleId;

    uint256 startBitKey = 1;
    uint256 nextBitKey;

    modifier isUniqueModuleName(string _name) {
        require(keccak256(_name) != keccak256(""));
        require(!moduleExists(_name));
        _;
    }

    modifier isModule(string _name) {
        require(moduleExists(_name));
        _;
    }

    modifier onlyModuleDesignerOrDirector(string _name) {
        if (msg.sender == moduleDesigner(_name)) {
            require(designerExists(msg.sender));
        } else {
            require(isDirector());
        }
        _;
    }

    function ModuleMaker() public {
        require(startBitKey > 0);
        nextBitKey = startBitKey;
    }

    function addModule(string _name) onlyAuthorized isUniqueModuleName(_name) public returns(bool) {
        uint256 id = nextBitKey;
        Module memory newModule;
        newModule.name = _name;
        newModule.designer = msg.sender;
        newModule.index = moduleCount();
        newModule.isModule = true;
        modules[id] = newModule;
        moduleIndex.push(id);
        moduleNameIndex.push(_name);
        nameToModuleId[_name] = id;
        emit ModuleAdded(id, _name, msg.sender);
        _increaseBitKey();
        return true;
    }

    function removeModule(string _name) onlyModuleDesignerOrDirector(_name) public returns(bool) {
        require(moduleAttributeCount(_name) == 0);

        uint256 moduleIdToDelete = moduleId(_name);

        if (moduleCount() > 1) {
            uint256 rowToDelete = modules[moduleIdToDelete].index;
            uint256 keyToMove = moduleIndex[moduleCount() - 1];
            string memory nameToMove = moduleNameIndex[moduleCount() - 1];
            moduleIndex[rowToDelete] = keyToMove;
            moduleNameIndex[rowToDelete] = nameToMove;
            modules[keyToMove].index = rowToDelete;
        }
        moduleIndex.length--;
        moduleNameIndex.length--;
        delete nameToModuleId[_name];
        emit ModuleRemoved(moduleIdToDelete, _name, msg.sender);
        return true;
    }

    function _increaseBitKey() internal {
        uint previousKey = nextBitKey;
        nextBitKey = nextBitKey.add(1);
        emit BitKeyIncreased(nextBitKey, previousKey, msg.sender);
    }

    function moduleCount() view public returns(uint256) {
        return moduleIndex.length;
    }

    function moduleId(string _name) isModule(_name) view public returns(uint256) {
        return nameToModuleId[_name];
    }

    function moduleAttributeCount(string _module) view public returns(uint256) {
        return modules[moduleId(_module)].attributes.length;
    }

    function getModuleAttributeAtIndex(string _module, uint _row) public constant returns(uint256) {
        return modules[moduleId(_module)].attributes[_row];
    }

    function moduleExists(string _name) view public returns(bool) {
        if (moduleCount() == 0) return false;
        return modules[nameToModuleId[_name]].isModule;
    }

    function moduleDesigner(string _name) view public returns(address) {
        return modules[moduleId(_name)].designer;
    }
}
