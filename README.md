# Claude Code Skills

一组自定义的 [Claude Code](https://claude.ai/code) slash command skills，用于简化日常开发工作流。

## 安装

将本仓库克隆到 `~/.claude/skills/` 目录即可被 Claude Code 自动加载：

```bash
git clone git@github.com:wmzhai/skills.git ~/.claude/skills
```

## 典型工作流

```
/issue2task 42       # 1. 将 Issue 拆解为任务
/plantask            # 2. 规划当前任务的实现方案
                     # 3. 确认方案后编码实现
/checktask           # 4. 验收当前任务
/ship                # 5. 提交推送
                     # 重复 2-5 直到所有任务完成
/ship v1.0.0         # 6. 发版部署
```

## Skills 一览

| Skill | 命令 | 说明 |
|-------|------|------|
| [issue2task](#issue2task) | `/issue2task` | 从 GitHub Issues 拆解为有序开发任务 |
| [plantask](#plantask) | `/plantask` | 读取任务并进入 plan mode 规划实现方案 |
| [checktask](#checktask) | `/checktask` | 验收任务并更新完成状态 |
| [ship](#ship) | `/ship` | 提交、推送、可选版本部署 |

---

### issue2task

从 GitHub Issues 自动分析、拆解、合并为粒度合理的开发任务文件。

**用法：**

```
/issue2task 42                       # 分析指定 issue 并生成任务
/issue2task #42                      # 同上，# 前缀可选
```

**产出：**

- `tasks/T{序号}-xxx.md` — 任务文件

每个任务文件包含来源 Issue、任务描述、验收标准（checkbox 列表）和前置依赖。

---

### plantask

读取 `tasks/` 目录下编号最小的待办任务，深入分析需求和现有代码，进入 plan mode 输出详细实现方案。

**用法：**

```
/plantask              # 规划编号最小的待处理任务
/plantask T05          # 规划指定任务
```

**流程：**

1. 定位 `tasks/` 下目标任务文件，提取需求和验收标准
2. 调用 `EnterPlanMode` 进入规划模式
3. 探索相关代码，分析影响范围，设计实现方案
4. 输出包含文件清单、实现细节、实现顺序的完整规划
5. 使用 `ExitPlanMode` 提交规划，等待用户确认后再编码

注意：规划阶段只做研究和设计，不会编辑任何代码文件。

---

### checktask

逐项验证任务的验收标准，自动更新 checkbox 状态，通过则归档。

**用法：**

```
/checktask              # 检查编号最小的待处理任务
/checktask T04          # 检查指定任务
```

**流程：**

1. 定位 `tasks/` 下目标任务文件
2. 逐条核对验收标准（检查代码、运行 CI 等）
3. 通过的项自动勾选 `[x]`
4. 全部通过 → `git mv` 移入 `tasks/done/`；部分未通过 → 报告待修复项
5. 最后执行 `/simplify` 审查代码质量

注意：只做检查和报告，不会自行修复代码。

---

### ship

一键提交代码并推送到远程，可选创建版本 tag 触发部署。

**用法：**

```
/ship                   # 运行 CI → 提交 → 推送
/ship v0.1.3            # 提交 → 推送 → 创建 tag → 触发部署
```

**无版本号 (`/ship`)：**

1. 运行 `bun run ci`，失败则中止
2. 暂存所有变更，自动生成 conventional commit 消息
3. 提交并推送

**带版本号 (`/ship v0.1.3`)：**

1. 校验版本号格式 (`vX.Y.Z`)
2. 提交变更（如有）并推送
3. 创建 git tag 并推送，触发 CI/CD 部署

Commit 消息自动使用 conventional commits 格式。

---

## 编写新 Skill

在仓库中创建 `{skill-name}/SKILL.md`，格式如下：

```markdown
---
name: skill-name
description: 一句话描述
allowed-tools: Bash, Read, Write, ...
disable-model-invocation: true       # 可选，有副作用的 skill 设为 true
argument-hint: "[arg-description]"   # 可选，自动补全中的参数提示
---

# 标题

执行指令（支持 $ARGUMENTS 引用用户参数）
```

`allowed-tools` 只授权实际需要的工具，遵循最小权限原则。有副作用的 skill 应设置 `disable-model-invocation: true` 防止自动调用。
