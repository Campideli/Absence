# Absence Management API Server

Backend API server em Dart para o sistema de gerenciamento de ausências.

## Características

- **Framework**: Shelf (Dart HTTP server framework)
- **Autenticação**: Firebase Authentication
- **Banco de dados**: Cloud Firestore
- **Arquitetura**: REST API com middleware modular
- **Documentação**: OpenAPI/Swagger (planejado)

## Estrutura do Projeto

```
lib/
├── src/
│   ├── config/          # Configurações do servidor
│   ├── controllers/     # Controllers REST
│   ├── middleware/      # Middleware (auth, CORS, logging)
│   ├── models/          # Modelos de dados
│   ├── routes/          # Definição de rotas
│   ├── services/        # Serviços (Firebase, Firestore)
│   └── api_server.dart  # Classe principal do servidor
└── api_server.dart      # Biblioteca principal
```

## Configuração

### 1. Instalar dependências

```bash
dart pub get
```

### 2. Configurar Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
2. Ative Authentication e Firestore
3. Gere uma chave de conta de serviço:
   - Vá em Project Settings > Service Accounts
   - Clique em "Generate new private key"
   - Baixe o arquivo JSON

### 3. Configurar variáveis de ambiente

Copie `.env.example` para `.env` e configure:

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações:

```env
ENVIRONMENT=development
PORT=8080
HOST=0.0.0.0

FIREBASE_PROJECT_ID=seu-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nSUA_CHAVE_PRIVADA_AQUI\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@seu-project-id.iam.gserviceaccount.com

ENABLE_CORS=true
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### 4. Gerar código (JSON serializable)

```bash
dart run build_runner build
```

## Executando o servidor

### Desenvolvimento

```bash
dart run bin/api_server.dart
```

### Com observador (debug)

```bash
dart run --observe bin/api_server.dart
```

### Usando Melos (na raiz do projeto)

```bash
melos run api
```

## API Endpoints

### Autenticação

- `POST /api/v1/auth/register` - Registrar novo usuário
- `GET /api/v1/auth/profile` - Obter perfil do usuário (requer auth)
- `PUT /api/v1/auth/profile` - Atualizar perfil (requer auth)
- `POST /api/v1/auth/verify` - Verificar token (requer auth)

### Usuários

- `GET /api/v1/users` - Listar usuários (admin)
- `GET /api/v1/users/{id}` - Obter usuário específico

### Ausências

- `GET /api/v1/absences` - Listar ausências do usuário
- `POST /api/v1/absences` - Criar nova ausência
- `GET /api/v1/absences/{id}` - Obter ausência específica
- `PUT /api/v1/absences/{id}` - Atualizar ausência
- `DELETE /api/v1/absences/{id}` - Deletar ausência

### Admin - Ausências

- `GET /api/v1/admin/absences` - Listar todas as ausências (admin)
- `GET /api/v1/admin/absences/pending` - Listar ausências pendentes (admin)
- `POST /api/v1/admin/absences/{id}/approve` - Aprovar ausência (admin)
- `POST /api/v1/admin/absences/{id}/deny` - Negar ausência (admin)

## Autenticação

A API usa Firebase Authentication com tokens JWT. Inclua o token no header:

```
Authorization: Bearer YOUR_FIREBASE_TOKEN
```

## Modelos de Dados

### UserModel

```json
{
  "id": "string",
  "email": "string",
  "displayName": "string?",
  "photoUrl": "string?",
  "createdAt": "string",
  "updatedAt": "string",
  "isActive": "boolean",
  "metadata": "object?"
}
```

### AbsenceModel

```json
{
  "id": "string",
  "userId": "string",
  "type": "vacation|sick_leave|personal|emergency|other",
  "status": "pending|approved|denied|cancelled",
  "startDate": "string",
  "endDate": "string",
  "reason": "string?",
  "notes": "string?",
  "approvedBy": "string?",
  "approvedAt": "string?",
  "createdAt": "string",
  "updatedAt": "string",
  "totalDays": "number?",
  "metadata": "object?"
}
```

## Desenvolvimento

### Comandos úteis

```bash
# Instalar dependências
dart pub get

# Executar testes
dart test

# Gerar código (modelos)
dart run build_runner build

# Watch mode para geração de código
dart run build_runner watch

# Limpar cache de build
dart run build_runner clean

# Analisar código
dart analyze

# Formatar código
dart format .

# Compilar para executável
dart compile exe bin/api_server.dart -o build/api_server
```

### Estrutura de Middleware

O servidor usa um pipeline de middleware:

1. **LoggingMiddleware** - Log de requisições
2. **CorsMiddleware** - Headers CORS
3. **AuthMiddleware** - Autenticação (quando necessário)
4. **Router** - Roteamento de endpoints

### Adicionando novos endpoints

1. Crie um método no controller apropriado
2. Adicione a rota em `api_routes.dart`
3. Configure middleware se necessário

## Produção

### Build

```bash
dart compile exe bin/api_server.dart -o build/api_server
```

### Deploy

O executável gerado pode ser implantado em qualquer servidor que suporte executáveis nativos.

### Variáveis de ambiente de produção

```env
ENVIRONMENT=production
PORT=8080
FIREBASE_PROJECT_ID=seu-project-id-prod
FIREBASE_PRIVATE_KEY=sua-chave-privada-prod
FIREBASE_CLIENT_EMAIL=seu-client-email-prod
ALLOWED_ORIGINS=https://seudominioprod.com
```

## Contribuição

1. Faça fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## Licença

Este projeto está sob a licença MIT.
