# Roger

Ambiente de trabalho do Claude Code: a configuração versionada de MCPs, plugins
e skills usada nas ferramentas internas da agência.

## Como usar

Este repositório é onde a configuração é **curada**, não onde as ferramentas são
construídas:

| O que você cria | Onde cria | Como chega na equipe |
| --- | --- | --- |
| skills, agentes, comandos, hooks, MCPs, plugins | **aqui, no Roger** | `./sync-config.sh ~/AGE/AGE-IA` |
| apps | **direto no `AGE-IA`** | já nasce lá |

App não se constrói aqui pra depois mover — nasce como pasta dentro do
[`AGE-IA`](https://github.com/ageferramentas-hub/AGE-IA), com histórico próprio
desde o primeiro commit.

O que está em `.claude/` e `.mcp.json` aqui tem escopo *projeto* — vale só
dentro desta pasta. Há dois caminhos pra levar isso adiante, e eles servem a
propósitos diferentes.

### Para a equipe → `sync-config.sh`

O que a equipe usa mora na raiz do
[`AGE-IA`](https://github.com/ageferramentas-hub/AGE-IA). Quem clona aquele
repositório recebe as 37 skills e os 3 MCPs sem rodar nada, e isso vale
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

Máquina nova: clone este repositório e rode `./setup-workspace.sh`. Se quiser as
skills fora do AGE-IA também, rode `./install.sh` — mas leia o aviso acima antes.

## Estrutura

Três repositórios, lado a lado:

```
~/AGE/
  ├── AGE-IA/       ← monorepo dos apps
  │     ├── GERADOR-DE-CARROSSEL/
  │     ├── AGE-WORKSPACE/
  │     └── <novos apps>/
  ├── Roger/        ← ambiente de trabalho (este repositório, só configuração)
  └── Cleverton/    ← projeto
```

**App novo é uma pasta dentro do `AGE-IA`**, não um repositório separado:

```bash
mkdir ~/AGE/AGE-IA/EDITOR-DE-VIDEO   # exemplo
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

Configurados em [`.claude/settings.json`](.claude/settings.json). A intenção é
que o marketplace se registre e o plugin habilite sozinho assim que você confia
na pasta do projeto, sem rodar `/plugin` à mão.

> ⚠️ **Plugin não funciona no Claude Code na web.** O comando `/plugin` nem
> existe lá — responde `/plugin isn't available in this environment.` E o
> `enabledPlugins` também não resolve sozinho: numa sessão remota de teste o
> `~/.claude/plugins/installed_plugins.json` ficou vazio e só um dos quatro
> marketplaces foi baixado.
>
> Por isso **o conteúdo destes plugins está copiado como skill**, que é a rota
> que funciona em qualquer ambiente:
>
> | Plugin | O que veio por cópia | Onde |
> | --- | --- | --- |
> | `superpowers` | 12 das 14 skills | raiz |
> | `watch@claude-video` | a skill `watch` | raiz |
> | `social-media-skills` | as 17 skills | `AGE-IA/GERADOR-DE-CARROSSEL/` |
> | `stripe` | nada | — |
>
> O `stripe` ficou de fora porque não há cobrança em nenhum app ainda; são 8
> skills que só somariam ruído. Quando entrar pagamento, é só pedir.
>
> As entradas continuam no `settings.json` porque no CLI e no desktop elas
> funcionam, e lá dão atualização automática. Se você usar por lá, rode
> `/plugin` e confira — havendo plugin e cópia ao mesmo tempo, a skill copiada
> na raiz é a que vale, e a do plugin fica inerte.

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

São 37 no total, 4,8 MB. Todas **copiadas** pra cá — os repositórios de origem ou
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
| `skill-creator` | `anthropics/skills` @ `f6656c1` | Criar, editar e medir performance de skills — inclusive as deste repo |

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

### Processo de engenharia

As 12 do [`obra/superpowers`](https://github.com/obra/superpowers) @ `b36e082`,
copiadas porque a rota de plugin não funciona na web:

| Skill | O que faz |
| --- | --- |
| `brainstorming` | Entrevista você até a ideia virar spec, antes de qualquer código |
| `writing-plans` | Vira spec em plano de passos |
| `executing-plans` | Executa um plano com checkpoints de revisão |
| `test-driven-development` | Teste antes da implementação |
| `systematic-debugging` | Método para bug e teste quebrado, antes de propor conserto |
| `requesting-code-review` / `receiving-code-review` | Pedir e receber revisão sem concordância performática |
| `verification-before-completion` | Proíbe dizer "pronto" sem rodar a verificação |
| `using-git-worktrees` | Isola o trabalho numa worktree |
| `subagent-driven-development` / `dispatching-parallel-agents` | Divide tarefas independentes entre agentes |
| `finishing-a-development-branch` | Fecha e integra a branch |

### Vídeo

| Skill | Origem | O que faz |
| --- | --- | --- |
| `watch` | [`bradautomates/claude-video`](https://github.com/bradautomates/claude-video) | `/watch <url> <pergunta>` — baixa com `yt-dlp`, extrai frames com `ffmpeg`, transcreve por legenda. Precisa de `ffmpeg` e `yt-dlp` |

### Removidas por redundância

Seis skills foram instaladas e depois tiradas. Cada descrição entra no contexto
toda sessão, e duas skills parecidas fazem o modelo escolher pior — cortar é
ganho, não perda.

| Removida | Motivo |
| --- | --- |
| `docx`, `pdf` | Já existem embutidas no Claude Code. A cópia de projeto vencia a embutida sem acrescentar nada |
| `nano-banana-2` | É um único modelo (Gemini 3.1 Flash Image) que o `ai-image-generation` já cobre entre os 50+ dele |
| `writing-skills` | Mesmo trabalho do `skill-creator`, que é mais completo (tem eval e benchmark) |
| `using-superpowers` | Roteador do pacote superpowers, feito para o plugin. Solto, exige invocar skill antes de qualquer resposta — atrito em toda conversa, sem ganho |
| `find-skills` | Descobre e instala skills, mas a rota de instalação não funciona neste ambiente e tudo já está copiado |

Duas que **pareciam** duplicadas e ficaram: `dispatching-parallel-agents` (várias
falhas independentes em paralelo) e `subagent-driven-development` (executar um
plano em sequência, um subagente por tarefa). São trabalhos diferentes.

### A avaliar

As **12 skills `remotion-*`** são 32% do total e nenhum app usa Remotion ainda.
Quando o app de vídeo existir, o lugar delas é dentro da pasta dele — não na
raiz, onde pesam em toda sessão de todo app.

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
