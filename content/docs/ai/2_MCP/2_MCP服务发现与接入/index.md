+++
date = '2026-06-26T22:00:00+08:00'
draft = false
title = 'MCP服务发现与接入'
description = '寻找 MCP 服务，并在AI客户端中完成配置与调用'
tags = ['ai', '教程']
weight = 20
+++

本篇介绍如何发现现成的 MCP 服务，并在 AI 客户端（Host）中完成接入与调用。

## 一. 获取MCP服务

1. 登录 [mcp.so](https://mcp.so)，查询 MCP 服务（以下以高德地图为例）

2. 找到 Amap Maps，获取 Server Config

{{< figure src="mcp1.png" width="700" >}}

3. 进入 [高德开发者平台](https://console.amap.com/)，申请一个测试应用，并获取一个 API Key。

{{< figure src="mcp2.png" width="700" >}}

## 二. 配置MCP服务

以下配置以 stdio 方式启动 MCP Server（通过 `npx` 拉取并运行），需要本机已安装 Node.js 环境。

将 `AMAP_MAPS_API_KEY` 替换为你在上一步申请的 Key。**请勿将真实 Key 提交到 Git 仓库**，建议仅在本地配置中使用。

示例配置如下（`XXXX` 处填入你的 API Key）：

```
{
  "mcpServers": {
    "amap-maps": {
      "command": "npx",
      "args": [
        "-y",
        "@amap/amap-maps-mcp-server"
      ],
      "env": {
        "AMAP_MAPS_API_KEY": "XXXX"
      }
    }
  }
}
```

### 1. Cursor

1. 依次点击 Settings -> Tool&MCPs -> Open New MCP

2. 粘贴上方配置并保存

3. 对应服务展示绿灯，并显示可用工具数量

{{< figure src="mcp_cursor1.png" width="700" >}}

4. 在对话框中提问，LLM 会自动调用高德地图 MCP 工具

{{< figure src="mcp_cursor2.png" width="300" >}}

### 2. Claude Code

Claude Code 通常借助 [cc switch](https://github.com/farion1231/cc-switch)（模型与 MCP 管理工具）进行 MCP 配置。

{{< figure src="mcp_claude0.png" width="700" >}}

1. 在 cc switch 中依次点击 MCP 管理 -> 添加 MCP，粘贴配置，注意这里的配置不包含mcpServers。

{{< figure src="mcp_claude1.png" width="700" >}}

2. 在 Claude Code 中提问，验证 MCP 工具是否被正常调用

{{< figure src="mcp_claude2.png" width="700" >}}

### 3. Cherry Studio
Cherry Studio是一款桌面端AI客户端工具，界面清晰简洁，适合小白使用。

1. 依次点击 Settings -> MCP 服务器 -> 添加 -> 从JSON导入
{{< figure src="mcp_cherry1.png" width="700" >}}

2. 导入跟 Cursor一样的配置

3. 提问，注意需要选择启用mcp服务器（默认禁用）
{{< figure src="mcp_cherry2.png" width="700" >}}

## 三. 常见问题
### 1. **配置好之后，但是调用MCP失败？**  
重新启动客户端，或者重新启用一个新的Agent。