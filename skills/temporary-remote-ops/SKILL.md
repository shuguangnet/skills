---
name: temporary-remote-ops
description: 通过 EasyTier 和临时 SSH 凭据安全访问并执行远程运维任务，包括备份、迁移、文件传输、服务部署与启停、故障诊断、配置修改和数据核验等。适用于 AI Agent 需要按 EasyTier 节点名或主机名连接服务器、现有 SSH 密钥无法登录、需要为 VPS 或内网设备授予可按需保留或撤销的访问权限，或需要在远端完成一组可审计的运维操作时。
---

# 临时远程运维

## 目标与边界

建立一次临时、可审计的远程运维会话，并完成用户批准的实际工作，而不只是测试 SSH。典型任务包括备份、恢复、迁移、文件同步、服务部署或启停、配置变更、日志检查、健康检查和故障诊断。

为每个目标生成专用 ed25519 密钥；不要复用长期个人密钥，也不要输出私钥。除非用户明确要求清理，任务完成后保留本地私钥和远端 `authorized_keys` 中的精确公钥授权，并在报告中说明保留状态和清理命令。

## 工作流程

1. 确认目标、执行范围、完成标准、源端/目标端、数据范围、停机要求、回滚方式和验证标准。
2. 接受 `user@host`、`user@ip`、主机/IP 或 EasyTier 节点名；未指定用户时，VPS 控制台或迁移场景可使用 `root`，否则先询问。
3. 对非明确 IP/DNS 的名称先解析 EasyTier；多个匹配必须展示候选并让用户选择，不能猜测地址。
4. 在本机生成新密钥，注释包含目标、日期和随机后缀；只向用户提供公钥授权命令。
5. 使用 `BatchMode=yes`、`ConnectTimeout`、`StrictHostKeyChecking=accept-new` 验证登录。
6. 先只读盘点，再执行变更、备份、迁移或服务操作；每阶段记录命令、目的、预期和实际结果。
7. 验证服务状态、数据完整性、权限、空间和可回滚性。
8. 默认保留访问状态；只有用户明确要求时，才删除远端精确公钥行和本地密钥对。

## EasyTier 解析

在当前可操作环境尝试以下命令（按可用项执行）：

```bash
easytier-cli peer list || easytier-cli peers || easytier-cli node list || easytier-cli status || easytier peers || easytier status
```

Windows PowerShell 可让用户执行 `easytier-cli.exe peer list`、`easytier-cli.exe peers` 或 `easytier-cli.exe status` 并贴回输出。匹配 hostname、节点名或别名后，从匹配行提取 IPv4；若当前环境没有 CLI，向用户索取组网 IP、完整节点列表输出或可用跳板机。匹配不到时不要把猜测的内网地址用于 SSH。

## 一键准备脚本

以下脚本只在本机生成密钥并打印命令，不会主动修改远端。保存为 `temp-remote-ops.sh` 后运行 `bash temp-remote-ops.sh <host-or-node|user@host> [user] [port]`。

```bash
#!/usr/bin/env bash
set -euo pipefail

target="${1:?用法: bash temp-remote-ops.sh <host-or-node|user@host> [user] [port]}"
default_user="${2:-root}"
port="${3:-22}"
have() { command -v "$1" >/dev/null 2>&1; }
quote_sq() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
sanitize() { printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'; }
is_address() { case "$1" in localhost|*.*|*:*) return 0;; *) return 1;; esac; }
easytier_outputs() {
  if have easytier-cli; then
    easytier-cli peer list 2>/dev/null || true; easytier-cli peers 2>/dev/null || true
    easytier-cli node list 2>/dev/null || true; easytier-cli status 2>/dev/null || true
  fi
  if have easytier; then easytier peer list 2>/dev/null || true; easytier peers 2>/dev/null || true; easytier status 2>/dev/null || true; fi
}
resolve() {
  local q="$1" lines ips count
  lines="$(easytier_outputs | awk -v q="$q" 'BEGIN{IGNORECASE=1} index($0,q)>0 {print}')"
  [ -n "$lines" ] || return 1
  ips="$(printf '%s\n' "$lines" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '!seen[$0]++')"
  [ -n "$ips" ] || return 1
  count="$(printf '%s\n' "$ips" | sed '/^$/d' | wc -l | tr -d ' ')"
  [ "$count" = 1 ] || { printf '多个 EasyTier IP 候选:\n%s\n' "$ips" >&2; return 2; }
  printf '%s\n' "$ips"
}
if [[ "$target" == *@* ]]; then remote_user="${target%@*}"; target_host="${target#*@}"; else remote_user="$default_user"; target_host="$target"; fi
resolved_host="$target_host"; resolved_status=0
if ! is_address "$target_host"; then resolved_host="$(resolve "$target_host")" || resolved_status=$?; [ "$resolved_status" = 2 ] && { echo "EasyTier 名称匹配多个地址，请明确选择" >&2; exit 2; }; [ "$resolved_status" != 0 ] && resolved_host="$target_host"; fi
umask 077; safe_host="$(sanitize "$target_host")"; stamp="$(date +%Y%m%d%H%M%S)"
suffix="$(openssl rand -hex 4 2>/dev/null || date +%s)"; comment="agent-temp-access-${safe_host}-$(date +%Y-%m-%d)-${suffix}"
key_path="$HOME/.ssh/agent_temp_${safe_host}_${stamp}"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -f "$key_path" -N '' -C "$comment" >/dev/null; chmod 600 "$key_path"
pub_line="$(cat "$key_path.pub")"; pub_q="$(quote_sq "$pub_line")"
remote_auth="umask 077; mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF ${pub_q} ~/.ssh/authorized_keys || printf '%s\\n' ${pub_q} >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
remote_cleanup="tmp=\$(mktemp); grep -vxF ${pub_q} ~/.ssh/authorized_keys > \"\$tmp\" || true; cat \"\$tmp\" > ~/.ssh/authorized_keys; rm -f \"\$tmp\"; chmod 600 ~/.ssh/authorized_keys"
host_q="$(quote_sq "$remote_user@$resolved_host")"; port_q="$(quote_sq "$port")"
printf 'target_user=%s\ntarget_name=%s\nresolved_host=%s\nport=%s\nkey_path=%s\npublic_key=%s\n\n' "$remote_user" "$target_host" "$resolved_host" "$port" "$key_path" "$pub_line"
printf '远端授权命令（以 %s 执行）：\n%s\n\n' "$remote_user" "$remote_auth"
printf '验证：\nssh -i %s -p %s -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new %s %s\n\n' "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq 'hostname; whoami; uname -a')"
printf 'SSH：\nssh -i %s -p %s -o StrictHostKeyChecking=accept-new %s\n\n' "$(quote_sq "$key_path")" "$port_q" "$host_q"
printf 'SCP：\nscp -i %s -P %s -o StrictHostKeyChecking=accept-new ./file %s\n\n' "$(quote_sq "$key_path")" "$port_q" "$(quote_sq "$remote_user@$resolved_host:/tmp/")"
printf '清理（仅用户明确要求时）：\nssh -i %s -p %s -o BatchMode=yes %s %s\n随后本机执行：rm -f %s %s\n' "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq "$remote_cleanup")" "$(quote_sq "$key_path")" "$(quote_sq "$key_path.pub")"
```

不要把脚本输出中的私钥内容贴入对话；公钥整行可用于授权。脚本不能解析 EasyTier 时，将名称作为 SSH 主机名仅在用户确认 DNS/hosts 可用后使用。

## 远程执行与验证

- **备份/迁移**：先检查路径、权限、空间、服务依赖和回滚点；迁移采用预同步、最终增量同步、切换后校验。
- **文件传输**：优先 `rsync --dry-run`、断点续传和校验；完成后检查大小、文件数或哈希。
- **服务操作**：先读状态和最近日志，再部署、重启、停止或回滚；未确认影响范围不得停止生产服务。
- **诊断/配置**：优先只读命令；修改前备份原文件，用临时文件校验语法，变更后检查状态。

每项操作都报告命令、目的、预期结果和实际结果。连接成功不等于任务完成。

验证示例：

```bash
ssh -i "$key_path" -p 22 -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new user@host 'hostname; whoami; uname -a'
```

出现 `Permission denied` 时，停止密码重试，核对目标用户、授权执行账号、SSH 端口和公钥登录策略。

## 按需清理与安全规则

只有用户明确提出清理、撤销访问或删除授权时执行。先确认主机、用户、公钥和本地路径，再按完整公钥精确删除，确认远端删除成功后删除本地 `.key` 和 `.pub`。不要按模糊注释删除，也不要改动其他 `authorized_keys` 条目。

始终使用 `StrictHostKeyChecking=accept-new`，不覆盖已有密钥，不关闭主机密钥检查，不自动执行未授权的破坏性操作；任务结束明确说明访问是否仍保留以及清理方式。
