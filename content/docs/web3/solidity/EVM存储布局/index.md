+++
date = '2026-05-12T20:00:00+08:00'
draft = false
title = 'EVM存储布局'
description = '智能合约在EVM数据的存储方式，熟悉后对理解Gas优化和合约安全有所帮助'
weight = 40
+++

## 一. 空间资源
EVM对空间应用可以视为键值对数据库，读写一次都是以256字节为单位。  
EVM中空间资源划分为四类，有不同的特点和gas消耗。  

### 1. 永久存储
变量会永久保存在链上，使用方式是成员变量的默认值或storage。  
初始化数据、冷数据启动(第一次交易)、更新数据都需要消耗大量的gas（分别是20000， 2100， 5000）。

EVM操作码
- SSTORE(slot, value) 存储
- SLOAD(slot) 加载  
slot指槽位，后续解释。上面两个操作码gas消耗100。

### 2. 瞬时存储
仅在一个交易中保存的数据，交易完成后变量会被丢弃，在成员变量前添加transient。
gas消耗大幅降低。  
通常会在防重入锁中用到，可以节约gas消耗。

EVM操作码
- TSTORE(slot, value) 存储
- TLOAD(slot) 加载  
上面两个操作码gas消耗100。

### 3. 内存
函数传参、返回值、内部变量等等都需要用到内存。  
通常会在内联汇编（assembly）中用到。

EVM操作码
- MSTORE(index, value) 存储
- MLOAD(index) 加载  
上面两个操作码gas消耗3。

内联汇编示例
```
let result := add(x, y)
mstore(0x0, result)
return(0x0, 32)
```

### 4. 栈
EVM自动进行管理。


## 二. 存储布局

### 1. 槽位Slot
合约的不同数据类型的成员变量，最终会转换为在链上占用一定空间的槽位。  
槽位从0开始，依次递增，每个槽位占用32字节。  

**槽位合并**
变量和槽位的关系不是一对一，而是多对一。当相邻两个或多个变量的数据类型字节小于等于32字节时，会合并并保存到同一个槽位上。  
举例：存在两个uint8 a, uint8 b，两者合并到槽位0。a在偏移0xFF位置，b在偏移0xFF00位置。
```
内联汇编取值
a := and 0xFF(sload 0x0)
b := and 0xFF00(sload 0x0)
```

### 2. 定长存储
整型、布尔型、地址型等固定长度都是定长存储。

### 3. 不定长存储
#### （1）数组
数组元素在存储空间中总是连续存储的。
- 定长数组
直接保存数组所有元素。  
举例：uint[2] arr; 元素0、1分别占用slot 0、 slot 1。

- 不定长数组
数组当前slot保存数组长度，数组元素起始位置通过keccak256(slot)计算，后续元素向后排列。  
举例：uint[] arr; arr具有3个元素，arr本身slot 0 保存3（数组长度）。
arr[0]位于keccak256(0)，arr[1]位于keccak256(0)+1，依次类推。

#### （2）mapping
mapping与数组最大的区别是mapping是离散存储的。  
mapping的key不保存，value槽位计算是keccak256(abi.encode(key, mapping slot))  
举例：mapping(uint=>uint) wallets，其中wallets在slot 0。  
那么key=0，value槽位在keccak256(abi.encode(0, 0x0))

#### （3）string/bytes
string/bytes属于紧凑型的数组。
- 当占用字节小于等于31时
直接在当前槽位保存数据，并在最后一个字节保存数组长度。

- 当占用字节大于31时
跟正常数组一致，当前位置保存数组长度，起始元素通过keccak256(slot)计算。


### 4. 查询存储布局
- foundry  
forge inspect \<ContractName\> storageLayout
- rpc  
eth_getStorageAt
- viem  
publicClient.getStorageAt
- solidity
```
assembly{
    value:=sload(slot)
}
```
