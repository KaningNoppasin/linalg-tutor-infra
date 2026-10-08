# Edge stack — Azure VM

Traefik (TLS, rate limit) → CrowdSec (IP reputation) → Authelia (login + 2FA, OIDC) → Open WebUI → LiteLLM on CT 100 over Tailscale.
Design: `copy-of-tutor-setup.md` §7.4.

| Path | Purpose |
|---|---|
| `docker-compose.yml` | The 4 services. Only port 443 is published |
| `traefik/dynamic.yml` | Security headers, rate limit, CrowdSec bouncer, TLS ≥ 1.2 |
| `crowdsec/acquis.d/traefik.yaml` | CrowdSec reads Traefik's access log |
| `authelia/configuration.yml` | Portal, brute-force protection, OIDC client for Open WebUI |
| `authelia/users_database.yml.example` | Template for your login user |
| `scripts/gen-secrets.sh` | Generates all secrets on the VM (never committed) |
| `.env.example` | Template for `.env` on the VM |

## 0. Prerequisites
- Azure VM up, `tailscale ssh azureuser@edge` works, DuckDNS points at the VM.
- `tailscale ip -4 llm-gw` → put it in `.env` as `LLM_GW_TAILSCALE_IP`.

## 1. LiteLLM key for Open WebUI (on CT 100)
```bash
cd /root/llm-stack
set -a; . ./.env; set +a                      # loads LITELLM_MASTER_KEY into this shell only
curl -s localhost:4000/v1/models -H "Authorization: Bearer $LITELLM_MASTER_KEY" | jq -r '.data[].id'   # model names
curl -s -X POST localhost:4000/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H 'Content-Type: application/json' \
  -d '{"key_alias":"openwebui","models":["qwen3.8-27b"],"max_parallel_requests":4}' | jq -r .key
```
Keep the printed `sk-...` for step 3. (Adjust `models` to the names the first curl prints.)

## 2. Copy this folder to the VM (from your Mac, in `infra/`)
```bash
tar -czf - edge | tailscale ssh azureuser@edge 'sudo mkdir -p /opt && sudo tar -C /opt -xzf - && sudo chown -R root:root /opt/edge'
```

## 3. Configure on the VM
```bash
tailscale ssh azureuser@edge
cd /opt/edge
sudo cp .env.example .env && sudo nano .env    # ACME_EMAIL, LLM_GW_TAILSCALE_IP, OPENWEBUI_LITELLM_KEY
sudo chmod +x scripts/gen-secrets.sh && sudo ./scripts/gen-secrets.sh

# Your login user
sudo docker run --rm -it authelia/authelia:4.39 authelia crypto hash generate argon2   # type a password; copy the Digest
sudo cp authelia/users_database.yml.example authelia/users_database.yml
sudo nano authelia/users_database.yml          # paste the digest, set your email
```

## 4. Start
```bash
sudo docker compose up -d
sudo docker compose ps                          # all "running"
sudo docker compose logs -f traefik authelia    # watch for certificate + config errors, Ctrl-C to stop
```
The first certificate request happens when a host is first visited; it takes a few seconds.

## 5. First login
1. Open `https://tutor.cpre-tutor.duckdns.org` → **Continue with Authelia**.
2. Log in with the user from step 3. Authelia asks you to register a **TOTP** app (Google Authenticator, 1Password, ...).
   It sends a one-time code by "email" — with the filesystem notifier, read it on the VM:
   `sudo cat /opt/edge/authelia/notification.txt`
3. Back in Open WebUI: the first account becomes **admin**. Pick model `qwen3.8-27b` and chat.

## Checks
```bash
curl -sI https://tutor.cpre-tutor.duckdns.org | head -5          # 200/302 + strict-transport-security
curl -sI http://tutor.cpre-tutor.duckdns.org --max-time 5        # times out: port 80 closed
sudo docker compose exec crowdsec cscli bouncers list            # "traefik" bouncer, valid
sudo docker compose exec crowdsec cscli decisions list           # bans (empty is fine)
```

## Update / change
Edit files here → commit → re-run step 2 (copy) → on the VM `sudo docker compose up -d`.
Never edit on the VM only: the repo is the source of truth.
