# T3 Code in WSL and Linux

Run `./install.sh` to install the `t3` CLI alongside the other tools. `boot.sh`
calls the same entrypoint, so remote bootstrap includes it too. The
[official installer](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md)
downloads the latest stable self-contained CLI and checks its SHA-256 checksum.
It needs `sh`, `curl`, `tar`, and `sha256sum` or `shasum`; Node.js and npm are
not required. Linux x64 and arm64 are supported.

The launcher lives at `~/.local/bin/t3`. Existing installations are left alone;
use `t3 update` when you want to update. Installation does not start a server.

## Start and reconnect

In WSL, register your project and start the server in a terminal:

```bash
cd /path/to/project
t3 project add .
t3 serve --host 127.0.0.1
```

`serve` runs in the foreground without opening a browser. Copy the printed
pairing URL into your Windows browser for the first connection. Keep that URL
private. The server serves the website itself; the Windows desktop app is not
needed. Windows browsers can reach WSL servers through
[localhost forwarding](https://learn.microsoft.com/en-us/windows/wsl/networking).
If it fails, check that WSL localhost forwarding is enabled.

Leave the terminal running while you work. Reopen the server's local URL in the
same browser to reconnect. Stop with Ctrl-C; run the same `t3 serve` command to
restart with your saved projects and threads. If pairing is needed again, run
`t3 pair` in another WSL terminal while the server is running.

The server chooses an available port starting at 3773. Use the URL it prints.
`--port <number>` selects a port explicitly. `--host 127.0.0.1` keeps the bind
local; `t3 start --no-browser --host 127.0.0.1` is another way to start without
opening a browser. See `t3 serve --help` for the installed version's flags.
On Linux, open the printed pairing URL in a browser on the same machine.

## Providers and storage

Install and authenticate your chosen agent CLI inside WSL or Linux, where the
server runs. Enable it in Settings > Providers. Its executable must be on the
server's `PATH`, or set its Binary path in provider settings. See the
[upstream provider instructions](https://github.com/pingdotgg/t3code/blob/main/docs/user/install.md#providers).
No provider or model is selected by these dotfiles.

T3 owns `~/.t3`, including downloaded runtimes and `userdata` for settings,
projects, threads, and authentication. These dotfiles do not stow or relocate
it. Upstream supports `T3CODE_HOME` and `--base-dir` for an explicit location;
keep the same location for all `t3` commands to retain your state. XDG variables
alone do not relocate it.

Server pairing and agent login are separate. For pairing and session management,
use `t3 auth --help` or the
[upstream access guide](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md).
