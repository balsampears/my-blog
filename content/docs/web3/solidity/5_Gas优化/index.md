+++
date = '2026-05-20T20:00:00+08:00'
draft = false
title = 'Gas优化'
description = '节省Gas燃料费的各种技巧'
tags = ['solidity', '解决方案']
weight = 50
+++

## 一. Gas评估
### 1. foundry测试
`forge test --gas-report`会在测试时同步打印每个方法消耗的Gas。

### 2. foundry评估文件
`forge snaphot`会生成Gas消耗报告文件，额外添加`--check`参数可以比较两次gas报告的变化。

### 3. RPC模拟交易
`eth_estimateGas`会RPC模拟一次交易，并返回Gas消耗多少，估算值会随状态变化而不精确。

### 4. Viem模拟交易
`publicClient.estimateGas`viem.js中对rpc方法的封装。

## 二. Gas优化

口诀：**合瞬妙无组，存小链多树**

### 1. 槽位合并
相邻的两个成员变量占用字节大小小于32字节时可以进行合并，减少占用storage永久存储来节省gas。
```
//共占用9字节，共用一个槽位
bool isAdmin;
uint40 time;
```

### 2. 瞬时存储
使用`transient`瞬时存储替代永久存储，TSTORE/TLOAD消耗100gas。

### 3. 常量与immutable
使用`constant/immutable`常量存储，仅会在部署合约时消耗一次。

### 4. 禁止无限增长数组
禁止使用无限制增长元素的数据，因为遍历时会消耗大量gas，直到gas超过限制会导致函数完全无法使用。  
考虑使用mapping代替数据。

### 5. 存储转移
将链上存储的数据转移到链下存储、ipfs存储，减少用户上传数据时消耗的gas。

### 6. 最小代理部署
先部署可复用的合约做逻辑，再用最小代理工厂部署代理合约，代理合约转发调用逻辑合约的逻辑。  
[最小代理工厂]({{<ref "docs/web3/solidity/7_合约创建/#四最小代理工厂">}})

### 7. 链表代替数组
（1）无序数组
```
# 定义链表
mapping(address=>address) private users;
mapping(address=>User) private userInfos;
# 定义起始点
address private constant HEAD = address(0);
```
- 新增  
在头部插入数据，更新HEAD指向当前地址。

- 删除（优化）
传入待删除元素的上一个元素，可以指定删除某个位置的元素达到O(1)的时间复杂度。

（2）有序数组
- 新增（优化）  
新增时需要保持数据有序性，可以链下遍历，然后传入上一个元素位置，则链上只需做校验和插入即可。

- 更新（优化）  
同时传入应该删除的上一个和应该插入的上一个元素，链上做校验、删除、新增。

- 查询（优化）  
查询时可以分阶段查询，避免数据过大导致查询失败。

### 8. multicall
在当前合约中需要调用本合约多个函数时，每一笔交易都需要支付一笔21000gas。可以通过一个函数封装来同时调用多个其他函数，以此来节约gas。  
注意需要使用**delegatecall**来保持上下文的状态和保持msg.sender不变。

[OpenZeppelin参考实现](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/cd05883078060e0cd8a7bd36636944570dbe1722/contracts/utils/Multicall.sol#L2)

### 9. MerkleTree
读者需要理解一下默克尔树原理。  
当需要在链上保存大量常量数据时，可以使用默克尔树，链上保存根节点哈希。  
当需要使用数据时，用户需要传入节点数据和证明过程，链上合约计算验证节点数据和证明过程结果是否等于保存的根节点哈希。  
如果验证通过，则说明用户的节点数据是正确的，可以继续进行下一步业务逻辑，否则拒绝。