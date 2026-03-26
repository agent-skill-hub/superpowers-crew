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
git clone https://github.com/agent-skill-hub/superpowers-agency-gstack.git ~/develop/code/git/superpowers-agency-gstack
cd ~/develop/code/git/superpowers-agency-gstack

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

从 gstack 提取方法论核心，安装为全局 skill。

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git ~/develop/code/git/gstack
mkdir -p ~/.claude/skills/security-audit ~/.claude/skills/architecture-review

cp ~/develop/code/git/gstack/cso/SKILL.md ~/.claude/skills/security-audit/SKILL.md
cp ~/develop/code/git/gstack/plan-eng-review/SKILL.md ~/.claude/skills/architecture-review/SKILL.md
```

另外 2 个（调试、代码审查）与 superpowers 内置 skill 重叠，已移除：
- ~~`/investigate`~~ -> 由 superpowers `/systematic-debugging` 替代
- ~~`/code-review`~~ -> 由 superpowers `/requesting-code-review` 替代

| Skill | 用途 | 来源 |
|-------|------|------|
| `/security-audit` | 安全审计（OWASP+STRIDE、17 条误报排除、8/10 置信度门槛） | gstack `/cso` |
| `/architecture-review` | 架构评审（15 认知模式、ASCII 覆盖图、E2E 决策矩阵） | gstack `/plan-eng-review` |

### 第五步：安装 Hook 和注册

如果你用了自动安装，这步已经做好了。手动安装的话，运行：

```bash
# setup.sh 会生成自适应 hook 并注册到 settings.json
cd ~/develop/code/git/superpowers-agency-gstack
./setup.sh  # 只会安装 hook，不会重复安装已有组件
```

或参考 `setup.sh` 中 `install_hook()` 和 `install_settings()` 函数的内容手动创建。

---

## 更新

```bash
# Agency Agents（symlink 自动生效）
cd ~/develop/code/git/agency-agents && git pull

# Design Skills（symlink 自动生效）
cd ~/develop/code/git/ui-ux-pro-max-skill && git pull

# Gstack（需手动对比合并）
cd ~/develop/code/git/gstack && git pull
diff ~/develop/code/git/gstack/cso/SKILL.md ~/.claude/skills/security-audit/SKILL.md
diff ~/develop/code/git/gstack/plan-eng-review/SKILL.md ~/.claude/skills/architecture-review/SKILL.md
# 如有有价值的变更，手动合并
```

---

## 验证

重新启动一个 Claude Code 会话（新窗口，非 `/clear`）：

1. **Superpowers**：发起任意开发请求，应自动进入 brainstorm -> plan -> execute 流程
2. **Agency + Superpowers 联动**：brainstorming 时 Claude 应自动派遣领域专家 subagent，并使用 `subagent_type` 加载 agent 定义
3. **Design Skills**：涉及 UI/UX 的请求应自动调用 `search.py`，设计任务应引用对应 skill
4. **Gstack Skills**：输入 `/security-audit`、`/architecture-review`，应能识别为 slash command

---

## 目录结构总览

```
~/.claude/
  settings.json                          # hooks 注册
  hooks/
    agency-superpowers.sh                # SessionStart hook（自适应，联动四层）
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
  superpowers-agency-gstack/             # 安装器仓库
```
