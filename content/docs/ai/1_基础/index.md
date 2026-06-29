+++
date = '2026-06-21T19:00:00+08:00'
draft = false
title = 'AI基础'
description= 'AI常见概念'
tags = ['ai']
weight = 10
+++


## 1. LLM
大语言模型，通过海量文本进行训练，通过神经网络学习语言规律，生成文本的模型，本质是个文字接龙游戏。

## 2. Token
LLM生成的最小单位，也是收费计价的单位。不同语言和模型的分词规则不一样，中文一个字和英文一个单词并不等于一个token。

## 3. Prompt 提示词
LLM是通用大模型，包含所有人类已有的知识。提示词是引导LLM往指定方向进行回答的提示，用户提问、用户规则都算提示词。

## 4. Function Calling / Tool Choice
函数调用/工具选择，由本地外部实现的工具，给大模型进行调用。

## 5. MCP
Model Context Protocol，模型上下文协议。  
MCP协议约定了大模型和工具之间调用的传输格式，使两者进行解耦合，可以更方便的开发MCP服务器和调用其他人的MCP服务。  

## 6. Agent
AI智能体，通过大模型和工作流设计，能够自主判断不同场景执行不同任务的机器人。  
agent = LLM + memory + planning + tool use（大模型+记忆+工作流+MCP） 

### 在线Agent平台
- [dify](https://cloud.dify.ai/apps)
- [n8n](https://n8n.io/)
- [coze国际版](https://www.coze.com/)
- [coze国内版](https://www.coze.cn/)
- [阿里云百炼](https://bailian.console.aliyun.com/)
- [文心智能体](https://agents.baidu.com/center)


## 7. RAG
检索-增强-生成，通过检索知识库文档，仅把相关联内容交给LLM，再让LLM进行回答，可以避免文档过大过大让无关内容占用太多的LLM上下文。
