# Usa a imagem oficial mais recente do Superset
FROM apache/superset:latest

# Muda para o usuário root para poder instalar pacotes
USER root

# ---- Início: Instalação do Oracle Instant Client ----
# Instala dependências necessárias para baixar, descompactar e executar o client Oracle
RUN apt-get update && apt-get install -y wget unzip libaio1 && rm -rf /var/lib/apt/lists/*

# Cria um diretório de trabalho padrão para software de terceiros
WORKDIR /opt/oracle

# Baixa o Oracle Instant Client. Esta é uma versão comum para Linux x64.
# Verifique o site da Oracle se precisar de uma versão diferente.
RUN wget https://download.oracle.com/otn_software/linux/instantclient/217000/instantclient-basic-linux.x64-21.7.0.0.dbru.zip

# Descompacta o arquivo baixado
RUN unzip instantclient-basic-linux.x64-21.7.0.0.dbru.zip

# ADICIONA O DIRETÓRIO DO CLIENT AO CAMINHO DE BIBLIOTECAS DO SISTEMA
# Esta é a linha mais importante, que resolve o erro "Cannot locate libclntsh.so"
ENV LD_LIBRARY_PATH /opt/oracle/instantclient_21_7
# Atualiza o cache do linker para que o sistema encontre a nova biblioteca
RUN ldconfig

# Retorna para o diretório de trabalho original da imagem do Superset
WORKDIR /app
# ---- Fim: Instalação do Oracle Instant Client ----


# Agora, continua com a instalação das outras dependências
RUN apt-get update && apt-get install -y \
    pkg-config \
    libmariadb-dev \
    default-libmysqlclient-dev \
    build-essential \
    libsasl2-dev \
    && rm -rf /var/lib/apt/lists/*

# Instala os drivers Python, incluindo o cx_Oracle que você está usando
RUN pip install mysqlclient psycopg2 pyhive cx_Oracle pyodbc PyAthena

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
