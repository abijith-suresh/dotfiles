# --------------------------------------
# 💫 Prompt Enhancer: Starship
# --------------------------------------
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
} else {
    Write-Host "⚠️ Starship not found. Prompt not enhanced."
}

# --------------------------------------
# 📦 Modules & Enhancements
# --------------------------------------
Import-Module posh-git -ErrorAction SilentlyContinue
Import-Module PSReadLine -ErrorAction SilentlyContinue

# --------------------------------------
# 🧠 PSReadLine Configuration
# --------------------------------------
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
Set-PSReadLineOption -MaximumHistoryCount 5000
Set-PSReadLineOption -HistorySavePath "$HOME\.ps_history"

# --------------------------------------
# 🔁 Git Functions
# --------------------------------------
function gits { git status }
function gita { git add $args }
function gitc { git commit -m $args }
function gitp { git push }
function gitl { git log }
function gitco { git checkout $args }
function gitb { git branch $args }

# --------------------------------------
# 🔁 Directory Navigation
# --------------------------------------
function .. { Set-Location .. }
function ... { Set-Location ..\.. }

# --------------------------------------
# 🧩 Utility Functions
# --------------------------------------
function mkcd {
    param([string]$dir)
    mkdir $dir
    Set-Location $dir
}

function reload-profile {
    . $PROFILE
    Write-Host "Profile reloaded successfully."
}

# --------------------------------------
# 🧰 Dev Environment Setup
# --------------------------------------
$DOTFILES = "$HOME\dotfiles"
