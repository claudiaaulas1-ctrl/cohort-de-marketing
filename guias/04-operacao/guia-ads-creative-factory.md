# GUIA — Criativos de IA pela ads-creative-factory (o caminho avançado, pago)

> **Estou perdido em:** "quero criativo de imagem de VERDADE, gerado por IA, não banner de texto sobre fundo liso — e li que existe uma tal de creative-factory".
> **O caminho simples deste guia:** o caminho grátis é o [guia-criativos.md](guia-criativos.md) (`/criativos-funil`, HTML→PNG, sem IA de imagem). **Faça ele primeiro.** Este guia aqui é o degrau seguinte: a `ads-creative-factory` gera a IMAGEM por IA (GPT Image via Codex CLI), aplica a sua identidade e ainda REPROVA sozinha a peça fraca.
> **O que você vai ter no final:** um lote de criativos PNG em `projetos/{slug}/criativos-ia/`, cada um com veredito do gate (`pass`/`fail`), nota de marca (0–100) e nota de "slop" (cara de IA) — mais o `manifest.json` dizendo por que cada peça passou ou caiu.
> **Fontes cruzadas:** `.claude/skills/ads-creative-factory/SKILL.md` + `scripts/doctor.py`, `build_brand_pack.py`, `factory.py`, `data/hooks-library.yaml` (código real conferido) · `_interno/criativos-cobertura.md` (os 3 motores de imagem do repo) · teste real do professor em 24/07/2026 no projeto `no-azul` (Windows 11) · [ImageMagick/MIT — conflito do `convert.exe` no Windows](https://web.mit.edu/graphics/share/ImageMagick/www/windows.html) · [OpenAI Codex — "model requires a newer version"](https://community.openai.com/t/codex-requires-newer-version/1387174).

> ⚠️ **Isto é o caminho PAGO.** A imagem sai pela sessão logada do **Codex CLI**, o que exige **assinatura ChatGPT ativa**. Chave de API (`OPENAI_API_KEY`) **não serve** — o código REMOVE as chaves do ambiente antes de chamar o Codex (`alib.py`, função `codex_image`). Não existe "só desta vez com API key".

## Pré-requisitos (confira ANTES)

| Tipo | Pré-requisito | Não tem? Faça isso |
|---|---|---|
| 📖 Conhecimento | Você já rodou o caminho grátis ([guia-criativos.md](guia-criativos.md)) e sabe o que é um hook curado | rode `/criativos-funil` primeiro — este guia assume que você já sabe escolher 2–3 finalistas |
| 🔑 Assinatura | **ChatGPT paga**, com o **Codex CLI logado** nessa conta | assine em chatgpt.com → instale e faça login ([guia-codex](../01-pre-requisitos/guia-codex.md)). Sem isso, PARE: este caminho não roda |
| 📄 Artefato | `projetos/{slug}/DESIGN.md` — **bloqueante**: é dele que sai a paleta, a tipografia e a autorização de uso | rode `/design-md` (Aula 2) |
| 📄 Artefato | `projetos/{slug}/copy.md` — de onde saem os hooks (headline, sub, CTA) | rode `/copy-funil` (Aula 2) |
| 🧰 Ferramenta | **Python 3** com Pillow, PyYAML e NumPy | `pip install pillow pyyaml numpy` |
| 🧰 Ferramenta | **ImageMagick** com o comando `magick` no PATH | Windows: `winget install ImageMagick.ImageMagick` · macOS: `brew install imagemagick`. **Depois REABRA o terminal** |
| 🧰 Ferramenta | **Codex CLI atualizado** (não basta estar instalado — ver CF2) | `npm install -g @openai/codex@latest` |

## Passo 1 — Conferir a máquina (o doctor)

Rode o diagnóstico ANTES de qualquer geração. Ele checa os 6 pré-requisitos de uma vez:

```bash
SKILL_DIR="$(git rev-parse --show-toplevel)/.claude/skills/ads-creative-factory"
python3 "$SKILL_DIR/scripts/doctor.py" --json
```

**No Windows, se a saída explodir com `UnicodeEncodeError`,** rode assim (vale para TODOS os comandos deste guia):

```bash
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 python3 "$SKILL_DIR/scripts/doctor.py" --json
```

Você quer ver `"status": "ready"` e `"required_blockers": 0`. Qualquer check em `blocked` tem a instrução do que fazer no próprio campo `action`.

> ⚠️ **O doctor NÃO checa a versão do Codex** — ele marca `ready` só por encontrar o comando. Um Codex velho passa aqui e só falha lá na geração, como `FAILED_GENERATION`. Por isso o pré-requisito manda atualizar antes (CF2).

## Passo 2 — Montar o brand-pack (a sua identidade, uma vez por projeto)

O brand-pack é o `DESIGN.md` traduzido para o formato que a fábrica entende. Sem ele, nada roda.

```bash
python3 "$SKILL_DIR/scripts/build_brand_pack.py" \
  --design "projetos/{slug}/DESIGN.md" \
  --output "projetos/{slug}/brand-pack" \
  --rights-notice "Declaro que tenho direito de usar estes ativos neste projeto." \
  --json
```

O `--rights-notice` é obrigatório e é uma declaração sua, de verdade: você afirma ter direito de usar aquela identidade. Sem ela o builder falha fechado.

Quer incluir logo ou fonte própria? Acrescente `--asset` (repetível):
`--asset "logo:/caminho/para/logo.svg"` · tipos aceitos: `logo`, `font`, `reference`, `texture`, `other`.

**Confira na saída:** `"status": "valid"` e se a paleta (`primary`, `secondary`, `background`) bate com o seu `DESIGN.md`. Se vier cor que você não reconhece, o problema está no `DESIGN.md`, não aqui.

## Passo 3 — Escrever a campanha (o `campaign.yaml`)

Crie um arquivo `campanha.yaml` com os hooks que VOCÊ curou (2–3 finalistas, do `copy.md`):

```yaml
campaign: "meu-projeto-lote-01"
brand_id: "meu-projeto"
params:
  primary_axis: "archetype"
  variants_per_hook: 1
  formats: ["feed"]
  personas: []
hooks:
  - id: "H1"
    mechanism: "bold_question"
    eyebrow: "Autônomo e MEI"
    headline: "Faturou R$ 12 mil e não sabe quanto é seu?"
    emphasis_word: "quanto é seu"
    sub: "Faça esta conta em 15 minutos."
    cta: "Quero organizar meu caixa"
```

Regras que economizam retrabalho:

- **`mechanism` tem que ser um ID do catálogo**, não um nome livre. Se você inventar ("Renda Fixa Artificial"), a fábrica aceita mas cai em `before_after` no silêncio de um warning — e a peça sai com um visual que você não escolheu (CF5). IDs válidos ficam em `data/hooks-library.yaml`; os mais usados: `bold_question` (pergunta-gancho) · `before_after` (antes/depois) · `benchmark_proof` (prova comparativa) · `visual_metaphor_object` (metáfora de objeto) · `severed_dependency` (dependência rompida) · `emergence` (surgimento do método) · `authority_founder` (autoridade — **exige persona_pack com foto real**).
- **Comece com `variants_per_hook: 1` e um formato só.** Cada peça é uma chamada de geração de imagem; lote grande no primeiro teste é dinheiro e tempo jogados fora.
- **O arquétipo (o visual da peça) é sorteado pela fábrica**, não escolhido por você — é assim que ela garante diversidade de espécie. `person_authority` só entra com `persona_pack`.

## Passo 4 — Gerar o lote

```bash
export ACF_OUT_DIR="projetos/{slug}/criativos-ia"
export ACF_BRAND_PACK="projetos/{slug}/brand-pack"
PYTHONUTF8=1 PYTHONIOENCODING=utf-8 python3 "$SKILL_DIR/scripts/factory.py" campanha.yaml
```

A saída final é uma linha por peça:

```
=== meu-projeto-lote-01 — 2/3 hooks OK ===
  H1-dark_editorial-0 OK               verdict=pass  slop=0.0   brand=100.0
  H2-light_clean-0    FLAGGED_REVIEW   verdict=fail  slop=40.0  brand=75.0
  H3-person_authority-0 OK             verdict=pass  slop=0.0   brand=100.0
```

Como ler: **`brand`** = quanto a peça respeita a sua paleta (quer alto). **`slop`** = quanto ela tem cara de IA genérica (quer 0). **`FLAGGED_REVIEW`** = a própria fábrica reprovou; a peça existe no disco, mas não vai pro Gerenciador sem você consertar.

**Peça aprovada é a que está em `criativos-ia/{campanha}/final/{formato}/`.** O que está solto na raiz da pasta é intermediário (`__bg`, `__ts`, `__logo`) — não suba isso.

## Teste de sucesso

Abra `projetos/{slug}/criativos-ia/{campanha}/final/feed/`: existe pelo menos 1 PNG, ele abre, e as cores são as do seu `DESIGN.md` (não o azul/roxo genérico de IA). No `manifest.json` da campanha, esse mesmo item aparece com `"status": "OK"` e `"verdict": "pass"`. Régua honesta: se `brand` < 80 ou `slop` > 20, a peça não está pronta, mesmo que tenha passado.

## POSSÍVEIS ERROS — catálogo (pare no primeiro que resolver)

| # | Sintoma | Causa | O que fazer (em ordem) |
|---|---|---|---|
| **CF1** | `doctor.py` acusa ImageMagick `blocked` com **"Especificação de unidade inválida"** (ou "Invalid drive specification") | Windows tem um `convert.exe` NATIVO em `System32` que converte FAT→NTFS; sem ImageMagick instalado, o doctor acha ESSE e executa o programa errado | 1. `winget install ImageMagick.ImageMagick` · 2. **feche e reabra o terminal** (o PATH só atualiza aí) · 3. confirme com `magick -version` · 4. rode o doctor de novo. Nunca confie no comando `convert` no Windows — use sempre `magick` ([fonte](https://web.mit.edu/graphics/share/ImageMagick/www/windows.html)) |
| **CF2** | Todas as peças saem `FAILED_GENERATION` com `error: "render falhou"`, e o doctor dizia `ready` | Codex CLI desatualizado. O modelo padrão atual recusa CLI antigo com HTTP 400: *"The '{modelo}' model requires a newer version of Codex"*. O doctor só checa se o comando EXISTE, não a versão | 1. `npm install -g @openai/codex@latest` · 2. `codex --version` · 3. teste isolado: `codex exec --ephemeral --sandbox workspace-write --skip-git-repo-check --cd . -o t.png.last` com o prompt "Generate ONE advertising image using the image_gen tool, then save the PNG to t.png" · 4. só depois rode o lote de novo ([fonte](https://community.openai.com/t/codex-requires-newer-version/1387174)) |
| **CF3** | `UnicodeEncodeError: 'charmap' codec can't encode character '\xe3'` ao salvar o manifest (Windows) | O Python no Windows usa a codificação do sistema (cp1250/cp1252) e engasga no primeiro acento — e ainda grava um `manifest.json` corrompido | 1. rode SEMPRE com `PYTHONUTF8=1` na frente · 2. o lote anterior ficou corrompido: veja CF4 antes de repetir |
| **CF4** | `ValueError: manifesto anterior invalido; nao e seguro retomar o lote` | Um `manifest.json` corrompido (normalmente pelo CF3) ficou na pasta, e a fábrica se recusa a retomar em cima de estado duvidoso — comportamento CORRETO, não bug | 1. mova a pasta da campanha para `_archive/{data}-{nome}/` (mover, não apagar) · 2. rode o lote do zero com `PYTHONUTF8=1` |
| **CF5** | O criativo saiu com um visual que você não pediu; o log traz `mechanism legado '...' nao existe no catalogo; usando 'before_after'` | O `mechanism` do seu `campaign.yaml` é texto livre, não um ID do catálogo | 1. abra `.claude/skills/ads-creative-factory/data/hooks-library.yaml` · 2. troque pelo `id` que descreve o VISUAL que você quer (ver lista no Passo 3) · 3. gere de novo |
| **CF6** | `FLAGGED_REVIEW` com `slop` alto e `brand` baixo | A própria fábrica reprovou a peça: ficou com cara de IA e/ou fora da sua identidade | 1. **não suba essa peça** · 2. troque o `mechanism` por um mais concreto (`benchmark_proof`, `before_after`) — metáfora abstrata puxa slop pra cima · 3. confira se o `DESIGN.md` tem paleta de verdade (cor genérica → `brand` baixo) · 4. gere de novo: a fábrica sorteia arquétipo, então a segunda rodada não repete a primeira |
| **CF7** | "Posso usar minha OPENAI_API_KEY em vez da assinatura?" / erro de autenticação | Não dá, por decisão de código: `alib.py` REMOVE `OPENAI_API_KEY`, `CODEX_API_KEY` e `ANTHROPIC_API_KEY` do ambiente antes de chamar o Codex | Ou você tem assinatura ChatGPT com Codex logado, ou usa o caminho grátis ([guia-criativos.md](guia-criativos.md)). Não existe meio-termo — e não adianta exportar a chave |
| **CF8** | Quero rosto de pessoa real no criativo | `person_authority` e os presets UGC exigem `persona_pack` explícito, com foto real e autorização | 1. monte com `build_persona_pack.py` · 2. **rosto de pessoa NUNCA é gerado por IA** no método: entra só como edição de foto real, com autorização de quem aparece |

## Os dois caminhos, lado a lado (escolha com critério)

| | `/criativos-funil` (grátis) | `ads-creative-factory` (pago) |
|---|---|---|
| Motor | Chrome/Edge headless, HTML→PNG | GPT Image via Codex CLI |
| Custo | zero | assinatura ChatGPT |
| O que sai | banner de texto na sua identidade | imagem gerada, 8 arquétipos visuais |
| Controle de qualidade | seu olho (gate de 6 critérios) | gate automático + seu olho |
| Quando usar | sempre; é o padrão do cohort | quando o banner de texto já não diferencia |

Regra honesta: **criativo bom é hook bom**. A fábrica melhora a IMAGEM, não a mensagem. Hook fraco com imagem cara continua sendo hook fraco — e o gate não conserta isso.

## Regras de ouro (valem igual aos dois caminhos)

1. **Inspiração ≠ cópia**: do concorrente você extrai a ESTRUTURA e reescreve na sua voz.
2. **Rosto de pessoa nunca é gerado por IA** — só edição de foto real, com autorização.
3. **Logo não entra na geração** — é aplicado depois, na composição.
4. **Sem promessa de renda com cifra, sem antes/depois em saúde, sem depoimento inventado.**
5. **Nunca AFIRME uma característica da pessoa** ("você que está endividado") — a Meta reprova por atributo pessoal. Pergunte: "por acaso você...?".

## Pronto. Próximos passos

| Agora | O quê |
|---|---|
| ▶️ Fazer | separe só as peças `verdict=pass` de `final/{formato}/` — com `brand` ≥ 80 e `slop` ≤ 20 |
| 📖 Ler | **[guia-campanha-no-ar.md](guia-campanha-no-ar.md)** (zelador → estruturador → Gerenciador) |
| 🚑 Se travar | o catálogo CF1–CF8 acima — e, se o problema for de ambiente (Python, PATH, Codex), o [guia-codex](../01-pre-requisitos/guia-codex.md) |
