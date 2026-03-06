---
name: ship
description: 提交代码并推送，可选版本号触发部署
allowed-tools: Bash, Read, Glob, Grep
---

# Ship — 提交、推送、可选部署

将当前工作区变更提交并推送到远程。如果提供版本号参数，还会创建 git tag 触发 CI/CD 自动部署。

## Step 1 — 检查当前状态

运行以下命令了解工作区状态：

```bash
git status
git log --oneline -5
```

- 如果没有任何变更（工作区干净）且没有版本号参数，告诉用户"没有需要提交的变更"并结束。
- 记录近期 commit 消息风格，后续生成 commit 消息时保持一致。

## Step 2 — 根据是否有版本号参数分支处理

检查 `$ARGUMENTS` 是否包含版本号。

---

### 路径 A：无参数（`/ship`）

1. **运行本地 CI（如有）**：先检查 `package.json` 中是否存在 `ci` script（或项目是否有 `package.json`）。如果没有则直接跳过此步，不要尝试运行。如果有，执行 `bun run ci`，失败则停止流程并向用户报告具体错误，不要继续提交。
2. **暂存变更**：CI 通过后，运行 `git add -A` 暂存所有变更。
3. **生成 commit 消息**：分析 `git diff --cached` 的内容，生成符合 conventional commits 格式的消息（`feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `chore:` 等）。消息应简洁准确地描述变更内容。
4. **提交**：使用 HEREDOC 格式执行 `git commit`，让 pre-commit hook 正常运行。
5. **处理 hook 修改**：如果 pre-commit hook 修改了文件（如格式化），需要重新 `git add -A` 并创建一个**新的** commit（不要用 `--amend`）。
6. **推送**：运行 `git push` 推送到远程。

---

### 路径 B：带版本号（如 `/ship v0.1.3`）

1. **校验版本号格式**：版本号必须匹配 `v\d+\.\d+\.\d+`（如 `v0.1.3`、`v1.0.0`）。格式不对则报错并停止。
2. **检查 tag 是否已存在**：运行 `git tag -l <version>`，如果已存在则报错并停止。
3. **提交变更（如有）**：如果有未提交变更，执行 `git add -A` → 分析变更 → 生成 conventional commit 消息 → `git commit`（同路径 A 的 HEREDOC 格式）。如果 pre-commit hook 修改了文件，重新 stage 并创建新 commit。
4. **推送代码**：运行 `git push` 推送到远程。
5. **创建 tag**：运行 `git tag <version>`。
6. **推送 tag**：运行 `git push origin <version>` 触发 CI/CD。
7. **提示用户**：告知 tag 已推送，CI 将自动触发并部署。

---

## Step 3 — 输出摘要

完成后输出简洁的摘要，包含：

- 提交了哪些变更（简要列出修改的文件或变更类型）
- 推送到了哪个分支
- 是否创建了 tag（如果是路径 B）
- commit hash

## 重要注意事项

- **提交所有变更，不做任何过滤**：`git add -A` 后直接提交，不要对任何文件做额外判断（如跳过 todo.md、忽略某类文件等）。用户会在执行 `/ship` 前自行清理不需要提交的文件，skill 只管全部提交。
- **绝不使用 `--no-verify`** 跳过 git hooks
- **绝不使用 `--amend`**，始终创建新 commit
- commit 消息必须使用 HEREDOC 格式传递，且**不要**添加 `Co-Authored-By` 签名行：
  ```bash
  git commit -m "$(cat <<'EOF'
  feat: 描述变更内容
  EOF
  )"
  ```
- 版本号参数从 `$ARGUMENTS` 变量读取
- 路径 B 不运行本地 CI（CI 由 GitHub Actions 在 tag 推送后自动运行）
