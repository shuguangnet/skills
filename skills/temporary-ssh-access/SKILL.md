---
name: temporary-ssh-access
description: 生成、授权、验证并清理远程服务器的临时 SSH 密钥访问。适用于 AI coding agent 需要用户为某台主机授予短期 SSH 访问权限、现有 SSH 密钥无法登录、需要连接新的 VPS/服务器进行迁移或运维、或需要给用户提供安全可复制的临时公钥授权命令时。
---

# 临时 SSH 访问

## 概览

使用本 Skill 建立临时 SSH 访问，不复用长期个人密钥。流程是生成专用密钥对、给用户一条远端授权命令、验证连接，并在任务完成后清理授权。

## 工作流程

1. 确认目标 `user@host`。如果用户明确是 VPS 控制台或 root 迁移场景，可以默认使用 `root@host`。
2. 生成一把专用 ed25519 密钥，文件名和注释要能看出用途与日期。
3. 给用户一条远端执行命令，把公钥追加到 `~/.ssh/authorized_keys`，并设置正确权限。
4. 使用临时私钥和非交互参数测试 SSH 登录。
5. 后续 SSH、SCP、rsync 操作都使用这把临时私钥。
6. 任务完成后，主动提出或执行清理：删除远端精确匹配的临时公钥行，并删除本地临时密钥对。

## 常用命令

在本机生成临时密钥：

```bash
target_host="203.0.113.10"
key_path="$HOME/.ssh/agent_temp_${target_host//./_}_$(date +%Y%m%d%H%M%S)"
ssh-keygen -t ed25519 -f "$key_path" -N '' -C "agent-temp-access-$(date +%Y-%m-%d)"
chmod 600 "$key_path"
cat "${key_path}.pub"
```

把下面这条远端授权命令发给用户执行。需要把 `<PUBLIC_KEY>` 替换成完整 `.pub` 公钥行：

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh && printf '%s\n' '<PUBLIC_KEY>' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
```

验证连接：

```bash
ssh -i "$key_path" -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new user@host 'hostname; whoami; uname -a'
```

使用临时密钥传输文件：

```bash
rsync -az -e "ssh -i $key_path -o StrictHostKeyChecking=accept-new" ./local-path/ user@host:/remote-path/
scp -i "$key_path" -o StrictHostKeyChecking=accept-new file.tar.gz user@host:/root/
```

任务完成后，在目标服务器删除这条临时公钥。优先使用唯一注释精确清理：

```bash
tmp_comment='agent-temp-access-YYYY-MM-DD'
cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.bak.$(date +%Y%m%d%H%M%S)
grep -v "$tmp_comment" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp && mv ~/.ssh/authorized_keys.tmp ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

删除本地临时密钥对：

```bash
rm -f "$key_path" "${key_path}.pub"
```

## 安全注意事项

- 不要在对话中输出或粘贴私钥。
- 不要覆盖已有密钥；每台目标服务器或每次任务都使用新的文件名。
- 测试登录时使用 `BatchMode=yes`，避免卡在密码输入。
- 新主机使用 `StrictHostKeyChecking=accept-new`；不要直接完全关闭主机密钥检查。
- 清理时只删除临时公钥行或唯一注释匹配的行，不要改动无关的 `authorized_keys` 条目。
- 如果目标用户不是 root，远端授权命令会写入该用户自己的 home 目录。
