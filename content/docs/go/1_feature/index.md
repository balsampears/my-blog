+++
date = '2026-04-16T19:00:00+08:00'
draft = false
title = 'Go语言特点'
description= 'Go语言的独特之处和注意事项'
weight = 10
+++

Golang是一个拥有接近c语言的运行速度和python语言的开发效率的语言。  
本篇文章不会介绍基础的语法以及语法细节，仅重点介绍go语言的与众不同的特点以及注意事项。

## 一. 指针

go中存在指针可以直接获取内存地址：
- &变量 是取地址符
- *指针变量 是读地址上的具体数据

**语法糖**
```
stu := &Student{}
stu.name
```
stu是指针变量，但却可以直接取内部的属性，是go进行语法糖包装，实际上是(*stu).name

## 二. 引用类型
引用类型只有三类：slice、map、channel，需要使用make()分配内存空间

### 1.值类型与引用类型对比
int、float、bool等大部分都是值类型；  
仅有slice、map、channel是引用类型；  
注意结构体是值类型，而不像java中是引用类型  

**注意**  
在函数传递数据时，特别注意传递的是值类型还是引用类型，如果是值类型（结构体）要使用指针

### 2.slice
数组与slice对比：
- 数组是值类型，定长不可更改，类似java的[]数组。
- slice是引用类型，不定长可扩容，通过make()方式创建。类似java的ArrayList。

### 3.map
```
# keyType、valueType代表数据类型
stuMap := make(map[keyType]valueType)
```


## 三.结构体
```
type Student struct {
    name string
    gender int
}
```
Go不是一款面向对象的语言，但面向对象的思想可以用struct结构体实现。

### 1.构造函数
```
func newStudent() *Student{
    stu := Student{}
    //todo
    return &stu
}
```
结构体没有构造函数，但是可以用一个单独函数去创建对象来充当构造函数

### 2.接收者方法（成员函数）
```
// 定义
func (stu *Student) DoHomework(){
    //do homework
}
// 使用
stu.DoHomework()
```
结构体没有成员函数，但是可以定义一个接收者方法，向结构体类型插入一个方法，类似于javascript中的object.prototype属性

### 3.继承
```
type Person struct{
    name string
}
type Student struct{
    no string
    Person
}
# 使用
stu:= Student{}
stu.name
```
匿名结构体的特点是可以将字段映射到外部，通过这个特点就可以实现父子级的继承

### 4.JSON序列化与反序列化
结构体与json字符串可以进行相互转化
```
type Student struct{
    name string `json:"名称"` 
    gender int `json:"性别"`
}

# 序列化
stu := Student{}
stuString, err = json.Marshal(stu)

# 反序列化
stuString = "{"名称":"xxx", "性别":1}"
stu := &Student{}
err = json.Ummarshal([]byte(str), stu)
```

## 四.流程控制
### 1. switch
switch中的case匹配执行后，不会继续执行下一个匹配的case（java中会继续向下执行代码直到遇到break）

### 2. select
类似与switch，但是用于channal
//todo


## 五. 函数

1. 可以有多个返回值
2. 可以将函数赋值给一个变量
```
var f func(int,int) int = add
```

### 1.闭包函数
```
func a() {
    var m int 
    func b (){
        //...
    }
    return b
}
c = a()
```
闭包函数是指有内外嵌套的函数，被外部引用时，嵌套函数的变量不会被内存回收。  
如a()内部嵌套b()，c引用了a内部的b，此时变量m不会被清除，会跟c的生命周期生命周期保持一致。



### 2.defer
`defer 语句` 是 延迟执行函数，在当前作用域return之前对语句进行调用，并遵循先进后出原则。
```
func f(){
    for i range 5{
        defer fmt.Println(i)
    }
}
// 输出 4，3，2，1，0
f()
```
在f函数结束前，调用打印函数，然后遵循先进后出原则倒序打印

**注意**  
若有 `defer entity.DoSomething(arg)`：
- entity是引用类型，则后续修改会影响最终结果
- arg是引用类型，则后续修改会影响最终结果
- defer闭包函数，则后续修改会影响最终结果

在 go 1.22版本更新中，循环变量每次都会重新赋值一块变量空间，则输出结果会不一样
```
type Student struct {
	name string
}

func (stu *Student) DoHomework(page int) {
	fmt.Println(stu.name, "做作业", page, "页")
}
func main() {
	stus := []Student{{"小明"}, {"小红"}, {"小军"}}
	for index, stu := range stus {
        // 1.22及之后，相当于添加了语句 stu:=stu，重新分配了空间
		defer stu.DoHomework(index)
	}
}
```
- 1.22之前：小军做三次作业
- 1.22及之后：小军、小红、小明分别做了作业

## 六.异常

### 1. panic
panic类似与java中的RuntimeException，运行时异常，通常不需要显示处理。  
但是为了避免报错可以用类似try catch结构避免程序抛错终止。

**抛出**  
`panic('这是一个异常')`

**recover**  
recover可以捕获panic
```
defer func {
    if err := recover(); err != nil{
        fmt.Println(err)
    }
}()
```

### 2.error
error类似于java中的Exception，编译时异常，通常需要显示处理。

**抛出**
```
err = errors.New('这是一个异常')
return value, err
```


## 七.接口
接口是定义了一组需要实现的方法。在go中没有显式继承，只要struct拥有了接口中的一样方法，编译器就认为该struct实现了接口。

### 1.接口的作用：多态
```
type Mover interface{
    Move()
}
type Person struct{}
func (p Person) Move(){
}

func main{
    var m Mover = Person{}  //类似java中的多台
    m.Move()
}
```

### 2.不同接收者实现接口的区别
值类型接收者可以用两种参数，指针类型接收者只能用指针。
```
func (p *Person) Move(){
}
var m Mover = &Person{} //可以
var m2 Mover = Person{} //编译报错，但是如果Move是值类型则可以编译通过
```

### 3.空接口
空接口可以用来接收所有数据类型，类似java中的Object  
`var person interface{}`

### 4.类型判断和强制转换
可以用`x.(Type)`判断空接口的数据类型与强制类型转换
```
var i interface{}
value, ok = i.(int)
```