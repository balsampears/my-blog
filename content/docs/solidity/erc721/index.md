+++
date = '2026-04-12T22:00:00+08:00'
draft = false
title = 'ERC721 - NFT'
weight = 20
+++

ERC721是非同质化货币，Non-fungible token，简称NFT。  
非同质化货币，每一个代币都是独特的、有区别的、与众不同的。ERC20中类似于法币，我的一块跟你的一块没有区别；ERC721类似于画作，虽然都是画，但是我的画跟你的画内容是完全不一样的。所以ERC721最早从数字藏品开始流行。  
每一个NFT都有一个独特编号，这个编号是**tokenId**。tokenId格式没有明确的要求，可以是自增ID，也可以是随机数。

## 一. NFT组成部分
NFT由五个部分组成：ERC721、ERC165、ERC721TokenReceiver、ERC721Metadata、Metadata JSON。
- ERC721 基础标准
- ERC165 接口描述标准
- ERC721TokenReceiver NFT接收标准，所有接收NFT的合约必须实现
- ERC721Metadata  NFT元数据，基本属性
- Metadata JSON NFT元数据详情属性文件，通常保存在去中心化存储服务
  
其中NFT合约需要实现ERC721、ERC165、ERCMetadata，接收NFT合约需要实现ERC721TokenReceiver，Metadata JSON则放在去中心化存储服务。

### 1.ERC721
```
interface ERC721 {
  # 事件
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  # 查询
  function balanceOf(address _owner) external view returns (uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function getApproved(uint256 _tokenId) external view returns (address);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  # 操作：转账与授权
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  function approve(address _approved, uint256 _tokenId) external payable;

  function setApprovalForAll(address _operator, bool _approved) external;
}
```

**查询**
- balanceOf(owner)  
  查询owner用户拥有多少个NFT
- ownerOf(tokenId)  
  查询tokenId的持有者是谁
- getApproved(tokenId)  
  查询token被持有者单独授权的用户
- isApprovedForAll(owner, operator)  
  查询某个用户所有的NFT是否被授权给operator用户

**转账与授权**
- safeTransferFrom(from, to, tokenId, data)  
  安全转账，将from用户的tokenId的NFT转账给to用户，可以携带data描述信息
- safeTransferFrom(from, to, tokenId)  
  安全转账，将from用户的tokenId的NFT转账给to用户
- transferFrom(from, to, tokenId)  
  转账，将from用户的tokenId的NFT转账给to用户
- approve(operator, tokenId)  
  单个授权，可以授权某个tokenId的NFT给operator用户
- setApprovalForAll(operator, approved)  
  全部授权/取消授权，可以将当前用户的所有NFT全部授权/取消授权给operator用户

**安全转账**  
用户对一个地址进行转账时，如果目标是合约地址，则强制要求其实现IERC721TokenReceiver接口（ERC721接收接口），否则会转账失败。（相当于ERC20的升级版ERC1363）

**与ERC20的区别**
1. NFT有tokenId标识唯一性
2. NFT支持安全转账，防止转入合约锁死
3. NFT支持全部授权

事件+查询+操作=3+4+5=12，一个12个定义。

### 2.ERC165
ERC165是合约接口描述标准，用于让外部判断本合约是否实现了某些标准。  
ERC721强制要求实现。  
具体标准如下：
```
interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```

#### (1) interfaceId
interfaceId计算方式是合约中所有的、对外的函数选择器进行异或运算，取前4个字节。

#### (2) 具体实现（ERC721）
```
function supportsInterface(bytes4 interfaceID) public view override returns (bool){
  return
    interfaceID == 0x01ffc9a7 ||
    interfaceID == type(IERC721).interfaceId  # 这里使用了openZepplin的IERC721，同时使用type.interfaceId自动计算。
    #如果后续实现了其他接口也可以继续加，如ERC721Metadata、ERC721Enumerable
}
```

#### (3) 外界调用方式
- 先判断某个合约是否实现了ERC165
- 如果返回了true，再判断是否实现了某个标准（如ERC721）

### 3.ERC721TokenReceiver
接收NFT的合约必须实现这个接口，避免NFT被锁死在某个合约
```
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}
```

### 4.ERC721Metadata
```
interface ERC721Metadata {

    function name() external view returns (string _name);

    function symbol() external view returns (string _symbol);

    function tokenURI(uint256 _tokenId) external view returns (string);
}
```
- name() 名称
- symbol() 符号
- tokenURI(tokenId) tokenId前缀URL  
  通过url+tokenId即可找到tokenId的具体数据。  $$
  以知名无聊猿NFT举例：tokenURI是ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/，那么tokenId=12的NFT则会找到：ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/12，这个就是具体属性文件（Metadata JSON）

### 5. Metadata JSON
元数据描述文件分为两个部分：元数据定义文件和元数据文件。  

- 元数据定义文件  
  ERC721规定的是元数据定义，约定了元数据应该有什么
```
{
    "title": "Asset Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this NFT represents"
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this NFT represents"
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
        }
    }
}
```

- 元数据  
  元数据是根据元数据定义来填写的具体数据。例如根据上述的定义，可以写出以下元数据文件：
```
{
  "name": "Monkey #1",
  "image": "ipfs://xxxxx",
  "description": "...."
}
```

**定义文件与元数据文件区别**
- 定义文件规定了表字段，元数据文件填写了表数据
- 定义文件通常放在项目仓库、网站上，元数据文件则需要放在去中心化存储服务中
- 定义文件是ERC721的标准的一部分，元数据文件是根据定义文件衍生的文件

## 二. 去中心化存储 - IPFS
IPFS是一个免费的去中心化存储的方案，可以在本地搭建一个节点上传下载链上存储的文件数据。  
缺点是一开始上传的数据只有本地节点拥有，外面未缓存数据的节点访问较慢。  

### 1.安装
1.下载并安装IPFS在本地运行
{{< figure src="ipfs_local.png" width="900" >}}
2.下载并安装浏览器插件
{{< figure src="ipfs_chrome.png" width="900" >}}

### 2.创建NFT目录并获取TokenURI
1.创建目录，命名为“MyERC721”
{{< figure src="ipfs_folder_create.png" width="900" >}}
2.复制目录的CID
{{< figure src="ipfs_folder_copyCID.png" width="900" >}}
3.构造tokenURI
“ipfs://+CID”就是tokenURI，例如：ipfs://QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn


### 3.上传NFT图片
1.上传图片到根目录
{{< figure src="ipfs_img_create.png" width="900" >}}
2.获取图片的CID
{{< figure src="ipfs_img_copyCID.png" width="900" >}}
例如我获得的是：QmRRPWG96cmgTn2qSzjwr2qvfNEuhunv6FNeMFGa9bx6mQ，拼接一下图片的地址就是：ipfs://QmRRPWG96cmgTn2qSzjwr2qvfNEuhunv6FNeMFGa9bx6mQ

### 4.编写元数据文件
1.编写一个json文件，命名为0（不带后缀），其中image地址替换为你的图片ipfs地址
```
{
    "description": "",
    "image": "ipfs://QmRRPWG96cmgTn2qSzjwr2qvfNEuhunv6FNeMFGa9bx6mQ",
    "name": "MyERC721 #1"
}
```
2.进入MyERC721目录，将元数据文件上传进去
{{< figure src="ipfs_token_0.png" width="900" >}}

这样合约的tokenURI设置完成，并且添加了tokenId=0的NFT。


## 三. 参考资料

- [EIP721](https://eips.ethereum.org/EIPS/eip-721)
- [EIP165](https://eips.ethereum.org/EIPS/eip-165)
- [无聊猿NFT](ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/)
- [NFT市场OpenSea](https://opensea.io/)


