---
name: issue2task
description: 分析 GitHub Issues 并拆解为有序的独立开发任务文件
allowed-tools: Bash, Read, Write, Glob, Grep, Agent
---

# Issue to Task — GitHub Issues 拆解为开发任务

你是一个项目规划助手。请分析当前仓库的 GitHub Issues，将它们拆解/合并为粒度合理、可独立开发的任务，并输出为 `tasks/` 目录下的 markdown 文件。

## 执行流程

### 1. 获取 Issues

使用 `gh` CLI 获取当前仓库所有 open issues 的详细信息：

```bash
gh issue list --state open --json number,title,body,labels,comments,milestone,assignees --limit 200 $ARGUMENTS
```

`$ARGUMENTS` 可用于传入额外筛选条件，例如：
- `--label "feature"` — 只看某个 label
- `--milestone "v2.0"` — 只看某个 milestone

如果 `$ARGUMENTS` 为空，则获取所有 open issues。

### 2. 分析与规划

仔细阅读每个 issue 的标题、正文、标签和评论，然后：

- **理解全貌**：梳理项目当前的整体需求图景
- **识别依赖**：哪些 issue 之间存在前后依赖关系
- **合并相关**：将高度相关的小 issue 合并为一个任务
- **拆分过大**：将过于庞大的 issue 拆分为多个可独立完成的任务
- **排定顺序**：按开发逻辑排序，遵循以下优先级：
  1. 基础设施 / 配置 / 环境
  2. 数据模型 / 数据库变更
  3. 后端逻辑 / API / Server Actions
  4. 前端 UI / 页面 / 组件
  5. 测试 / 文档 / 优化

### 3. 生成任务文件

在项目根目录创建 `tasks/` 目录（如已存在则复用），每个任务生成一个 md 文件。

**确定起始编号**：生成前先检查已有任务的最大编号，新任务从最大编号+1 开始。按以下优先级查找：
1. 先看 `tasks/` 目录下现有的 `T{序号}-*.md` 文件
2. 如果 `tasks/` 下没有任务文件，再看 `tasks/done/` 目录下已完成的任务文件
3. 都没有则从 T01 开始

**文件命名**: `T{序号}-{简短描述}.md`，序号两位补零，如 `T01-init-db-schema.md`

**文件模板**:

```markdown
# T{序号}: {任务标题}

## 来源 Issue

{列出相关的 issue 编号和标题，格式：- #123 issue标题}

## 任务描述

{清晰描述这个任务要做什么，包含足够的上下文让开发者理解}

## 验收标准

{用 checkbox 列表列出可验证的完成标准}

- [ ] 标准 1
- [ ] 标准 2

## 前置依赖

{列出必须先完成的任务编号，如无则写"无"}

## 参考信息

{来自 issue 评论中的关键讨论、技术方案等补充信息，如无则省略此节}
```

### 4. 生成索引

所有任务文件创建完成后，生成 `tasks/README.md` 作为索引：

```markdown
# 任务列表

> 由 `/issue2task` 从 GitHub Issues 自动生成

| 序号 | 任务 | 来源 Issue | 前置依赖 |
|------|------|-----------|----------|
| T01 | [任务标题](T01-xxx.md) | #1, #2 | 无 |
| T02 | [任务标题](T02-xxx.md) | #3 | T01 |
```

### 5. 输出摘要

最后向用户输出一份简要摘要：
- 共分析了多少个 issues
- 生成了多少个任务
- 任务的依赖链概览

## 注意事项

- 任务粒度应控制在 **1-3 个小时** 可完成的范围
- 每个任务应该是 **可独立提交** 的，完成后项目仍可正常运行
- 如果 issue 中有明确的技术方案讨论，应体现在任务描述中
- 保留 issue 原文中的关键细节，不要过度精简丢失信息
- 如果项目中已有 `tasks/` 目录且包含旧任务文件，先提示用户确认是否覆盖
