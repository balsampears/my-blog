+++
date = '2026-06-27T22:00:00+08:00'
draft = false
title = 'MCP Server TS搭建'
description= '使用 TypeScript 搭建 MCP Server'
tags = ['ai', '实践']
weight = 30
+++

本文以一个加法工具为例，演示如何使用 TypeScript 搭建 MCP Server，并分别通过 Stdio、SSE、Streamable HTTP 三种传输方式接入 Cherry Studio，最后介绍常用调试方法与上线方式。

## 一. TypeScript 搭建 MCP Server 项目
### 1. 配置环境
进入 [Node.js 官网](https://nodejs.org/zh-cn/download)，下载安装 Node.js。

安装完成后，查看版本
```bash
npm --version
node --version
```

### 2. 创建项目结构
```bash
mkdir mcp-server-ts
cd mcp-server-ts

# Initialize a new npm project
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk express zod@3
npm install -D @types/express @types/node typescript

# Create our files
mkdir src
touch src/index.ts
```

在 `package.json` 中合并以下字段：
```json
{
  "type": "module",
  "bin": {
    "mcp-server-ts-demo": "./build/index.js"
  },
  "scripts": {
    "build": "tsc && chmod 755 build/*.js"
  },
  "files": ["build"]
}
```

创建 `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "./build",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

### 3. 编写简易MCP服务
在 `src/index.ts` 编写：
```ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// 创建 server 实例
const server = new McpServer({
  name: "mathcalculation",
  version: "1.0.0",
});

server.registerTool(
  "add_method",
  {
    description: "这是个加法运算",
    inputSchema: {
      numberA: z.number().describe("第一个数字"),
      numberB: z.number().describe("第二个数字"),
    },
  },
  async ({ numberA, numberB }) => {
    return {
      content: [
        {
          type: "text",
          text: `结果是：${numberA + numberB}`,
        },
      ],
    };
  },
);
  
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Math MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error in main():", error);
  process.exit(1);
});
```

### 4. 启动MCP服务
编译项目
```bash
npm run build
```

启动项目
```bash
node build/index.js
```

## 二. MCP 不同传输方式的搭建与接入
下面以 Cherry Studio 演示 MCP Server 不同传输方式的接入。

### 1. Stdio 方式

#### （1）Stdio 搭建
以上演示的 `new StdioServerTransport();` 就是 Stdio 的方式启动。

#### （2）Stdio 接入
类型选择标准输入输出，命令填 `node`，参数传入 `build/index.js` 的绝对路径。
{{< figure src="stdio1.png" width="700" >}}

### 2. SSE 方式
#### （1）SSE 搭建
SSE 需要启动一个 HTTP 服务，并提供一个 SSE 长连接 endpoint（如 `/sse`）接收服务端推送。

前面已经安装了 `express` 和 `@types/express`，这里直接新增服务文件即可。

- 新增 `src/sse.ts`：
```ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import type { Request, Response } from "express";
import { z } from "zod";

function createServer() {
  const server = new McpServer({
    name: "mathcalculation",
    version: "1.0.0",
  });

  server.registerTool(
    "add_method",
    {
      description: "这是个加法运算",
      inputSchema: {
        numberA: z.number().describe("第一个数字"),
        numberB: z.number().describe("第二个数字"),
      },
    },
    async ({ numberA, numberB }) => {
      return {
        content: [
          {
            type: "text",
            text: `结果是：${numberA + numberB}`,
          },
        ],
      };
    },
  );

  return server;
}

const transports: Record<string, SSEServerTransport> = {};
const app = createMcpExpressApp();

// SSE 长连接 endpoint
app.get("/sse", async (_req: Request, res: Response) => {
  try {
    // 创建 SSE transport
    const transport = new SSEServerTransport("/messages", res);
    // 存储 transport
    transports[transport.sessionId] = transport;
    // 连接MCP Server
    const server = createServer();
    await server.connect(transport);
  } catch (error) {
    console.error("Error establishing SSE connection:", error);
    if (!res.headersSent) {
      res.status(500).send("Error establishing SSE connection");
    }
  }
});

// 客户端通过 /messages 发送消息到服务端
app.post("/messages", async (req: Request, res: Response) => {
  const sessionId = req.query.sessionId as string | undefined;
  if (!sessionId) {
    res.status(400).send("Missing sessionId parameter");
    return;
  }

  const transport = transports[sessionId];
  if (!transport) {
    res.status(404).send("Session not found");
    return;
  }

  try {
    await transport.handlePostMessage(req, res, req.body);
  } catch (error) {
    console.error("Error handling message:", error);
    if (!res.headersSent) {
      res.status(500).send("Error handling request");
    }
  }
});

// 启动 HTTP 服务
async function main() {
  const PORT = 3000;
  app.listen(PORT, () => {
    console.error(
      `Math MCP Server running on SSE at http://127.0.0.1:${PORT}/sse`,
    );
  });
}

main().catch((error) => {
  console.error("Fatal error in main():", error);
  process.exit(1);
});

```

- 启动 HTTP 服务
```bash
npm run build
node build/sse.js
```

#### （2）SSE 接入
类型选择 SSE，并且添加服务端地址。
{{< figure src="sse1.png" width="700" >}}

### 3. Streamable HTTP 方式
#### （1）Streamable HTTP 搭建
Streamable HTTP 同样需要启动一个 HTTP 服务，并提供一个统一的 HTTP endpoint（如 `/mcp`），与服务端交互、建立长连接、接收推送。

- 新增 `src/streamable_http.ts`：
```ts
import { randomUUID } from "node:crypto";

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createMcpExpressApp } from "@modelcontextprotocol/sdk/server/express.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js";
import type { Request, Response } from "express";
import { z } from "zod";

function createServer() {
  const server = new McpServer({
    name: "mathcalculation",
    version: "1.0.0",
  });

  server.registerTool(
    "add_method",
    {
      description: "这是个加法运算",
      inputSchema: {
        numberA: z.number().describe("第一个数字"),
        numberB: z.number().describe("第二个数字"),
      },
    },
    async ({ numberA, numberB }) => {
      return {
        content: [
          {
            type: "text",
            text: `结果是：${numberA + numberB}`,
          },
        ],
      };
    },
  );

  return server;
}

const transports: Record<string, StreamableHTTPServerTransport> = {};
const app = createMcpExpressApp();

// POST 是 Streamable HTTP 的主通道，客户端向服务端发送的所有 JSON-RPC 请求都会通过这个路由处理
// 包括 initialize tools/list tools/call 等
app.post("/mcp", async (req: Request, res: Response) => {
  // 协议约定使用mcp-session-id来识别客户端，如果客户端没有提供，则认为是新的会话
  const sessionId = req.headers["mcp-session-id"] as string | undefined;

  try {
    let transport: StreamableHTTPServerTransport;

    // 如果客户端提供了sessionId，则使用已有的transport
    if (sessionId && transports[sessionId]) {
      transport = transports[sessionId];
    } 
    // 如果客户端没有提供sessionId，则认为是新的会话
    else if (!sessionId && isInitializeRequest(req.body)) {
      // 创建新的transport
      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (id) => {
          transports[id] = transport;
        },
      });
      // 设置transport的onclose回调，当transport关闭时，删除对应的sessionId
      transport.onclose = () => {
        const sid = transport.sessionId;
        if (sid && transports[sid]) {
          delete transports[sid];
        }
      };

      // 创建新的server
      const server = createServer();
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
      return;
    } else {
      res.status(400).json({
        jsonrpc: "2.0",
        error: {
          code: -32000,
          message: "Bad Request: No valid session ID provided",
        },
        id: null,
      });
      return;
    }

    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error("Error handling MCP POST request:", error);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal server error",
        },
        id: null,
      });
    }
  }
});

// GET 是 Streamable HTTP 的通知通道，客户端与服务端通过这里建立长连接
// 客户端通过这个通道发送心跳包，服务端通过这个通道发送通知
app.get("/mcp", async (req: Request, res: Response) => {
  const sessionId = req.headers["mcp-session-id"] as string | undefined;
  if (!sessionId || !transports[sessionId]) {
    res.status(400).send("Invalid or missing session ID");
    return;
  }

  try {
    await transports[sessionId].handleRequest(req, res);
  } catch (error) {
    console.error("Error handling MCP GET request:", error);
    if (!res.headersSent) {
      res.status(500).send("Error handling request");
    }
  }
});

// DELETE 是 Streamable HTTP 的关闭通道，客户端通过这个通道关闭会话
// 服务端通过这个通道关闭会话，并删除对应的transport
app.delete("/mcp", async (req: Request, res: Response) => {
  const sessionId = req.headers["mcp-session-id"] as string | undefined;
  if (!sessionId || !transports[sessionId]) {
    res.status(400).send("Invalid or missing session ID");
    return;
  }

  try {
    await transports[sessionId].handleRequest(req, res);
  } catch (error) {
    console.error("Error handling MCP DELETE request:", error);
    if (!res.headersSent) {
      res.status(500).send("Error handling request");
    }
  }
});

async function main() {
  const PORT = 3000;
  app.listen(PORT, () => {
    console.error(
      `Math MCP Server running on Streamable HTTP at http://127.0.0.1:${PORT}/mcp`,
    );
  });
}

main().catch((error) => {
  console.error("Fatal error in main():", error);
  process.exit(1);
});

```

- 启动 HTTP 服务
```bash
npm run build
node build/streamable_http.js
```

#### （2）Streamable HTTP 接入
类型选择 Streamable HTTP，并且添加服务端地址。
{{< figure src="streamable_http1.png" width="700" >}}

## 三. MCP调试
在 AI 客户端工具调用 MCP 服务时，有时会出现连接不上，或者查询工具为空的情况。此时需要对 MCP 服务进行检查与调试。
### 1. Curl
curl 是常用的命令行工具，可以方便地发送 HTTP 请求。curl 不能测试 Stdio 传输方式。
#### (1) SSE 方式
SSE 方式需要开启两个终端窗口，一个用来长连接接收响应，一个用来短连接发送请求。

**1. 发起长连接**  
在长连接窗口中执行以下命令：
```bash
curl -X GET -i http://127.0.0.1:3000/sse
```
现在会返回 `sessionId`，将这个 `sessionId` 记录下来，后面需要用到。同时这个窗口会持续接收响应数据。  
下面操作都在短连接窗口中执行，需要将 `sessionId` 替换到请求中。

**2. 初始化请求**
```bash
# 需要替换获取的sessionId
curl -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{"elicitation":{}},"clientInfo":{"name":"example-client","version":"1.0.0"}}}' \
 "http://127.0.0.1:3000/messages?sessionId=<sessionId>"
```
请求成功后短连接窗口无数据返回，在长连接窗口可以看到初始化响应。

**3. 客户端通知初始化完成**
```bash
# 需要替换获取的sessionId
curl -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
 "http://127.0.0.1:3000/messages?sessionId=<sessionId>"
```
请求成功后两个窗口都不会返回任何数据。

**4. 查询工具列表**
```bash
# 需要替换获取的sessionId
curl -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
 "http://127.0.0.1:3000/messages?sessionId=<sessionId>"
```
请求成功后短连接窗口无数据返回，在长连接窗口可以看到工具列表。

**5. 调用工具**
```bash
# 需要替换获取的sessionId
curl -X POST -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"add_method","arguments":{"numberA":1,"numberB":2}}}' \
 "http://127.0.0.1:3000/messages?sessionId=<sessionId>"
```
请求成功后短连接窗口无数据返回，在长连接窗口可以看到工具调用结果。

**6. 关闭会话**  
停止长连接，即可关闭会话。 

#### (2) Streamable HTTP 方式
Streamable HTTP 方式仅需要一个终端窗口，需要记录 `mcp-session-id`，用于后续发送请求。

**1. 初始化请求**
```bash
curl -X POST -H "Accept: application/json,text/event-stream" \
 -H "Content-Type: application/json" \
 -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{"elicitation":{}},"clientInfo":{"name":"example-client","version":"1.0.0"}}}' \
 -i http://127.0.0.1:3000/mcp
```
请求成功可以看到响应数据和响应头 `mcp-session-id`。

**2. 客户端通知初始化完成**
```bash
# 需要替换获取的mcp-session-id
curl -X POST -H "Accept: application/json,text/event-stream" \
 -H "Content-Type: application/json" \
 -H "mcp-session-id: <mcp-session-id>" \
 -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
 -i http://127.0.0.1:3000/mcp
```
请求成功后不会返回任何数据。

**3. 查询工具列表**
```bash
# 需要替换获取的mcp-session-id
curl -X POST -H "Accept: application/json,text/event-stream" \
 -H "Content-Type: application/json" \
 -H "mcp-session-id: <mcp-session-id>" \
 -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
 http://127.0.0.1:3000/mcp
```
请求成功可以看到工具列表。

**4. 调用工具**
```bash
# 需要替换获取的mcp-session-id
curl -X POST -H "Accept: application/json,text/event-stream" \
 -H "Content-Type: application/json" \
 -H "mcp-session-id: <mcp-session-id>" \
 -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"add_method","arguments":{"numberA":1,"numberB":2}}}' \
 http://127.0.0.1:3000/mcp
```
请求成功可以看到工具调用结果。

**5. 关闭会话**
```bash
# 需要替换获取的mcp-session-id
curl -X DELETE -H "Accept: application/json,text/event-stream" \
 -H "Content-Type: application/json" \
 -H "mcp-session-id: <mcp-session-id>" \
 http://127.0.0.1:3000/mcp
```
请求成功后不会返回任何数据。

### 2. MCP Inspector
MCP Inspector 是官方提供的 MCP 调试工具，可以方便地调试 MCP 服务。

1. 安装并启动 MCP Inspector
```bash
npx -y @modelcontextprotocol/inspector@latest
```
npx 是 npm 的命令行工具，可以直接运行可执行的 npm 包。`-y` 参数表示自动同意安装。

2. MCP 连接
{{< figure src="mcp_inspector1.png" width="700" >}}

3. 工具列表与调用
{{< figure src="mcp_inspector2.png" width="700" >}}
{{< figure src="mcp_inspector3.png" width="700" >}}

## 四. MCP Server 部署上线
### 1. npm打包上线
适用于 Stdio 传输方式，将项目打包成可执行文件，并上线到 [npm 包管理平台](https://www.npmjs.com/)。

#### （1）整理代码
`package.json` 修改代码，注意包名可以自行取，避免和笔者的包冲突导致后续发布失败。  
`name` 和 `bin` 的命令设置为一样，后续可以进行简写。
```json
{
  "name": "mcp-server-ts-demo",
  "bin": {
    "mcp-server-ts-demo": "./build/index.js"
  }
}
```
或者写为 scoped package 格式
```json
{
  "name": "@balsampears/mcp-server-ts-demo",
  "bin": {
    "mcp-server-ts-demo": "./build/index.js"
  }
}
```

`src/index.ts` 第一行补充代码，避免 bin 执行时识别为普通的 shell 命令而不是 `node` 命令。
```bash
#!/usr/bin/env node
```

#### （2）注册账号
在 [npm 官网](https://www.npmjs.com/)注册账号，记下账号密码。

#### （3）开启账号2FA
2FA 是登录账号后的双重校验，为了账号安全性添加的功能。  
进入 Account → Enable 2FA，输入密码，选择 2FA 方式（iCloud 钥匙串、Google 密码工具等），然后记下密钥。

#### （4）登录与发布
```bash
# 命令行登录，使用--registry是指定官方仓库（笔者本地配置的是淘宝镜像）
npm login --registry=https://registry.npmjs.org

# 查看登录账号
npm whoami --registry=https://registry.npmjs.org

# 编译，公开发布
npm run build
npm publish --registry=https://registry.npmjs.org --access=public
```

#### （5）测试
```bash
npx -y mcp-server-ts-demo
# 或者scoped package
npx -y @balsampears/mcp-server-ts-demo
```

**注意**  
测试另外开一个目录，不要在当前工程目录下进行，否则命令可能会报错：`command not found`。

#### （6）接入
在 Cherry Studio 进行接入，跟 LLM 进行交互验证。
{{< figure src="stdio2.png" width="700" >}}


### 2. 服务器部署上线
适用于 SSE、Streamable HTTP 传输方式，将项目部署到服务器，通过 HTTP 访问。

部署方式跟第二章节的 2、3 小节类似，生产环境需放行端口，使用时将 `localhost` 改为对应公网 IP 或域名。

跟第二章节的2、3小节类似，生产环境需放行端口，使用时将localhost改为对应公网IP即可。

## 五. 参考资料
- [MCP Example](https://modelcontextprotocol.io/docs/develop/build-server#typescript)
- [从零编写MCP并发布上线](https://www.bilibili.com/video/BV1RNTtzMENj)