function Get-PoshSystemInfo {
    [CmdletBinding()]
    param()

    process {
        $ram = 0
        $osName = "Unknown"

        if ($IsWindows) {
            # Lógica para Windows
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem
            $ram = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            $osName = $os.Caption
        } else {
            # Lógica para Linux (Kali/Ubuntu)
            if (Test-Path /etc/os-release) {
                $osLine = Get-Content /etc/os-release | Select-String "PRETTY_NAME"
                $osName = $osLine.ToString().Split('=')[1].Trim('"')
            }
            
            if (Test-Path /proc/meminfo) {
                # Usando Out-String para garantir que o replace funcione no objeto
                $memLine = Get-Content /proc/meminfo | Select-String "MemTotal" | Out-String
                $ramKb = [double]($memLine -replace '\D')
                $ram = [Math]::Round($ramKb / 1MB, 2)
            }
        }

        # O Pulo do Gato: Se as variáveis de ambiente falharem, usa o comando 'hostname'
        $currentHost = $env:COMPUTERNAME ?? $env:HOSTNAME ?? (hostname)

        [PSCustomObject]@{
            ComputerName = $currentHost
            OS           = $osName
            TotalRAM_GB  = $ram
            User         = $env:USER ?? $env:USERNAME ?? "unknown"
            Timestamp    = Get-Date
        }
    }
}

Export-ModuleMember -Function Get-PoshSystemInfo