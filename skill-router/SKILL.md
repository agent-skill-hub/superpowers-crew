---
name: skill-router
description: 统一 skill 发现入口，覆盖 native skills 与归档专家角色。触发词：找专家、找skill、dispatch、哪个角色适合、crew搜索
---

# Skill Router

统一发现入口，覆盖两个命名空间：
- **Native skills**：system-reminder 中列出的内置技能，用 `Skill` 工具直接调用
- **归档角色/技能**：`~/.claude/crew-archive/` 中的专家角色，用 BM25 脚本搜索

## 使用流程

### 第一步：匹配 native skills

扫描当前 system-reminder 中列出的所有 skills，判断是否有匹配用户需求的条目。

- **有明确匹配** → 直接调用 `Skill("{skill-name}")`，流程结束
- **无明确匹配** → 进入第二步

### 第二步：搜索归档

运行 BM25 搜索脚本（禁止用 subagent 读取 CSV，直接 Bash 执行）：

```bash
python ~/.claude/skills/skill-router/scripts/search.py "{需求描述}"
```

- **有匹配结果** → 展示 top 3，确认后进入第三步
- **无匹配结果** → 告知用户两个命名空间均无匹配，建议用 `general-purpose`

### 第三步：加载归档条目

```bash
# 脚本输出中的 Path 字段展开 ~ 后直接 Read
```

根据 Type 决定使用方式：
- **agent**：dispatch `general-purpose` subagent，将 .md 内容作为角色指令注入 prompt
- **skill**：在当前上下文按 .md 中的指令执行

## 重建索引

新增归档文件后运行：
```bash
python ~/.claude/skills/skill-router/scripts/build_registry.py
```

## 注意

- 归档内容不在 Agent tool 的内置类型列表中，dispatch 时统一用 `general-purpose`
- 第二步必须用 Bash 运行脚本，不得 dispatch subagent 读取 registry.csv
