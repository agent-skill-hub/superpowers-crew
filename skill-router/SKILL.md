---
name: skill-router
description: 按需搜索已归档的专家角色和技能，语义匹配后加载对应定义。触发词：找专家、找skill、dispatch、哪个角色适合、crew搜索
---

# Skill Router

按需发现和加载 `~/.claude/crew-archive/` 中归档的专家角色（agent）和技能（skill）。

## 使用流程

1. **语义搜索**：dispatch 一个 subagent，让它读取 registry.csv 全部条目，根据用户需求做语义匹配，返回最佳匹配（top 3）。

   Subagent prompt 模板：
   > 读取 `~/.claude/skills/skill-router/data/registry.csv`，理解每条记录的 Name、Type、Description。
   > 用户需求是：「{需求描述}」
   > 返回最匹配的 3 条，格式：Name | Type | Path | 匹配理由（一句话）。
   > 如果没有匹配项，直接说"无匹配"。

2. 确认后 Read 对应 Path 的 .md 文件
3. 根据 Type 决定使用方式：
   - **agent**: dispatch `general-purpose` subagent，将 .md 内容作为角色指令注入 prompt
   - **skill**: 在当前上下文按 .md 中的指令执行

## 重建索引

新增归档文件后运行：
```bash
python ~/.claude/skills/skill-router/scripts/build_registry.py
```

## 注意

- 归档内容不在 Agent tool 的内置类型列表中，dispatch 时统一用 `general-purpose`
- 搜索无结果时说明归档中没有匹配项，用 `general-purpose` 即可
