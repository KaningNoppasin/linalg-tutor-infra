# linalg-tutor-infra

Infrastructure as code for a **hybrid-cloud RAG tutor** for linear algebra (Gilbert Strang's MIT 18.06):
a public edge on **Azure**, connected over a least-privilege **Tailscale/WireGuard** tunnel to an on-prem
**Proxmox** GPU server running vLLM + LiteLLM.

```
Internet ─HTTPS─▶ Azure VM: Traefik → CrowdSec → Authelia (OIDC + TOTP) → Open WebUI
                        ══ Tailscale (tag:edge → tag:llm-gw:4000 only) ══▶
                  Proxmox CT: LiteLLM :4000 → vLLM (Qwen, RTX 3090, loopback only)
```

| Path | What |
|---|---|
| [`cloud/azure/`](cloud/azure/) | OpenTofu: VNet, NSG (443 + Tailscale UDP only), VM with managed identity, Key Vault, backup |
| [`tailscale/policy.hujson`](tailscale/policy.hujson) | Tailnet ACL as code, with policy tests that block widening access |
| [`edge/`](edge/) | Docker Compose edge stack deployed on the Azure VM |

Highlights:
- Zero inbound ports on the home network.
- The cloud VM can reach exactly one on-prem port.
- No cloud credentials on disk: the VM uses a managed identity.
- Secrets live in Key Vault or are generated on the host. None are in git.
- checkov/tflint clean, with documented exceptions.

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
