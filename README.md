# 🌐 Dotfiles

My personal dotfiles and configuration scripts for Linux, macOS, and Windows. Managed using [GNU Stow](https://www.gnu.org/software/stow/) for Unix-like systems, with PowerShell scripts for Windows setup.

---

## 📁 Structure

```bash
dotfiles/
├── configs/          # All configuration files organized by app (for stow)
├── install/          # OS and distro-specific install scripts
├── scripts/          # Utility scripts for maintenance, backups, etc.
├── wallpapers/       # Wallpapers and visual assets
└── README.md         # This file
```

---

## 🚀 Quick Start
### 🐧 Linux/macOS (with Stow)

```bash
cd dotfiles/configs
stow zsh bash git starship nvim tmux
```

### 🪟 Windows (PowerShell)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install\windows.ps1
```

Customize and run Windows setup script manually or automate later.

---

## 💻 Supported Systems
- Ubuntu (WSL)
- Windows 11 (PowerShell setup, WSL tweaks)

---

### 📦 Software Managed
- Shell: zsh, bash, starship
- Editors: nvim
- Terminal: tmux, terminal themes

---

### 🛠️ Scripts
Located in /scripts for easy access:

- `update.sh` — System and config updates