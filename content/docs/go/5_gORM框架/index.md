+++
date = '2026-05-22T20:00:00+08:00'
draft = false
title = 'gORM框架'
description= 'Gin是最流行的http web框架'
weight = 50
+++

## 一. 连接数据库
### 1. 引入gORM
```
import (
    "gorm.io/driver/mysql"
	"gorm.io/gorm"
)
```
引入gorm，并用`go mod tidy`安装

### 2. 连接数据库
```
dsn := "root:root@tcp(127.0.0.1:3307)/test_db?charset=utf8mb4&parseTime=True&loc=Local"
db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
```
**配置表名策略**
默认表名是下划线式+表名复数，通过以下方式可以将表名复数去除。
```
&gorm.Config{
    NamingStrategy: schema.NamingStrategy{
        SingularTable: true, //禁用表名复数形式
    },
}
```

## 二. 定义实体
```
type SysUser struct {
	UserId      uint   `gorm:"primaryKey"` # 默认主键列名是Id
	OrgId       uint
	UserName    string
}
```

### 1. 自定义表名
```
func (SysUser) TableName() string {
    return "sys_user"
}
```
默认表名是下划线式+表名复数，只要实现`TableName() string`接口即可覆盖。

### 2. 默认模型
gorm提供了默认模型给用户模型继承。
```
gorm.Model
type Model struct {
  ID        uint           `gorm:"primaryKey"`
  CreatedAt time.Time
  UpdatedAt time.Time
  DeletedAt gorm.DeletedAt `gorm:"index"` # 软删除
}
```

### 3. 注意事项
- 字段名需要首字母大写，数据库表名下划线式会对应go模型的大写驼峰式

## 三. 增删改查
gorm对sql操作有两种写法：泛型API和传统API。泛型API可以在编译器就检查出错误，下面主要以泛型API写法为主。

### 1. 泛型API增删改查

```
# 以下的SysUser为业务表名
ctx := context.Background()
# 查所有
users, err := gorm.G[SysUser](db).Find(ctx)
# 查单个
user, err := gorm.G[SysUser](db).Where("id = ?", 1).First(ctx)
# 新增
err := gorm.G[SysUser](db).Create(ctx, &user)
# 更新
rows, err := gorm.G[SysUser](db).Where("id = ?", 1).Updates(ctx, &users)
# 删除
row, err := gorm.G[SysUser](db).Where("id = ?", 1).Delete(ctx)
```

### 2. 原生Sql
```
# 查询
users, err := gorm.G[SysUser](db).Raw("select * from sys_user").Find(ctx)
# 执行
err := gorm.G[SysUser](db).Exec(ctx, "update sys_user set user_name=? where id=?", newName, id)
```

## 四. 关联关系与级联
可以通过标签将关联关系标记出来，进行级联查询。

### 1. 多对一/一对一
一个学生属于一个学校，一个学校有多个学生。

```
# 定义
type Student struct{
    Id uint
    Name string
    SchoolId uint
    School School `gorm:"foreignKey:SchoolId;reference:Id"` #指定外键，student.schoolId映射school.id
}
type School struct{
    Id uint
    Name string
}
# 查询
db.Model(&Student{}).Preload("School").Find(&stus)
```

### 2. 一对多
```
# 定义
type Student struct{
    Id uint
    Name string
    SchoolId uint
}
type School struct{
    Id uint
    Name string
    Students []Student `gorm:"foreignKey:SchoolId"` #指定外键
}
# 查询
db.Model(&School{}).Preload("Student").Find(&schools)
```

### 3. 多对多
多对多关系的级联查询对数据库查询开销很大，一般不使用，实在需要用到时再查官方文档即可。

## 五. 安全
### 1. Sql注入
防止sql注入有以下几点需要注意。
- 1. 使用占位符传值，不直接拼接sql
- 2. 查询表名、列名等无法使用占用符情况，使用白名单完整匹配后查询
- 3. 数据值是数字类型，传入字符串必须使用`strconv.Atoi`转为整数型