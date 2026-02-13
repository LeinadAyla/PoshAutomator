import pandas as pd
import os

def check_ml_data():
    data_source = "system_data.csv"
    script_dir = os.path.dirname(__file__)
    csv_path = os.path.join(script_dir, data_source)

    print(f"🔍 Verificando arquivo de dados: {csv_path}")

    if not os.path.exists(csv_path):
        print(f"❌ ERRO: O arquivo '{data_source}' não foi encontrado em '{script_dir}'.")
        print("Certifique-se de que a função 'Export-PoshData' foi executada para criar o CSV.")
        return

    try:
        df = pd.read_csv(csv_path)
        print(f"
✅ Arquivo '{data_source}' carregado com sucesso!")

        print("
📊 Primeiras 5 linhas do dataset:")
        print(df.head().to_markdown(index=False, numalign="left", stralign="left")) # Using to_markdown for better CLI display

        print("
📈 Resumo estatístico transposto:")
        print(df.describe().T.to_markdown(numalign="left", stralign="left")) # Using to_markdown for better CLI display

        if 'CPU_Usage_Percent' in df.columns:
            cpu_mean = df['CPU_Usage_Percent'].mean()
            print(f"
⚙️ Média de uso da CPU: {cpu_mean:.2f}%")

            if cpu_mean > 50:
                print("⚠️ INSIGHT: Carga constante, a média de uso da CPU está acima de 50%.")
            else:
                print("✅ INSIGHT: Sistema saudável, a média de uso da CPU está abaixo de 50%.")
        else:
            print("⚠️ A coluna 'CPU_Usage_Percent' não foi encontrada no CSV.")

    except Exception as e:
        print(f"❌ ERRO ao processar o arquivo CSV: {e}")

if __name__ == "__main__":
    check_ml_data()
