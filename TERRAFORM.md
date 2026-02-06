# Terraform Pattern Guide V2

This document describes the Terraform patterns for managing cloud infrastructure alongside local development environments. The key insight is maintaining a **single source of truth** for configuration across all environments, while accommodating the reality that local development cannot use cloud provider APIs.

## Core Principles

### 1. Single Source of Truth

All environment configuration lives in one place: `infra/terraform/env/`. Both cloud deployments (via Terraform) and local development (via scripts) read from the same configuration files.

### 2. Separation of Concerns

- **JSON files** (`*.json`): Non-secret, environment-specific configuration (endpoints, hostnames, feature flags)
- **Terraform vars** (`*.tfvars`): Cloud infrastructure settings (SKUs, regions, capacity)
- **Secrets files** (`*.secrets.tfvars`): Sensitive values (API keys, passwords) - gitignored

### 3. Local Environment Independence

Cloud providers (Azure, AWS, GCP) require valid credentials even when no resources are created. Rather than fighting this limitation, local environments use a lightweight script that reads the same config files and generates a `.env` file.

## Directory Structure

```
project/
├── infra/
│   └── terraform/
│       ├── providers.tf          # Provider definitions & version constraints
│       ├── variables.tf          # Input variables for cloud resources
│       ├── locals.tf             # Computed values & naming conventions
│       ├── main.tf               # Resource definitions
│       ├── outputs.tf            # Output values for CI/CD
│       ├── backend.tf.example    # Template for remote state config
│       ├── scripts/
│       │   └── generate-env.py   # Generates .env from config files
│       └── env/
│           ├── local.json        # Local development config
│           ├── local.secrets.tfvars  # Local secrets (gitignored)
│           ├── dev.json          # Dev cloud config (optional)
│           ├── dev.tfvars        # Dev Terraform variables
│           ├── dev.secrets.tfvars    # Dev secrets (gitignored)
│           ├── ppe.tfvars        # Pre-production variables
│           └── prod.tfvars       # Production variables
├── switch-env                    # Convenience script for local dev
├── .env                          # Generated environment file (gitignored)
└── .gitignore
```

## Environment Types

| Environment | Method | Config Source | Output |
|-------------|--------|---------------|--------|
| **local** | `./switch-env` | `env/local.json` + `env/local.secrets.tfvars` | `.env` file |
| **dev** | `terraform apply` | `env/dev.tfvars` | Cloud resources |
| **ppe** | `terraform apply` | `env/ppe.tfvars` | Cloud resources |
| **prod** | `terraform apply` | `env/prod.tfvars` | Cloud resources |

## Configuration Files

### JSON Config (`env/{environment}.json`)

Stores non-secret configuration that may be shared between Terraform and other tools (scripts, CI/CD). For local environments, this contains service endpoints and application settings:

```json
{
  "postgres_host": "localhost",
  "postgres_port": 5432,
  "postgres_db": "myapp",
  "postgres_user": "admin",
  "api_endpoint": "https://api.example.com",
  "feature_flags": {
    "enable_cache": true
  },
  "log_level": "DEBUG"
}
```

For cloud environments, this may contain Azure/AWS account information shared with CI/CD:

```json
{
  "azure_tenant_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "azure_subscription_id": "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
}
```

### Terraform Variables (`env/{environment}.tfvars`)

Cloud-specific infrastructure settings. Not used for local environment:

```hcl
environment = "dev"
location    = "westus3"

app_service_sku = "B1"
enable_database = true
database_sku    = "B_Standard_B1ms"
```

### Secrets (`env/{environment}.secrets.tfvars`)

Sensitive values. Always gitignored. Same format used by both local scripts and Terraform:

```hcl
api_key           = "sk-..."
postgres_password = "secret123"
```

## Local Development Pattern

### The `generate-env.py` Script

A Python script that reads JSON config and secrets, then generates a `.env` file:

```python
#!/usr/bin/env python3
import json
import re
from pathlib import Path

def parse_tfvars(content: str) -> dict[str, str]:
    """Parse .tfvars file into dictionary."""
    result = {}
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        match = re.match(r'^(\w+)\s*=\s*"?([^"]*)"?\s*$', line)
        if match:
            result[match.group(1)] = match.group(2)
    return result

def main():
    env = sys.argv[1] if len(sys.argv) > 1 else "local"

    # Load config and secrets
    config = json.load(open(f"env/{env}.json"))
    secrets = parse_tfvars(open(f"env/{env}.secrets.tfvars").read())

    # Generate .env
    env_content = f"""
DATABASE_URL=postgresql://{config['postgres_user']}:{secrets['postgres_password']}@{config['postgres_host']}:{config['postgres_port']}/{config['postgres_db']}
API_KEY={secrets['api_key']}
LOG_LEVEL={config.get('log_level', 'INFO')}
"""

    Path("../../.env").write_text(env_content)
```

### The `switch-env` Script

A shell wrapper that handles Python/venv detection and provides a convenient interface:

```bash
#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="${1:-local}"

# Find Python - prefer uv, fall back to venv or system
find_python() {
    if command -v uv &> /dev/null; then
        echo "uv run python"
    elif [[ -f "$SCRIPT_DIR/.venv/bin/python" ]]; then
        echo "$SCRIPT_DIR/.venv/bin/python"
    else
        echo "python3"
    fi
}

PYTHON=$(find_python)
$PYTHON "$SCRIPT_DIR/infra/terraform/scripts/generate-env.py" "$ENV"

# Activate venv if being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    if [[ -f "$SCRIPT_DIR/.venv/bin/activate" ]]; then
        source "$SCRIPT_DIR/.venv/bin/activate"
    fi
fi
```

Usage:
```bash
./switch-env              # Generate .env for local
./switch-env local        # Same as above
source switch-env         # Generate .env and activate venv
```

## Cloud Deployment Pattern

### Terraform Usage

```bash
cd infra/terraform

# Development
terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars

# With secrets (local state)
terraform apply -var-file=env/dev.tfvars -var-file=env/dev.secrets.tfvars

# Production
terraform apply -var-file=env/prod.tfvars
```

### Reading JSON Config in Terraform

```hcl
# locals.tf
locals {
  config = jsondecode(file("${path.module}/env/${var.environment}.json"))
}

# Use in resources
resource "azurerm_linux_web_app" "main" {
  app_settings = {
    API_ENDPOINT = local.config.api_endpoint
  }
}
```

### Conditional Resources

Use `count` with boolean variables to make resources optional per environment:

```hcl
variable "enable_database" {
  type    = bool
  default = false
}

resource "azurerm_postgresql_flexible_server" "main" {
  count = var.enable_database ? 1 : 0
  # ...
}

output "database_host" {
  value = var.enable_database ? azurerm_postgresql_flexible_server.main[0].fqdn : null
}
```

## Secrets Management

### Pattern 1: Secrets Files (Development)

```bash
# Create gitignored secrets file
cat > env/dev.secrets.tfvars << 'EOF'
api_key = "sk-..."
db_password = "secret"
EOF

# Apply with secrets
terraform apply -var-file=env/dev.tfvars -var-file=env/dev.secrets.tfvars
```

### Pattern 2: Environment Variables (CI/CD)

```bash
export TF_VAR_api_key="sk-..."
export TF_VAR_db_password="secret"
terraform apply -var-file=env/prod.tfvars
```

### Pattern 3: Cloud Secret Store (Runtime)

For cloud deployments, use managed identity + Key Vault/Secrets Manager:

```hcl
resource "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  value        = var.api_key
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_linux_web_app" "main" {
  app_settings = {
    API_KEY = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.api_key.id})"
  }
}
```

## Gitignore Rules

```gitignore
# Environment files
.env
.env.*

# Terraform
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
*.tfplan
*.secrets.tfvars
backend.tf
```

## Adding a New Environment Variable

1. **Add to JSON config** (`env/local.json` and other environments):
   ```json
   {
     "new_service_url": "https://service.example.com"
   }
   ```

2. **Update generate-env.py** to include it:
   ```python
   NEW_SERVICE_URL={config.get('new_service_url', '')}
   ```

3. **For cloud environments**, add to Terraform app settings:
   ```hcl
   app_settings = {
     NEW_SERVICE_URL = local.config.new_service_url
   }
   ```

4. **Regenerate local .env**:
   ```bash
   ./switch-env
   ```

## Why This Pattern?

### Problem: Cloud Providers Require Credentials

Terraform's cloud providers (azurerm, aws, google) validate credentials at initialization, even when no resources use the provider. This makes it impossible to have a single Terraform configuration that works for both local (no cloud) and cloud environments.

### Solution: Dual Execution Paths

- **Cloud environments**: Full Terraform with provider authentication
- **Local environment**: Lightweight script that reads the same config files

### Benefits

1. **Single source of truth**: All config in `env/` directory
2. **No credential issues**: Local dev doesn't touch cloud APIs
3. **Consistent format**: Same JSON/tfvars files everywhere
4. **Fast local iteration**: No Terraform init/plan cycle for local changes
5. **Clear separation**: Infrastructure code vs application config

## State Bootstrap Pattern (Local-Then-Migrate)

When provisioning a new environment from scratch, Terraform faces a chicken-and-egg problem: the Azure Storage Account that will hold remote state doesn't exist yet, so you can't configure a remote backend. The solution is a two-step bootstrap:

### Step 1: Provision with Local State

Run Terraform **without** `backend.tf` so state is stored locally in `terraform.tfstate`. This creates all resources including the storage account and `tfstate` container that will eventually hold the remote state:

```bash
cd infra/terraform

# No backend.tf exists yet — state stays local
terraform init
terraform apply -var-file=env/ppe.tfvars -var-file=env/ppe.secrets.tfvars

# Note the outputs:
# storage_account_name = "todoosystppe"
# tfstate_container_name = "tfstate"
```

The key resources created during this step (`main.tf`):

```hcl
resource "azurerm_storage_account" "main" {
  count = var.create_storage_account ? 1 : 0
  name  = local.names.storage_account
  # ...
}

resource "azurerm_storage_container" "tfstate" {
  count              = var.create_storage_account ? 1 : 0
  name               = "tfstate"
  storage_account_id = azurerm_storage_account.main[0].id
  # ...
}
```

### Step 2: Migrate State to Azure Storage

Now that the storage account exists, create `backend.tf` from the template and run `terraform init` to migrate:

```bash
cp backend.tf.example backend.tf
# Edit backend.tf with values from Step 1 outputs:
#   resource_group_name  = "todoosy-rg-ppe"
#   storage_account_name = "todoosystppe"
#   container_name       = "tfstate"
#   key                  = "ppe.tfstate"

terraform init
# Terraform detects the backend change and prompts:
#   "Do you want to copy existing state to the new backend?"
# Answer "yes" to migrate local state into Azure Storage.
```

After migration, the local `terraform.tfstate` becomes a stub pointing to the remote backend. All subsequent `terraform plan/apply` operations read and write state from Azure Storage.

### Why This Pattern?

- **Self-contained**: Terraform creates its own state infrastructure — no manual Azure CLI prerequisites required.
- **Idempotent**: If the storage account already exists (e.g., created by a teammate), you can skip Step 1 and go straight to creating `backend.tf`.
- **Safe**: The migration prompt gives you a chance to verify before state moves. The storage account has `versioning_enabled = true` for rollback safety.

### Alternative: Manual Bootstrap

Instead of the two-step Terraform approach, you can create the storage account manually first:

```bash
az group create --name todoosy-rg-ppe --location westus3
az storage account create --name todoosystppe --resource-group todoosy-rg-ppe \
  --sku Standard_LRS --min-tls-version TLS1_2
az storage container create --name tfstate --account-name todoosystppe
```

Then start directly with `backend.tf` in place — no migration needed since there's no prior local state.

## Migration from V1

If using the original pattern with `locals.tf` reading JSON for cloud config:

1. Keep JSON files for any config shared between Terraform and scripts
2. Add `scripts/generate-env.py` for local environment
3. Add `switch-env` wrapper script
4. Remove any `environment = "local"` handling from Terraform
5. Update gitignore for `*.secrets.tfvars`
