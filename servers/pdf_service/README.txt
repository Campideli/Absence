# PDF Schedule Extraction Microservice

## 🚀 Como rodar localmente:

### 1. Configure o ambiente:
   ```bash
   # Copie o arquivo .env.example para .env
   cp .env.example .env
   
   # Edite o .env e configure as variáveis:
   # - ENVIRONMENT=development
   # - ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
   ```

### 2. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
   (opcional: python3 -m venv venv && source venv/bin/activate)

### 3. Rode o servidor:
   ```bash
   uvicorn main:app --reload --port 8000
   ```

## 📡 Endpoint principal:
**POST /extract-schedule**
- Recebe um PDF (campo 'file')
- Retorna JSON com matérias, horários, dias e texto bruto extraído

Ajuste o parser conforme o layout real do PDF da UEM para resultados mais precisos.
