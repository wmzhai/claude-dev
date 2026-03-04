# Claude Code Skills

一组自定义的 [Claude Code](https://claude.ai/code) slash command skills，用于简化日常开发工作流。

## 安装

将本仓库克隆到 `~/.claude/skills/` 目录即可被 Claude Code 自动加载：

```bash
git clone git@github.com:wmzhai/skills.git ~/.claude/skills
```

## Skills 一览

| Skill | 命令 | 说明 |
|-------|------|------|
| [issue2task](#issue2task) | `/issue2task` | 从 GitHub Issues 拆解为有序开发任务 |
| [checktask](#checktask) | `/checktask` | 验收任务并更新完成状态 |
| [ship](#ship) | `/ship` | 提交、推送、可选版本部署 |

---

### issue2task

从 GitHub Issues 自动分析、拆解、合并为粒度合理的开发任务文件。

**用法：**

```
/issue2task                          # 分析所有 open issues
/issue2task --label "feature"        # 只分析特定 label
/issue2task --milestone "v2.0"       # 只分析特定 milestone
```

**产出：**

- `tasks/T01-xxx.md`, `tasks/T02-xxx.md` ... — 按依赖顺序编号的任务文件
- `tasks/README.md` — 任务索引表

每个任务文件包含来源 Issue、任务描述、验收标准（checkbox 列表）和前置依赖。任务粒度控制在 1-3 小时可完成。

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

Commit 消息自动使用 conventional commits 格式，附带 `Co-Authored-By: Claude`。

---

## 典型工作流

```
/issue2task          # 1. 将 Issues 拆解为任务
                     # 2. 按任务顺序逐个开发
/checktask           # 3. 验收当前任务
/ship                # 4. 提交推送
                     # 重复 2-4 直到所有任务完成
/ship v1.0.0         # 5. 发版部署
```

## 编写新 Skill

在仓库中创建 `{skill-name}/SKILL.md`，格式如下：

```markdown
---
name: skill-name
description: 一句话描述
allowed-tools: Bash, Read, Write, ...
---

# 标题

执行指令（支持 $ARGUMENTS 引用用户参数）
```

`allowed-tools` 只授权实际需要的工具，遵循最小权限原则。
