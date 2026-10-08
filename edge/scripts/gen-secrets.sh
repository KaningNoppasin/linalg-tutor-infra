#!/usr/bin/env bash
# Generate edge-stack secrets on the VM. Idempotent: existing values are kept.
# Run from anywhere:  sudo ./scripts/gen-secrets.sh
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077

[ -f .env ] || { echo "Create .env from .env.example first" >&2; exit 1; }
mkdir -p secrets

gen_file() { [ -s "secrets/$1" ] || openssl rand -hex 48 | tr -d '\n' > "secrets/$1"; }
gen_file jwt_secret
gen_file session_secret
gen_file storage_key
gen_file oidc_hmac

# RSA key Authelia uses to sign OIDC tokens
[ -s secrets/oidc_jwks.pem ] || openssl genrsa -out secrets/oidc_jwks.pem 2048 2>/dev/null

# OIDC client secret: plain value for Open WebUI (.env), pbkdf2 hash for Authelia
if [ ! -s secrets/oidc_client_secret ]; then
  openssl rand -hex 32 | tr -d '\n' > secrets/oidc_client_secret
  docker run --rm authelia/authelia:4.39 authelia crypto hash generate pbkdf2 --variant sha512 \
    --password "$(cat secrets/oidc_client_secret)" | sed -n 's/^Digest: //p' | tr -d '\n' > secrets/oidc_client_secret.hash
  [ -s secrets/oidc_client_secret.hash ] || { echo "hashing the OIDC client secret failed" >&2; exit 1; }
fi

set_env() { # add KEY=value to .env only if KEY is not already set
  grep -q "^$1=" .env || printf '%s=%s\n' "$1" "$2" >> .env
}
set_env CROWDSEC_BOUNCER_KEY "$(openssl rand -hex 32)"
set_env WEBUI_SECRET_KEY "$(openssl rand -hex 32)"
set_env OWUI_OIDC_SECRET "$(cat secrets/oidc_client_secret)"
chmod 600 .env

echo "secrets ready in $(pwd)/secrets and .env"
