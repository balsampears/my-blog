+++
date = '2026-04-10T20:00:00+08:00'
draft = false
title = 'ERC20'
description= 'ERC20是以太坊中的代币标准'
weight = 10
+++

## 一. EIP 与 ERC

EIP（Ethereum Improvement Proposals）是以太坊改进协议，包括从链底层到应用层，从共识算法到智能合约，范围广泛。  
ERC（Ethereum Requests For Commments）是以太坊征求意见，主要针对应用层智能合约的改进，属于EIP的其中一种。

## 二. ERC20

ERC20是代币标准提案，智能合约中最广泛应用的标准之一，提出于ERC的第20个issue。  
ERC20定义了一系列代币交易的标准接口，使得不同智能合约的代币可以互相调用、互相交易。
具体标准如下：

```
## 事件
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);

## 代币属性
function name() public view returns (string)
function symbol() public view returns (string)
function decimals() public view returns (uint8)

## 代币查询
function totalSupply() public view returns (uint256)
function balanceOf(address _owner) public view returns (uint256 balance)
function allowance(address _owner, address _spender) public view returns (uint256 remaining)

## 代币操作：转账和授权
function transfer(address _to, uint256 _value) public returns (bool success)
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
function approve(address _spender, uint256 _value) public returns (bool success)
```

事件+属性+查询+操作：2+3+3+3，一共11个定义。

### 1. 代币属性

代币属性通常在构造函数中定义完成

- name() 定义代币名，如Tether
- symbol() 定义符号名，如USDT
- decimals() 定义代币精度，solidity中没有小数，用代币精度来表示小数位。  
通常是18位，这种精度下 1个代币 = 1*10^18个(代码中表示)  
USDT是6位。

### 2. 代币查询

- totalSupply() 统计总共发行多少代币
- balanceOf(owner) 查询owner用户持有多少代币
- allowance(owner, spender) 查询spender用户可以在owner用户的钱包中花费多少代币

### 3. 代币操作：转账与授权

- transfer(to, value) 调用方转账给to用户value个代币  
value跟精度有关。口语中，转账给其他用户1个USDT，而实际代码中，实际转账给1*10^6个USDT（USDT精度decimals=6）  
最后一步需要触发Transfer事件
- transferFrom(from, to, value) 从from用户钱包转移给to用户value个代币  
进行这个操作前必须让from用户授权to用户大于等于value个数量的代币
最后一步需要触发Transfer事件
- approve(spender, value) 调用方授权给spender用户value个代币
最后一步需要触发Approval事件

#### 注意事项

这里需要特别注意各个用户的区别：谁在调用（调用方）？从谁的钱包取钱（出钱方）？到谁的钱包中去（得钱方）？

- transfer 调用方和出钱方是同一个人
- transferFrom 调用方、出钱方、得钱方可以是不同的人，不过通常情况下调用方和得钱方是同一个人
- approve 调用方和出钱方是同一个人，不同的是现在是授权没有发生实际转账

#### 授权优点

用户直接转账拆分成两步：授权+第三方转账，可以避免用户是调用代币合约执行操作还是调用业务合约操作产生的混乱，将业务逻辑全部放在业务合约便于管理。  
具体用户操作如下：用户在一个业务合约消费时，先授权业务合约多少代币，然后调用业务合约执行函数，该合约可以从用户钱包查询并转入代币，再执行业务方法，这样操作可以保证一个交易原子性。  

### 4. 代币发行

代币发行并没有在ERC20标准中体现，而是由不同项目根据需求自行实现，通常是

```
function mint(address to, uint256 value) public returns (bool);
```

其中最重要的是需要控制权限，不能让用户随便mint货币

### 5. 标准库

OpenZeppelin是标准合约工具库，经过合约审计，安全性有保障，也可以避免重复造轮子  
- [OpenZeppelin Github地址](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [ERC20标准接口](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
- [ERC20标准实现](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)

### 6. 常见应用

区块链合约骨架之一，只要跟钱相关的都离不开ERC20，例如NFT交易、稳定币、Dex。

## 三. 扩展：ERC1363
ERC1363是可支付代币标准，是对ERC20增强补充，添加了支付回调函数、支付额外传参的功能。

### (1)合约要求
#### 代币合约要求
代币合约要求支持实现ERC20、ERC165，以及以下ERC1363要求的标准：
```
  function transferAndCall(address to, uint256 value) external returns (bool);

  function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool);

  function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

  function transferFromAndCall(address from, address to, uint256 value, bytes memory data) external returns (bool);

  function approveAndCall(address spender, uint256 value) external returns (bool);

  function approveAndCall(address spender, uint256 value, bytes memory data) external returns (bool);
```
   
#### 转账目标合约要求
```
function onTransferReceived(address operator, address from, uint256 value, bytes memory data) external returns (bytes4);
```

#### 授权目标合约要求
```
function onApprovalReceived(address owner, uint256 value, bytes memory data) external returns (bytes4);
```
**增强功能**
1. 转账/授权完成后需要调用目标合约的回调方法
   - transferAndCall、transferFromAndCall 结束前调用 onTransferReceived 
   - approveAndCall 结束前调用 onApprovalReceived
2. 调用目标合约回调方法时可以传递信息（bytes data）


### (2)优势
- 要求目标合约实现回调，防止代币转账到目标合约而目标合约又没有能力处理代币，导致代币被永久锁定到该合约
- 可以对交易发生时传递一些信息
- 可以将授权+转账两步合并为一个步骤

### (3)标准库
- [IERC1363](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC1363.sol)
- [IERC1363Receiver](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC1363Receiver.sol)
- [IERC1363Spender](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC1363Spender.sol)  
仅有接口标准，无具体实现

## 四.参考资料

- [EIP20](https://eips.ethereum.org/EIPS/eip-20)
- [EIP1363](https://eips.ethereum.org/EIPS/eip-1363)