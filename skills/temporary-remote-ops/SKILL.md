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
5. 已知目标曾在 EasyTier 上卡默认 KEX 时，第一次连接就使用 `KexAlgorithms=curve25519-sha256`；不要重复探测已知失败路径。
6. 新目标先用单个、5 秒总截止时间的轻量命令验证；不要在传输参数未知时并行启动多个 SSH。
7. 若默认连接超时，EasyTier 目标立即用 `curve25519-sha256` 做 10 秒重试；只有重试也失败才运行 `-vvv`。
8. 验证成功后固化目标专用 SSH 配置、启用短时连接复用，并把负载、磁盘、内存、系统版本等只读检查合并到一个 SSH 会话。
9. 先只读盘点，再执行变更、备份、迁移或服务操作；每阶段记录命令、目的、预期和实际结果。
10. 验证服务状态、数据完整性、权限、空间和可回滚性。
11. 默认保留访问状态；只有用户明确要求时，才删除远端精确公钥行和本地密钥对。

## EasyTier 解析

在当前可操作环境尝试以下命令（按可用项执行）：

```bash
easytier-cli peer list || easytier-cli peers || easytier-cli node list || easytier-cli status || easytier peers || easytier status
```

Windows PowerShell 可让用户执行 `easytier-cli.exe peer list`、`easytier-cli.exe peers` 或 `easytier-cli.exe status` 并贴回输出。匹配 hostname、节点名或别名后，从匹配行提取 IPv4；若当前环境没有 CLI，向用户索取组网 IP、完整节点列表输出或可用跳板机。匹配不到时不要把猜测的内网地址用于 SSH。

## 快速连接与故障分类

首次验证只运行一条轻量命令。GNU/Linux 使用 `timeout`，macOS 安装 coreutils 后使用 `gtimeout`；两者都没有时仍使用 SSH 自身超时参数，但必须主动观察进程，不能无限等待。

若目标是 AFLY，或同一目标旁的 `${key_path}.transport` 已记录 `KexAlgorithms=curve25519-sha256`，跳过默认探测，直接使用兼容 KEX。新目标的默认探测只给 5 秒：

```bash
timeout 5s ssh -i "$key_path" -p "$port" \
  -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 \
  -o ServerAliveInterval=3 -o ServerAliveCountMax=2 \
  -o StrictHostKeyChecking=accept-new user@host 'printf "ready\\n"; hostname; whoami'
```

默认探测超时后不要重复相同命令，也不要立即判断为公钥授权失败。EasyTier 目标先直接尝试 10 秒兼容 KEX；如果它也失败，再跑一次详细诊断并按最后阶段分类：

```bash
timeout 12s ssh -vvv -i "$key_path" -p "$port" \
  -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 \
  -o PreferredAuthentications=publickey -o PasswordAuthentication=no \
  -o KbdInteractiveAuthentication=no -o StrictHostKeyChecking=accept-new \
  user@host 'hostname'
```

- 未出现 `Connection established`：路由、防火墙、端口或 EasyTier 节点可达性问题。
- 已建立连接但停在 `expecting SSH2_MSG_KEX_ECDH_REPLY`：尚未进入认证，优先判断为 EasyTier 链路 MTU/默认混合 KEX 兼容问题。
- 出现 `Offering public key`、`Authentications that can continue` 或 `Permission denied`：已进入认证阶段，再检查用户、公钥和 sshd 策略。
- 已认证但远端命令无输出：检查 shell、远端命令和会话通道，不要重新生成密钥。

EasyTier 链路若卡在 KEX，只尝试现代算法，不降级到 `diffie-hellman-group1-sha1` 等过时算法：

```bash
timeout 10s ssh -i "$key_path" -p "$port" \
  -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 \
  -o ServerAliveInterval=3 -o ServerAliveCountMax=2 \
  -o StrictHostKeyChecking=accept-new \
  -o KexAlgorithms=curve25519-sha256 user@host 'printf "ready\\n"; hostname; whoami'
```

若此命令成功，将 `-o KexAlgorithms=curve25519-sha256` 记录为该目标本次会话的传输配置。随后开启连接复用，避免每条远端命令重复握手：

```bash
ssh -i "$key_path" -p "$port" \
  -o KexAlgorithms=curve25519-sha256 \
  -o ControlMaster=auto -o ControlPersist=10m -o ControlPath=%d/.ssh/cm-%C \
  user@host 'uptime; echo; df -hT /; echo; free -h; echo; cat /etc/os-release'
```

只在默认 KEX 确实卡住时保留强制 KEX 参数；普通公网 SSH 若默认协商成功，继续使用默认算法集。

### 固化已验证配置

验证成功后，在密钥旁创建 `${key_path}.ssh_config` 和 `${key_path}.transport`。配置只包含目标、用户名、端口、密钥路径和已验证传输参数，不包含私钥内容：

```bash
alias_name="agent-temp-$(printf '%s' "$target_host" | tr -c 'A-Za-z0-9_.-' '_')"
config_path="${key_path}.ssh_config"
transport_path="${key_path}.transport"
cat > "$config_path" <<EOF
Host $alias_name
  HostName $resolved_host
  User $remote_user
  Port $port
  IdentityFile $key_path
  IdentitiesOnly yes
  BatchMode yes
  ConnectTimeout 6
  ConnectionAttempts 1
  ServerAliveInterval 3
  ServerAliveCountMax 2
  StrictHostKeyChecking accept-new
  KexAlgorithms curve25519-sha256
  ControlMaster auto
  ControlPersist 10m
  ControlPath %d/.ssh/cm-%C
EOF
printf '%s\n' 'KexAlgorithms=curve25519-sha256' > "$transport_path"
chmod 600 "$config_path" "$transport_path"
```

后续命令缩短为：

```bash
ssh -F "$config_path" "$alias_name" 'uptime; df -hT /; free -h'
scp -F "$config_path" ./file "$alias_name:/tmp/"
rsync -az --partial -e "ssh -F $config_path" ./local-path/ "$alias_name:/remote-path/"
ssh -F "$config_path" -O check "$alias_name"
```

再次使用同一密钥时先读取 `.transport`；如果已经记录兼容 KEX，直接命中配置，不再执行默认算法探测。目标 IP、端口或用户改变时必须重新验证，不能复用旧配置。

## 一键准备脚本

以下脚本只在本机生成密钥并打印命令，不会主动修改远端。保存为 `temp-remote-ops.sh` 后运行 `bash temp-remote-ops.sh <host-or-node|user@host> [user] [port] [auto|easytier]`。已知 AFLY 或已知默认 KEX 不兼容的目标使用 `easytier`，从第一次连接就强制兼容 KEX。

```bash
#!/usr/bin/env bash
set -euo pipefail

target="${1:?用法: bash temp-remote-ops.sh <host-or-node|user@host> [user] [port] [auto|easytier]}"
default_user="${2:-root}"
port="${3:-22}"
transport_profile="${4:-auto}"
have() { command -v "$1" >/dev/null 2>&1; }
require() { have "$1" || { printf '缺少依赖命令: %s\n' "$1" >&2; exit 1; }; }
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
  [ "$count" = 1 ] || {
    printf 'EasyTier 匹配到多个候选。匹配行:\n%s\n候选 IP:\n%s\n' "$lines" "$ips" >&2
    return 2
  }
  printf '%s\n' "$ips"
}
if [[ "$target" == *@* ]]; then remote_user="${target%@*}"; target_host="${target#*@}"; else remote_user="$default_user"; target_host="$target"; fi
[ -n "$remote_user" ] && [ -n "$target_host" ] || { echo '目标用户和主机不能为空' >&2; exit 2; }
case "$remote_user$target_host" in *[[:space:]]*) echo '目标用户和主机不能包含空白字符' >&2; exit 2;; esac
case "$port" in ''|*[!0-9]*) echo '端口必须是 1-65535 的数字' >&2; exit 2;; esac
if (( port < 1 || port > 65535 )); then echo '端口必须是 1-65535 的数字' >&2; exit 2; fi
case "$transport_profile" in auto|easytier) ;; *) echo '传输模式必须是 auto 或 easytier' >&2; exit 2;; esac
for dependency in awk cat grep mktemp sed ssh-keygen tr; do require "$dependency"; done
if have timeout; then deadline_fast='timeout 5s'; deadline_compat='timeout 10s'; elif have gtimeout; then deadline_fast='gtimeout 5s'; deadline_compat='gtimeout 10s'; else deadline_fast=''; deadline_compat=''; fi
resolved_host="$target_host"; resolved_status=0
resolved_via_easytier=0
if ! is_address "$target_host"; then resolved_host="$(resolve "$target_host")" || resolved_status=$?; [ "$resolved_status" = 2 ] && { echo "EasyTier 名称匹配多个地址，请明确选择" >&2; exit 2; }; if [ "$resolved_status" = 0 ]; then resolved_via_easytier=1; else resolved_host="$target_host"; fi; fi
if [ "$transport_profile" = auto ] && [ "$resolved_via_easytier" = 1 ]; then transport_profile=easytier; fi
umask 077; safe_host="$(sanitize "$target_host")"; stamp="$(date +%Y%m%d%H%M%S)"
suffix="$(openssl rand -hex 4 2>/dev/null || date +%s)"; comment="agent-temp-access-${safe_host}-$(date +%Y-%m-%d)-${suffix}"
key_path="$HOME/.ssh/agent_temp_${safe_host}_${stamp}"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
ssh-keygen -t ed25519 -f "$key_path" -N '' -C "$comment" >/dev/null; chmod 600 "$key_path"
pub_line="$(cat "$key_path.pub")"; pub_q="$(quote_sq "$pub_line")"
remote_auth="umask 077; mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF ${pub_q} ~/.ssh/authorized_keys || printf '%s\\n' ${pub_q} >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
remote_cleanup="tmp=\$(mktemp); grep -vxF ${pub_q} ~/.ssh/authorized_keys > \"\$tmp\" || true; cat \"\$tmp\" > ~/.ssh/authorized_keys; rm -f \"\$tmp\"; chmod 600 ~/.ssh/authorized_keys"
host_q="$(quote_sq "$remote_user@$resolved_host")"; port_q="$(quote_sq "$port")"
alias_name="agent-temp-${safe_host}-${stamp}"
config_path="${key_path}.ssh_config"
transport_path="${key_path}.transport"
if [ "$transport_profile" = easytier ]; then
  {
    printf 'Host %s\n' "$alias_name"
    printf '  HostName %s\n  User %s\n  Port %s\n' "$resolved_host" "$remote_user" "$port"
    printf '  IdentityFile "%s"\n' "$key_path"
    printf '  IdentitiesOnly yes\n  BatchMode yes\n  ConnectTimeout 6\n  ConnectionAttempts 1\n'
    printf '  ServerAliveInterval 3\n  ServerAliveCountMax 2\n  StrictHostKeyChecking accept-new\n'
    printf '  KexAlgorithms curve25519-sha256\n  ControlMaster auto\n  ControlPersist 10m\n  ControlPath %%d/.ssh/cm-%%C\n'
  } > "$config_path"
  printf '%s\n' 'KexAlgorithms=curve25519-sha256' > "$transport_path"
  chmod 600 "$config_path" "$transport_path"
fi
deadline_note="${deadline_fast:-请手动在 5 秒后终止命令}"
printf 'target_user=%s\ntarget_name=%s\nresolved_host=%s\nport=%s\ntransport_profile=%s\nkey_path=%s\npublic_key=%s\n' "$remote_user" "$target_host" "$resolved_host" "$port" "$transport_profile" "$key_path" "$pub_line"
if [ "$transport_profile" = easytier ]; then printf 'ssh_config=%s\nssh_alias=%s\ntransport_record=%s\n' "$config_path" "$alias_name" "$transport_path"; fi
printf '\n'
printf '远端授权命令（以 %s 执行）：\n%s\n\n' "$remote_user" "$remote_auth"
if [ "$transport_profile" = easytier ]; then
  printf '已知 EasyTier 兼容模式，跳过默认 KEX（总截止时间：10 秒）：\n%s ssh -i %s -p %s -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 -o ServerAliveInterval=3 -o ServerAliveCountMax=2 -o StrictHostKeyChecking=accept-new -o KexAlgorithms=curve25519-sha256 %s %s\n\n' "$deadline_compat" "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq 'printf "ready\\n"; hostname; whoami')"
  printf '验证成功后的短命令：\nssh -F %s %s\nscp -F %s ./file %s\nrsync -az --partial -e %s ./local-path/ %s\n\n' "$(quote_sq "$config_path")" "$(quote_sq "$alias_name")" "$(quote_sq "$config_path")" "$(quote_sq "$alias_name:/tmp/")" "$(quote_sq "ssh -F $config_path")" "$(quote_sq "$alias_name:/remote-path/")"
else
  printf '新目标快速验证（总截止时间工具：%s）：\n%s ssh -i %s -p %s -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 -o ServerAliveInterval=3 -o ServerAliveCountMax=2 -o StrictHostKeyChecking=accept-new %s %s\n\n' "$deadline_note" "$deadline_fast" "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq 'printf "ready\\n"; hostname; whoami')"
  printf '默认 KEX 超时后的 EasyTier 快速重试：\n%s ssh -i %s -p %s -o BatchMode=yes -o ConnectTimeout=6 -o ConnectionAttempts=1 -o ServerAliveInterval=3 -o ServerAliveCountMax=2 -o StrictHostKeyChecking=accept-new -o KexAlgorithms=curve25519-sha256 %s %s\n\n' "$deadline_compat" "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq 'printf "ready\\n"; hostname; whoami')"
fi
printf 'KEX 重试成功后使用连接复用：\nssh -i %s -p %s -o KexAlgorithms=curve25519-sha256 -o ControlMaster=auto -o ControlPersist=10m -o ControlPath=%%d/.ssh/cm-%%C %s\n\n' "$(quote_sq "$key_path")" "$port_q" "$host_q"
printf 'SCP（KEX 重试成功后）：\nscp -i %s -P %s -o KexAlgorithms=curve25519-sha256 -o ControlMaster=auto -o ControlPersist=10m -o ControlPath=%%d/.ssh/cm-%%C ./file %s\n\n' "$(quote_sq "$key_path")" "$port_q" "$(quote_sq "$remote_user@$resolved_host:/tmp/")"
printf 'rsync（KEX 重试成功后）：\nrsync -az --partial -e %s ./local-path/ %s\n\n' "$(quote_sq "ssh -i $key_path -p $port -o KexAlgorithms=curve25519-sha256 -o ControlMaster=auto -o ControlPersist=10m -o ControlPath=%d/.ssh/cm-%C")" "$(quote_sq "$remote_user@$resolved_host:/remote-path/")"
if [ "$transport_profile" = easytier ]; then
  printf '清理（仅用户明确要求时）：\nssh -F %s %s %s\n' "$(quote_sq "$config_path")" "$(quote_sq "$alias_name")" "$(quote_sq "$remote_cleanup")"
else
  printf '清理（仅用户明确要求时）：\nssh -i %s -p %s -o BatchMode=yes %s %s\n' "$(quote_sq "$key_path")" "$port_q" "$host_q" "$(quote_sq "$remote_cleanup")"
fi
printf '远端清理成功后再执行：rm -f %s %s %s %s\n' "$(quote_sq "$key_path")" "$(quote_sq "$key_path.pub")" "$(quote_sq "$config_path")" "$(quote_sq "$transport_path")"
```

不要把脚本输出中的私钥内容贴入对话；公钥整行可用于授权。脚本不能解析 EasyTier 时，将名称作为 SSH 主机名仅在用户确认 DNS/hosts 可用后使用。

## 远程执行与验证

- **备份/迁移**：先检查路径、权限、空间、服务依赖和回滚点；迁移采用预同步、最终增量同步、切换后校验。
- **文件传输**：优先 `rsync --dry-run`、断点续传和校验；完成后检查大小、文件数或哈希。
- **服务操作**：先读状态和最近日志，再部署、重启、停止或回滚；未确认影响范围不得停止生产服务。
- **诊断/配置**：优先只读命令；修改前备份原文件，用临时文件校验语法，变更后检查状态。

每项操作都报告命令、目的、预期结果和实际结果。连接成功不等于任务完成。

验证成功后优先合并只读检查，减少握手次数：

```bash
ssh -i "$key_path" -p 22 -o BatchMode=yes -o ConnectTimeout=6 \
  -o ConnectionAttempts=1 -o ServerAliveInterval=3 -o ServerAliveCountMax=2 \
  -o StrictHostKeyChecking=accept-new ${kex_option:-} \
  -o ControlMaster=auto -o ControlPersist=10m -o ControlPath=%d/.ssh/cm-%C \
  user@host 'hostname; whoami; uname -a; echo; uptime; echo; df -hT /; echo; free -h'
```

只有日志明确进入认证阶段并出现 `Permission denied` 时，才停止密码重试并核对目标用户、授权执行账号、SSH 端口和公钥登录策略。若日志停在 KEX 阶段，不要让用户重复授权公钥。

## 按需清理与安全规则

只有用户明确提出清理、撤销访问或删除授权时执行。先确认主机、用户、公钥和本地路径，再按完整公钥精确删除，确认远端删除成功后删除本地 `.key` 和 `.pub`。不要按模糊注释删除，也不要改动其他 `authorized_keys` 条目。

清理命令必须复用该目标已验证的端口、KEX 和跳板参数；如果本次连接依赖 `KexAlgorithms=curve25519-sha256`，撤销公钥时也要携带该选项。

始终使用 `StrictHostKeyChecking=accept-new`，不覆盖已有密钥，不关闭主机密钥检查，不自动执行未授权的破坏性操作；任务结束明确说明访问是否仍保留以及清理方式。
