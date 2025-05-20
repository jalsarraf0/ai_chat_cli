<#
.SYNOPSIS
  Prompt for OpenAI API key and persist it, and optionally update PATH.

.DESCRIPTION
  This script will:
   - Ask you to enter your OpenAI API key.
   - Persist it into your User environment variables.
   - Export it into the current session.
   - Offer to add $Env:USERPROFILE\Scripts to your User PATH.

#>

# Helper to persist an environment variable at the User scope
function Set-UserEnvVar {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
}

Write-Host "=== AI-Chat CLI Configuration ===`n"

# 1) API Key
$key = Read-Host -AsSecureString "Enter your OpenAI API key (sk-...)" |
    ConvertFrom-SecureString -AsPlainText
Set-UserEnvVar -Name 'OPENAI_API_KEY' -Value $key
# Also set for this session:
$Env:OPENAI_API_KEY = $key
Write-Host "`n✓ OPENAI_API_KEY set for this session and persisted."

# 2) Optionally update PATH for Scripts folder
$scriptsDir = "$Env:USERPROFILE\Scripts"
$currentUserPath = [Environment]::GetEnvironmentVariable('PATH','User')

if (-not ($currentUserPath -split ';' | Where-Object { $_ -eq $scriptsDir })) {
    $ans = Read-Host "`nWould you like to add '$scriptsDir' to your User PATH? (Y/N)"
    if ($ans -match '^[Yy]') {
        $newPath = "$currentUserPath;$scriptsDir"
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
        Write-Host "✓ Added Scripts folder to User PATH. You must restart PowerShell for this to take effect."
    }
    else {
        Write-Host "• Skipped adding Scripts folder to PATH."
    }
}
else {
    Write-Host "`n• '$scriptsDir' is already in your User PATH."
}

Write-Host "`n✅ Configuration complete!"

