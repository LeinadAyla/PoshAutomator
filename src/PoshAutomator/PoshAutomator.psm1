function Get-PoshSystemInfo {
    <#
    .SYNOPSIS
        Coleta informações básicas de hardware e sistema operacional.
    .DESCRIPTION
        Esta função utiliza o CIM para buscar o nome do computador, versão do Windows/Linux e capacidade de memória.
    .EXAMPLE
        Get-PoshSystemInfo
    #>
    [CmdletBinding()]
    param()

    process {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem

        [PSCustomObject]@{
            ComputerName = $os.CSName
            OS           = $os.Caption
            Version      = $os.Version
            TotalRAM_GB  = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
            User         = $env:USERNAME
            Timestamp    = Get-Date
        }
    }
}

# Exporta a função para que o usuário possa usá-la
Export-ModuleMember -Function Get-PoshSystemInfo