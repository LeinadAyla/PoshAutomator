# tests/Get-PoshSystemInfo.Tests.ps1

BeforeAll {
    # Resolve o caminho de forma absoluta para o Pester não se perder
    $modulePath = Resolve-Path (Join-Path $PSScriptRoot "../src/PoshAutomator/PoshAutomator.psm1")
    Import-Module $modulePath -Force
}

Describe "Get-PoshSystemInfo" {
    Context "Validação de Objeto" {
        
        # Movemos a execução para dentro de um BeforeEach ou diretamente no teste
        # para garantir que a variável $info esteja disponível no escopo do It
        BeforeAll {
            $info = Get-PoshSystemInfo
        }

        It "Deve retornar um objeto não nulo" {
            $info | Should -Not -BeNullOrEmpty
        }

        It "Deve conter a propriedade ComputerName preenchida" {
            $info.ComputerName | Should -Not -BeNullOrEmpty
        }

        It "TotalRAM_GB deve ser um número maior que zero" {
            $info.TotalRAM_GB | Should -BeGreaterThan 0
        }
    }
}