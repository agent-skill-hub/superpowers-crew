# Superpowers Crew

> 一个人写代码，四支团队在背后。

把 **思考流程**、**领域专家**、**设计智能**、**安全护栏** 四层能力焊死在一起，让 Claude Code 从"能写代码的 AI"变成"能交付项目的 AI"。

---

## 这是什么

四个开源项目的精华，拼成一套完整的 AI 协作系统：

| 层级 | 项目来源 | 干什么的 |
|------|---------|---------|
| 思考流程层 | [Superpowers](https://github.com/anthropics/claude-plugins-official) | brainstorm -> plan -> execute -> verify，把"想到哪写到哪"变成有章法的开发 |
| 领域专家层 | [Agency Agents](https://github.com/msitarzewski/agency-agents) | 50+ 非工程角色——营销、产品、销售、游戏、法务……想得到的都有 |
| 设计智能层 | [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 7 个设计 skill——67 种风格、161 调色板、57 字体、99 UX 规则、搜索引擎 |
| 工程执行层 | [Gstack](https://github.com/garrytan/gstack) 精简版 | security-audit + architecture-review，交付前最后一道关 |
| 集成层 | Patcher + Skill Router（本项目） | Patcher 注入流程指令，Skill Router 按需发现专家，零上下文污染 |

一句话总结：**Superpowers 管流程，Skill Router 管发现，Agency Agents 管视角，Design Skills 管美学，Gstack 管底线。**

---

## 核心设计：零上下文污染

传统方式把所有 agent/skill 描述加载到每轮对话的上下文中，100+ 个 agent 消耗 ~10000 tokens/轮。

**Superpowers Crew 的做法不同：**

```
~/.claude/skills/          ← 热区：高频 skill，描述每轮携带（~500 tokens）
~/.claude/crew-archive/    ← 冷区：100+ agent/skill，零上下文开销
~/.claude/skills/skill-router/  ← 唯一入口：1 条描述占位，按需语义搜索
```

- **冷区内容**通过 `registry.csv`（Name + Description + Path）索引
- **需要时**：Skill Router dispatch subagent 读 registry.csv 做语义匹配，返回最佳结果
- **不需要时**：零 token 消耗，就像不存在

即使融入上千个外部 agent/skill，上下文开销始终为 1 条 skill-router 描述。

---

## 为什么值得装

单独用 Claude Code 写代码，够快，但容易"工程师思维"一条路走到黑。

装上这套系统之后：

- **Brainstorming 阶段** —— Skill Router 自动搜索最匹配的领域专家，产品经理问"用户真的需要这个吗"，安全专家问"这个接口裸奔没问题吗"；涉及 UI/UX 时自动调用 `search.py` 生成数据驱动的设计建议
- **Writing Plans 阶段** —— 每个任务自动分配最合适的专家角色和对应的设计 skill，不再是一个人的 TODO list
- **Execute 阶段** —— subagent 按角色执行，Skill Router 找到对应专家定义注入 prompt，设计任务先查 skill 再写代码
- **Verify 阶段** —— 完成前自动推荐 security-audit、architecture-review、UX 验证，上线前帮你再看一眼

**不装：** 你是一个全栈开发。
**装了：** 你是一个全栈开发 + 产品经理 + UI 设计师 + 安全顾问 + 架构师 + 市场总监 + ……

---

## 协作流程一览

```
用户提出需求
    |
    v
[Brainstorm] ──> Skill Router 搜索匹配专家 + 设计智能
    |                  "从产品/市场/安全/设计多角度审视需求"
    |                  "UI/UX 项目自动运行 search.py --design-system"
    v
[Plan] ──> 每个任务分配专家角色 + 设计 skill
    |          "安全相关任务 -> 安全专家"
    |          "视觉设计任务 -> UI Designer -> ui-ux-pro-max"
    v
[Execute] ──> Skill Router 加载专家定义 + skill 指令
    |              "读取 .md 注入 subagent prompt"
    |              "设计任务先查 skill 再写代码"
    v
[Verify] ──> security-audit + architecture-review + UX 验证
    |              "上线前最后一道防线"
    v
  交付
```

---

## 模块化安装

Superpowers 是必装的基础层，其它组件按需加装：

```bash
git clone https://github.com/agent-skill-hub/superpowers-crew.git ~/develop/code/git/superpowers-crew
cd ~/develop/code/git/superpowers-crew

# 只装基础（Superpowers + Skill Router + hook）
./setup.sh

# 加装领域专家（→ crew-archive，零上下文开销）
./setup.sh --agents

# 加装设计智能（7 个设计 skill）
./setup.sh --design

# 加装安全护栏（security-audit + architecture-review）
./setup.sh --gstack

# 混搭
./setup.sh --agents --design

# 全装
./setup.sh --all

# 查看当前安装状态
./setup.sh --status
```

> 详细说明请参考 `setup.md`。

---

## 组件详情

### 领域专家（--agents）

50+ 非工程角色，安装到 `~/.claude/crew-archive/`，通过 Skill Router 按需发现：

| 类别 | 角色示例 |
|------|---------|
| 产品 | Product Manager, UX Researcher, Growth Hacker |
| 营销 | Content Strategist, SEO Specialist, Social Media Strategist |
| 销售 | Sales Engineer, Account Strategist, Deal Strategist |
| 设计 | Inclusive Visuals Specialist（抗 AI 图像偏见） |
| 游戏 | Psychologist, Narratologist, Geographer, Historian |
| 运营 | Project Shepherd, Studio Producer, Incident Response Commander |
| ... | 还有很多，`python skill-router/scripts/search.py "关键词"` 搜一下 |

你不需要手动选角色。Superpowers 流程中 Skill Router 自动搜索最匹配的专家，读取完整定义后注入 subagent。

### Skill Router（自动安装）

crew-archive 的唯一入口。在 `~/.claude/skills/` 中只占一条描述（~50 tokens），按需时 dispatch subagent 读 `registry.csv` 做语义匹配。

```bash
# 手动搜索（BM25 快速查找）
python ~/.claude/skills/skill-router/scripts/search.py "compliance audit"

# 新增归档后重建索引
python ~/.claude/skills/skill-router/scripts/build_registry.py
```

### 设计智能（--design）

7 个设计 skill，覆盖从品牌到实现的全链路：

| Skill | 做什么 |
|-------|-------|
| `ui-ux-pro-max` | 设计搜索引擎：67 风格、161 调色板、57 字体、99 UX 规则 |
| `design` | Logo（55 风格）、CIP 品牌样机、图标、社交图片 |
| `brand` | 品牌声音、视觉识别、消息框架、一致性审计 |
| `banner-design` | 22 种风格的 Banner（社交/广告/网页/印刷） |
| `ui-styling` | shadcn/ui + Tailwind CSS + 暗黑模式 + 无障碍组件 |
| `design-system` | 三层 Token（primitive->semantic->component）、CSS 变量 |
| `slides` | HTML 演示文稿 + Chart.js 数据可视化 |

### 安全护栏（--gstack）

| Skill | 做什么 |
|-------|-------|
| `/security-audit` | OWASP+STRIDE 安全审计，17 条误报排除，8/10 置信度门槛，1-10 置信度分级 |
| `/architecture-review` | 架构评审，15 认知模式，ASCII 覆盖图，E2E/EVAL 决策矩阵，Outside Voice 独立挑战 |

两个 skill 都是从 gstack 上游**只抽方法论、剥掉 harness**的精简版——保留"审什么、怎么审"的判断标准，剥掉 gstack 专有二进制、目录约定、跨 skill 链，以及任何依赖 gstack 运行时的状态语义。从 gstack 上游同步新能力时请参考 [setup.md 第四步](setup.md#第四步安装-gstack-精简版-skills可选) 的精简原则。

---

## 自定义补丁

补丁文件在 `patches/` 目录下，每个文件对应一个 Superpowers skill。添加新补丁只需创建文件，不用改脚本。

**补丁文件格式：**

```markdown
<!-- ANCHOR: skill 中的锚点文本 -->
<!-- PATCH:skill-name vN -->

要注入的内容...
```

- 文件名 = skill 名（`xxx.patch.md` -> 打到 `skills/xxx/SKILL.md`）
- 第 1 行 = 锚点（注入到该行之后）
- 第 2 行 = 补丁标记（用于幂等检测）
- 其余 = 注入内容

---

## 扩展 crew-archive

你可以往 `~/.claude/crew-archive/` 放任意 .md 文件（agent 或 skill），然后重建索引：

```bash
python ~/.claude/skills/skill-router/scripts/build_registry.py
```

即使放入上千个文件，上下文开销始终为零——只有被搜索命中的才会被加载。

---

## 适合谁用

- 独立开发者想要"团队感"的协作体验
- 用 Claude Code 做完整项目交付，不只是写函数
- 想让 AI 在动手前先"想清楚"，而不是上来就生成代码
- 关心设计质量，希望 UI/UX 决策有数据支撑
- 关心安全和架构质量，希望有自动化的 review 环节

## 不适合谁

- 只想让 AI 补全几行代码的场景——杀鸡用牛刀了
- 不用 Claude Code 的用户——这套系统是为 Claude Code 设计的

---

## 致谢

站在四个开源项目的肩膀上：

- **Superpowers** by [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — 思考流程的骨架
- **Agency Agents** by [@msitarzewski](https://github.com/msitarzewski/agency-agents) — 50+ 领域专家的灵魂
- **ui-ux-pro-max-skill** by [@nextlevelbuilder](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) — 设计智能的眼睛
- **Gstack** by [@garrytan](https://github.com/garrytan/gstack) — 安全与架构的底线

---

## License

MIT
