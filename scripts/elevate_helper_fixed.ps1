# Sekom Clenner Elevation Helper
# This PowerShell script provides better elevation handling and user guidance

param(
    [string]$ExecutablePath = "",
    [switch]$CheckElevation,
    [switch]$AutoElevate,
    [switch]$ShowHelp
)

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to show elevation help
function Show-ElevationHelp {
    Write-Host @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                    SEKOM CLENNER - ADMINISTRATOR REQUIRED                    ║
╚══════════════════════════════════════════════════════════════════════════════╝

This application requires administrator privileges to perform system cleaning
and optimization tasks safely.

REQUIRED PERMISSIONS:
• Registry modification and cleaning
• System file and folder access
• Service management (Windows Update, Search, etc.)
• Windows Defender signature updates
• Driver management and updates

SOLUTIONS:
1. Right-click → "Run as administrator"
2. Use the provided launcher script
3. Move to user directory if admin unavailable

"@ -ForegroundColor Yellow
}

# Function to auto-elevate
function Invoke-AutoElevation {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "Executable not found: $Path"
        return $false
    }

    try {
        Write-Host "Attempting automatic elevation..." -ForegroundColor Cyan
        
        # Create process start info
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Path
        $psi.Verb = "runas"  # This triggers UAC elevation
        $psi.UseShellExecute = $true
        
        # Start the process
        $process = [System.Diagnostics.Process]::Start($psi)
        
        if ($process) {
            Write-Host "✓ Successfully launched with elevation" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "✗ Failed to elevate automatically" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

# Function to check system compatibility
function Test-SystemCompatibility {
    $issues = @()
    
    # Check UAC status
    try {
        $uacReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        if ($uacReg.EnableLUA -eq 0) {
            $issues += "UAC is disabled - elevation may not work properly"
        }
    }
    catch {
        $issues += "Cannot determine UAC status"
    }
    
    # Check if in Program Files
    $currentDir = Get-Location
    if ($currentDir.Path -like "*Program Files*") {
        $issues += "Application is in Program Files - requires elevation"
    }
    
    # Check antivirus exclusions
    $defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defender -and $defender.RealTimeProtectionEnabled) {
        $issues += "Windows Defender is active - ensure application is whitelisted"
    }
    
    return $issues
}

# Main execution
if ($ShowHelp) {
    Show-ElevationHelp
    exit 0
}

if ($CheckElevation) {
    $isAdmin = Test-Administrator
    $issues = Test-SystemCompatibility
    
    Write-Host "Elevation Status Check:" -ForegroundColor Cyan
    Write-Host "Running as Administrator: $(if ($isAdmin) { '✓ YES' } else { '✗ NO' })" -ForegroundColor $(if ($isAdmin) { 'Green' } else { 'Red' })
    
    if ($issues.Count -gt 0) {
        Write-Host "`nPotential Issues:" -ForegroundColor Yellow
        $issues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Yellow }
    }
    
    exit $(if ($isAdmin) { 0 } else { 1 })
}

if ($AutoElevate -and $ExecutablePath) {
    $success = Invoke-AutoElevation -Path $ExecutablePath
    exit $(if ($success) { 0 } else { 1 })
}

# Default behavior - show help if no parameters
Show-ElevationHelp
