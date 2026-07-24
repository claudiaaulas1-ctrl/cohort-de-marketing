#!/bin/bash
# ===================================================================
# gerar_png.sh - Captura {prefixo}-*.html de um diretorio como PNG
#                em QUALQUER tamanho (feed, story, quadrado, display)
# ===================================================================
#
# Uso: ./gerar_png.sh caminho/para/pasta/ [largura] [altura] [prefixo]
#   largura  default: 1080
#   altura   default: 1350   (feed 4:5)
#   prefixo  default: slide  (captura {prefixo}-*.html)
#
# Exemplos:
#   ./gerar_png.sh criativos/banners 1080 1350 feed    # feed 4:5
#   ./gerar_png.sh criativos/banners 1080 1920 story   # stories/reels 9:16
#   ./gerar_png.sh carrossel                            # compativel com o padrao slide-*.html 1080x1350
#
# Rode UM passe por formato: o tamanho da janela precisa bater com o
# width/height fixado no html,body de cada arquivo (senao corta/sobra).
# ===================================================================

set -e

DIR="${1:-}"
W="${2:-1080}"
H="${3:-1350}"
PREFIX="${4:-slide}"

if [ -z "$DIR" ]; then
  echo "Uso: $0 caminho/para/pasta/ [largura] [altura] [prefixo]"
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "ERRO: diretorio nao encontrado: $DIR"
  exit 1
fi

DIR_ABS="$(cd "$DIR" && pwd)"

# ---------- Detecta o Chrome ----------
CHROME=""
for cmd in google-chrome google-chrome-stable chromium chromium-browser "Google Chrome"; do
  if command -v "$cmd" &> /dev/null; then
    CHROME="$cmd"
    break
  fi
done

if [ -z "$CHROME" ] && [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

# Windows (Git Bash): caminhos padrao do Chrome e do Edge (o Edge ja vem no Windows)
if [ -z "$CHROME" ]; then
  for p in \
    "/c/Program Files/Google/Chrome/Application/chrome.exe" \
    "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
    "$LOCALAPPDATA/Google/Chrome/Application/chrome.exe" \
    "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" \
    "/c/Program Files/Microsoft/Edge/Application/msedge.exe"; do
    if [ -f "$p" ]; then
      CHROME="$p"
      break
    fi
  done
fi

if [ -z "$CHROME" ]; then
  echo "Nenhum Chrome/Chromium encontrado automaticamente."
  echo ""
  echo "Para gerar os PNGs, instale o Chrome:"
  echo "  macOS:   brew install --cask google-chrome"
  echo "  Windows: winget install Google.Chrome"
  echo ""
  echo "Ou abra cada ${PREFIX}-*.html no navegador e capture manualmente em ${W}x${H}."
  exit 1
fi

echo "Chrome:  $CHROME"
echo "Pasta:   $DIR_ABS"
echo "Tamanho: ${W}x${H} · prefixo: ${PREFIX}-*"
echo ""

# ---------- Captura cada {prefixo}-*.html ----------
shopt -s nullglob
ARQUIVOS=("$DIR_ABS"/${PREFIX}-*.html)

if [ ${#ARQUIVOS[@]} -eq 0 ]; then
  echo "ERRO: nenhum ${PREFIX}-*.html encontrado em $DIR_ABS"
  exit 1
fi

# Perfil temporario proprio: sem ele, com um Chrome/Edge ja aberto a captura
# retorna sem gerar arquivo (da 2a peca do lote em diante) e falha em silencio.
PROFILE_DIR="$(mktemp -d)"
# O Edge segura o lockfile do perfil por alguns instantes depois de sair; o || true
# evita que a limpeza derrube o script (set -e) depois dos PNGs ja terem saido.
trap 'rm -rf "$PROFILE_DIR" 2>/dev/null || true' EXIT
PROFILE_ARG="$(cygpath -m "$PROFILE_DIR" 2>/dev/null || echo "$PROFILE_DIR")"

# --default-background-color (fundo transparente) e flag de Chrome: no Edge ela
# ABORTA a captura e nenhum PNG e escrito. Banner de ad tem fundo opaco, entao
# fora do Chrome simplesmente nao usamos a flag.
BG_FLAG=()
case "$CHROME" in
  *msedge*|*Edge*) ;;
  *) BG_FLAG=(--default-background-color=00000000) ;;
esac

COUNT=0
for HTML in "${ARQUIVOS[@]}"; do
  BASENAME="$(basename "$HTML" .html)"
  OUT="$DIR_ABS/$BASENAME.png"
  echo "[$((COUNT+1))/${#ARQUIVOS[@]}] $BASENAME.html -> $BASENAME.png"
  # No Windows o navegador exige C:/... tanto na URL de ENTRADA quanto no caminho
  # de SAIDA do --screenshot; cygpath -m converte os dois. Fora do Git Bash cai no
  # caminho normal. Sem converter a saida, o navegador nao escreve o PNG.
  HTML_URL="file://$(cygpath -m "$HTML" 2>/dev/null || echo "$HTML")"
  OUT_ARG="$(cygpath -m "$OUT" 2>/dev/null || echo "$OUT")"
  # 2 tentativas: rodando um formato logo apos o outro, o navegador anterior ainda
  # esta encerrando e a 1a captura volta sem escrever o arquivo. 1 retry resolve.
  for TENTATIVA in 1 2; do
    ERRO="$("$CHROME" \
      --headless \
      --disable-gpu \
      --no-sandbox \
      --hide-scrollbars \
      "${BG_FLAG[@]}" \
      --force-device-scale-factor=1 \
      --user-data-dir="$PROFILE_ARG" \
      --window-size=${W},${H} \
      --screenshot="$OUT_ARG" \
      "$HTML_URL" 2>&1)" || true
    [ -f "$OUT" ] && break
    [ "$TENTATIVA" = "1" ] && sleep 2
  done
  if [ -f "$OUT" ]; then
    COUNT=$((COUNT+1))
  else
    echo "  ! falhou: $BASENAME"
    # Nunca engolir o motivo: sem isto o aluno so ve "falhou" e nao tem o que pesquisar.
    [ -n "$ERRO" ] && echo "$ERRO" | tail -3 | sed 's/^/    /'
  fi
done

echo ""
echo "PNGs gerados: $COUNT de ${#ARQUIVOS[@]} (${W}x${H})"
