+++
date = '2026-04-29T20:00:00+08:00'
draft = false
title = '并发编程'
description= '协程的应用'
weight = 20
+++

## 一. 简介
### 1.进程、线程、协程
- 进程 操作系统级别，CPU操作和内存调度的单位。
- 线程 进程的执行实体，CPU操作的最小单位。
- 协程 线程的更小一层执行实体，拥有独立的栈空间和共享的堆空间。

### 2.并发、并行
- 并发 不同的任务，在一个CPU上，分时间段执行。
- 并行 不同的任务，在不同CPU上，同时执行。
  
## 二. goroutine
goroutine是go中协程，最小占用4~5KB栈空间，并且创建和销毁成本大幅降低，这是go实现高并发的基础。
```
go funcXXX()
```

### 共享变量
goroutine通过通信来共享内存，而不是加锁来共享内存。

### GPM
GPM是go实现的一套调度机制
- G 指 Goroutine，go协程
- P 指 逻辑处理器，负责将Goroutine任务都分派到不同的M
- M 指 Machine，操作系统线程，Go程序执行需要映射到对应的M上。  

#### 运作流程
- 一个G被创建时会进入本地队列或全局队列。  
- 然后调度器在P在队列中取出G，并在P绑定的M上执行G。  
- 当G执行完成时，调度器会从队列中取出下一个G继续在相同的M执行。  
- 当G被阻塞时，有两种情况。第一种是通道/锁用户态阻塞，P与M不解绑，而是将G挂起，取出下一个G继续执行。第二种是系统级阻塞，P与M解绑，M持续阻塞，调度器重新给P分配一个新的M，然后再执行下一个G。当阻塞的M释放后，会尝试绑定一个新的P。  

#### 对应关系
同一时刻下P与M是一对一关系。  
当某个G阻塞时，P会重新创建个M并将其余的G迁移过去。当阻塞的G完成或终止时，旧的M会被回收。
G与M是多对多关系（M:N)
多个G可以在一个M上执行。G阻塞入队列时，可以被不同的M取走。


### 常用函数
#### runtime.Gosched()
让出当前占用内存给其他协程
#### runtime.Goexit()
终止当前协程
#### runtime.GOMAXPROCS
使用的CPU最大内核，默认对应当前系统的CPU核心数

## 三. channel
channel是用于goroutine传输数据的通道

### 1. 创建
```
var 变量 chan 数据类型 //指定这个chan可以传输什么数据类型
变量 = make(chan 数据类型, [容量]) //创建之后需要使用make分配内存，同时可以指定channel最多容纳多少条数据
```

### 2.操作
channel操作可以分为：发送、接收、关闭
```
c := make(chan int)
```

#### 发送
```
c <- 1 #发送1到c的channel
```

#### 接收
```
m := <- c #接收c传输的数据
```

#### 关闭
```
close(m)
```

### 3.无缓冲/有缓冲通道
#### 无缓冲通道
```
c := make(chan int)
```
没有指定容量的，就是无缓冲通道，特点是必须先指定接收者，才能发送数据

#### 有缓冲通道
```
c := make(chan int, 3) //缓冲容量为3
```
有指定容量的，就是有缓冲通道，特点是会发生阻塞。
- 接收方，如果chan是nil或空，则会阻塞
- 发送方，如果chan是nil或满了，则会阻塞

### 4.接收的方法
#### 判断结果
```
m, ok := <- c //如果c已经close，则ok=false
```

#### 使用for range
```
for m := range <- c { //如果c已经close，则会退出for range循环
    //...
}
```

### 5.单向通道
指定通道只能作为发送方/接收方，通常用在方法的形参进行限制。
```
func a(out <-chan int, in chan<- int) // out是接收方的通道，in是发送方的通道
```

### 6.select
select是用于channel的条件分支语句，只要其中一个channal运行成功，则执行对应的case。
```
select {
    case <- chan1:
        //如果chan1接收数据成功，则运行这里
    case chan2 <- 1:
        //如果chan2写入数据成功，则运行这里
    default:
        //都没有成功， 则运行这里
}
```
- 有default，当所有case阻塞，立刻运行default中的代码
- 没有default，这段代码会永久阻塞，直到某个case就绪

## 四. 锁
当不同goroutine同时对同一个变量进行修改时，就需要上锁和解锁，只有获得锁的goroutine才能修改变量。  
用法类似java的ReentrantLock可重入锁。

### 1. 互斥锁
只有获得锁的goroutine才能运行中间的代码
```
var lock sync.Mutex
lock.Lock() //上锁
...
lock.Unlock() //解锁
```

### 2. 读写锁
读写锁分为读锁和写锁，读锁可以被多个goroutine获取，写锁是个互斥锁
```
var lock sync.RWMutex
lock.Lock()     //上写锁
lock.Unlock()   //解写锁
lock.RLock()    //上读锁
lock.RUnlock()  //解读锁
```

## 五. Sync
Sync提供了很多并发控制的类库。

### 1. sync.WaitGroup
通过WaitGroup可以实现：所有任务完成后再执行某些代码/结束。  
waitGroup内部维护计数器，计数器可以增加和减少。
```
var wg sync.WaitGroup
wg.Add(数字)    # 计数器增加/减少
wg.Done()       # 计数器减少1
wg.Wait()       # 等待计数器归零才往后执行
```

### 2. sync.Once
并发场景下，只运行一次某代码。  
Once内部采用了互斥锁和布尔值。  
```
var one sync.Once
one.Do(f)  # f 是 func (){} 格式函数
```

### 3. sync.Map
并发情况下使用的Map，类似java的ConcurrentHashMap
```
var m sync.Map{}
m.Store(key, value)
m.Load(key)
m.LoadOrStore(key, value)
m.Delete(key)
m.Range(func(key, value interface{}) bool {
    fmt.Println(key, value)
    return true
})
```
适用于以下情况：
1. 读多写少
2. goruntine读写key不相交

## 六. atomic
原子性操作基本数据类型，类似java中的Atomic包
### 方式一（推荐）
声明原子变量
```
var count atomic.Int32
count.Load()
count.Store(value)
```

### 方式二
自行定义一个变量，然后将变量的指针传进atomic中的函数来操作。
```
atomic.LoadInt32(addr)
atomic.StoreInt32(addr, value)
```