@{
    # Arquivo principal do módulo
    RootModule = 'PoshAutomator.psm1'

    # Versão inicial
    ModuleVersion = '1.2.0'

    # Identificador único (mantive o seu)
    GUID = 'b5bce30b-825f-4587-9cf4-ef1f3ed0b57b'

    # Seus dados profissionais
    Author = 'LeinadAyla'
    CompanyName = 'LeinadAyla'
    Copyright = '(c) 2026 LeinadAyla. All rights reserved.'

    # Descrição exigida pela Galeria
    Description = 'Modulo PowerShell para automação de coleta de informações de hardware e sistema.'

    # O que o módulo exporta (usando '*' para facilitar agora)
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'

    PrivateData = @{
        PSData = @{
            # Tags ajudam as pessoas a encontrarem seu módulo
            Tags = @('Automation', 'SystemInfo', 'Hardware', 'KaliLinux')
            
            # Link para o seu repositório que acabamos de criar
            ProjectUri = 'https://github.com/LeinadAyla/PoshAutomator'
            
            # Licença que você escolheu no GitHub
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}