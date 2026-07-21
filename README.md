# Agent Skills

一组遵循 [Agent Skills](https://agentskills.io/) 目录规范的可复用技能，适用于 Codex、Claude Code、OpenCode、Qoder、Pi、Reasonix 等 AI coding agent。

项目提供交互式一键安装器，可以选择目标平台、选择一个或多个 skill，并一次安装到多个 Agent。

## 一键安装

在 Linux 或 macOS 终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/shuguangnet/skills/main/install.sh | bash
```

安装器会依次要求选择：

1. 目标 Agent，可多选或选择全部。
2. 需要安装的 skill，可多选或选择全部。

输入序号或名称进行选择，多个选项使用空格或逗号分隔。

## 非交互安装

安装指定 skill 到 Codex：

```bash
curl -fsSL https://raw.githubusercontent.com/shuguangnet/skills/main/install.sh | bash -s -- --target codex temporary-ssh-access
```

同时安装到 Claude Code、OpenCode 和 Pi：

```bash
curl -fsSL https://raw.githubusercontent.com/shuguangnet/skills/main/install.sh | bash -s -- --target claude,opencode,pi temporary-ssh-access
```

将全部 skill 安装到所有支持的平台：

```bash
curl -fsSL https://raw.githubusercontent.com/shuguangnet/skills/main/install.sh | bash -s -- --all-targets --all
```

## 支持平台

| 参数 | Agent | 默认用户级目录 |
| --- | --- | --- |
| `codex` | Codex | `~/.codex/skills` |
| `claude` | Claude Code | `~/.claude/skills` |
| `opencode` | OpenCode | `~/.config/opencode/skills` |
| `qoder` | Qoder | `~/.agents/skills` |
| `pi` | Pi | `~/.pi/agent/skills` |
| `reasonix` | Reasonix | `~/.reasonix/skills` |

Qoder 使用通用的 `~/.agents/skills` 目录。OpenCode、Pi 和 Reasonix 也能识别 Agent Skills 的通用目录，但安装器默认使用各自的原生用户目录，便于独立管理。

可通过环境变量调整平台配置根目录：

```text
CODEX_HOME
CLAUDE_CONFIG_DIR
OPENCODE_CONFIG_DIR
AGENT_SKILLS_HOME
PI_CODING_AGENT_DIR
REASONIX_HOME
```

对于其他兼容 `SKILL.md` 的 Agent，可以使用 `--dest` 指定其 skills 目录：

```bash
./install.sh --dest ~/.my-agent/skills temporary-ssh-access
```

## 本地安装

```bash
git clone https://github.com/shuguangnet/skills.git
cd skills
./install.sh
```

常用参数：

```text
./install.sh                                  交互选择平台和 skill
./install.sh -t codex <skill>                安装到指定平台
./install.sh -t claude,opencode <skill>      同时安装到多个平台
./install.sh --all-targets --all             全平台安装全部 skill
./install.sh --list                          查看可用 skill
./install.sh --list-targets                  查看平台和安装目录
./install.sh --force -t pi <skill>           覆盖已安装的 skill
./install.sh --dest <目录> <skill>           安装到自定义目录
```

## Skills 介绍

### build-saas-product-site

用于构建克制、精致且以真实产品界面为核心的 SaaS 或软件官网。规范覆盖参考站点分析、Astro + Tailwind CSS v4 技术选型、视觉系统、响应式布局、产品主视觉、动效、可访问性、浏览器截图验收、公网启动以及 Git 交付。

### temporary-ssh-access

用于生成、授权、验证并清理远程服务器的临时 SSH 密钥访问。适合新 VPS 连接、服务器迁移、临时运维以及现有密钥无法登录等场景。

它强调短期、独立的访问凭据，并包含以下完整流程：

- 生成专用 ed25519 临时密钥
- 提供安全的远端公钥授权命令
- 使用非交互参数验证连接
- 通过 SSH、SCP 或 rsync 执行后续操作
- 任务结束后精确清理远端授权和本地密钥

## 项目结构

```text
.
├── install.sh
└── skills/
    ├── build-saas-product-site/
    │   ├── SKILL.md
    │   ├── agents/
    │   └── references/
    └── temporary-ssh-access/
        └── SKILL.md
```

每个 skill 使用独立目录，入口文件为 `SKILL.md`。安装器会自动发现 `skills/*/SKILL.md`，新增 skill 时无需修改安装器。

## 添加 Skill

1. 在 `skills/` 下创建以 skill 名称命名的目录。
2. 在目录中添加包含 `name` 和 `description` frontmatter 的 `SKILL.md`。
3. 如有需要，可在同一目录添加 `scripts/`、`references/` 或 `assets/`。
4. 在本 README 的 Skills 介绍中补充用途说明。

```text
skills/my-skill/
├── SKILL.md
├── scripts/
└── references/
```

安装器复制整个 skill 目录，因此附属脚本、参考资料和资源文件会一并安装。

## 系统要求

- Bash 3.2 或更高版本
- 远程安装需要 `curl` 或 `wget`
- 需要 `tar` 解压项目包
