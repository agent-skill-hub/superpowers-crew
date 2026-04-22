# Superpowers + Agency Agents + Design Skills + Gstack 安装说明

## 四层定位

| 层级 | 工具 | 作用 | 调用方式 |
|------|------|------|---------|
| 思考流程 | **Superpowers** | brainstorm -> plan -> execute -> verify | 自动触发（必装） |
| 领域专家 | **Agency Agents** | 非工程领域的专家视角（营销/产品/销售等） | brainstorming 时由 hook 自动派遣 |
| 设计智能 | **Design Skills** | 7 个设计 skill（UI/UX/品牌/Banner/Slides 等） | 主会话 skill 触发 + subagent 通过 search.py/Read |
| 工程执行 | **Gstack 精简版** | 安全审计、架构评审 | `/security-audit`、`/architecture-review` slash command |

协作流程示例：
```
brainstorming（superpowers）
  -> hook 自动派遣领域专家（agency-agents subagent_type）
  -> UI/UX 项目自动运行 search.py --design-system
  -> 输出方案

writing-plans（superpowers）
  -> 每个任务分配角色 + 对应设计 skill
  -> /architecture-review（gstack skill 审架构）

执行开发（superpowers subagent-driven-development）
  -> subagent 按 subagent_type 加载完整 agent 定义
  -> 设计任务先查 skill 再写代码
  -> /requesting-code-review（superpowers 派 subagent 审代码）
  -> /security-audit（gstack skill 审安全）

遇到 bug
  -> /systematic-debugging（superpowers 系统调试）
```

---

## 前提

- Claude Code 已安装并登录
- Git 已安装

---

## 自动安装（推荐）

```bash
git clone https://github.com/agent-skill-hub/superpowers-crew.git ~/develop/code/git/superpowers-crew
cd ~/develop/code/git/superpowers-crew

# 只装基础（Superpowers + hook）
./setup.sh

# 加装组件（可混搭）
./setup.sh --agents             # + 领域专家
./setup.sh --design             # + 设计智能（7 个 skill）
./setup.sh --gstack             # + 安全护栏
./setup.sh --agents --design    # 混搭
./setup.sh --all                # 全装

# 查看安装状态
./setup.sh --status
```

安装器会自动：
1. 安装 Superpowers 插件
2. Clone 所需的源码仓库到 `~/develop/code/git/`
3. 创建 symlink（agents、design skills）或复制文件（gstack skills）
4. 生成自适应 hook（根据已安装组件动态输出指令）
5. 注册 hook 到 `~/.claude/settings.json`

---

## 手动安装

如果你更喜欢手动控制，以下是各组件的安装步骤。

### 第一步：安装 Superpowers（必装）

```bash
claude plugin install superpowers@claude-plugins-official
```

### 第二步：安装 Agency Agents（可选）

用 symlink 指向 git repo，`git pull` 即可更新。

```bash
git clone --depth 1 https://github.com/msitarzewski/agency-agents.git ~/develop/code/git/agency-agents
mkdir -p ~/.claude/agents

# 非工程角色目录
for dir in academic examples marketing paid-media product project-management sales specialized support game-development; do
  ln -sfn ~/develop/code/git/agency-agents/$dir ~/.claude/agents/$dir
done

# 设计类只保留 Inclusive Visuals Specialist（抗 AI 图像偏见，其它由 Design Skills 覆盖）
ln -sf ~/develop/code/git/agency-agents/design/design-inclusive-visuals-specialist.md ~/.claude/agents/design-inclusive-visuals-specialist.md

# 工程类只保留 Incident Response Commander
ln -sf ~/develop/code/git/agency-agents/engineering/engineering-incident-response-commander.md ~/.claude/agents/engineering-incident-response-commander.md
```

#### 排除的内容

- `engineering/` 整个目录（Claude 内置了充分的软件工程训练，工程执行纪律由 gstack skills 提供）
  - 仅保留 `engineering-incident-response-commander.md`（生产事故协调，含 SEV 分级、runbook 模板、on-call 轮转）
- `design/` 整个目录（由 Design Skills 7 个 skill 覆盖）
  - 仅保留 `design-inclusive-visuals-specialist.md`（抗 AI 图像生成偏见，skill 不覆盖此能力）

### 第三步：安装 Design Skills（可选）

7 个设计 skill，通过 symlink 指向源码仓库：

```bash
git clone --depth 1 https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git ~/develop/code/git/ui-ux-pro-max-skill
mkdir -p ~/.claude/skills

for skill in ui-ux-pro-max design brand banner-design ui-styling slides design-system; do
  ln -sfn ~/develop/code/git/ui-ux-pro-max-skill/.claude/skills/$skill ~/.claude/skills/$skill
done
```

| Skill | 做什么 | 何时使用 |
|-------|-------|---------|
| `ui-ux-pro-max` | 设计搜索引擎：67 风格、161 调色板、57 字体、99 UX 规则 | 任何 UI/UX 工作，总是从这里开始 |
| `design` | Logo（55 风格、Gemini）、CIP 品牌样机、图标、社交图片 | 品牌视觉资产创作 |
| `brand` | 品牌声音、视觉识别、消息框架、一致性审计 | 品牌内容、语调 |
| `banner-design` | 22 种风格的 Banner（社交/广告/网页/印刷） | 营销视觉、广告创意 |
| `ui-styling` | shadcn/ui + Tailwind CSS + 暗黑模式 + 无障碍组件 | 代码级 UI 实现 |
| `design-system` | 三层 Token（primitive->semantic->component）、CSS 变量 | 设计 Token 架构 |
| `slides` | HTML 演示文稿 + Chart.js 数据可视化 | 幻灯片、数据展示 |

**依赖链：** `brand` + `design-system` -> `ui-styling` -> `design` -> `banner-design` / `slides`

### 第四步：安装 Gstack 精简版 Skills（可选）

本仓库已经提供剥好的精简版（`skills/security-audit/` 和 `skills/architecture-review/`）。手动安装直接从这里复制，**不要从 gstack 原仓库复制**——原仓库的 SKILL.md 包含大量 gstack harness 依赖（二进制调用、`~/.gstack/` 目录约定、跨 skill 链），离开 gstack 生态不可用。

```bash
mkdir -p ~/.claude/skills/security-audit ~/.claude/skills/architecture-review

cp ~/develop/code/git/superpowers-crew/skills/security-audit/SKILL.md ~/.claude/skills/security-audit/SKILL.md
cp ~/develop/code/git/superpowers-crew/skills/architecture-review/SKILL.md ~/.claude/skills/architecture-review/SKILL.md
```

另外 2 个（调试、代码审查）与 superpowers 内置 skill 重叠，已移除：
- ~~`/investigate`~~ -> 由 superpowers `/systematic-debugging` 替代
- ~~`/code-review`~~ -> 由 superpowers `/requesting-code-review` 替代

| Skill | 用途 | 来源 |
|-------|------|------|
| `/security-audit` | 安全审计（OWASP+STRIDE、17 条误报排除、8/10 置信度门槛、1-10 置信度分级、趋势字段） | gstack `/cso` 精简 |
| `/architecture-review` | 架构评审（15 认知模式、ASCII 覆盖图、E2E/EVAL 决策矩阵、Outside Voice 独立挑战、Anti-skip 规则） | gstack `/plan-eng-review` 精简 |

#### 精简原则：保留审核方法论，剥离 gstack harness

crew 的定位是**纯 prompt 层的知识注入**——只保留"审什么、怎么审"的判断标准和流程，不绑定任何运行时。用户自己的 harness（如果有）决定持久化、跨 skill 编排、下游消费怎么做。

以下是从 gstack 上游合并更新时的判断标准。**保留**：

- 审核方法论：phase 划分、检查维度、评分门槛、决策矩阵、画图格式
- 知识规则：OWASP / STRIDE / 认知模式、误报排除规则、框架默认保护清单
- 判断标准：置信度分级表、finding 输出格式、严重度校准
- 通用反模式：反 AI 共识自动通过（User Sovereignty）、反省略规则、跨模型挑战的 prompt 模板
- 给另一个 AI 的边界提示：如 outside voice prompt 里的 filesystem boundary（告诉它别读 skill 定义目录）

**剥离**：

- **二进制调用**：`gstack-learnings-log`、`gstack-learnings-search`、`gstack-review-log`、`gstack-review-read`、`gstack-slug`、`gstack-config` 等。crew 里让模型"记下来"但没地方记，就是空转指令
- **目录约定**：`~/.gstack/projects/{slug}/`、`.gstack/security-reports/`。输出路径替换为通用路径（`.security-reports/`）或让用户自己定
- **跨 skill 链**：`/ship` `/retro` `/office-hours` `/canary` 等 gstack 内部命令引用。如果概念有用，改成"你的 ship 流程 / 问题定义阶段"这种通用表述；如果只是流程衔接，整段丢掉
- **跨运行持久化语义**：calibration learning（"记住校准事件下次提高置信度"）、prior learnings 搜索、trend tracking 的实现细节（fingerprint 匹配、JSON schema 持久化）——crew 可以保留**格式**（如 trend 输出模板），但不假设上次的文件存在
- **gstack 特化输出物**：review readiness dashboard、plan file review report、review log JSONL——这些要 gstack 下游 skill 消费才有意义
- **模型/风格包装**：model overlay、voice directive、writing style V1、jargon list、preamble 里的 gstack 品牌话术
- **安装/升级流程**：vendoring 检测、`./setup` 交叉引用、CLAUDE.md routing 注入

**合并混合块的原则**：核心是方法论但夹杂了 harness 实现（比如 outside voice 方法论 + codex 特定命令）——留方法论，改写实现为通用路径（`codex exec` → "通过 Agent tool 起 subagent"）。

**判断话术**：如果一段内容**离开 gstack 的 `~/.gstack/` 目录、`gstack-*` 二进制、`/ship` `/retro` 这些命令后仍然有判断力**，它就是方法论，合进来；如果**离开这些东西后就只剩空转指令或孤儿文件**，它是 harness，丢掉。

### 第五步：安装 Patcher Hook 和补丁

如果你用了自动安装，这步已经做好了。手动安装的话：

```bash
# 复制 patcher 脚本
mkdir -p ~/.claude/hooks ~/.claude/patches
cp ~/develop/code/git/superpowers-crew/patcher.sh ~/.claude/hooks/agency-superpowers-patcher.sh
chmod +x ~/.claude/hooks/agency-superpowers-patcher.sh

# 复制补丁文件
cp ~/develop/code/git/superpowers-crew/patches/*.patch.md ~/.claude/patches/

# 立即执行一次打补丁
bash ~/.claude/hooks/agency-superpowers-patcher.sh
```

然后在 `~/.claude/settings.json` 中注册 hook（如果还没有）：

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "bash $HOME/.claude/hooks/agency-superpowers-patcher.sh",
        "timeout": 5
      }]
    }]
  }
}
```

**工作原理：** Patcher 在每次对话启动时运行，检测 Superpowers skill 文件是否已打补丁。已打补丁则静默退出（零 token 消耗），未打补丁则自动注入。插件更新覆盖源文件后，下次启动自动重新打补丁。

---

## 更新

```bash
# Agency Agents（symlink 自动生效）
cd ~/develop/code/git/agency-agents && git pull

# Design Skills（symlink 自动生效）
cd ~/develop/code/git/ui-ux-pro-max-skill && git pull

# Gstack 精简版（crew 维护的提取版，跟随本仓库更新）
cd ~/develop/code/git/superpowers-crew && git pull
cp skills/security-audit/SKILL.md ~/.claude/skills/security-audit/SKILL.md
cp skills/architecture-review/SKILL.md ~/.claude/skills/architecture-review/SKILL.md

# 想从 gstack 上游汲取新方法论时：
# 1. 拉 gstack 最新版并和上一次合并点做 diff（不是和 crew 版 diff——crew 是剥过的，那会全是噪声）
cd ~/develop/code/git/gstack && git pull
git log --oneline <last-merged-sha>..HEAD -- cso/ plan-eng-review/
git diff <last-merged-sha>..HEAD -- cso/SKILL.md plan-eng-review/SKILL.md
# 2. 按"精简原则"筛：保留审核方法论，剥离 harness（详见上文第四步）
# 3. 只把筛过的内容合进 crew 的 skills/security-audit/ 和 skills/architecture-review/
```

---

## 验证

重新启动一个 Claude Code 会话（新窗口，非 `/clear`）：

1. **Superpowers**：发起任意开发请求，应自动进入 brainstorm -> plan -> execute 流程
2. **Patcher 补丁验证**：检查 skill 源文件是否已注入补丁内容：
   ```bash
   grep -c "PATCH:" ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/skills/brainstorming/SKILL.md
   # 应输出 1
   ```
3. **Agency + Superpowers 联动**：brainstorming 时 Claude 应自动派遣领域专家 subagent（指令已在 skill 的 checklist 中）
4. **Design Skills**：涉及 UI/UX 的请求应自动调用 `search.py`，设计任务应引用对应 skill
5. **Gstack Skills**：输入 `/security-audit`、`/architecture-review`，应能识别为 slash command

---

## 目录结构总览

```
~/.claude/
  settings.json                          # hooks 注册
  hooks/
    agency-superpowers-patcher.sh        # SessionStart hook（检测+打补丁，零 token）
  patches/                               # 补丁文件（注入 superpowers skill 源文件）
    brainstorming.patch.md
    writing-plans.patch.md
    subagent-driven-development.patch.md
    executing-plans.patch.md
    verification-before-completion.patch.md
  agents/                                # Agency Agents 角色（symlink）
    academic/ -> .../agency-agents/academic/
    marketing/ -> .../agency-agents/marketing/
    game-development/ -> .../agency-agents/game-development/
    ...
    design-inclusive-visuals-specialist.md -> ...
    engineering-incident-response-commander.md -> ...
  skills/                                # 全局 Skills
    ui-ux-pro-max/ -> .../ui-ux-pro-max-skill/.claude/skills/ui-ux-pro-max/
    design/ -> .../ui-ux-pro-max-skill/.claude/skills/design/
    brand/ -> .../ui-ux-pro-max-skill/.claude/skills/brand/
    banner-design/ -> .../ui-ux-pro-max-skill/.claude/skills/banner-design/
    ui-styling/ -> .../ui-ux-pro-max-skill/.claude/skills/ui-styling/
    design-system/ -> .../ui-ux-pro-max-skill/.claude/skills/design-system/
    slides/ -> .../ui-ux-pro-max-skill/.claude/skills/slides/
    security-audit/SKILL.md              # 从 gstack 复制
    architecture-review/SKILL.md         # 从 gstack 复制

~/develop/code/git/
  agency-agents/                         # 源码仓库（git pull 更新）
  ui-ux-pro-max-skill/                   # 源码仓库（git pull 更新）
  gstack/                                # 源码仓库（diff 对比用）
  superpowers-crew/             # 安装器仓库
```
