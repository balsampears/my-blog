+++
date = '2026-06-26T19:00:00+08:00'
draft = false
title = 'MCP组成原理'
description= 'MCP是模型上下文协议，用于大模型跟业务服务进行约定通信的协议'
tags = ['ai', '理论']
weight = 10
+++

## 一. MCP概述
Model Context Protocol，模型上下文协议。  
MCP 协议约定了大模型与外部工具/数据之间的调用格式，使两者解耦，便于独立开发业务服务，并在不同 AI 客户端中复用同一套 MCP Server。

### 1. 组成部分
- **MCP Host（AI客户端）**：嵌入 LLM 的应用程序（如 Cursor、Claude Desktop），负责与用户交互、调度大模型，并管理 MCP Client。
- **MCP Client**：运行在 Host 内的连接器，通常与一个 MCP Server 一一对应，负责协议握手与 JSON-RPC 调用。
- **MCP Server**：对外提供 Tools、Resources、Prompts 等能力的服务端进程。

### 2. 交互流程
1. 用户在 Host 中发起问题
2. Host 调用 LLM，判断是否需要调用某个 MCP Tool
3. Host 内的 MCP Client 向 MCP Server 发起调用
4. MCP Server 执行逻辑并返回结果
5. Host 将结果交回 LLM，整理后输出回答

下一篇将介绍如何在 Cursor 等 Host 中配置并使用 MCP 服务。

## 二. MCP分层
### 1. 传输层
传输层负责 MCP Client 与 MCP Server 之间的通信连接管理，目前主要有 stdio、Streamable HTTP 两种方式。

#### （1）Stdio 
Stdio 即标准输入/输出方式，常用于本地开发。  
Host 内的 MCP Client 将 MCP Server 作为子进程启动，向 Server 的 stdin 写入请求，从 stdout 读取响应。此方式不涉及 HTTP 或 SSE。

#### （2）HTTP+SSE（已废弃，不推荐）
早期（协议版本 2024-11-05）采用 HTTP+SSE 传输，现已由 Streamable HTTP 取代。  
该方式需要两个 HTTP 入口：一个 SSE 长连接endpoint（如 `/sse`）接收服务端推送，一个 POST 端点（如 `/message`）发送客户端消息。  
缺陷在于服务端需为每个客户端维持长连接，占用更多内存，高并发场景下开销较大，部署配置也更复杂。

#### （3）Streamable HTTP（推荐）
采用统一入口（如 `/mcp`），MCP Client 与 MCP Server 通过 HTTP 通信。  
每次请求可按需选择：直接返回 `application/json`，或使用 `text/event-stream` 进行 SSE 流式传输。  
无需固定维持长连接，系统开销更低，配置也更简单。

#### （4）SSE 补充说明
SSE（Server-Sent Events）是一种基于 HTTP 的流式传输机制，响应头为 `Content-Type: text/event-stream`，服务端可持续向客户端单向推送数据。

报文由若干字段组成，常见如下：
```
event: message        // 事件类型名，可由应用自行定义
data: {"key":"value"} // 数据内容
id: 1                 // 事件 ID，用于断线重连
```

若未指定 `event` 字段，浏览器默认按 `message` 事件处理。

>旧版 HTTP+SSE 传输中，约定使用以下事件名

- `endpoint`：连接建立后首个事件，携带客户端发送消息所用的 POST 地址
- `message`：服务端下发的 JSON-RPC 消息，内容在 `data` 字段中

>新版 Streamable HTTP 传输时

SSE 同样通过 `data` 字段承载 JSON-RPC 消息，按需开启流式传输。

### 2. 数据层
MCP 数据层采用 JSON-RPC 2.0 协议，强制以 JSON 格式进行请求与响应。

#### （1）请求格式
以下为 JSON-RPC 通用格式示例；MCP 的 `method` 有固定命名约定（如 `initialize`、`tools/list`）：
```
{
  "jsonrpc": "2.0",
  "method": "add",
  "params": [2, 3],
  "id": 1
}
```
- jsonrpc：JSON-RPC 协议版本
- method：请求目标方法
- params：请求参数
- id：请求唯一标识（notification 类型无此字段）

#### （2）响应格式
```
{
  "jsonrpc": "2.0",
  "result": 5,
  "id": 1
}
```
- jsonrpc：JSON-RPC 协议版本
- result：响应结果
- id：与请求 id 对应

#### （3）错误响应格式
```
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found"
  },
  "id": 1
}
```

#### （4）JSON-RPC 与 RESTful 对比
JSON-RPC：
1. 本地调用、远程调用都常使用
2. 不依赖 URL 路径，可配置单一入口，通过 `method` 字段区分接口
3. 强制要求 JSON 格式

RESTful：
1. 常用于 HTTP 远程调用
2. 通过 URL 路径区分接口
3. 依赖 HTTP 方法（GET、POST、PUT、DELETE、OPTIONS）
4. 可传输 JSON、XML 等多种格式


## 三. MCP请求流程与核心功能
MCP 核心能力分为 Tools、Resources、Prompts。  
完整流程为：建立连接 → 初始化握手 → 按能力调用对应接口。

### 1. 初始化
MCP Client 与 MCP Server 建立传输连接后，须先完成初始化握手，之后才能调用其他接口。

（1）Client 发送 initialize 请求
```
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2025-06-18",
    "capabilities": {
      "elicitation": {}
    },
    "clientInfo": {
      "name": "example-client",
      "version": "1.0.0"
    }
  }
}
```

（2）Server 返回 InitializeResult
```
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2025-06-18",
    "capabilities": {
      "tools": {
        "listChanged": true
      },
      "resources": {
        "subscribe": true,
        "listChanged": true
      },
      "prompts": {
        "listChanged": true
      }
    },
    "serverInfo": {
      "name": "example-server",
      "version": "1.0.0"
    }
  }
}
```
后续 Tools、Resources、Prompts 是否可用，取决于此响应中 `capabilities` 的声明。

（3）Client 发送 initialized 通知
此为 notification（无 `id` 字段），服务端不返回 result：
```
{
  "jsonrpc": "2.0",
  "method": "notifications/initialized"
}
```
收到此通知后，双方初始化完成，可开始正常通信。

### 2. Tools 工具（主要）
Tool 代表 MCP Server 可提供的可调用服务。仅当服务端在 initialize 响应的 `capabilities` 中声明支持 `tools` 时，方可使用。

#### （1）查询工具列表
```
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}
```

#### （2）调用工具
```
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "weather_current",
    "arguments": {
      "location": "San Francisco",
      "units": "imperial"
    }
  }
}
```

### 3. Resources 资源
Resource 提供 AI 可读取的数据源（如文件、数据库记录）。仅当服务端在 initialize 响应的 `capabilities` 中声明支持 `resources` 时，方可使用。

#### （1）查询资源列表
```
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "resources/list",
  "params": {
    "cursor": "optional-cursor-value"
  }
}
```

#### （2）读取资源
```
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "resources/read",
  "params": {
    "uri": "file:///project/src/main.rs"
  }
}
```

### 4. Prompts 提示
Prompt 提供可复用的提示词模板。仅当服务端在 initialize 响应的 `capabilities` 中声明支持 `prompts` 时，方可使用。

#### （1）查询提示列表
```
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "prompts/list",
  "params": {
    "cursor": "optional-cursor-value"
  }
}
```

#### （2）获取提示
```
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "prompts/get",
  "params": {
    "name": "code_review",
    "arguments": {
      "code": "def hello():\n    print('world')"
    }
  }
}
```

## 四. 参考资料
- [MCP 官网](https://modelcontextprotocol.io/)
- [JSON-RPC 2.0 规范](https://www.jsonrpc.org/specification)
