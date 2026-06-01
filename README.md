<div align="center">

# ☕ claude-keep-awake

### Keep your Mac wide awake while Claude is working.

[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Made with: Bash](https://img.shields.io/badge/Made%20with-Bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Powered by: caffeinate](https://img.shields.io/badge/Powered%20by-caffeinate-6F4E37)](x-man-page://caffeinate)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Maintenance: active](https://img.shields.io/badge/Maintained-yes-brightgreen.svg)](#-author)

<sub>A tiny macOS LaunchAgent that holds <code>caffeinate -i</code> whenever Claude Code (VS Code extension <em>or</em> CLI) or the Claude desktop app is running. When they all exit, your Mac is free to sleep again.</sub>

</div>

---

## 🎯 Why?

> "I left it running overnight and the machine slept."

Sound familiar? `caffeinate -i <command>` works if you launch Claude Code from a shell you control — but it breaks the moment you use the VS Code extension, the desktop app, or anything launched outside your terminal. This watcher solves it from the *outside*: it polls the process table and holds the assertion as long as **anything** Claude is alive.

---

## ✨ What it watches

| | Process | Matched by |
|---|---|---|
| 🟣 | **Claude Code — VS Code extension** | `anthropic.claude-code-*` |
| 🟢 | **Claude Code — CLI (Homebrew)** | `Caskroom/claude-code/*`, `/opt/homebrew/bin/claude`, `/usr/local/bin/claude` |
| 🔵 | **Claude desktop app** | `/Applications/Claude.app/*` |

While **any** of these is running → `caffeinate -i` is held.
When **all** of them exit → assertion released; macOS can sleep normally.

> The display can still sleep — only the *system* is held. Want the screen kept on too? Flip `-i` to `-di` in the watcher script.

---

## 🚀 Install

### One-line install ✨ (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/rahulrajsbkk/claude-keep-awake/main/setup.sh | bash
```

That clones to `~/.local/share/claude-keep-awake` and runs `install.sh`. Re-run any time to update.

### From a local clone

```bash
git clone https://github.com/rahulrajsbkk/claude-keep-awake.git
cd claude-keep-awake
./install.sh
```

### What gets installed

| From | → | To |
|---|---|---|
| `bin/caffeinated-claude.sh`   | → | `~/bin/caffeinated-claude.sh` |
| `bin/caffeinated-claude-ctl`  | → | `~/bin/caffeinated-claude-ctl` |
| `LaunchAgents/com.user.caffeinated-claude.plist` | → | `~/Library/LaunchAgents/com.user.caffeinated-claude.plist` (with `$HOME` substituted) |

…then the LaunchAgent is loaded with `launchctl load -w`. **It will start at every login. No further action required.**

Add `~/bin` to your `$PATH` to call `caffeinated-claude-ctl` directly.

---

## 🎮 Usage

After install you don't need to do anything — it just works.

```bash
caffeinated-claude-ctl status     # is it running? is an assertion held right now?
caffeinated-claude-ctl tail       # follow the log live
caffeinated-claude-ctl log        # dump full log
caffeinated-claude-ctl stop       # disable (survives reboots)
caffeinated-claude-ctl start      # re-enable
caffeinated-claude-ctl restart    # after editing the script
```

### Logs

- `~/Library/Logs/caffeinated-claude.log` — watcher's own log
- `~/Library/Logs/caffeinated-claude.out.log` / `.err.log` — LaunchAgent stdout/stderr

### ✅ Verify it's working

With Claude Code (VS Code or CLI) or `Claude.app` open:

```bash
caffeinated-claude-ctl status
pmset -g assertions | grep -i preventuseridlesystemsleep
```

You should see the watcher process, the `caffeinate -i` child, and a `PreventUserIdleSystemSleep` assertion held by the OS.

---

## ⚙️ Configuration

Both knobs are environment variables — set them in the LaunchAgent plist:

| Variable | Default | Meaning |
|---|---|---|
| `CAFFEINATED_CLAUDE_INTERVAL` | `30` | Seconds between checks |
| `CAFFEINATED_CLAUDE_PATTERN`  | `anthropic\.claude-code-\|Caskroom/claude-code/\|/opt/homebrew/bin/claude\|/usr/local/bin/claude\|/Applications/Claude\.app/` | `pgrep -f` regex for processes that should hold the system awake |

To pass them to the LaunchAgent, add an `EnvironmentVariables` dict to `~/Library/LaunchAgents/com.user.caffeinated-claude.plist`, then `caffeinated-claude-ctl restart`.

### 🖥️ Want the display held on too?

Edit `~/bin/caffeinated-claude.sh` — change `caffeinate -i` to `caffeinate -di` — then `caffeinated-claude-ctl restart`.

### ➕ Watch more processes

Want to also keep awake while (say) `ollama` is running? Override `CAFFEINATED_CLAUDE_PATTERN` to include `|/ollama( |$)`.

---

## 🧠 How it works

A small bash script polls every 30s for matching processes:

```
┌──────────────────────────────────┐
│  com.user.caffeinated-claude     │  ← LaunchAgent (RunAtLoad + KeepAlive)
│  └─ caffeinated-claude.sh        │  ← watcher loop, 30s tick
│       └─ caffeinate -i           │  ← spawned only while Claude is running
└──────────────────────────────────┘
```

- Watcher crashes? → `KeepAlive` respawns it.
- You reboot? → `RunAtLoad` starts it at login.
- No Claude running? → `caffeinate` child is killed, Mac sleeps normally.

---

## 🧹 Uninstall

```bash
./uninstall.sh
```

Removes the LaunchAgent and the two scripts in `~/bin`. Logs are left in place (you can delete `~/Library/Logs/caffeinated-claude*.log` if you want a clean wipe).

---

## 📋 Requirements

- macOS (uses `launchctl`, `caffeinate`, `pgrep`)
- Bash (ships with macOS)

Tested on Apple Silicon, macOS 14+. Intel paths (`/usr/local/bin/claude`) are also matched by the default pattern.

---

## 📜 License

[MIT](LICENSE)

---

## 👤 Author

**Rahul Raj** — [@rahulrajsbkk](https://github.com/rahulrajsbkk)

> _"A cup of coffee commits one to forty years of friendship."_ — Turkish proverb ☕

<sub>Built because too many Claude Code sessions died to macOS idle sleep. If this saved you some grief, a ⭐ on the repo is appreciated.</sub>
