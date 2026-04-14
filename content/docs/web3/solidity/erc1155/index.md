+++
date = '2026-04-13T22:00:00+08:00'
draft = false
title = 'ERC1155'
description= 'ERC1155是以太坊中的多重代币标准'
weight = 30
+++

ERC1155是多重货币，一个同时支持ERC20和ERC721的合约标准。  
- 对于ERC20，ERC1155可以设置元数据。
- 对于ERC721，ERC1155可以同一个设置多个NFT。
- 相对于两者，ERC1155可以在一个合约中同时发行ERC20和NFT，简化发行多数不同类型代币合约的需求。  

在ERC721中存在tokenId，在ERC1155中存在id，标识一种类型货币或者一个NFT。

## 一. ERC1155组成
ERC1155由四个部分组成：ERC1155、ERC165、ERC1155Received、Metadata JSON。  
对比ERC721，缺少的部分是ERC1155Metadata接口，这是因为将这个接口填的数据放在了Metadata JSON配置文件进行管理。这样做的好处是，在当前合约发行ERC20类型的货币时，每个都可以有自己的name、decimals。

### 1. ERC1155
```
interface ERC1155 /* is ERC165 */ {
  # 事件
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  event URI(string _value, uint256 indexed _id);

  # 查询
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  # 操作：转账与授权
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

  function setApprovalForAll(address _operator, bool _approved) external;

}
```

1. 事件
- URI(value,id) 当某个id的前缀地址发生变化时，需要触发这个事件
  
2. 查询
- balanceOf(owner,id) 查询用户在某个id下货币持有多少
- balanceOfBatch(owners, ids) 查询多个用户在多个id下货币持有多少
- isApprovedForAll(owner, operator) 查询用户是否给operator用户对所有货币进行了授权

3. 操作：转账与授权
-  safeTransferFrom(from, to, id, value, data)  
  安全转账，将from用户的第id种货币转移value个给to用户
-  safeBatchTransferFrom(from, to, ids, values, data)  
  安全批量转账，将from用户的第ids种货币转移values个给to用户，ids和values一一对应
-  setApprovalForAll(operator, approved)
  将当前用户的所有货币给operator用户，进行全部授权/取消授权

### 2. ERC165
```
function supportsInterface(bytes4 interfaceID) external view returns (bool) {
  return  interfaceID == 0x01ffc9a7 ||    // ERC-165 support
          interfaceID == type(IERC1155).interfaceId
          ...
}
```
跟 ERC721 合约中的ERC165用法一致

### 3. ERC1155Received
```
interface ERC1155TokenReceiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);       
}
```
接收ERC1155代币的合约必须实现，需要支持单id转账和多id转账。

### 4. Metadata JSON
ERC1155也分为两部分：元数据定义文件和元数据文件。

- 1. 元数据定义文件
```
{
    "title": "Token Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this token represents"
        },
        "decimals": {
            "type": "integer",
            "description": "The number of decimal places that the token amount should display - e.g. 18, means to divide the token amount by 1000000000000000000 to get its user representation."
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this token represents"
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this token represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
        },
        "properties": {
            "type": "object",
            "description": "Arbitrary properties. Values may be strings, numbers, object or arrays."
        }
    }
}
```
decimals货币精度，让ERC20类型代币的精度完全交给配置文件进行管理。在代码中精度是不受影响，但是给用户展示货币持有时需要查询元数据文件来对货币余额进行计算。

- 2. 元数据文件
```
{
	"name": "Asset Name",
	"description": "Lorem ipsum...",
	"image": "https:\/\/s3.amazonaws.com\/your-bucket\/images\/{id}.png",
	"properties": {}
}
```
元数据文件通常需要保管在去中心化存储中。

### 5.MetadataURI（可选，推荐）
```
interface ERC1155Metadata_URI {
    function uri(uint256 _id) external view returns (string memory);
}
```
查询id号代币的URL前缀

## 二. 铸造
```
function mint(address to, uint256 id, uint256 value) public returns (bool);
```
给to用户铸造id号代币value个，如果是铸造NFT，则将value固定为1即可；如果是铸造ERC20，则value可以大于1。


## 三. 标准库

- [IERC1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol)
- [IERC1155MetadataURI](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol)
- [ERC1155](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)

## 四.参考资料

- [EIP1155](https://eips.ethereum.org/EIPS/eip-1155)