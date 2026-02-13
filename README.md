# 🚀 PoshAutomator v1.3 - AI Powered Monitoring

Uma ferramenta híbrida que une o poder do PowerShell para automação de sistemas com Machine Learning em Python para predição de carga de CPU.

## ✨ Funcionalidades

*   Coleta de métricas em tempo real (PowerShell).
*   Predição de tendência de CPU usando Regressão Linear (Scikit-Learn).
*   Dashboard interativo no terminal.
*   Visualização de dados com gráficos de tendência.

## 📦 Como Instalar

Para configurar e rodar o PoshAutomator, siga os passos abaixo:

1.  **Clonar o repositório:**
    ```bash
    git clone https://github.com/PoshAutomator/PoshAutomator.git
    cd PoshAutomator
    ```

2.  **Criar e ativar o ambiente virtual Python:**
    ```bash
    python3 -m venv .venv
    # No Linux/macOS:
    source .venv/bin/activate
    # No Windows (cmd.exe):
    .venv\Scripts\activate.bat
    # No Windows (PowerShell):
    .venv\Scripts\Activate.ps1
    ```

3.  **Instalar as dependências Python:**
    ```bash
    pip install -r src/PoshAutomator/requirements.txt
    ```

## 🚀 Como Usar

1.  **Importar o módulo PowerShell (dentro de uma sessão PowerShell):**
    ```powershell
    Import-Module ./src/PoshAutomator/PoshAutomator.psm1
    ```

2.  **Iniciar o menu interativo:**
    ```powershell
    Show-PoshMenu
    ```
    A partir do menu, você pode gerar relatórios, exportar dados para ML, e visualizar métricas com previsão de CPU.

## 🌳 Estrutura do Projeto

```
.
├───src/
│   └───PoshAutomator/
│       ├───PoshAutomator.psd1
│       ├───PoshAutomator.psm1
│       ├───system_data.csv
│       ├───visualize_metrics.py
│       ├───predict_cpu.py
│       └───requirements.txt
└───...
```

## 🏷️ Tecnologias

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Scikit-Learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)
