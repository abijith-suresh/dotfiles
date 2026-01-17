# Enable error handling
$ErrorActionPreference = "Stop"

# App list
$apps = @(
    "ajeetdsouza.zoxide",
    "Bitwarden.Bitwarden",
    "CoreyButler.NVMforWindows",
    "Discord.Discord",
    "Docker.DockerDesktop",
    "eza-community.eza",
    "Git.Git",
    "Google.Chrome",
    "JernejSimoncic.Wget",
    "JetBrains.IntelliJIDEA.Community",
    "junegunn.fzf",
    "Microsoft.VisualStudioCode",
    "Mozilla.Firefox",
    "Neovim.Neovim",
    "nepnep.neofetch-win",
    "Obsidian.Obsidian",
    "Postman.Postman",
    "qBittorrent.qBittorrent",
    "sharkdp.bat",
    "Starship.Starship",
    "Valve.Steam",
    "VideoLAN.VLC"
)

foreach ($app in $apps) {
    Write-Host "`n========== Checking: $app ==========" -ForegroundColor Cyan
    try {
        $installed = winget list --id $app | Where-Object { $_ -match $app }

        if ($installed) {
            Write-Host "[INFO] $app is installed. Checking for updates..." -ForegroundColor Green

            $update = winget upgrade --id $app --accept-source-agreements 2>&1

            if ($update -match $app) {
                Write-Host "[UPDATE] Updating $app..." -ForegroundColor Yellow
                winget upgrade --id $app --accept-package-agreements --accept-source-agreements
                Write-Host "[DONE] $app updated successfully." -ForegroundColor DarkGreen
            } else {
                Write-Host "[OK] $app is up to date." -ForegroundColor Gray
            }
        } else {
            Write-Host "[INSTALL] $app is not installed. Installing..." -ForegroundColor Red
            winget install --id $app --accept-package-agreements --accept-source-agreements
            Write-Host "[DONE] $app installed successfully." -ForegroundColor DarkGreen
        }
    } catch {
        Write-Host "[ERROR] Something went wrong with $app" -ForegroundColor Magenta

        try {
            Write-Host "[INFO] Skipping to next app..." -ForegroundColor DarkYellow
            continue
        } catch {
            Write-Host "[FATAL] Cannot continue. Exiting script." -ForegroundColor Red
            exit 1
        }
    }
}
