+++
date = '2026-04-29T20:00:00+08:00'
draft = true
title = 'Gin框架'
description= 'Gin是最流行的http web框架'
weight = 40
+++

## 一. 安装和启动

### 1. 安装Gin
```
go mod init <项目名>
go get -u github.com/gin-gonic/gin
```

### 2. 启动Web服务
添加main.go:
```
func main(){
    r := gin.Default()
    // 定义一个接口
    r.GET('/', func(c *gin.Context){
        c.String(http.StatusOK, "Hello Gin")
    })
    // 启动项目，默认8080端口
    r.Run()
}
```

## 二. 接口请求与响应

### 1. Restful风格接口
```
r.GET(...)
r.POST(...)
r.PUT(...)
r.DELETE(...)
```

### 2. 请求参数
```
# （1）Query入参
r.GET('/get', func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})

# （2）路径入参
r.GET('/get2/:name', func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})
# 路径入参有两种写法，:name和*name，*name写法获取的值会带个/

# （3）表单入参
r.POST('/post', func(c *gin.Context){
    name := c.PostForm("name")
    c.String(http.StatusOK, "Hello Gin")
})

# （4）表单json入参
type Article struct{
    Title string `json:title`
    Content string `json:content`
}
r.POST('/post', func(c *gin.Context){
    var art Article
    if err:= c.ShouldBindJSON(&art); err!= nil{
        c.String(http.StatusOK, "Hello Gin")
    }
})
# 普通表单可以用ShouldBindQuery，xml可以用ShouldBindXML

# （5）文件入参
r.POST('/post', func(c *gin.Context){
    file, err := c.FormFile("file")
    if err == nil {
        c.SaveUploadFile(file, file.Filename) //保存文件到当前目录下
        c.String(http.StatusOK, "Hello Gin")
    }
})


```

### 3. 响应参数

```
# 字符串响应
c.String(http.StatusOK, "Hello Gin")
c.String(http.StatusOK, "This is %v", name)

# json响应
c.JSON(http.StatusOK, gin.H{
    "name": "Xiaoming"
})
# gin.H 等效于 map[string]interface

# json对象响应
# 传入对象指针即可
art := &Article{
    Title: '',
    Content: ''
}
c.JSON(http.StatusOK, art)
```

### 4. 路由分组
将接口路由进行分组，路由组等效于java类上的@RequestMapping
```
apiRouter := r.Group('/api'){
    apiRouter.GET('/get', ...)
    apiRouter.POST('/post', ...)
}
```
可以将不同的路由组分到目录/routers/不同的文件中，实现对路由的分组分文件管理。

## 三. 中间件
### 1. 路由中间件
```
# 最后一个方法之前都算中间件
r.GET('/get', routerMiddle, func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})
func routerMiddle(c *gin.Context){
    //执行当前中间件方法
    c.Next() //执行后面的中间件和路由方法
    //执行完之前后再向下执行
}
```
c.Next()类似java中AOP变成的Around通知
