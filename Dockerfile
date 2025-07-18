# Usa a imagem oficial mais recente do Superset
FROM apache/superset:latest

# Muda para o usuário root para poder instalar pacotes
USER root

# ---- Início: ADIÇÃO PARA MSSQL - Instalação do driver ODBC da Microsoft ----
RUN apt-get update && apt-get install -y curl apt-transport-https gnupg
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17
# ---- Fim: ADIÇÃO PARA MSSQL ----


# Agora, instala as outras dependências de sistema
RUN apt-get update && apt-get install -y \
    pkg-config \
    libmariadb-dev \
    default-libmysqlclient-dev \
    build-essential \
    libsasl2-dev \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala os drivers Python
# ALTERADO: Trocamos cx_Oracle por oracledb (que não precisa do Instant Client)
RUN pip install mysqlclient psycopg2 pyhive pyodbc PyAthena oracledb

# Configura as variáveis de ambiente para a inicialização do Superset
ENV ADMIN_USERNAME $ADMIN_USERNAME
ENV ADMIN_EMAIL $ADMIN_EMAIL
ENV ADMIN_PASSWORD $ADMIN_PASSWORD
ENV DATABASE $DATABASE

# Copia e prepara o script de inicialização
COPY /config/superset_init.sh ./superset_init.sh
RUN chmod +x ./superset_init.sh

# Copia o arquivo de configuração personalizado do Superset
COPY /config/superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py
ENV SECRET_KEY $SECRET_KEY

# Retorna para o usuário não-privilegiado 'superset' por segurança
USER superset

# Define o ponto de entrada do container
ENTRYPOINT [ "./superset_init.sh" ]
