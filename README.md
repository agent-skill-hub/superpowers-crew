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

一句话总结：**Superpowers 管流程，Agency Agents 管视角，Design Skills 管美学，Gstack 管底线。**

---

## 为什么值得装

单独用 Claude Code 写代码，够快，但容易"工程师思维"一条路走到黑。

装上这套系统之后：

- **Brainstorming 阶段** —— hook 自动派遣领域专家，产品经理问"用户真的需要这个吗"，安全专家问"这个接口裸奔没问题吗"；涉及 UI/UX 时自动调用 `search.py` 生成数据驱动的设计建议
- **Writing Plans 阶段** —— 每个任务自动分配最合适的专家角色和对应的设计 skill，不再是一个人的 TODO list
- **Execute 阶段** —— subagent 按角色执行并加载完整 agent 定义，设计任务先查 skill 再写代码，营销文案用营销专家视角写
- **Verify 阶段** —— 完成前自动推荐 security-audit、architecture-review、UX 验证，上线前帮你再看一眼

**不装：** 你是一个全栈开发。
**装了：** 你是一个全栈开发 + 产品经理 + UI 设计师 + 安全顾问 + 架构师 + 市场总监 + ……

---

## 协作流程一览

```
用户提出需求
    |
    v
[Brainstorm] ──> hook 自动派遣领域专家 + 设计智能
    |                  "从产品/市场/安全/设计多角度审视需求"
    |                  "UI/UX 项目自动运行 search.py --design-system"
    v
[Plan] ──> 每个任务分配专家角色 + 设计 skill
    |          "安全相关任务 -> 安全专家"
    |          "视觉设计任务 -> UI Designer -> ui-ux-pro-max"
    |          "品牌任务 -> Brand Strategist -> brand skill"
    v
[Execute] ──> subagent 按角色 + skill 执行
    |              "匹配 subagent_type 加载完整 agent 定义"
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

# 只装基础（Superpowers + hook）
./setup.sh

# 加装领域专家
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

50+ 非工程角色，brainstorming 时由 hook 自动派遣：

| 类别 | 角色示例 |
|------|---------|
| 产品 | Product Manager, UX Researcher, Growth Hacker |
| 营销 | Content Strategist, SEO Specialist, Social Media Strategist |
| 销售 | Sales Engineer, Account Strategist, Deal Strategist |
| 设计 | Inclusive Visuals Specialist（抗 AI 图像偏见） |
| 游戏 | Psychologist, Narratologist, Geographer, Historian |
| 运营 | Project Shepherd, Studio Producer, Incident Response Commander |
| ... | 还有很多，装了自己看 |

你不需要手动选角色。系统根据上下文自动判断该派谁出场，并通过 `subagent_type` 加载完整 agent 定义。

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
| `/security-audit` | OWASP+STRIDE 安全审计，17 条误报排除，8/10 置信度门槛 |
| `/architecture-review` | 架构评审，15 认知模式，ASCII 覆盖图，E2E 决策矩阵 |

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
