# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

这是一个 Claude Code 的私人 skill 仓库，存放自定义的 slash command skill 定义。每个 skill 是一个目录，内含 `SKILL.md` 文件，通过 YAML frontmatter 定义名称、描述和允许的工具，正文是执行指令。

仓库位于 `~/.claude/skills/`，被 Claude Code 自动加载为可用的 slash command。

## 仓库结构

```
{skill-name}/SKILL.md   — 每个 skill 一个目录，核心文件是 SKILL.md
```

### SKILL.md 格式

```markdown
---
name: skill-name
description: 一句话描述
allowed-tools: Bash, Read, Write, ...
disable-model-invocation: true       # 可选，有副作用的 skill 设为 true
argument-hint: "[arg-description]"   # 可选，自动补全中的参数提示
---

# 标题

具体执行指令（支持 $ARGUMENTS 引用用户参数）
```

## 现有 Skills

- **issue2task** — 从 GitHub Issues 拆解为 `tasks/` 目录下的有序开发任务文件
- **plantask** — 读取任务文件，进入 plan mode 规划实现方案
- **checktask** — 验收 `tasks/` 下编号最小的任务，逐项检查验收标准，通过则移入 `tasks/done/`
- **ship** — 提交代码并推送，可选带版本号（`/ship v0.1.3`）创建 tag 触发部署

## Skills 之间的协作关系

`issue2task` → 生成任务文件 → 开发者实现 → `checktask` 验收 → `ship` 提交推送

## 编写新 Skill 的约定

- 目录名即 skill 名，保持简短的 kebab-case
- `allowed-tools` 只授权 skill 实际需要的工具，遵循最小权限
- 用户参数通过 `$ARGUMENTS` 变量传入
- 执行指令应结构清晰，分步骤描述，包含异常处理
- skill 不应自行 git commit，提交由用户或 `/ship` 统一处理
- 有副作用的 skill（写文件、推代码、调外部 API）应设置 `disable-model-invocation: true`
