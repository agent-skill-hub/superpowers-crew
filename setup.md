# Superpowers + Agency Agents + Gstack Skills 安装说明

## 三者定位

| 层级 | 工具 | 作用 | 调用方式 |
|------|------|------|---------|
| 思考流程 | **Superpowers** | brainstorm → plan → execute → verify | 自动触发 |
| 领域专家 | **Agency Agents** | 非工程领域的专家视角（营销/产品/销售等） | brainstorming 时由 hook 自动派遣 |
| 工程执行 | **Gstack 精简版** | 安全审计、架构评审 | `/security-audit`、`/architecture-review` slash command |

协作流程示例：
```
brainstorming（superpowers）
  → 自动派遣领域专家（agency-agents hook）
  → 输出方案

writing-plans（superpowers）
  → /architecture-review（gstack skill 审架构）

执行开发（superpowers TDD）
  → /requesting-code-review（superpowers 派 subagent 审代码）
  → /security-audit（gstack skill 审安全）

遇到 bug
  → /systematic-debugging（superpowers 系统调试）
```

---

## 前提

- Claude Code 已安装并登录
- Superpowers 插件已安装：`claude plugin install superpowers@claude-plugins-official`

---

## 第一步：下载源码仓库

```bash
# 统一放在 git 源码目录下
mkdir -p ~/develop/code/git

# Agency Agents
git clone --depth 1 https://github.com/msitarzewski/agency-agents.git ~/develop/code/git/agency-agents

# Gstack（仅作为提取源，不安装）
git clone --depth 1 https://github.com/garrytan/gstack.git ~/develop/code/git/gstack
```

---

## 第二步：安装 Agency Agents（symlink 方式）

用 symlink 指向 git repo，`git pull` 即可更新。

```bash
mkdir -p ~/.claude/agents

# 非工程角色目录（symlink）
for dir in academic design examples marketing paid-media product project-management sales specialized support; do
  ln -sfn ~/develop/code/git/agency-agents/$dir ~/.claude/agents/$dir
done

# 唯一保留的工程角色：Incident Response Commander
ln -sfn ~/develop/code/git/agency-agents/engineering/engineering-incident-response-commander.md ~/.claude/agents/engineering-incident-response-commander.md
```

### 排除的内容

- `engineering/` 整个目录（Claude 内置了充分的软件工程训练，工程执行纪律由 gstack skills 提供）
- 仅保留 `engineering-incident-response-commander.md`（生产事故协调，含 SEV 分级、runbook 模板、on-call 轮转）

### 更新

```bash
cd ~/develop/code/git/agency-agents && git pull
# symlink 自动生效，如有新目录需手动添加 symlink
```

---

## 第三步：安装 Gstack 精简版 Skills

从 gstack 提取方法论核心，去除 telemetry/contributor/analytics 等噪音，安装为全局 skill。

### 提取的 2 个 skill

另外 2 个（调试、代码审查）与 superpowers 内置 skill 功能重叠，已移除：
- ~~`/investigate`~~ → 由 superpowers `/systematic-debugging` 替代（更完整：含多组件诊断、3-strike 架构质疑规则、辅助材料）
- ~~`/code-review`~~ → 由 superpowers `/requesting-code-review` 替代（subagent 隔离上下文，不污染主对话）

| Skill | 用途 | 来源 |
|-------|------|------|
| `/security-audit` | 安全审计（OWASP+STRIDE、17 条误报排除、8/10 置信度门槛、独立验证） | gstack `/cso` |
| `/architecture-review` | 架构评审（Scope Challenge、15 认知模式、ASCII 覆盖图、E2E 决策矩阵） | gstack `/plan-eng-review` |

### 安装位置

```
~/.claude/skills/
  security-audit/SKILL.md
  architecture-review/SKILL.md
```

### 更新方式

gstack skills 经过精简修改，不能直接 `git pull`。更新流程：

```bash
# 1. 拉取上游更新
cd ~/develop/code/git/gstack && git pull

# 2. 对比变更
diff ~/develop/code/git/gstack/cso/SKILL.md ~/.claude/skills/security-audit/SKILL.md
diff ~/develop/code/git/gstack/plan-eng-review/SKILL.md ~/.claude/skills/architecture-review/SKILL.md

# 3. 如有有价值的变更，手动合并到精简版
```

---

## 第四步：创建 Hook 联动三者

这个 hook 在 SessionStart 时注入指令，让 superpowers 的 brainstorming/writing-plans/subagent 流程自动调用 agency agents 的专家角色。

### 4-1. 创建 hook 脚本

```bash
mkdir -p ~/.claude/hooks
cat > ~/.claude/hooks/agency-superpowers.sh << 'HOOKEOF'
#!/usr/bin/env bash
cat << 'INSTRUCTIONS'
<AGENCY_SUPERPOWERS>

## Domain Expert Role Consultation

These instructions SUPPLEMENT the superpowers skills. They apply on top of brainstorming, writing-plans, and subagent-driven-development. Follow them in addition to the skill's own process.

### When using `brainstorming`

After exploring project context and BEFORE asking clarifying questions, identify which domain expert roles are relevant to this project. Then dispatch a domain expert consultation subagent for each relevant role, asking them to contribute their perspective to the design. Incorporate their input into the clarifying questions and approach proposals.

**Role selection guide:**

| Project type | Relevant roles |
|---|---|
| Ad / marketing landing page | Ad Creative Strategist, Conversion Copywriter, UX Architect, Paid Social Strategist |
| Consumer product / app | Product Designer, UX Architect, Growth Hacker |
| B2B SaaS | Product Manager, Sales Engineer, UX Architect |
| Game / entertainment | Game Designer, Creative Director, Narrative Designer |
| Internal tool / dashboard | UX Architect, Data Analyst |
| API / developer tool | Developer Advocate, Technical Writer |
| E-commerce | Conversion Rate Optimizer, Brand Strategist, UX Architect |
| Payment system / fintech | Compliance Auditor, Security Engineer, Backend Architect |
| Microservices / infrastructure | SRE, Backend Architect, DevOps Automator |

**How to consult a domain expert:**
Dispatch a subagent with subagent_type=general-purpose, framed as the expert:

> "You are a [Role]. The user wants to build: [brief description].
> Provide your top 3-5 observations, risks, and recommendations from your domain perspective. Be specific and opinionated. 2-3 sentences each."

Collect responses, then synthesize into your clarifying questions and approach proposals. Attribute insights: "从合规角度..." / "安全工程师建议..."

### When using `writing-plans`

After writing the plan and BEFORE dispatching the plan-document-reviewer:
1. Assign a domain expert role to each task via `**Role:**` field
2. For architecture-heavy plans, recommend running `/architecture-review`

**Role assignment examples:**

| Task type | Assign role |
|---|---|
| Copywriting, headlines, CTAs | Conversion Copywriter |
| Visual layout, component design | UI Designer |
| User flow, interaction design | UX Architect |
| Analytics, UTM, tracking | Growth Analyst |
| SEO, meta tags | SEO Strategist |
| Security-sensitive changes | → recommend `/security-audit` after implementation |
| Architecture changes (8+ files) | → recommend `/architecture-review` before implementation |
| API integration, backend | Backend Engineer |
| General implementation | Senior Software Engineer |

### When using `subagent-driven-development`

When dispatching implementer subagents, use the `**Role:**` field from the plan to frame the subagent:

In the implementer prompt, prepend:

> "You are a [Role]. Bring your domain expertise to this task. [Role-specific lens: e.g., 'Think about compliance impact', 'Consider failure modes', 'Optimize for observability'.]"

If the plan has no role assigned, infer the appropriate role from the task description before dispatching.

### When completing implementation

Before claiming work is done, recommend relevant skills based on change scope:
- Security-sensitive code → `/security-audit`
- PR ready for merge → `/requesting-code-review`（superpowers subagent）
- Bug fix → `/systematic-debugging` methodology was hopefully already used
- Architecture change → `/architecture-review` should have been done at plan stage

</AGENCY_SUPERPOWERS>
INSTRUCTIONS
HOOKEOF
chmod +x ~/.claude/hooks/agency-superpowers.sh
```

### 4-2. 注册到 settings.json

在 `hooks.SessionStart` 中添加（不覆盖已有条目）：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash $HOME/.claude/hooks/agency-superpowers.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

---

## 验证

重新启动一个 Claude Code 会话：

1. **Agency + Superpowers 联动**：发起 brainstorming 请求，Claude 应在提问前自动派遣领域专家 subagent
2. **Gstack Skills**：输入 `/security-audit`、`/architecture-review`，应能识别为 slash command
3. **技能列表**：在系统提示中应看到 security-audit、architecture-review 两个 gstack skill

---

## 目录结构总览

```
~/.claude/
  settings.json                          # hooks 注册
  CLAUDE.md                              # 全局规则
  hooks/
    agency-superpowers.sh                # SessionStart hook（联动三者）
  agents/                                # Agency Agents 角色（symlink）
    academic/ → ~/develop/code/git/agency-agents/academic/
    design/ → ~/develop/code/git/agency-agents/design/
    marketing/ → ...
    ...
    engineering-incident-response-commander.md → ...
  skills/                                # 全局 Skills
    security-audit/SKILL.md              # 从 gstack 提取
    architecture-review/SKILL.md         # 从 gstack 提取

~/develop/code/git/
  agency-agents/                         # 源码仓库（git pull 更新）
  gstack/                                # 源码仓库（diff 对比用）
```
