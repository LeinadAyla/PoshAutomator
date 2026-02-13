<#
.SYNOPSIS
    Módulo PoshAutomator v1.1.9 - Ferramentas de Automação e Inventário.
#>

function Get-PoshSystemInfo {
    [CmdletBinding()]
    param()

    process {
        $ram = 0
        $osName = "Unknown"

        if ($IsWindows) {
            # Lógica para Windows
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
                $ram = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                $osName = $os.Caption
            } catch {
                Write-Warning "Falha ao coletar dados via CIM no Windows."
            }
        } else {
            # Lógica para Linux (Kali/Ubuntu)
            if (Test-Path /etc/os-release) {
                $osLine = Get-Content /etc/os-release | Select-String "PRETTY_NAME"
                $osName = $osLine.ToString().Split('=')[1].Trim('"')
            }
            
            if (Test-Path /proc/meminfo) {
                # Extrai apenas os dígitos para o cálculo de RAM
                $memLine = Get-Content /proc/meminfo | Select-String "MemTotal" | Out-String
                $ramKb = [double]($memLine -replace '[^\d]') 
                $ram = [Math]::Round($ramKb / 1MB, 2)
            }
        }

        # Identificação do Host e Usuário
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
        Write-Host "🔍 Gerando relatório ($TipoRelatorio) para: $ComputerName..." -ForegroundColor Cyan
        
        # Chama a função de coleta interna
        $data = Get-PoshSystemInfo 

        if ($TipoRelatorio -eq "Completo") {
            Write-Host "--- Relatório Detalhado ---" -ForegroundColor Yellow
            $data | Format-List
        } else {
            return $data
        }
    }
}

# Exporta as funções para que fiquem visíveis aos usuários do módulo
Export-ModuleMember -Function Get-PoshSystemInfo, Get-SystemReport