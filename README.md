# Superpowers Agency Gstack

> 一个人写代码，三支团队在背后。

把 **思考流程**、**领域专家**、**安全护栏** 三层能力焊死在一起，让 Claude Code 从"能写代码的 AI"变成"能交付项目的 AI"。

---

## 这是什么

三个开源项目的精华，拼成一套完整的 AI 协作系统：

| 层级 | 项目来源 | 干什么的 |
|------|---------|---------|
| 思考流程层 | [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) (Superpowers) | brainstorm -> plan -> execute -> verify，把"想到哪写到哪"变成有章法的开发 |
| 领域专家层 | [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents) (Agency Agents) | 50+ 非工程角色——营销、产品、销售、设计、法务……想得到的都有 |
| 工程执行层 | [garrytan/gstack](https://github.com/garrytan/gstack) (Gstack 精简版) | 提取了 security-audit 和 architecture-review 两个 skill，交付前最后一道关 |

一句话总结：**Superpowers 管流程，Agency Agents 管视角，Gstack 管底线。**

---

## 为什么值得装

单独用 Claude Code 写代码，够快，但容易"工程师思维"一条路走到黑。

装上这套系统之后：

- **Brainstorming 阶段** —— hook 自动派遣领域专家，产品经理会问"用户真的需要这个吗"，安全专家会问"这个接口裸奔没问题吗"
- **Writing Plans 阶段** —— 每个任务自动分配最合适的专家角色，不再是一个人的 TODO list
- **Execute 阶段** —— subagent 按角色 framing 执行，营销文案就用营销专家的视角写，不是程序员硬凑
- **Verify 阶段** —— 完成前自动推荐 security-audit 和 architecture-review，上线前帮你再看一眼

**不装：** 你是一个全栈开发。
**装了：** 你是一个全栈开发 + 产品经理 + 安全顾问 + 架构师 + 市场总监 + ……

---

## 协作流程一览

```
用户提出需求
    |
    v
[Brainstorm] ──> Agency Agents hook 自动派遣领域专家
    |                  "从产品/市场/安全多角度审视需求"
    v
[Plan] ──> 每个任务分配专家角色
    |          "安全相关任务 -> 安全专家"
    |          "用户体验任务 -> 设计专家"
    v
[Execute] ──> subagent 按角色执行
    |
    v
[Verify] ──> Gstack security-audit + architecture-review
    |              "上线前最后一道防线"
    v
  交付
```

---

## 50+ 专家角色速览

Agency Agents 覆盖的领域远比你想象的多：

| 类别 | 角色示例 |
|------|---------|
| 产品 | Product Manager, UX Researcher, Growth Hacker |
| 营销 | Content Strategist, SEO Specialist, Brand Manager |
| 销售 | Sales Engineer, Account Executive, Customer Success |
| 设计 | UI Designer, Design System Lead, Motion Designer |
| 运营 | DevOps Engineer, SRE, Technical Writer |
| 商业 | Business Analyst, Financial Modeler, Legal Advisor |
| ... | 还有很多，装了自己看 |

你不需要手动选角色。系统根据上下文自动判断该派谁出场。

---

## 安装

所有安装细节都在 `setup.md` 里，按步骤操作即可。

```bash
# 简单来说就是三步：
# 1. 安装 Superpowers（思考流程层）
# 2. 安装 Agency Agents（领域专家层）
# 3. 安装 Gstack 精简版（工程执行层）

# 具体命令和配置请参考 setup.md
cat setup.md
```

> **提示：** 三个组件之间有依赖顺序，请严格按照 setup.md 的步骤来。

---

## 适合谁用

- 独立开发者想要"团队感"的协作体验
- 用 Claude Code 做完整项目交付，不只是写函数
- 想让 AI 在动手前先"想清楚"，而不是上来就生成代码
- 关心安全和架构质量，希望有自动化的 review 环节

## 不适合谁

- 只想让 AI 补全几行代码的场景——杀鸡用牛刀了
- 不用 Claude Code 的用户——这套系统是为 Claude Code 设计的

---

## 致谢

站在三个开源项目的肩膀上：

- **Superpowers** by [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) — 思考流程的骨架
- **Agency Agents** by [@msitarzewski](https://github.com/msitarzewski/agency-agents) — 50+ 领域专家的灵魂
- **Gstack** by [@garrytan](https://github.com/garrytan/gstack) — 安全与架构的底线

---

## License

MIT
