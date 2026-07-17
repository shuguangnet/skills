#!/usr/bin/env bash

set -Eeuo pipefail

REPO="shuguangnet/skills"
REF="${SKILLS_REF:-main}"
FORCE=0
INSTALL_ALL=0
INSTALL_ALL_TARGETS=0
LIST_ONLY=0
LIST_TARGETS_ONLY=0
CUSTOM_DEST=""
REQUESTED=()
REQUESTED_TARGETS=()
WORK_DIR=""
SUPPORTED_TARGETS=(codex claude opencode qoder pi reasonix)

if [[ -t 1 ]]; then
  BLUE=$'\033[1;34m'
  GREEN=$'\033[1;32m'
  RED=$'\033[1;31m'
  RESET=$'\033[0m'
else
  BLUE=""
  GREEN=""
  RED=""
  RESET=""
fi

info() { printf '%s%s%s\n' "$BLUE" "$*" "$RESET"; }
success() { printf '%s%s%s\n' "$GREEN" "$*" "$RESET"; }
error() { printf '%s错误：%s%s\n' "$RED" "$*" "$RESET" >&2; }

cleanup() {
  if [[ -n "$WORK_DIR" && -d "$WORK_DIR" ]]; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Agent Skills 安装器

用法：
  ./install.sh                                      交互选择平台和 skill
  ./install.sh -t <平台> <skill> [skill...]        安装到指定平台
  ./install.sh -t <平台1,平台2> --all              安装全部 skill

选项：
  -t, --target <平台>  目标平台，可重复或使用逗号分隔
      --all-targets   安装到全部支持的平台
      --list-targets  列出支持的平台及安装目录
  -a, --all           安装全部 skill
  -l, --list          列出可用 skill
  -d, --dest <目录>   安装到自定义目录，不再选择平台
  -f, --force         覆盖已安装的同名 skill
  -h, --help          显示帮助

支持平台：codex、claude、opencode、qoder、pi、reasonix

环境变量：
  SKILLS_REF               Git 分支或标签，默认 main
  CODEX_HOME               Codex 数据目录
  CLAUDE_CONFIG_DIR        Claude Code 配置目录
  OPENCODE_CONFIG_DIR      OpenCode 配置目录
  AGENT_SKILLS_HOME        Qoder/通用 Agent Skills 数据目录
  PI_CODING_AGENT_DIR      Pi agent 配置目录
  REASONIX_HOME            Reasonix 数据目录
EOF
}

need_value() {
  if [[ $# -lt 2 ]]; then
    error "$1 需要一个参数"
    exit 2
  fi
}

add_targets() {
  local value item
  value="${1//,/ }"
  for item in $value; do
    REQUESTED_TARGETS+=("$item")
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all) INSTALL_ALL=1; shift ;;
    -l|--list) LIST_ONLY=1; shift ;;
    -t|--target) need_value "$@"; add_targets "$2"; shift 2 ;;
    --all-targets) INSTALL_ALL_TARGETS=1; shift ;;
    --list-targets) LIST_TARGETS_ONLY=1; shift ;;
    -d|--dest) need_value "$@"; CUSTOM_DEST="$2"; shift 2 ;;
    -f|--force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; REQUESTED+=("$@"); break ;;
    -*) error "未知选项：$1"; usage >&2; exit 2 ;;
    *) REQUESTED+=("$1"); shift ;;
  esac
done

target_label() {
  case "$1" in
    codex) printf 'Codex' ;;
    claude) printf 'Claude Code' ;;
    opencode) printf 'OpenCode' ;;
    qoder) printf 'Qoder' ;;
    pi) printf 'Pi' ;;
    reasonix) printf 'Reasonix' ;;
    custom) printf '自定义目录' ;;
  esac
}

target_dir() {
  case "$1" in
    codex) printf '%s/skills' "${CODEX_HOME:-$HOME/.codex}" ;;
    claude) printf '%s/skills' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}" ;;
    opencode) printf '%s/skills' "${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}" ;;
    qoder) printf '%s/skills' "${AGENT_SKILLS_HOME:-$HOME/.agents}" ;;
    pi) printf '%s/skills' "${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}" ;;
    reasonix) printf '%s/skills' "${REASONIX_HOME:-$HOME/.reasonix}" ;;
    custom) printf '%s' "$CUSTOM_DEST" ;;
  esac
}

canonical_target() {
  case "$1" in
    codex|openai) printf 'codex' ;;
    claude|claude-code|claudecode) printf 'claude' ;;
    opencode|open-code) printf 'opencode' ;;
    qoder|qodercli) printf 'qoder' ;;
    pi|pi-coding-agent) printf 'pi' ;;
    reasonix) printf 'reasonix' ;;
    *) return 1 ;;
  esac
}

print_targets() {
  local i target
  printf '支持的平台：\n'
  for i in "${!SUPPORTED_TARGETS[@]}"; do
    target="${SUPPORTED_TARGETS[$i]}"
    printf '  %2d) %-12s %-16s %s\n' \
      "$((i + 1))" "$target" "$(target_label "$target")" "$(target_dir "$target")"
  done
}

if [[ $LIST_TARGETS_ONLY -eq 1 ]]; then
  print_targets
  exit 0
fi

if [[ -n "$CUSTOM_DEST" && ( ${#REQUESTED_TARGETS[@]} -gt 0 || $INSTALL_ALL_TARGETS -eq 1 ) ]]; then
  error "--dest 不能与 --target 或 --all-targets 同时使用"
  exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)"
if [[ -d "$SCRIPT_DIR/skills" ]]; then
  SOURCE_DIR="$SCRIPT_DIR/skills"
else
  WORK_DIR="$(mktemp -d)"
  ARCHIVE="$WORK_DIR/repo.tar.gz"
  URL="https://github.com/$REPO/archive/$REF.tar.gz"

  info "正在获取 $REPO ($REF)..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$URL" -o "$ARCHIVE"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$ARCHIVE" "$URL"
  else
    error "需要 curl 或 wget 才能下载安装包"
    exit 1
  fi

  if ! command -v tar >/dev/null 2>&1; then
    error "需要 tar 才能解压安装包"
    exit 1
  fi
  tar -xzf "$ARCHIVE" -C "$WORK_DIR"
  SOURCE_DIR=""
  for candidate in "$WORK_DIR"/*/skills; do
    if [[ -d "$candidate" ]]; then
      SOURCE_DIR="$candidate"
      break
    fi
  done
  if [[ -z "$SOURCE_DIR" ]]; then
    error "安装包中未找到 skills 目录"
    exit 1
  fi
fi

AVAILABLE=()
for skill_file in "$SOURCE_DIR"/*/SKILL.md; do
  if [[ -f "$skill_file" ]]; then
    skill_dir="${skill_file%/SKILL.md}"
    AVAILABLE+=("${skill_dir##*/}")
  fi
done

if [[ ${#AVAILABLE[@]} -eq 0 ]]; then
  error "没有发现可安装的 skill"
  exit 1
fi

description_for() {
  sed -n 's/^description:[[:space:]]*//p' "$SOURCE_DIR/$1/SKILL.md" | head -n 1
}

print_skills() {
  local i name description
  printf '可用 Skills：\n'
  for i in "${!AVAILABLE[@]}"; do
    name="${AVAILABLE[$i]}"
    description="$(description_for "$name")"
    printf '  %2d) %-28s %s\n' "$((i + 1))" "$name" "$description"
  done
}

if [[ $LIST_ONLY -eq 1 ]]; then
  print_skills
  exit 0
fi

read_choice() {
  local result
  if IFS= read -r result 2>/dev/null </dev/tty; then
    :
  else
    IFS= read -r result
  fi
  printf '%s' "$result"
}

SELECTED_TARGETS=()
if [[ -n "$CUSTOM_DEST" ]]; then
  SELECTED_TARGETS=(custom)
elif [[ $INSTALL_ALL_TARGETS -eq 1 ]]; then
  SELECTED_TARGETS=("${SUPPORTED_TARGETS[@]}")
elif [[ ${#REQUESTED_TARGETS[@]} -gt 0 ]]; then
  for requested_target in "${REQUESTED_TARGETS[@]}"; do
    if ! normalized_target="$(canonical_target "$requested_target")"; then
      error "不支持的平台：$requested_target（可使用 --list-targets 查看）"
      exit 1
    fi
    SELECTED_TARGETS+=("$normalized_target")
  done
else
  print_targets
  printf '\n选择安装平台（多个用空格或逗号分隔，a=全部，q=退出）：'
  target_choice="$(read_choice)"
  case "$target_choice" in
    a|A|all|ALL) SELECTED_TARGETS=("${SUPPORTED_TARGETS[@]}") ;;
    q|Q|quit|QUIT|'') info "已取消安装"; exit 0 ;;
    *)
      target_choice="${target_choice//,/ }"
      for item in $target_choice; do
        if [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#SUPPORTED_TARGETS[@]} )); then
          SELECTED_TARGETS+=("${SUPPORTED_TARGETS[$((item - 1))]}")
        elif normalized_target="$(canonical_target "$item")"; then
          SELECTED_TARGETS+=("$normalized_target")
        else
          error "不支持的平台：$item"
          exit 1
        fi
      done
      ;;
  esac
fi

SELECTED=()
if [[ $INSTALL_ALL -eq 1 ]]; then
  SELECTED=("${AVAILABLE[@]}")
elif [[ ${#REQUESTED[@]} -gt 0 ]]; then
  SELECTED=("${REQUESTED[@]}")
else
  printf '\n'
  print_skills
  printf '\n选择 skill（多个用空格或逗号分隔，a=全部，q=退出）：'
  choice="$(read_choice)"
  case "$choice" in
    a|A|all|ALL) SELECTED=("${AVAILABLE[@]}") ;;
    q|Q|quit|QUIT|'') info "已取消安装"; exit 0 ;;
    *)
      choice="${choice//,/ }"
      for item in $choice; do
        if [[ "$item" =~ ^[0-9]+$ ]] && (( item >= 1 && item <= ${#AVAILABLE[@]} )); then
          SELECTED+=("${AVAILABLE[$((item - 1))]}")
        else
          SELECTED+=("$item")
        fi
      done
      ;;
  esac
fi

is_available() {
  local candidate available
  candidate="$1"
  for available in "${AVAILABLE[@]}"; do
    [[ "$candidate" == "$available" ]] && return 0
  done
  return 1
}

for name in "${SELECTED[@]}"; do
  if ! is_available "$name"; then
    error "不存在的 skill：$name（可使用 --list 查看）"
    exit 1
  fi
done

installed=0
skipped=0
seen_destinations=" "
for selected_target in "${SELECTED_TARGETS[@]}"; do
  destination="$(target_dir "$selected_target")"
  [[ "$seen_destinations" == *" $destination "* ]] && continue
  seen_destinations+="$destination "
  mkdir -p "$destination"

  seen_names=" "
  for name in "${SELECTED[@]}"; do
    [[ "$seen_names" == *" $name "* ]] && continue
    seen_names+="$name "
    target="$destination/$name"

    if [[ -e "$target" ]]; then
      if [[ $FORCE -ne 1 ]]; then
        printf '跳过 %s / %s：目标已存在（使用 --force 覆盖）\n' \
          "$(target_label "$selected_target")" "$name"
        ((skipped += 1))
        continue
      fi
      rm -rf "$target"
    fi

    cp -R "$SOURCE_DIR/$name" "$target"
    success "已安装：$(target_label "$selected_target") / $name -> $target"
    ((installed += 1))
  done
done

printf '\n完成：安装 %d 份，跳过 %d 份。\n' "$installed" "$skipped"
if (( installed > 0 )); then
  printf '请重新启动或重新加载对应 Agent 的 skills。\n'
fi
