# claude-keep-awake

Keep your Mac awake while Claude is doing work — automatically, in the background, forever.

A tiny macOS LaunchAgent that watches for any of:

- **Claude Code VS Code extension** running tasks
- **Claude Code CLI** (`claude` from the Homebrew cask)
- **Claude desktop app**

…and holds a system idle-sleep assertion (via `caffeinate -i`) while any of them are running. When they all exit, the assertion is released and your Mac can sleep normally.

No more "I left it running overnight and the machine slept."

## How it works

A small bash watcher (`caffeinated-claude.sh`) polls every 30 seconds for matching processes. While at least one is running, it spawns `caffeinate -i` as a child process. When none are running, it kills the child. A LaunchAgent (`com.user.caffeinated-claude`) starts the watcher at every login and respawns it if it crashes (`KeepAlive`).

Only `caffeinate -i` is used — the display can still sleep, only the system is kept awake. (Change to `-di` in the script if you want the display held on too.)

## Install

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/rahulrajsbkk/claude-keep-awake/main/setup.sh | bash
```

That clones the repo to `~/.local/share/claude-keep-awake` and runs `install.sh`. Re-run the same command any time to update.

### From a local clone

```bash
git clone https://github.com/rahulrajsbkk/claude-keep-awake.git
cd claude-keep-awake
./install.sh
```

Either path copies:

| File | Destination |
|---|---|
| `bin/caffeinated-claude.sh` | `~/bin/caffeinated-claude.sh` |
| `bin/caffeinated-claude-ctl` | `~/bin/caffeinated-claude-ctl` |
| `LaunchAgents/com.user.caffeinated-claude.plist` | `~/Library/LaunchAgents/com.user.caffeinated-claude.plist` (with `$HOME` substituted) |

…and loads the LaunchAgent. It will now start at every login.

Make sure `~/bin` is on your `$PATH` so you can call `caffeinated-claude-ctl` directly.

## Usage

After install, you don't need to do anything — it just works.

To inspect or control it:

```bash
caffeinated-claude-ctl status     # is it running? is an assertion held right now?
caffeinated-claude-ctl tail       # follow the log live
caffeinated-claude-ctl log        # dump full log
caffeinated-claude-ctl stop       # disable (survives reboots)
caffeinated-claude-ctl start      # re-enable
caffeinated-claude-ctl restart    # after editing the script
```

Logs live at:

- `~/Library/Logs/caffeinated-claude.log` — watcher's own log
- `~/Library/Logs/caffeinated-claude.out.log` / `.err.log` — LaunchAgent stdout/stderr

## Verifying it works

With Claude Code (VS Code or CLI) or Claude.app running:

```bash
caffeinated-claude-ctl status
```

You should see the watcher process plus a `caffeinate -i` line. You can also confirm the assertion at the OS level:

```bash
pmset -g assertions | grep -i preventuseridlesystemsleep
```

## Configuration

Both knobs are environment variables, overridable in the LaunchAgent plist:

| Variable | Default | Meaning |
|---|---|---|
| `CAFFEINATED_CLAUDE_INTERVAL` | `30` | Seconds between checks. |
| `CAFFEINATED_CLAUDE_PATTERN` | `anthropic\.claude-code-\|Caskroom/claude-code/\|/opt/homebrew/bin/claude\|/usr/local/bin/claude\|/Applications/Claude\.app/` | `pgrep -f` regex of processes that should hold the system awake. |

To pass them to the LaunchAgent, add an `EnvironmentVariables` dict to `~/Library/LaunchAgents/com.user.caffeinated-claude.plist` and `caffeinated-claude-ctl restart`.

### Holding the display on too

Edit `~/bin/caffeinated-claude.sh` and change `caffeinate -i` to `caffeinate -di`, then `caffeinated-claude-ctl restart`.

### Adding more process patterns

Want to also keep the system awake while (say) `ollama` is running? Override `CAFFEINATED_CLAUDE_PATTERN` to include `|/ollama( |$)`.

## Uninstall

```bash
./uninstall.sh
```

Removes the LaunchAgent and the two scripts in `~/bin`. Logs are left in place.

## Why not `caffeinate -i <command>`?

That works if you launch Claude Code from a shell you control. It does **not** work when:

- Claude Code runs inside VS Code (you don't launch it yourself).
- The Claude desktop app is launched from the Dock.
- You want a single source of truth that always knows when *anything* Claude-related is running.

This repo solves that by watching the process table from the outside.

## Requirements

- macOS (uses `launchctl`, `caffeinate`, `pgrep`)
- Bash (ships with macOS)

Tested on Apple Silicon / macOS 14+. Paths for Intel Macs (`/usr/local/bin/claude`) are also matched by the default pattern.

## License

MIT — see [LICENSE](LICENSE).
