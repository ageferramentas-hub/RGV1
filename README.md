# Roger

Ambiente de trabalho do Claude Code: a configuração versionada de MCPs, plugins
e skills usada nas ferramentas internas da agência.

## Como usar

Este repositório é onde a configuração é **curada**, não onde as ferramentas são
construídas. O que está em `.claude/` e `.mcp.json` aqui tem escopo *projeto* —
vale só dentro desta pasta. Há dois caminhos pra levar isso adiante, e eles
servem a propósitos diferentes.

### Para a equipe → `sync-config.sh`

O que a equipe usa mora na raiz do
[`AGE-IA`](https://github.com/ageferramentas-hub/AGE-IA). Quem clona aquele
repositório recebe as 28 skills, os 4 plugins e os 3 MCPs sem rodar nada, e vale
em qualquer app de lá. Depois de editar a configuração aqui:

```bash
./sync-config.sh ~/AGE/AGE-IA --dry-run   # ver o que mudaria
./sync-config.sh ~/AGE/AGE-IA             # copiar
```

Ele só copia — não faz commit nem push. Revise com `git diff` no AGE-IA e
publique de lá. E recusa qualquer destino cujo `origin` não seja o AGE-IA, pra
não sobrescrever a configuração do repositório errado.

### Só pra você → `install.sh`

Publica a configuração em `~/.claude` (escopo usuário), fazendo valer em **toda**
pasta da sua máquina, inclusive fora do AGE-IA:

```bash
./install.sh            # instala
./install.sh --dry-run  # mostra o que faria, sem escrever
./install.sh --force    # sobrescreve skills já existentes
```

É idempotente e, por padrão, não sobrescreve skill existente. Depois, reinicie o
Claude Code.

⚠️ **Não use os dois pro mesmo conjunto de skills.** O escopo pessoal
(`~/.claude/skills/`) **vence** o do projeto. Se você rodar o `install.sh` e
depois a equipe atualizar uma skill no AGE-IA, você continua na versão antiga
sem nenhum aviso. Escolha um: `install.sh` se trabalha sozinho fora do AGE-IA,
`sync-config.sh` se trabalha em equipe dentro dele.

O arranjo pretendido:

| Onde | O que |
| --- | --- |
| `~/.claude/` | skills, MCPs e plugins ativos — valem em qualquer projeto |
| este repositório | a cópia versionada disso + o instalador |
| [`AGE-IA`](https://github.com/ageferramentas-hub/AGE-IA) | monorepo dos apps — cada app é uma pasta na raiz de lá |

Máquina nova: clone este repositório, rode `./install.sh`, cole os comandos
`/plugin` que ele imprime no final, e o ambiente está de pé.

## Estrutura

Três repositórios, lado a lado:

```
~/AGE/
  ├── AGE-IA/       ← monorepo dos apps
  │     ├── GERADOR-DE-CARROSSEL/
  │     ├── EDITOR-DE-VIDEO/
  │     └── <novos apps>/
  ├── Roger/        ← ambiente de trabalho (este repositório, só configuração)
  └── Cleverton/    ← projeto
```

**App novo é uma pasta dentro do `AGE-IA`**, não um repositório separado:

```bash
mkdir ~/AGE/AGE-IA/EDITOR-DE-VIDEO
```

O `Roger` é o único que não é projeto — só guarda configuração. Nenhum código de
app mora aqui.

```bash
./setup-workspace.sh --dry-run   # ver o que faria
./setup-workspace.sh             # criar ~/AGE e clonar os três repositórios
```

Também é idempotente — repositório já clonado é pulado, nunca sobrescrito. Para
usar outro caminho: `AGE_WORKSPACE=/onde/quiser ./setup-workspace.sh`.

Repositório novo (não app) entra na lista `REPOS` no topo do script, no formato
`nome-no-github:NOME-DA-PASTA`.

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
| [`stripe@claude-plugins-official`](https://github.com/stripe/ai/tree/main/providers/claude/plugin) | 8 skills da Stripe, entre elas `stripe-best-practices`, além de `stripe-docs`, `stripe-apps` e `upgrade-stripe` |

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

São 28 no total, 5,7 MB. Todas **copiadas** pra cá — os repositórios de origem ou
não publicam `marketplace.json`, ou publicam mas você pediu skills específicas
em vez do pacote inteiro. Por isso **nenhuma recebe atualização automática**:
pra atualizar, recopie a pasta do upstream. Os plugins da seção acima, esses
sim, se atualizam sozinhos.

### Design e frontend

| Skill | Origem | O que faz |
| --- | --- | --- |
| `web-artifacts-builder` | `anthropics/skills` @ `f6656c1` | Artifacts da claude.ai multi-componente com React 18 + TS + Vite + Tailwind + shadcn/ui, empacotados num HTML único |
| `frontend-design` | `anthropics/skills` @ `f6656c1` | Direção visual, tipografia e escolhas estéticas que não parecem template |
| `shadcn` | [`shadcn-ui/ui`](https://github.com/shadcn-ui/ui) @ `d4fc45b` | Adiciona, busca, corrige e compõe componentes shadcn/ui; entende `components.json`, registries e presets |
| `web-design-guidelines` | [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) @ `b8caa26` | Audita código de UI contra as Web Interface Guidelines (acessibilidade, UX) |

### Vídeo, imagem e mídia

| Skill | Origem | O que faz |
| --- | --- | --- |
| `remotion-*` (12 skills) | [`remotion-dev/skills`](https://github.com/remotion-dev/skills) @ `9f0faa5` | Vídeo programático com [Remotion](https://www.remotion.dev). Entre por `remotion-best-practices`, que roteia pras demais |
| `ai-image-generation` | [`inference-sh/skills`](https://github.com/inference-sh/skills) @ `becc256` | Geração de imagem com FLUX, GPT-Image-2, Gemini, Seedream e +50 modelos via CLI da inference.sh |
| `nano-banana-2` | `inference-sh/skills` @ `becc256` | Gemini 3.1 Flash Image (Nano Banana 2): text-to-image, edição, até 14 imagens de entrada |
| `ai-video-generation` | `inference-sh/skills` @ `becc256` | Vídeo com Veo 3.1, Seedance 2.0, Wan, Grok e +40 modelos |

### Backend, dados e infra

| Skill | Origem | O que faz |
| --- | --- | --- |
| `supabase-postgres-best-practices` | [`supabase/agent-skills`](https://github.com/supabase/agent-skills) @ `8331f91` | Regras de Postgres: schema, migrations, RLS, índices, pgvector, diagnóstico de query lenta |
| `mcp-builder` | `anthropics/skills` @ `f6656c1` | Construir servidores MCP em Python (FastMCP) ou Node/TS |
| `webapp-testing` | `anthropics/skills` @ `f6656c1` | Testa webapp local com Playwright: screenshots, logs do browser, verificação de UI |

### Marketing e conteúdo

| Skill | Origem | O que faz |
| --- | --- | --- |
| `copywriting` | [`coreyhaines31/marketingskills`](https://github.com/coreyhaines31/marketingskills) @ `7868cb9` | Copy de homepage, landing, pricing, features — headline, CTA, proposta de valor |
| `content-strategy` | `coreyhaines31/marketingskills` @ `7868cb9` | Decide *o que* produzir: pilares, clusters de tópico, calendário editorial |

### Documentos e meta

| Skill | Origem | O que faz |
| --- | --- | --- |
| `docx` | `anthropics/skills` @ `f6656c1` | Criar, ler e editar `.docx` / `.dotx` |
| `pdf` | `anthropics/skills` @ `f6656c1` | Ler, extrair, juntar, dividir, preencher formulário e OCR em PDF |
| `skill-creator` | `anthropics/skills` @ `f6656c1` | Criar, editar e medir performance de skills — inclusive as deste repo |
| `find-skills` | [`vercel-labs/skills`](https://github.com/vercel-labs/skills) @ `c6f69c6` | Descobre e instala skills quando você pergunta "existe uma skill pra X?" |

### Dependências

- `web-artifacts-builder`: Node 18+ e `pnpm` (o `init-artifact.sh` instala o
  pnpm sozinho via `npm i -g` se não achar). A primeira execução baixa Vite,
  Tailwind e ~26 pacotes Radix.
- `remotion-*`: um projeto Remotion (Node 18+). São documentação e padrões —
  não instalam nada por conta própria.
- `ai-image-generation`, `nano-banana-2`, `ai-video-generation`: CLI da
  [inference.sh](https://inference.sh) e **conta com créditos**. As skills em si
  são grátis; os modelos que elas chamam são cobrados por geração.
- `webapp-testing`: Playwright.
- `docx`, `pdf`: Python 3.

### Duplicatas

- **`brainstorming`** você pediu via `npx skills add`, mas ele **já vem** no
  plugin `superpowers@superpowers-dev` instalado acima. Copiar de novo criaria
  duas cópias da mesma skill, então não copiei.
- **`docx` e `pdf`** já existem como skills embutidas do Claude Code. As cópias
  aqui são de projeto e têm precedência sobre as embutidas — instalei porque
  você pediu explicitamente, mas dá pra remover sem perder a funcionalidade.

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
