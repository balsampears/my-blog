+++
date = '2026-05-16T20:00:00+08:00'
draft = false
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
#### （1）Query入参
```
r.GET("/get", func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})
```

#### （2）路径入参
```
r.GET('/get2/:name', func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})
```
路径入参有两种写法，:name和*name，*name写法获取的值会带个/

#### （3）表单入参
```
r.POST("/post", func(c *gin.Context){
    name := c.PostForm("name")
    c.String(http.StatusOK, "Hello Gin")
})
```

#### （4）表单json入参
```
type Article struct{
    Title string `json:title`
    Content string `json:content`
}
r.POST("/post", func(c *gin.Context){
    var art Article
    if err:= c.ShouldBindJSON(&art); err!= nil{
        c.String(http.StatusOK, "Hello Gin")
    }
})
```
普通表单可以用ShouldBindQuery，xml可以用ShouldBindXML

#### （5）文件上传
```
r.POST("/upload", func(c *gin.Context) {
    file, err := c.FormFile("file")
    if err == nil {
        filepath := path.Join("./static/upload", file.Filename)
        c.SaveUploadedFile(file, filepath) //保存文件到对应目录下
        c.String(http.StatusOK, "Hello Gin")
    }
})

```

### 3. 响应参数

#### （1）字符串响应
```
c.String(http.StatusOK, "Hello Gin")
c.String(http.StatusOK, "This is %v", name)
```

#### （2）json响应
```
c.JSON(http.StatusOK, gin.H{
    "name": "Xiaoming"
})
```
gin.H 等效于 map[string]interface

#### （3）json结构体响应
```
# 传入结构体指针即可
art := &Article{
    Title: '',
    Content: ''
}
c.JSON(http.StatusOK, art)
```

### 4. 路由分组
将接口路由进行分组，路由组等效于java类上的@RequestMapping
```
apiRouter := r.Group("/api"){
    apiRouter.GET("/get", ...)
    apiRouter.POST("/post", ...)
}
```
可以将不同的路由组分到目录/routers/不同的文件中，实现对路由的分组分文件管理。

## 三. 中间件
中间件是请求接口时对参数进行预处理功能，类似java中的过滤器和拦截器。  
### 1.全局与局部中间件
（1）全局中间件
```
func routerMiddleware(c *gin.Context){}
r.Use(routerMiddleware)
```
（2）局部中间件
```
r.GET("/get", routerMiddleware, ...)
```
（3）路由组中间件
```
apiRouter := r.Group("/api"){
    apiRouter.Use(routerMiddleware)
}
```

可以使用多个中间件叠加，洋葱模型一层层展开调用。

### 2. 常见的中间件方法
（1）c.Next
```
# 最后一个方法之前都算中间件
r.GET("/get", routerMiddleware, func(c *gin.Context){
    name := c.Query("name")
    c.String(http.StatusOK, "Hello Gin")
})
func routerMiddleware(c *gin.Context){
    //执行当前中间件方法
    c.Next() //执行后面的调用链方法
    //执行完之前后再向下执行
}
```
c.Next()类似java中AOP变成的Around通知

（2）c.Abort
```
c.Abort() //不会执行之后的调用链
c.AbortWithStatusJSON(错误码, 返回值) //不会执行之后的调用链并返回结果
```

### 3. 默认中间件
`r := gin.Default()`默认加载了Logger和Recovery中间件，用于日志记录和错误恢复。  
`r := gin.New()`可以创建一个空的上下文。

### 4. 中间件使用goroutine
```
cCp := c.Copy()
go func(){
    //对上下文进行操作
}()
```
协程中不要直接使用c *gin.Context上下文对象，当前中间件的上下文使用完后会分配给下一个中间件，如果此时协程持有上下文则会引发并发问题。  
协程中使用上下文需要c.Copy()使用上下文的副本。


### 5. Cookie与Session

#### （1）Cookie
```
# 设置cookie
c.SetCookie(名称，值， 过期时间单位秒， 路径， 域名， 是否仅https， 是否禁用js获取)
# 过期时间设置-1代表删除

# 获取cookie
cookie, res = c.Cookie(名称)
```

#### （2）Session
session需要使用另一个依赖库：https://github.com/gin-contrib/sessions

```
# 初始化
session := sessions.Default(c)
# 设置
session.Set(名称，值)
session.Save()
# 获取
session.Get(名称)
```