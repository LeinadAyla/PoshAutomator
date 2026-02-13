import pandas as pd
from sklearn.linear_model import LinearRegression
import sys

# Define o caminho para o arquivo de dados
data_file = 'src/PoshAutomator/system_data.csv'

try:
    # Carrega os dados do sistema
    df = pd.read_csv(data_file)

    # Converte a coluna 'Timestamp' para datetime
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])

    # Verifica se há dados suficientes para a previsão
    if len(df) < 3:
        print("⚠️ Dados insuficientes para prever.")
        sys.exit()

    # Calcula os segundos relativos desde o primeiro registro
    df['Seconds_Elapsed'] = (df['Timestamp'] - df['Timestamp'].min()).dt.total_seconds()

    # Define as features (X) e o alvo (y)
    X = df[['Seconds_Elapsed']]
    y = df['CPU_Usage_Percent']

    # Cria e treina o modelo de Regressão Linear
    model = LinearRegression()
    model.fit(X, y)

    # Calcula o tempo futuro para a previsão (último tempo + 30 segundos)
    future_time = df['Seconds_Elapsed'].max() + 30
    
    # Faz a predição para o futuro
    predicted_cpu = model.predict([[future_time]])

    # Imprime a tendência detectada
    print(f"🔮 [AutoML] Tendência detectada! Próximo pico estimado: {predicted_cpu[0]:.2f}%")

except FileNotFoundError:
    print(f"❌ Erro: Arquivo '{data_file}' não encontrado.")
    sys.exit(1)
except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)
