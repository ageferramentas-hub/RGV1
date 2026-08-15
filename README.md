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

## Plugins

Configurados em [`.claude/settings.json`](.claude/settings.json). O marketplace é
registrado e o plugin habilitado automaticamente assim que você confia na pasta
do projeto — sem precisar rodar os comandos `/plugin` à mão.

| Plugin | Comando | O que faz |
| --- | --- | --- |
| [`watch@claude-video`](https://github.com/bradautomates/claude-video) | `/watch` | Dá input de vídeo pro Claude: baixa com `yt-dlp`, extrai frames com `ffmpeg`, transcreve por legenda ou Whisper, e entrega tudo pro modelo |

Uso: `/watch <url-ou-caminho> <sua pergunta>`.

### Dependências do `/watch`

Precisa de `ffmpeg` e `yt-dlp` na máquina. No macOS o plugin instala sozinho via
Homebrew na primeira execução; no Linux/Windows ele imprime o comando exato.
No Debian/Ubuntu:

```bash
sudo apt install ffmpeg && pipx install yt-dlp
```

Transcrição sai de graça quando o vídeo tem legenda — a maioria dos públicos tem.
Só cai no fallback Whisper (que pede chave da Groq ou da OpenAI) em vídeo sem
faixa de legenda nenhuma.

## Skills

Ficam em `.claude/skills/`. Carregam sozinhas ao abrir o projeto — nada a instalar.

| Skill | O que faz |
| --- | --- |
| [`web-artifacts-builder`](https://github.com/anthropics/skills/tree/main/skills/web-artifacts-builder) | Monta artifacts da claude.ai grandes e multi-componente com React 18 + TypeScript + Vite + Tailwind + shadcn/ui, e empacota tudo num HTML único e autocontido |

Oficial da Anthropic ([`anthropics/skills`](https://github.com/anthropics/skills)),
copiada do commit `f6656c1`. Como é uma cópia versionada aqui, não recebe
atualização automática — pra atualizar, recopie a pasta do repositório upstream.

Ela dispara sozinha quando o artifact pede estado, roteamento ou componentes
shadcn. Para um HTML/JSX de arquivo único ela não entra — e isso é intencional.

### Dependências

Node 18+ e `pnpm` (o `init-artifact.sh` instala o pnpm sozinho via `npm i -g`
se não achar). O script baixa bastante coisa na primeira execução: Vite,
Tailwind, ~26 pacotes Radix e mais.

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
