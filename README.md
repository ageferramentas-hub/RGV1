# RGV1

## MCP servers

Os servidores MCP do projeto ficam em [`.mcp.json`](.mcp.json) (escopo *project*).
Ao abrir o repositório no Claude Code, ele pede aprovação uma vez e passa a
carregar os três servidores automaticamente.

Só estão configurados servidores **100% gratuitos** — nenhum deles pede API key
ou conta paga.

| Servidor | O que faz | Custo | Pré-requisito |
| --- | --- | --- | --- |
| `playwright` | Controla um navegador (clicar, preencher, navegar, screenshot) via árvore de acessibilidade — testa o app como um QA | Grátis / open source (Microsoft) | Node 18+ |
| `chrome-devtools` | Conecta no Chrome já aberto: lê console, network, performance trace, DOM das abas | Grátis / open source (Google) | Chrome instalado |
| `glyph` | Mapeia a codebase por símbolo (Tree-sitter): funções, classes, tipos, sem despejar o arquivo inteiro no contexto. Go, Java, JS/TS, Python | Grátis / open source | binário `glyph` no `PATH` |

### Instalação dos pré-requisitos

`playwright` e `chrome-devtools` são baixados sob demanda pelo `npx` — nada a fazer.

O `glyph` é um binário Go e precisa ser instalado uma vez:

```bash
go install github.com/benmyles/glyph@latest
```

Isso instala em `$(go env GOPATH)/bin` (normalmente `~/go/bin`). Garanta que esse
diretório está no `PATH`:

```bash
export PATH="$PATH:$(go env GOPATH)/bin"   # adicione ao ~/.zshrc ou ~/.bashrc
```

Se preferir não mexer no `PATH`, troque `"command": "glyph"` no `.mcp.json` pelo
caminho absoluto do binário.

### Verificar

```bash
claude mcp list
```

### Notas

- **`chrome-devtools` roda contra o Chrome da sua máquina.** Em sessão remota /
  container não há Chrome com interface, então ele só é útil rodando o Claude
  Code localmente.
- **`playwright` e `chrome-devtools` se sobrepõem.** Playwright para automação e
  teste de ponta a ponta; Chrome DevTools para inspecionar o que já está aberto
  na sua aba (console, requests, performance).

### Não instalados (são pagos)

Ficaram de fora por exigirem conta e API key:

- **Perplexity** (`@perplexity-ai/mcp-server`) — busca ao vivo na internet. O
  pacote é open source, mas cada chamada consome a API paga da Perplexity
  (Sonar a partir de ~$1/M tokens + taxa por requisição). Não há tier gratuito
  permanente; o crédito mensal de $5 do plano Pro foi descontinuado em fev/2026.
- **Firecrawl** (`firecrawl-mcp`) — varre um site inteiro e devolve em markdown.
  Freemium: 1.000 créditos/mês grátis com cadastro, depois a partir de ~$16/mês.

Para adicionar qualquer um deles depois, acrescente ao `.mcp.json` referenciando
a variável de ambiente — **nunca cole a chave no arquivo**, que é versionado:

```json
"firecrawl": {
  "command": "npx",
  "args": ["-y", "firecrawl-mcp"],
  "env": { "FIRECRAWL_API_KEY": "${FIRECRAWL_API_KEY}" }
}
```
