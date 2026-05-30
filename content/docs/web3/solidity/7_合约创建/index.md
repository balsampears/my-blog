+++
date = '2026-05-13T20:00:00+08:00'
draft = false
title = '合约创建'
description = '合约创建，可以合约工厂统一管理和创建合约'
tags = ['solidity', '教程']
weight = 70
+++

合约创建后返回的合约地址并不是随机的，接下来我们来了解如何获得确定性的合约地址。  

## 一.create
EVM操作码create，采用账户nonce创建合约。  

### 1.地址计算方式
创建合约的账户地址和交易记录计算获得hash，取后20个字节
`keccak256(rlp.encode([user address], [user nonce]))[12:]`

### 2.代码实现
- solidity
`ERC20 erc20 = new ERC20()`
- foundry
`forge create xxx.sol:xxx`

### 3.创建合约的账户
EOA账户和合约账号创建合约时有一些区别
- EOA账户
EOA的nonce每发生一笔交易则会增加一次。  
- 合约账户
合约账户的nonce每创建一个合约会增加一次。

### 4.优缺点
- 优点：gas消耗最低
- 缺点：create是solidity最基础的创建合约方式，很难控制合约地址。

## 二.create2 - 合约工厂
EVM操作码create2，采用加盐salt创建合约。  
通过合约工厂加盐创建合约，可以保证合约的地址的确定性。

### 1.地址计算方式
账户+盐+目标合约部署字节码
`keccak256(0xff + sender + salt + keccak256(init_code))`

### 2.代码实现
创建一个合约工厂，通过合约工厂来创建目标合约。
```
contract Factory{
    function create2Animal(uint _salt) public returns (address) {
        return address(new Animal{salt: _salt}()); //Animal是目标合约
    }
}
```

### 3.优缺点
- 优点：不受账户nonce影响  
- 缺点：目标合约的内容不能修改，当目标合约代码修改后，字节码变动，则最终获得的地址也会发生变动。

## 三.create3 - 合约工厂+部署器
为了防止目标合约代码变动导致最终合约地址发生变动，采用合约工厂+部署器方案。  
- 合约工厂：create2创建部署器，部署器代码固定，那么生成的合约地址只受salt影响。
- 部署器：create创建目标合约，一次性合约nonce总是0，生成的合约地址只受自身地址影响。

### 1.地址计算方式
通过create2计算部署器地址 -> 通过create计算目标地址

### 2.代码实现
参考：https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol

### 3.优缺点
优点：不受账户nonce影响、不受目标合约代码变动影响  
缺点：gas消耗最大

## 四.最小代理工厂
当一个合约经常被重复部署和使用时（例如ERC20），会浪费大量的gas，这时可以考虑使用最小代理工厂方式来避免重复部署。  

### 1.代理合约
{{< figure src="proxy.png" width="500" >}}
将一个合约拆分为代理合约和逻辑合约，代理合约负责保存数据和转发逻辑，逻辑合约负责具体实现。  
核心是使用delegatecall，使用当前合约的上下文，来执行目标合约的逻辑。

### 2.最小代理工厂
{{< figure src="miniProxy.png" width="700" >}}
EIP1167约定，工厂负责生成代理合约，代理合约指向相同的逻辑合约。  
举例：ERC20Facotry创建代理合约代币A、代理合约代币B，A和B都同时指向同一个ERC20的具体实现。

### 3.代码实现
```
function _createClone(address prototype) internal returns (address proxy) {
    bytes20 targetBytes = bytes20(prototype);
    assembly {
        let clone := mload(0x40)
        mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
        mstore(add(clone, 0x14), targetBytes)
        mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
        )
        proxy := create(0, clone, 0x37)
    }
    return proxy;
}
```

### 4.注意事项
逻辑合约的构造函数只会运行一次，但是代理合约会重复部署多次，所以逻辑合约不能使用构造函数进行数据初始化，而是添加一个普通的初始化函数给外部调用。

### 5.提案
- [EIP1167](https://eips.ethereum.org/EIPS/eip-1167)
