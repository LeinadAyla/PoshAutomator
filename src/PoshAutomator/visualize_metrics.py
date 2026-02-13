import pandas as pd
import matplotlib.pyplot as plt
import os

def visualize_metrics():
    data_source = "system_data.csv"
    output_filename = "cpu_trend.png"
    
    script_dir = os.path.dirname(__file__)
    csv_path = os.path.join(script_dir, data_source)
    output_path = os.path.join(script_dir, output_filename)

    print(f"🔍 Carregando dados de: {csv_path}")

    if not os.path.exists(csv_path):
        print(f"❌ ERRO: O arquivo '{data_source}' não foi encontrado em '{script_dir}'.")
        print("Certifique-se de que a função 'Export-PoshData' foi executada para criar o CSV.")
        return

    try:
        df = pd.read_csv(csv_path)
        print(f"✅ Arquivo '{data_source}' carregado com sucesso!")

        # Convert 'Timestamp' column to datetime objects
        df['Timestamp'] = pd.to_datetime(df['Timestamp'])

        # Create the plot
        plt.figure(figsize=(12, 6))
        plt.plot(df['Timestamp'], df['CPU_Usage_Percent'], marker='o', linestyle='-', color='blue', label='Uso da CPU (%)')

        # Add horizontal alert line
        plt.axhline(y=80, color='red', linestyle='--', label='Alerta Crítico (80%)')

        # Customize plot
        plt.title('Tendência de Uso da CPU ao Longo do Tempo')
        plt.xlabel('Timestamp')
        plt.ylabel('Uso da CPU (%)')
        plt.grid(True, linestyle=':', alpha=0.7)
        plt.legend()
        plt.xticks(rotation=45) # Rotate x-axis labels for better readability
        plt.tight_layout() # Adjust layout to prevent labels from overlapping

        # Save the plot
        plt.savefig(output_path)
        print(f"🎉 Gráfico de tendência de CPU salvo como: {output_path}")

    except Exception as e:
        print(f"❌ ERRO ao processar ou plotar os dados: {e}")

if __name__ == "__main__":
    visualize_metrics()
