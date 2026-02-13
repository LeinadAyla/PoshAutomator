<#
.SYNOPSIS
    Módulo PoshAutomator v1.2.0 - Interface de Usuário e Inventário Robusto.
#>

function Get-PoshSystemInfo {
    [CmdletBinding()]
    param()

    process {
        $ram = 0
        $osName = "Unknown"

        if ($IsWindows) {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
                $ram = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                $osName = $os.Caption
            } catch {
                Write-Warning "Falha ao coletar dados via CIM no Windows."
            }
        } else {
            if (Test-Path /etc/os-release) {
                $osLine = Get-Content /etc/os-release | Select-String "PRETTY_NAME"
                $osName = $osLine.ToString().Split('=')[1].Trim('"')
            }
            if (Test-Path /proc/meminfo) {
                $memLine = Get-Content /proc/meminfo | Select-String "MemTotal" | Out-String
                $ramKb = [double]($memLine -replace '[^\d]') 
                $ram = [Math]::Round($ramKb / 1MB, 2)
            }
        }

        $currentHost = $env:COMPUTERNAME ?? $env:HOSTNAME ?? (hostname)
        $currentUser = $env:USER ?? $env:USERNAME ?? "unknown"

        [PSCustomObject]@{
            ComputerName = $currentHost
            OS           = $osName
            TotalRAM_GB  = $ram
            User         = $currentUser
            Timestamp    = Get-Date
        }
    }
}

function Get-SystemReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Digite o nome do computador ou 'localhost'")]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Resumido", "Completo")]
        [string]$TipoRelatorio = "Resumido"
    )
    
    process {
        Write-Host "`n🔍 Gerando relatório ($TipoRelatorio) para: $ComputerName..." -ForegroundColor Cyan
        $data = Get-PoshSystemInfo 

        if ($TipoRelatorio -eq "Completo") {
            Write-Host "--- Relatório Detalhado ---" -ForegroundColor Yellow
            $data | Format-List
        } else {
            return $data
        }
    }
}

function Show-PoshMenu {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "    PAINEL POSHAUTOMATOR v1.2.0     " -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "1. Gerar Relatório Rápido"
        Write-Host "2. Ver Detalhes Completos"
        Write-Host "3. Sair"
        Write-Host "------------------------------------"

        $choice = Read-Host "Escolha uma opção (1-3)"
        
        switch ($choice) {
            "1" { 
                Get-SystemReport -ComputerName "Localhost" -TipoRelatorio "Resumido" 
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "2" { 
                Get-SystemReport -ComputerName "Localhost" -TipoRelatorio "Completo" 
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "3" { 
                Write-Host "Saindo... Até logo!" -ForegroundColor Yellow
                return 
            }
            default { 
                Write-Host "❌ Erro: '$choice' não é válido! Use 1, 2 ou 3." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# Exporta as 3 funções oficiais para o usuário
Export-ModuleMember -Function Get-PoshSystemInfo, Get-SystemReport, Show-PoshMenu