# Absence - Sistema de Controle de Faltas Acadêmicas

Um sistema simples para controle de faltas acadêmicas construído com Flutter.

## Estrutura do Projeto

```
absence/
├── apps/
│   └── absence_app/         # Aplicativo Flutter
│       └── lib/
│           └── main.dart    # Aplicativo principal
├── melos.yaml               # Configuração do monorepo
└── README.md
```

## Tecnologias Utilizadas

- **Frontend**: Flutter
- **Design**: Material Design 3
- **Monorepo**: Melos

## Configuração do Ambiente

### Pré-requisitos

- Flutter SDK (3.32.7+)
- Dart SDK (3.8.1+)

### Instalação

1. Clone o repositório:
```bash
git clone https://github.com/Campideli/absence-private.git
cd absence-private
```

2. Instale as dependências:
```bash
melos get
```

## Executando o Projeto

### Opção 1: Comandos Melos

#### Web (porta 3000)
```bash
melos web
```

#### Android
```bash
melos android
```

### Opção 2: Task do VS Code

1. Pressione `Ctrl+Shift+P` para abrir a paleta de comandos
2. Digite "Tasks: Run Task"
3. Selecione "Flutter: Run Web App"

Isso iniciará o aplicativo web na porta 3000 usando o navegador Edge.

## Scripts Disponíveis

- `melos web` - Executa o app na web (porta 3000)
- `melos android` - Executa o app no Android
- `melos clean` - Limpa build artifacts
- `melos get` - Instala dependências
- `melos kill-port` - Encerra processos que estão usando a porta 3000

## Funcionalidades Atuais

- ✅ Splash Screen com logo e loading
- ✅ Navegação automática após 3 segundos
- ✅ Tela de Login básica
- ✅ Tema Material Design 3
- ✅ Suporte para web e mobile

## Desenvolvimento

O projeto está em sua versão inicial e contém apenas:
- Splash screen funcional
- Navegação básica
- Estrutura pronta para expansão

## Próximos Passos

1. Implementar sistema de autenticação
2. Criar telas de gerenciamento de matérias
3. Adicionar funcionalidades de controle de faltas
4. Implementar dashboard com estatísticas
