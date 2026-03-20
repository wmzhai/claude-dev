#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SETUP_SCRIPT="${REPO_ROOT}/setup"
MANAGED_SKILLS=(issue2task plantask checktask ships)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  local actual

  [ -L "$path" ] || fail "${path} is not a symlink"
  actual="$(readlink "$path")"
  [ "$actual" = "$expected" ] || fail "${path} points to ${actual}, expected ${expected}"
}

assert_missing() {
  local path="$1"
  [ ! -e "$path" ] && [ ! -L "$path" ] || fail "${path} should be missing"
}

assert_exists() {
  local path="$1"
  [ -e "$path" ] || [ -L "$path" ] || fail "${path} should exist"
}

write_legacy_skill() {
  local skills_dir="$1"
  local skill_name="$2"

  mkdir -p "${skills_dir}/${skill_name}"
  cat > "${skills_dir}/${skill_name}/SKILL.md" <<EOF
---
name: ${skill_name}
description: legacy fixture
---
EOF
}

run_setup() {
  local home_dir="$1"
  HOME="$home_dir" "$SETUP_SCRIPT" >/dev/null
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fresh_home="${TMP_ROOT}/fresh-home"
mkdir -p "$fresh_home"
run_setup "$fresh_home"

fresh_skills="${fresh_home}/.claude/skills"
assert_symlink_target "${fresh_skills}/claude-dev" "${REPO_ROOT}"
for skill_name in "${MANAGED_SKILLS[@]}"; do
  assert_symlink_target "${fresh_skills}/${skill_name}" "claude-dev/${skill_name}"
done
assert_missing "${fresh_skills}/ship"

run_setup "$fresh_home"
assert_symlink_target "${fresh_skills}/claude-dev" "${REPO_ROOT}"
for skill_name in "${MANAGED_SKILLS[@]}"; do
  assert_symlink_target "${fresh_skills}/${skill_name}" "claude-dev/${skill_name}"
done

legacy_home="${TMP_ROOT}/legacy-home"
legacy_skills="${legacy_home}/.claude/skills"
mkdir -p "${legacy_skills}/.git"
touch "${legacy_skills}/CLAUDE.md" "${legacy_skills}/README.md" "${legacy_skills}/.gitignore"
write_legacy_skill "$legacy_skills" "issue2task"
write_legacy_skill "$legacy_skills" "plantask"
write_legacy_skill "$legacy_skills" "checktask"
write_legacy_skill "$legacy_skills" "ship"
ln -s "/tmp/gstack" "${legacy_skills}/gstack"
ln -s "/tmp/gstack-ship" "${legacy_skills}/gstack-ship"

run_setup "$legacy_home"

assert_missing "${legacy_skills}/.git"
assert_missing "${legacy_skills}/CLAUDE.md"
assert_missing "${legacy_skills}/README.md"
assert_missing "${legacy_skills}/.gitignore"
assert_missing "${legacy_skills}/ship"
assert_symlink_target "${legacy_skills}/gstack" "/tmp/gstack"
assert_symlink_target "${legacy_skills}/gstack-ship" "/tmp/gstack-ship"
assert_symlink_target "${legacy_skills}/claude-dev" "${REPO_ROOT}"
for skill_name in "${MANAGED_SKILLS[@]}"; do
  assert_symlink_target "${legacy_skills}/${skill_name}" "claude-dev/${skill_name}"
done

conflict_home="${TMP_ROOT}/conflict-home"
conflict_skills="${conflict_home}/.claude/skills"
mkdir -p "${conflict_skills}/issue2task"

if HOME="$conflict_home" "$SETUP_SCRIPT" >/dev/null 2>&1; then
  fail "setup should fail when a managed skill path is a real directory"
fi

assert_exists "${conflict_skills}/issue2task"
assert_missing "${conflict_skills}/claude-dev"
assert_missing "${conflict_skills}/ships"

echo "setup smoke tests passed"
