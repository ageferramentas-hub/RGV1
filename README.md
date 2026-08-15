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

| Plugin | O que faz |
| --- | --- |
| [`watch@claude-video`](https://github.com/bradautomates/claude-video) | `/watch <url-ou-caminho> <pergunta>` — dá input de vídeo pro Claude: baixa com `yt-dlp`, extrai frames com `ffmpeg`, transcreve por legenda ou Whisper |
| [`superpowers@superpowers-dev`](https://github.com/obra/superpowers) | 14 skills de processo de engenharia: brainstorming, TDD, debug sistemático, escrever/executar planos, code review, git worktrees, agentes em paralelo |
| [`social-media-skills@social-media-skills`](https://github.com/charlie947/social-media-skills) | 17 skills de conteúdo do sistema do Charlie Hills: voz, LinkedIn, Reels, thumbnails de YouTube, hooks, carrosséis, analytics |

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

| Skill | Origem | O que faz |
| --- | --- | --- |
| [`web-artifacts-builder`](https://github.com/anthropics/skills/tree/main/skills/web-artifacts-builder) | `anthropics/skills` @ `f6656c1` | Monta artifacts da claude.ai grandes e multi-componente com React 18 + TypeScript + Vite + Tailwind + shadcn/ui, e empacota tudo num HTML único e autocontido |
| `remotion-*` (12 skills) | [`remotion-dev/skills`](https://github.com/remotion-dev/skills) @ `9f0faa5` | Vídeo programático com [Remotion](https://www.remotion.dev): criar, renderizar, legendas, mapas, animação, interatividade, multimídia, Studio, upgrade. Entre por `remotion-best-practices`, que roteia pras demais |

Nenhum dos dois repositórios publica `marketplace.json`, então as skills estão
copiadas aqui e **não recebem atualização automática** — pra atualizar, recopie
as pastas do upstream. Os plugins da seção acima, esses sim, se atualizam
sozinhos.

### Dependências

- `web-artifacts-builder`: Node 18+ e `pnpm` (o `init-artifact.sh` instala o
  pnpm sozinho via `npm i -g` se não achar). A primeira execução baixa Vite,
  Tailwind e ~26 pacotes Radix.
- `remotion-*`: um projeto Remotion (Node 18+). As skills são documentação e
  padrões — não instalam nada por conta própria.

## gstack

O [gstack](https://github.com/garrytan/gstack) do Garry Tan (23 especialistas e
8 ferramentas como slash commands: `/office-hours`, `/review`, `/ship`, `/qa`,
`/investigate`, `/browse`, entre outros) **não é copiado pra dentro do repo** —
tem 70 MB e o próprio autor recomenda instalação global com auto-update.

O que está aqui é o bootstrap de *team mode* no [`CLAUDE.md`](CLAUDE.md), no modo
**`optional`**: quem abrir o projeto vê a instrução de instalar, mas não é
bloqueado se não instalar. Cada pessoa roda uma vez na própria máquina:

```bash
git clone --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup --team
```

Requer [Bun](https://bun.sh) 1.0+. Existe também o modo `required`, que instala
um hook `PreToolUse` e **bloqueia qualquer trabalho** sem o gstack instalado —
não é o que está configurado. Para mudar:

```bash
~/.claude/skills/gstack/bin/gstack-team-init required
```

## Não instalado

- **[`corethaines31/marketingskills`](https://github.com/corethaines31/marketingskills)**
  — o repositório retorna **404**. Ou não existe, ou é privado, ou a URL tem um
  typo. Confirme o endereço.

### Pagos (ficaram de fora por exigirem conta e API key)

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
