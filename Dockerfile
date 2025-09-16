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

# ---- Início: Instalação do Oracle Instant Client (com o novo link funcional) ----
# Instala dependências para descompactar e executar o client
RUN apt-get update && apt-get install -y wget unzip libaio1 && rm -rf /var/lib/apt/lists/*
# Entra no diretório de destino
WORKDIR /opt/oracle
# ATUALIZADO: Usa o novo link que você forneceu para a versão 21.19
RUN wget https://download.oracle.com/otn_software/linux/instantclient/2119000/instantclient-basic-linux.x64-21.19.0.0.0dbru.zip
# RUN wget https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linuxx64.zip
# ATUALIZADO: Descompacta o novo nome de arquivo
RUN unzip instantclient-basic-linux.x64-21.19.0.0.0dbru.zip
# RUN unzip instantclient-basic-linuxx64.zip
# ATUALIZADO: Aponta para o novo nome do diretório (instantclient_21_19)
ENV LD_LIBRARY_PATH /opt/oracle/instantclient_21_19
# Atualiza o cache do linker
RUN ldconfig

# Retorna para o diretório de trabalho original do Superset
WORKDIR /app
# ---- Fim: Instalação do Oracle Instant Client ----

# Agora, instala as outras dependências de sistema
RUN apt-get update && apt-get install -y \
    pkg-config \
    libmariadb-dev \
    default-libmysqlclient-dev \
    build-essential \
    libsasl2-dev \
    unixodbc-dev \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*


# Instala os drivers Python
RUN pip install --upgrade pip

# ALTERADO: Trocamos cx_Oracle por oracledb (que não precisa do Instant Client)
RUN pip install psycopg2==2.9.10
RUN pip install mysqlclient pyhive pyodbc PyAthena cx_Oracle
# RUN pip install prophet

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

# Define o ponto de entrada do container
ENTRYPOINT [ "./superset_init.sh" ]

# Retorna para o usuário não-privilegiado 'superset' por segurança
USER superset
