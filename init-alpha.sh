# #!/usr/bin/env bash
# init-alpha.sh — SynapseShade MASTER (Modo automático, unificado)
# Cria/atualiza todo o projeto em /storage/emulated/0/Documents/AlphaOne/SynapseShade
# Autor: Gerado para Bruno Maia / AlphaOne Labs
# Versão: 1.0 (unified)
set -euo pipefail
IFS=$'\n\t'

##### ---------- CONFIGURAÇÕES (edite via env antes de rodar) ----------
# Caminho do projeto (padrão solicitado)
PROJECT_ROOT="${PROJECT_ROOT:-/storage/emulated/0/Documents/AlphaOne}"
PROJECT_NAME="${PROJECT_NAME:-SynapseShade}"
PROJECT_DIR="$PROJECT_ROOT/$PROJECT_NAME"

# Integrações (exportar como variáveis de ambiente 
# ANTES de rodar em modo --silent) Exemplo: export 
# GITHUB_REPO="owner/repo" export 
# GITHUB_TOKEN="ghp_xxx..." export 
# ENCRYPT_PASSWORD="SuaSenhaForte" export 
# FIREBASE_PROJECT="seu-projeto-firebase" export 
# FIREBASE_API_KEY="AIza..." export 
# GDRIVE_REMOTE="gdrive-synapseshade" export 
# WEBHOOK_URL="https://webhook.site/..."
GITHUB_REPO="${GITHUB_REPO:-}" 
GITHUB_TOKEN="${GITHUB_TOKEN:-}" 
ENCRYPT_PASSWORD="${ENCRYPT_PASSWORD:-}" 
FIREBASE_PROJECT="${FIREBASE_PROJECT:-}" 
FIREBASE_API_KEY="${FIREBASE_API_KEY:-}" 
GDRIVE_REMOTE="${GDRIVE_REMOTE:-}" 
WEBHOOK_URL="${WEBHOOK_URL:-}"
# Segurança
SEED="${SEED:-S3cr3tS33m2025SynapcMasterKey}" 
MASTER_FALLBACK="${MASTER_FALLBACK:-MASTERPASS}"
# Flags/CLI
SILENT=false for a in "$@"; do case "$a" in --silent) 
    SILENT=true ;; --force) FORCE=true ;;
  esac done
# Internals
TMP_DIR="$PROJECT_DIR/tmp" 
SCRIPTS_DIR="$PROJECT_DIR/scripts" 
PHASES_DIR="$PROJECT_DIR/phases" 
WEB_DIR="$PROJECT_DIR/web" 
BUILD_DIR="$PROJECT_DIR/builds" 
LOG_DIR="$PROJECT_DIR/.logs" 
HASH_FILE="$PROJECT_DIR/hashes.txt" 
WRAPPER="$HOME/RunSynapseShade.sh" mkdir -p 
"$PROJECT_DIR" "$TMP_DIR" "$SCRIPTS_DIR" "$PHASES_DIR" 
"$WEB_DIR" "$BUILD_DIR" "$LOG_DIR" 
LOG_FILE="$LOG_DIR/master.log" touch "$LOG_FILE"
# Logging
_log(){ printf '%s [INFO] %s\n' "$(date -u +'%Y-%m-%d 
%H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }
_warn(){ printf '%s [WARN] %s\n' "$(date -u +'%Y-%m-%d 
%H:%M:%S')" "$1" | tee -a "$LOG_FILE"; }
_err(){ printf '%s [ERROR] %s\n' "$(date -u +'%Y-%m-%d 
%H:%M:%S')" "$1" | tee -a "$LOG_FILE"; exit 1; }
compute_dynamic_pass(){ printf '%s' "$(date 
+%Y-%m-%d)$SEED" | md5sum | cut -c1-6; } 
send_webhook(){ [ -z "$WEBHOOK_URL" ] && return 0; 
curl -s -X POST "$WEBHOOK_URL" -d 
"{\"message\":\"$1\"}" >/dev/null 2>&1 || true; }
# Self path (for noexec handling)
_self_path="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null 
|| echo "${BASH_SOURCE[0]}")"
_self_dir="$(dirname "$_self_path")"
# Detecta mounts noexec: tenta criar/executar pequeno 
# binário
detect_noexec() { local 
  tmp_exec="$TMP_DIR/.exec_test_$$" mkdir -p 
  "$TMP_DIR" printf '%s\n' '#!/bin/sh' 'exit 0' > 
  "$tmp_exec" chmod +x "$tmp_exec" 2>/dev/null || true 
  if "$tmp_exec" >/dev/null 2>&1; then rm -f 
  "$tmp_exec"; return 1; else rm -f "$tmp_exec" 
  2>/dev/null || true; return 0; fi
}
ensure_executable_environment() { if detect_noexec; 
  then
    _log "Pasta parece montada com noexec. Criando 
    cópia temporária em \$HOME e executando a partir 
    dela..." local temp_home="$HOME/SynapseShadeTemp" 
    mkdir -p "$temp_home" cp -f "$_self_path" 
    "$temp_home/init-alpha.sh" chmod +x 
    "$temp_home/init-alpha.sh" || true _log 
    "Executando cópia temporária: 
    $temp_home/init-alpha.sh" exec bash 
    "$temp_home/init-alpha.sh" "$@" # substitui o 
    processo atual
  fi
}
# Instala dependências (Termux-friendly)
install_deps() { local deps=(git curl jq rsync openssl 
  unzip zip realpath sha256sum tar) local missing=() 
  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then 
    missing+=("$cmd"); fi
  done if [ ${#missing[@]} -gt 0 ]; then _warn 
    "Dependências ausentes: ${missing[*]}" if command 
    -v pkg >/dev/null 2>&1; then
      _log "Tentando instalar via pkg (Termux)..." pkg 
      update -y >/dev/null 2>&1 || _warn "pkg update 
      falhou (continuando)"
      pkg install -y "${missing[@]}" >/dev/null 2>&1 || _warn "Instalação automática falhou; instale manualmente: ${missing[*]}"
    else
      _warn "Gerenciador 'pkg' não disponível. Instale manualmente: ${missing[*]}"
    fi
  else
    _log "Todas dependências presentes."
  fi
}

# --- Criação da estrutura do projeto (React Native + Android skeleton)
create_structure() {
  _log "Criando/verificando estrutura em: $PROJECT_DIR"

  # README
  [ -f "$PROJECT_DIR/README.md" ] || cat > "$PROJECT_DIR/README.md" <<EOF
# SynapseShade
Autor: Bruno Maia / AlphaOne Labs
Local: $PROJECT_DIR
Descrição: Estação portátil para controle, atualização e deploy de apps Android via Termux + OTG.
EOF

  # package.json básico (react-native scaffold minimal)
  [ -f "$PROJECT_DIR/package.json" ] || cat > "$PROJECT_DIR/package.json" <<'JSON'
{
  "name": "synapseshade",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "android": "react-native run-android",
    "start": "react-native start",
    "build:android": "cd android && ./gradlew assembleRelease"
  }
}
JSON

  # app.json / entry
  [ -f "$PROJECT_DIR/app.json" ] || cat > "$PROJECT_DIR/app.json" <<JSON
{
  "name": "SynapseShade",
  "displayName": "SynapseShade"
}
JSON

  mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/assets" "$PROJECT_DIR/android/app/src/main/java/com/alphaone/synapseshade" || true

  # index / minimal app
  [ -f "$PROJECT_DIR/index.js" ] || cat > "$PROJECT_DIR/index.js" <<'JS'
import {AppRegistry} from 'react-native';
import App from './src/App';
import {name as appName} from './app.json';
AppRegistry.registerComponent(appName, () => App);
JS

  [ -f "$PROJECT_DIR/src/App.js" ] || cat > "$PROJECT_DIR/src/App.js" <<'JS'
import React from 'react';
import {SafeAreaView, Text} from 'react-native';
export default function App(){ return (<SafeAreaView><Text>SynapseShade</Text></SafeAreaView>); }
JS

  # Android skeleton for Android Studio to import
  mkdir -p "$PROJECT_DIR/android/app/src/main/res" "$PROJECT_DIR/android" || true
  [ -f "$PROJECT_DIR/android/settings.gradle" ] || cat > "$PROJECT_DIR/android/settings.gradle" <<GRADLE
rootProject.name = 'SynapseShade'
include ':app'
GRADLE

  [ -f "$PROJECT_DIR/android/build.gradle" ] || cat > "$PROJECT_DIR/android/build.gradle" <<GRADLE
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.0' }
}
allprojects { repositories { google(); mavenCentral() } }
GRADLE

  [ -f "$PROJECT_DIR/android/app/build.gradle" ] || cat > "$PROJECT_DIR/android/app/build.gradle" <<GRADLE
apply plugin: 'com.android.application'
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.alphaone.synapseshade"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    buildTypes {
        release { minifyEnabled false }
    }
    splits { abi { enable true; reset(); include 'armeabi-v7a','arm64-v8a','x86'; universalApk true } }
}
dependencies { implementation 'androidx.appcompat:appcompat:1.6.1' }
GRADLE

  # .gitignore
  [ -f "$PROJECT_DIR/.gitignore" ] || cat > "$PROJECT_DIR/.gitignore" <<EOF
node_modules/
android/.gradle/
android/build/
android/app/build/
*.keystore
local.properties
EOF

  # small web panel
  mkdir -p "$WEB_DIR"
  cat > "$WEB_DIR/painel.html" <<HTML
<!doctype html><html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>Painel SynapseShade</title></head><body><h1>SynapseShade</h1><p>Status: OK</p></body></html>
HTML

  _log "Estrutura inicial criada (React Native + Android skeleton)."
}

# Copia google-services.json se existir em locais comuns
copy_google_services() {
  local candidates=(
    "$PROJECT_DIR/google-services.json"
    "$PROJECT_ROOT/google-services.json"
    "$HOME/Download/google-services.json"
    "/storage/emulated/0/Download/google-services.json"
    "$PROJECT_DIR/../google-services.json"
  )
  for c in "${candidates[@]}"; do
    if [ -f "$c" ]; then
      mkdir -p "$PROJECT_DIR/android/app"
      cp -f "$c" "$PROJECT_DIR/android/app/google-services.json"
      _log "google-services.json copiado: $c -> $PROJECT_DIR/android/app/"
      return 0
    fi
  done
  _warn "google-services.json não encontrado nas localizações comuns. Coloque manualmente em $PROJECT_DIR/android/app/"
}

# Gera arquivo de hashes
generate_hashes() {
  _log "Gerando hashes SHA-256 em $HASH_FILE..."
  (cd "$PROJECT_DIR" && find . -type f -not -path "./backups/*" -not -path "./.logs/*" -not -path "./builds/*" -not -path "./tmp/*" -exec sha256sum {} \; ) > "$HASH_FILE" 2>/dev/null || true
  _log "Hashes gerados."
}

# Inicializa git local e tenta push (se env GITHUB_TOKEN/GITHUB_REPO setados)
init_and_push_git() {
  _log "Inicializando repositório Git local (se necessário)..."
  if [ ! -d "$PROJECT_DIR/.git" ]; then
    (cd "$PROJECT_DIR" && git init) || _warn "git init falhou"
  fi
  # corrige dubious ownership em Termux
  if ! git config --global --get-all safe.directory | grep -qx "$PROJECT_DIR" 2>/dev/null; then
    git config --global --add safe.directory "$PROJECT_DIR" 2>/dev/null || _warn "Não foi possível adicionar safe.directory"
    _log "safe.directory adicionado: $PROJECT_DIR"
  fi

  (cd "$PROJECT_DIR" && git add . >/dev/null 2>&1 || true; git commit -m "SynapseShade initial commit" >/dev/null 2>&1 || _warn "Commit pode ter falhado (configure git user.name/email)")

  if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPO" ]; then
    _log "Tentando push para GitHub: $GITHUB_REPO (HTTPS token auth)"
    auth_url="https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
    (cd "$PROJECT_DIR" && git remote set-url origin "$auth_url" 2>/dev/null || git remote add origin "$auth_url" 2>/dev/null || true; git push origin main --force) \
      && _log "Push para GitHub concluído." || _warn "Push para GitHub falhou (verifique token/perm)"
  else
    _warn "GITHUB_TOKEN ou GITHUB_REPO não fornecidos — pulando push."
  fi
}

# Backup criptografado opcional
encrypted_backup() {
  if [ -z "${ENCRYPT_PASSWORD:-}" ]; then _log "ENCRYPT_PASSWORD não definido — pulando backup criptografado"; return 0; fi
  _log "Criando backup criptografado..."
  mkdir -p "$PROJECT_DIR/backups"
  TS="$(date +%Y%m%d_%H%M%S)"
  TAR="$TMP_DIR/backup_$TS.tar.gz"
  (cd "$PROJECT_DIR" && tar -czf "$TAR" . --exclude='./tmp' --exclude='./.logs' --exclude='./backups' --exclude='./builds') || _warn "Falha ao criar tar"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$TAR" -out "$PROJECT_DIR/backups/backup_$TS.tar.gz.enc" -pass pass:"$ENCRYPT_PASSWORD" || _warn "Falha na criptografia do backup"
  shred -u "$TAR" 2>/dev/null || rm -f "$TAR"
  _log "Backup criado: $PROJECT_DIR/backups/backup_$TS.tar.gz.enc"
}

# Build local: tenta gradle; se falhar, gera placeholders (universal + ABIs)
build_apks() {
  _log "Iniciando processo de build (tentativa local)..."
  mkdir -p "$BUILD_DIR"
  local app_dir="$PROJECT_DIR/android"
  if [ -f "$app_dir/gradlew" ]; then
    _log "gradlew detectado. Executando ./gradlew assembleRelease..."
    (cd "$app_dir" && chmod +x ./gradlew && ./gradlew assembleRelease --no-daemon) && _log "Build local finalizada." || _warn "Build local falhou."
    apk_found="$(find "$app_dir" -type f -iname '*release*.apk' | head -n1 || true)"
    if [ -n "$apk_found" ]; then
      cp -f "$apk_found" "$BUILD_DIR/${PROJECT_NAME}-local.apk"
      echo "$BUILD_DIR/${PROJECT_NAME}-local.apk" > "$TMP_DIR/last_apk_path.txt"
      _log "APK local copiado: $BUILD_DIR/${PROJECT_NAME}-local.apk"
      return 0
    fi
  fi

  _log "Gradle não disponível ou build falhou — criando APK placeholders..."
  for abi in universal arm64-v8a armeabi-v7a; do
    ph="$BUILD_DIR/${PROJECT_NAME}-${abi}-placeholder-$(date +%s).apk"
    printf "SynapseShade placeholder APK (%s) - %s\n" "$abi" "$(date -u)" > "$TMP_DIR/placeholder.txt"
    (cd "$TMP_DIR" && zip -r "$ph" placeholder.txt >/dev/null 2>&1) || true
    rm -f "$TMP_DIR/placeholder.txt"
    _log "APK placeholder criado: $ph"
  done
  ls -t "$BUILD_DIR"/*placeholder*.apk | head -n1 > "$TMP_DIR/last_apk_path.txt" || true
}

# Dispara workflow do GitHub Actions e obtém artifact (se credenciais)
trigger_and_fetch_remote_build() {
  if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO" ]; then _warn "GITHUB creds ausentes — pulando CI remoto"; return 0; fi
  local wf_file="$(basename "${GITHUB_WORKFLOW_FILE:-.github/workflows/android-build.yml}")"
  _log "Disparando workflow $wf_file em $GITHUB_REPO"
  curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPO/actions/workflows/$wf_file/dispatches" \
    -d '{"ref":"main"}' >/dev/null 2>&1 || _warn "Dispatch possivelmente falhou"

  _log "Polling pelo run (aguardando conclusão)..."
  local attempt=0 max=240
  while [ $attempt -lt $max ]; do
    attempt=$((attempt+1)); sleep 6
    resp="$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/actions/runs?event=workflow_dispatch&per_page=5")"
    run_id="$(echo "$resp" | jq -r '.workflow_runs[0].id // empty')"
    run_status="$(echo "$resp" | jq -r '.workflow_runs[0].status // empty')"
    run_conclusion="$(echo "$resp" | jq -r '.workflow_runs[0].conclusion // empty')"
    if [ -n "$run_id" ]; then
      _log "Run $run_id - status=$run_status conclusion=$run_conclusion (try $attempt)"
      if [ "$run_status" = "completed" ]; then
        if [ "$run_conclusion" = "success" ] || [ "$run_conclusion" = "neutral" ]; then
          echo "$run_id" > "$TMP_DIR/last_run_id.txt"
          _log "Workflow finalizado com sucesso (run_id=$run_id)"
          break
        else
          _warn "Workflow terminou com conclusão: $run_conclusion"
          break
        fi
      fi
    fi
  done

  if [ -f "$TMP_DIR/last_run_id.txt" ]; then
    run_id="$(cat "$TMP_DIR/last_run_id.txt")"
    _log "Buscando artifacts do run $run_id"
    artifacts_resp="$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$GITHUB_REPO/actions/runs/$run_id/artifacts")"
    download_url="$(echo "$artifacts_resp" | jq -r '.artifacts[0].archive_download_url // empty')"
    if [ -n "$download_url" ]; then
      out_zip="$TMP_DIR/artifact_${run_id}.zip"
      curl -L -H "Authorization: Bearer $GITHUB_TOKEN" -o "$out_zip" "$download_url" || _warn "Falha no download do artifact"
      unzip -o "$out_zip" -d "$TMP_DIR/artifact_${run_id}" >/dev/null 2>&1 || true
      apk_found="$(find "$TMP_DIR/artifact_${run_id}" -type f -iname '*.apk' | head -n1 || true)"
      if [ -n "$apk_found" ]; then
        cp -f "$apk_found" "$BUILD_DIR/${PROJECT_NAME}-remote-${run_id}.apk"
        echo "$BUILD_DIR/${PROJECT_NAME}-remote-${run_id}.apk" > "$TMP_DIR/last_apk_path.txt"
        _log "APK remoto salvo: $BUILD_DIR/${PROJECT_NAME}-remote-${run_id}.apk"
      else
        _warn "Nenhum APK encontrado no artifact extraído."
      fi
      rm -f "$out_zip" || true
    else
      _warn "Nenhum artifact disponível do run."
    fi
  else
    _warn "Nenhum run_id encontrado — CI remoto pode ter falhado ou ter timeout."
  fi
}

# Cria release no GitHub e envia APK (opcional)
create_github_release() {
  if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_REPO" ]; then _warn "GITHUB creds ausentes — pulando release"; return 0; fi
  apkfile="$(cat "$TMP_DIR/last_apk_path.txt" 2>/dev/null || true)"
  [ -f "$apkfile" ] || { _warn "APK para release não encontrado"; return 0; }
  tag="v$(date +%Y%m%d%H%M%S)"
  _log "Criando release $tag"
  create_resp="$(curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$GITHUB_REPO/releases" \
    -d "{\"tag_name\":\"$tag\",\"name\":\"$PROJECT_NAME $tag\",\"body\":\"Automated release by SynapseShade\",\"draft\":false,\"prerelease\":false}")"
  upload_url="$(echo "$create_resp" | jq -r '.upload_url // empty' | sed -e 's/{?name,label}//')"
  if [ -n "$upload_url" ]; then
    fname="$(basename "$apkfile")"
    curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" -H "Content-Type: application/vnd.android.package-archive" \
      --data-binary @"$apkfile" "$upload_url?name=$fname" >/dev/null 2>&1 || _warn "Upload pode ter falhado"
    _log "Release criado e asset enviado."
    echo "https://github.com/$GITHUB_REPO/releases/tag/$tag" > "$TMP_DIR/last_release_url.txt"
  else
    _warn "Falha ao criar release (resposta: $create_resp)"
  fi
}

# Sincroniza com Google Drive via rclone (opcional)
sync_with_rclone() {
  if [ -z "$GDRIVE_REMOTE" ]; then _log "GDRIVE_REMOTE não definido — pulando rclone sync"; return 0; fi
  if ! command -v rclone >/dev/null 2>&1; then _warn "rclone não instalado — pulando rclone sync"; return 0; fi
  _log "Sincronizando Termux project -> ${GDRIVE_REMOTE}:SynapseShade_Termux"
  rclone sync "$PROJECT_DIR" "${GDRIVE_REMOTE}:SynapseShade" --progress || _warn "rclone sync falhou"
}

# Sincroniza para OTG (se houver e com permissão de escrita)
sync_to_otg() {
  _log "Tentando sincronizar para OTG/disc externo com permissão escrita..."
  for p in /storage/* /mnt/*; do
    [ -d "$p" ] || continue
    base="$(basename "$p")"
    if [[ "$base" =~ emulated|self|media_rw|c|d|e ]]; then continue; fi
    if [ -w "$p" ]; then
      dest="$p/AlphaOne"
      mkdir -p "$dest"
      _log "Sincronizando $PROJECT_DIR -> $dest/$PROJECT_NAME"
      rsync -a --delete --exclude '.logs' --exclude 'tmp' --exclude 'backups' --exclude 'builds' "$PROJECT_DIR/" "$dest/$PROJECT_NAME/" || _warn "rsync para OTG falhou"
      _log "Sincronização para OTG concluída: $dest/$PROJECT_NAME/"
      return 0
    fi
  done
  _warn "Nenhum OTG detectado com permissão de escrita."
  return 1
}

# Wrapper para executar o master a partir do home facilmente
create_wrapper() {
  cat > "$WRAPPER" <<WRAP
#!/usr/bin/env bash
bash "$PROJECT_DIR/init-alpha.sh" --silent
WRAP
  chmod +x "$WRAPPER" || true
  _log "Wrapper criado em: $WRAPPER"
}

# Autorização (dínamica ou MASTER_FALLBACK). Em modo silent tenta calcular dinamicamente se EXEC_PASS não definido.
authorize() {
  local provided="${EXEC_PASS:-}"
  if [ -z "$provided" ]; then
    if [ "$SILENT" = true ]; then
      provided="$(compute_dynamic_pass)"
      export EXEC_PASS="$provided"
      _log "EXEC_PASS calculado automaticamente (modo silent)."
    else
      read -s -rp "Senha dinâmica (ou master) para liberar execução: " provided; echo
    fi
  fi
  local dyn="$(compute_dynamic_pass)"
  if [ "$provided" != "$dyn" ] && [ "$provided" != "$MASTER_FALLBACK" ]; then
    _err "Senha inválida. dinâmica esperada: $dyn ou fallback: $MASTER_FALLBACK"
  fi
  _log "Autorização concedida."
}

# --- fluxo principal ---
main() {
  _log "=== SynapseShade MASTER START ==="
  ensure_executable_environment "$@"
  install_deps
  authorize
  create_structure
  copy_google_services
  generate_hashes
  init_and_push_git
  encrypted_backup
  build_apks
  trigger_and_fetch_remote_build
  create_github_release
  sync_with_rclone
  create_wrapper
  sync_to_otg || _warn "Sincronização OTG não realizada"
  _log "=== SynapseShade MASTER FINISHED ==="
  [ -f "$TMP_DIR/last_apk_path.txt" ] && _log "APK final: $(cat $TMP_DIR/last_apk_path.txt)"
  send_webhook "SynapseShade setup complete for $PROJECT_DIR"
}

main "$@")
