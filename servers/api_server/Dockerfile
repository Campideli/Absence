# Use imagem oficial do Dart
FROM dart:stable

# Crie diretório de trabalho
WORKDIR /app

# Copie os arquivos do projeto
COPY . .

# Instale dependências
RUN dart pub get

# Exponha a porta (ajuste conforme sua API)
EXPOSE 8080

# Comando para iniciar a API
CMD ["dart", "bin/api_server.dart"]
