+++
date = '2026-04-10T20:00:00+08:00'
draft = true
title = 'Solidity总结'
description = 'Soidity各种特点总结'
weight = 100
+++

## 成员变量修饰词对比
- storage  
  永久保存在链上的变量，不加transient就是默认storage。gas成本很高。  
- transient  
  临时保存在本地的变量，仅一次交易有效，交易完成后丢弃。gas成本较低。
- constant  
  常量，声明时需要赋值。gas成本最低。  
- immutable  
  常量，声明时可不赋值而改为在构造函数中赋值。gas成本最低。