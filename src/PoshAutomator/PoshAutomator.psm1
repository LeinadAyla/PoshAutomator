<#
.SYNOPSIS
    Módulo PoshAutomator v1.3.1 - Interface de Usuário, Inventário Robusto e Exportação de Dados para ML.
.DESCRIPTION
    Este módulo fornece ferramentas para coleta de informações do sistema, geração de relatórios
    e exportação de dados para análise de Machine Learning, focando em automação e monitoramento.
.VERSION 1.3.1
.DATE 2026-02-13
.AUTHOR Gemini CLI
.LICENSE MIT
#>

function Get-PoshSystemInfo {
<#
.SYNOPSIS
    Coleta informações técnicas detalhadas sobre o sistema operacional e hardware.
.DESCRIPTION
    Esta função é projetada para extrair dados essenciais do sistema, como nome do computador,
    sistema operacional, quantidade total de RAM instalada e o usuário atual.
    Ela se adapta automaticamente entre ambientes Windows e Linux para garantir a compatibilidade
    e a precisão na coleta de dados. Ideal para inventário e diagnóstico iniciais.
.OUTPUTS
    PSCustomObject. Um objeto contendo as propriedades: ComputerName, OS, TotalRAM_GB, User e Timestamp.
.EXAMPLE
    Get-PoshSystemInfo
    Este comando coleta e exibe as informações básicas do sistema onde é executado.
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Default'
    )]
    param()

    process {
        $ramTotalGB = 0
        $osName = "Unknown"
        $currentHost = $env:COMPUTERNAME ?? $env:HOSTNAME ?? (hostname)
        $currentUser = $env:USER ?? $env:USERNAME ?? "unknown"

        if ($IsWindows) {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
                $ramTotalGB = [Math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                $osName = $os.Caption
            } catch {
                Write-Warning "Falha ao coletar dados via CIM no Windows: $($_.Exception.Message)"
            }
        } else {
            if (Test-Path /etc/os-release) {
                $osLine = Get-Content /etc/os-release | Select-String "PRETTY_NAME"
                if ($osLine) {
                    $osName = $osLine.ToString().Split('=')[1].Trim('"')
                }
            }
            if (Test-Path /proc/meminfo) {
                $memTotalLine = Get-Content /proc/meminfo | Select-String "MemTotal" | Out-String
                if ($memTotalLine) {
                    $ramTotalKb = [double]($memTotalLine -replace '[^\d]') 
                    $ramTotalGB = [Math]::Round($ramTotalKb / 1MB, 2)
                }
            }
        }

        [PSCustomObject]@{
            ComputerName = $currentHost
            OS           = $osName
            TotalRAM_GB  = $ramTotalGB
            User         = $currentUser
            Timestamp    = Get-Date
        }
    }
}

function Get-SystemReport {
<#
.SYNOPSIS
    Gera um relatório de inventário do sistema, com opções de detalhamento.
.DESCRIPTION
    Esta função utiliza as informações coletadas por `Get-PoshSystemInfo` para compilar e exibir
    um relatório do sistema. Ela permite escolher entre um formato resumido e um formato detalhado,
    facilitando a visualização rápida ou uma análise mais aprofundada dos recursos do sistema.
.PARAMETER ComputerName
    O nome do computador alvo para o qual o relatório deve ser gerado.
    Para o sistema local, utilize "localhost".
.PARAMETER ReportType
    Define o nível de detalhe do relatório. "Resumido" (padrão) oferece uma visão geral,
    enquanto "Completo" exibe todas as propriedades disponíveis do objeto do sistema.
.OUTPUTS
    PSCustomObject. Um objeto de sistema formatado de acordo com o tipo de relatório solicitado.
.EXAMPLE
    Get-SystemReport -ComputerName "localhost" -ReportType "Completo"
    Gera um relatório completo para o computador local.
.EXAMPLE
    Get-SystemReport -ComputerName "MyServer01"
    Gera um relatório resumido para "MyServer01".
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Default'
    )]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Especifique o nome do computador (ex: 'localhost')")]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Resumido", "Completo")]
        [string]$ReportType = "Resumido"
    )
    
    process {
        Write-Host "`n🔍 Gerando relatório ($ReportType) para: $ComputerName..." -ForegroundColor Cyan
        # For simplicity, Get-PoshSystemInfo is always called locally for now.
        # In a real scenario, you might add remote capabilities to Get-PoshSystemInfo
        $systemData = Get-PoshSystemInfo 

        if ($ReportType -eq "Completo") {
            Write-Host "--- Relatório Detalhado ---" -ForegroundColor Yellow
            $systemData | Format-List
        } else {
            Write-Host "--- Relatório Resumido ---" -ForegroundColor Yellow
            $systemData | Format-Table -AutoSize
        }
    }
}

# Helper function for Linux CPU usage
function _Get-LinuxCpuUsage {
    <#
    .SYNOPSIS
        Calculates the current CPU usage percentage on Linux systems.
    .DESCRIPTION
        This internal helper function reads /proc/stat twice with a short delay
        to calculate the CPU utilization by comparing total CPU time and idle CPU time.
        It returns the CPU usage as a percentage.
    .OUTPUTS
        Double. The CPU usage percentage.
    .EXAMPLE
        _Get-LinuxCpuUsage
        Returns the current CPU utilization on Linux.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Default'
    )]
    param()

    begin {
        function Get-CpuStatFields {
            param($cpuStatLine)
            ($cpuStatLine -split '\s+', 2)[1] -split '\s+' | ForEach-Object { [long]$_ }
        }
    }

    process {
        try {
            $cpuStat1 = Get-Content /proc/stat | Select-String -Pattern "^cpu "
            Start-Sleep -Milliseconds 200 # Small delay for two samples

            $cpuStat2 = Get-Content /proc/stat | Select-String -Pattern "^cpu "

            if ($null -eq $cpuStat1 -or $null -eq $cpuStat2) {
                Write-Warning "Não foi possível ler /proc/stat para calcular o uso da CPU."
                return 0.0
            }

            $cpuFields1 = Get-CpuStatFields $cpuStat1
            $cpuFields2 = Get-CpuStatFields $cpuStat2

            $totalCpuTime1 = ($cpuFields1 | Measure-Object -Sum).Sum
            $idleCpuTime1 = $cpuFields1[3] # idle

            $totalCpuTime2 = ($cpuFields2 | Measure-Object -Sum).Sum
            $idleCpuTime2 = $cpuFields2[3] # idle

            $totalDiff = $totalCpuTime2 - $totalCpuTime1
            $idleDiff = $idleCpuTime2 - $idleCpuTime1

            if ($totalDiff -eq 0) {
                return 0.0 # Avoid division by zero
            }

            $cpuUsage = 100 * (1 - ([double]$idleDiff / [double]$totalDiff))
            return [Math]::Round($cpuUsage, 2)
        } catch {
            Write-Warning "Erro ao calcular uso da CPU no Linux: $($_.Exception.Message)"
            return 0.0
        }
    }
}

function Export-PoshData {
<#
.SYNOPSIS
    Coleta dados de RAM e CPU e os exporta para um arquivo CSV para análise de Machine Learning.
.DESCRIPTION
    Esta função coleta a quantidade de RAM disponível (real) e o uso real da CPU.
    Ela então registra esses dados, juntamente com informações do sistema, em um arquivo CSV
    (`system_data.csv`). Uma coluna 'Status' (Target) é adicionada, marcando 'Critical'
    se o uso da CPU exceder 80%, ou 'OK' caso contrário.
    Este CSV é preparado para ser usado em um Search Space de AutoML para treinamento de modelos de classificação.
.PARAMETER FilePath
    O caminho completo para o arquivo CSV onde os dados serão exportados.
    O padrão é 'system_data.csv' no diretório atual.
.OUTPUTS
    Nenhum. Os dados são gravados diretamente no arquivo CSV.
.EXAMPLE
    Export-PoshData
    Coleta os dados atuais e os anexa ao 'system_data.csv'.
.EXAMPLE
    Export-PoshData -FilePath "C:\Logs\ml_data.csv"
    Exporta os dados para um arquivo CSV especificado.
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Default'
    )]
    param(
        [Parameter(Mandatory=$false)]
        [string]$FilePath = (Join-Path $PSScriptRoot "system_data.csv")
    )

    process {
        Write-Host "📊 Coletando dados para exportação..." -ForegroundColor Magenta

        $systemInfo = Get-PoshSystemInfo
        $computerName = $systemInfo.ComputerName
        $os = $systemInfo.OS
        $totalRamGB = $systemInfo.TotalRAM_GB
        
        $availableRamGB = 0
        if ($IsWindows) {
            try {
                $availableRamMB = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
                $availableRamGB = [Math]::Round($availableRamMB / 1024, 2)
            } catch {
                Write-Warning "Falha ao obter RAM disponível no Windows: $($_.Exception.Message)"
            }
        } else {
            if (Test-Path /proc/meminfo) {
                $memAvailableLine = Get-Content /proc/meminfo | Select-String "MemAvailable" | Out-String
                if ($memAvailableLine) {
                    $memAvailableKb = [double]($memAvailableLine -replace '[^\d]')
                    $availableRamGB = [Math]::Round($memAvailableKb / 1MB, 2)
                }
            }
        }

        $cpuUsagePercent = 0.0
        if ($IsWindows) {
            try {
                $cpuUsagePercent = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
                if ($null -eq $cpuUsagePercent) { $cpuUsagePercent = 0.0 }
            } catch {
                Write-Warning "Falha ao obter uso de CPU no Windows: $($_.Exception.Message)"
                $cpuUsagePercent = 0.0
            }
        } else {
            # Call the internal helper function for Linux CPU
            $cpuUsagePercent = _Get-LinuxCpuUsage
        }
        
        $status = "OK"
        if ($cpuUsagePercent -gt 80) {
            $status = "Critical"
        }

        $dataEntry = [PSCustomObject]@{
            Timestamp         = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            ComputerName      = $computerName
            OS                = $os
            TotalRAM_GB       = $totalRamGB
            AvailableRAM_GB   = $availableRamGB
            CPU_Usage_Percent = $cpuUsagePercent
            Status            = $status # Target column for ML
        }

        # Check if CSV file exists to determine if headers are needed
        $csvExists = Test-Path $FilePath
        
        if (-not $csvExists) {
            Write-Host "Criando novo arquivo CSV: $FilePath" -ForegroundColor Green
            $dataEntry | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8
        } else {
            Write-Host "Anexando dados ao arquivo CSV existente: $FilePath" -ForegroundColor Green
            $dataEntry | Export-Csv -Path $FilePath -NoTypeInformation -Encoding UTF8 -Append
        }

        Write-Host "Dados exportados com sucesso!" -ForegroundColor Green
    }
}

function Show-PoshMenu {
<#
.SYNOPSIS
    Apresenta um menu interativo baseado em console para operar o PoshAutomator.
.DESCRIPTION
    Esta função cria uma interface de linha de comando amigável, permitindo aos usuários
    acessar as funcionalidades do módulo PoshAutomator através de opções numéricas.
    O menu oferece escolhas para gerar relatórios de sistema e sair, com validação de entrada
    e mensagens claras para o usuário.
.OUTPUTS
    Nenhum. Interage diretamente com o console para exibir informações e receber entradas.
.EXAMPLE
    Show-PoshMenu
    Inicia o menu principal do PoshAutomator.
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Default'
    )]
    param()
    
    do {
        Clear-Host
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "    PAINEL POSHAUTOMATOR v1.3.1     " -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "1. Gerar Relatório Rápido"
        Write-Host "2. Ver Detalhes Completos"
        Write-Host "3. Exportar Dados para ML"
        Write-Host "4. Ver Métricas e Previsão"
        Write-Host "5. Sair"
        Write-Host "------------------------------------"

        $choice = Read-Host "Escolha uma opção (1-5)"
        
        switch ($choice) {
            "1" { 
                Get-SystemReport -ComputerName "Localhost" -ReportType "Resumido" 
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "2" { 
                Get-SystemReport -ComputerName "Localhost" -ReportType "Completo" 
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "3" {
                Export-PoshData
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "4" {
                Show-PoshMetrics
                Read-Host "`nPressione Enter para voltar ao menu..."
            }
            "5" { 
                Write-Host "Saindo... Até logo!" -ForegroundColor Yellow
                return 
            }
            default { 
                Write-Host "❌ Erro: '$choice' não é válido! Use 1, 2, 3, 4 ou 5." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

function Show-PoshMetrics {
<#
.SYNOPSIS
    Exibe métricas do sistema e uma previsão de uso da CPU, com conselhos.
.DESCRIPTION
    Esta função limpa a tela, gera um gráfico de métricas, exibe uma previsão
    do uso futuro da CPU e oferece um conselho baseado nessa previsão.
.OUTPUTS
    Nenhum. Interage diretamente com o console.
.EXAMPLE
    Show-PoshMetrics
    Exibe o dashboard de métricas e previsão.
#>
    [CmdletBinding()]
    param()

    process {
        Clear-Host
        Write-Host "⚙️ Atualizando gráfico de métricas..." -ForegroundColor Cyan
        python3 src/PoshAutomator/visualize_metrics.py

        Write-Host "🧠 Analisando tendência de CPU..." -ForegroundColor Cyan
        $predictionOutput = python3 src/PoshAutomator/predict_cpu.py | Out-String
        
        # Extrair o valor da predição usando regex
        $cpuPrediction = 0.0
        if ($predictionOutput -match 'Próximo pico estimado: ([\d.]+?)%') {
            $cpuPrediction = [double]$Matches[1]
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor DarkGreen
        Write-Host "=== POSH AUTOMATOR DASHBOARD ===" -ForegroundColor DarkGreen
        Write-Host "========================================" -ForegroundColor DarkGreen
        Write-Host ""
        Write-Host "🔮 PREVISÃO DE CPU: $($cpuPrediction | ForEach-Object {"{0:N2}%" -f $_})" -ForegroundColor Yellow -BackgroundColor DarkCyan

        Write-Host ""
        Write-Host "💡 CONSELHO ESPECIALISTA:" -ForegroundColor Green
        if ($cpuPrediction -gt 80) {
            Write-Host "🔴 CRÍTICO: Sobrecarga iminente! Considere encerrar processos." -ForegroundColor Red
        } elseif ($cpuPrediction -gt 50) {
            Write-Host "🟡 ALERTA: Carga em crescimento. Monitore de perto." -ForegroundColor Yellow
        } else {
            Write-Host "🟢 ESTÁVEL: Sistema operando dentro dos parâmetros normais." -ForegroundColor Green
        }
        Write-Host ""
        Write-Host "========================================" -ForegroundColor DarkGreen
    }
}

# Exporta todas as funções oficiais para o usuário
Export-ModuleMember -Function Get-PoshSystemInfo, Get-SystemReport, Export-PoshData, Show-PoshMenu, Show-PoshMetrics