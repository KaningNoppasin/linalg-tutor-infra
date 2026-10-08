# Azure edge — OpenTofu

Creates the cloud half of the Linear Algebra Tutor (see `../../../copy-of-tutor-setup.md` §7):

| File | Creates |
|---|---|
| `main.tf` | Resource group `rg-linalg-tutor` |
| `network.tf` | VNet `10.100.0.0/16`, subnet `snet-edge`, NSG (443/tcp + 41641/udp only), static public IP, NIC |
| `keyvault.tf` | Key Vault (RBAC) holding ONE secret: the Tailscale auth key. Roles for you (write) and the VM (read) |
| `edge.tf` | Debian 12 VM `Standard_B2s`, managed identity, encryption at host, boot diagnostics |
| `cloud-init.yaml.tftpl` | First boot: updates, Docker, Tailscale, joins the tailnet as `tag:edge` |
| `backup.tf` | Daily Azure Backup, keep 7 (`enable_backup`) |
| `budget.tf` | Optional monthly budget alert (`enable_budget`) |
| `outputs.tf` | `edge_public_ip`, `key_vault_name`, ... |

## Prerequisites (getting-started steps 1–6)
- `brew install azure-cli opentofu tflint checkov`, `az login`
- Allowed region and B2s quota checked; providers and the `EncryptionAtHost` feature registered
- State storage `rg-tfstate` / `sttfstate…` / container `tfstate` created
- DuckDNS name created; Tailscale `tagOwners` added and a **tagged, pre-approved, non-reusable** auth key for `tag:edge` generated

## First deployment

```bash
cd infra/cloud/azure
cp backend.hcl.example backend.hcl                 # fill in storage_account_name
cp terraform.tfvars.example terraform.tfvars       # fill in subscription_id
#    az account show --query id -o tsv

tofu init -backend-config=backend.hcl
tofu fmt -check && tofu validate
tflint --init && tflint
checkov -d . --quiet                               # security scan; read the findings

# Phase 1: only the Key Vault + your write permission
tofu plan  -target=azurerm_role_assignment.me_kv_secrets_officer -out=phase1.tfplan
tofu apply phase1.tfplan

# Put the Tailscale key in the vault (via CLI, so it never enters tofu state).
# RBAC can take 1–5 min to propagate; retry if you get "Forbidden".
KV=$(tofu output -raw key_vault_name)
read -rs TS_KEY && az keyvault secret set --vault-name "$KV" --name tailscale-authkey --value "$TS_KEY" -o none && unset TS_KEY

# Phase 2: everything else
tofu plan -out=phase2.tfplan                       # READ the plan: what will be created?
tofu apply phase2.tfplan
tofu output edge_public_ip
```

> `-target` is only for this first bootstrap. Normal changes later are just `tofu plan -out=x.tfplan` and `tofu apply x.tfplan`.

## After apply
1. **DuckDNS:** set `<name>.duckdns.org` to `edge_public_ip` (on duckdns.org or with
   `curl "https://www.duckdns.org/update?domains=<name>&token=<token>&ip=<edge_public_ip>"`).
2. **Tailscale:** within ~10 min the admin console should show a machine `edge` tagged `tag:edge`.
   Then admin access: `tailscale ssh azureuser@edge`.
3. If `edge` does not appear: Portal → VM → **Serial console** →
   `sudo cat /var/log/cloud-init-output.log`.
4. Then continue with the edge stack (doc §7.4) and the Tailscale ACL (doc §8).

## Checks
```bash
nmap -Pn -p 22,80,443 <edge_public_ip>   # expect: 22 filtered, 80 filtered, 443 closed/open
az network nsg rule list -g rg-linalg-tutor --nsg-name nsg-linalg-edge -o table
```

## Save credit
```bash
az vm deallocate -g rg-linalg-tutor -n vm-linalg-edge   # stops compute billing (IP + disk still billed)
az vm start      -g rg-linalg-tutor -n vm-linalg-edge
tofu destroy                                            # remove everything; `tofu apply` recreates it
```

## Rules
- After this, **don't change these resources in the Portal**. Change the code and run plan/apply.
- Never commit `terraform.tfvars`, `backend.hcl`, `*.tfplan` or state (see `infra/.gitignore`).
- Commit messages follow Conventional Commits, e.g. `feat(azure): add edge vm and nsg`.
