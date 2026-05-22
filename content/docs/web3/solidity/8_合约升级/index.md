+++
date = '2026-05-13T13:00:00+08:00'
draft = false
title = '合约升级'
description= '合约升级，将存储和逻辑进行分离，支持开发者对合约进行修复和增强'
weight = 80
+++

实际合约开发过程中，经常会遇到合约代码的功能升级和问题修复的需求，此时就需要做合约升级。

**注意**
合约升级并不代表链上数据可篡改，合约升级仅支持对合约代码逻辑的修复和增强。


## 一. 升级 - 代理模式
业务合约拆分为代理合约和逻辑合约，代理合约负责保存用户数据和映射逻辑，逻辑合约负责逻辑计算。  
核心是使用delegatecall，使用当前合约的上下文，来执行目标合约的逻辑。

实现代码参考：
```
contract Animal{
    //逻辑合约
    address private impl; 
    //升级逻辑合约
    function updateTo(address newImpl) public{
        impl = newImpl;
    }
    function eat(){
        bytes memory data = abi.encodeWithSignature("eat()");
        (bool success, ) = impl.delegatecall(data);
        require(success, "delegatecall fail");
    }
    function run(){
        bytes memory data = abi.encodeWithSignature("run()");
        (bool success, ) = impl.delegatecall(data);
        require(success, "delegatecall fail");
    }
    ...
}

contract Cat{
    function eat(){}
    function run(){}
}
```

- 新的问题
1. 每个实现函数都需要在代理合约中实现一遍，代码耦合度非常高。同时逻辑合约升级有新的方法，代理合约却无法添加新方法。
2. 代理合约跟逻辑合约的成员变量顺序必须一致，否则会出现变量混乱问题。

## 二. 升级 - 统一委托
在代理合约中，将除了updateTo之外，所有的函数包括fallback和receive全部都映射到逻辑合约。

实现代码参考：
```
contract Animal{
    //逻辑合约
    address private impl; 
    //升级逻辑合约
    function updateTo(address newImpl) public{
        impl = newImpl;
    }
    //统一处理
    fallback() external {
        _delegate(impl);
    }
    receive() external {
        _delegate(impl);
    }

    //核心转发逻辑
    function _delegate(address _implementation) internal virtual {
        assembly {
            // 1. 复制调用数据
            calldatacopy(0, 0, calldatasize())
            
            // 2. 执行 delegatecall
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            
            // 3. 复制返回数据
            returndatacopy(0, 0, returndatasize())
            
            // 4. 根据结果返回或还原
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

contract Cat{
    function eat(){}
    function run(){}
}
```

- 新的问题
当逻辑合约出现跟代理合约一样的updateTo(address)的函数选择器时，则逻辑合约的对应函数不会正常运作。

## 三. 升级 - 最终升级
为了解决函数选择器在代理合约和逻辑合约冲突的问题，有几种不同的处理方案。

### 1. UUPS（通用升级代理）
代理合约不再负责updateTo函数实现，改为由逻辑合约进行实现。

#### OpenZeppelin实现
```
// 逻辑合约继承升级方法
contract Cat is UUPSUpgradeable{
    ...
}
// 部署
address animalProxy = Upgrades.deployUUPSProxy(<合约>, <合约初始化函数>, <配置>);
// 升级
Upgrades.upgradeProxy(animalProxy, <合约>, <升级合同初始化函数>, <配置>);
```

**缺点**
每次升级合约都需要实现updateTo函数，部署gas消耗会增大。

### 2. 透明代理
updateTo函数改为internal，然后在fallback中判断如果当前是admin则直接调用updateTo方法，否则正常委托调用。

#### OpenZeppelin实现
```
// 部署
address animalProxy = Upgrades.deployTransparentProxy(<合约>, <admin地址>,<合约初始化函数>, <配置>);
// 升级
Upgrades.upgradeProxy(animalProxy, <合约>, <升级合同初始化函数>, <配置>);
```

**缺点**
每次调用函数都需要判断一下admin，运行gas消耗会增大。

### 3. 信标代理
适用于最小代理工厂创建的合约，信标合约负责保存和管理逻辑合约地址，最小代理工厂（信标代理合约）通过信标合约获取逻辑合约地址。
{{< figure src="beacon.png" width="700" >}}

#### OpenZeppelin实现
```
// 部署
address admin = vm.addr(privateKey);
address beacon = Upgrades.deployBeacon("12_miniProxyFactory.sol:ERC20Impl", admin, opts); 
bytes memory data = abi.encodeCall(ERC20Impl.initialize, ("MyERC20", "MY", 100 * 10**18, 10**18, admin));
address tokenProxy = Upgrades.deployBeaconProxy(beacon, data);

// 升级
Upgrades.upgradeProxy(tokenProxy, <合约>, <升级合同初始化函数>, <配置>);
```

### 4. 钻石代理
todo