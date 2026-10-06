# Wire repos to Terraform Cloud (personal account)

This matches the **two-repo** layout (like Upwork EKS module + `terraform-rancher-clusters-usw2`):

| GitHub repo | Role on Terraform Cloud |
|-------------|-------------------------|
| [ShokryPlatForge/terraform-azurerm-aks](https://github.com/ShokryPlatForge/terraform-azurerm-aks) | **Private module registry** (reusable module) |
| [ShokryPlatForge/terraform-azure-aks-clusters-project](https://github.com/ShokryPlatForge/terraform-azure-aks-clusters-project) | **VCS workspace** (runs `dev/` and applies Azure) |

Terraform Cloud runs in HashiCorp’s cloud. It does **not** use `az login` on your Mac. You must give it Azure credentials (service principal or OIDC).

---

## Part A — One-time HCP / Terraform Cloud setup

1. Sign in: [https://app.terraform.io](https://app.terraform.io)
2. Organization for this lab: **`PlatformForge`** (must match `dev/remote_backend.tf`).
3. **Connect GitHub (VCS)**  
   - **Settings** → **Providers** (or **Version control**) → **Connect GitHub**  
   - Authorize **ShokryPlatForge** (or all repos you need).  
   - Both repos must be visible to the VCS connection.

---

## Part B — Module repo → Private module registry

1. **Registry** → **Modules** → **Publish** → **Module**
2. **Version control provider:** GitHub → org **ShokryPlatForge**
3. **Repository:** `terraform-azurerm-aks`
4. Confirm the module root is the **repository root** (where `versions.tf` / `main.tf` live).
5. Publish a version from tag **`v1.1.0`** (or push a new tag and publish that).

When publishing, set the registry name to **`aks`** / provider **`azurerm`** so it matches `dev/clusters.tf`:

```hcl
source  = "app.terraform.io/PlatformForge/aks/azurerm"
version = "1.1.0"
```

If the UI shows a different name, either republish with module name `aks` or change `clusters.tf` to match the UI string exactly.

Optional: enable **Automatic speculative plans** for the module repo later; not required for learning.

---

## Part C — Project repo → Workspace for `dev/`

### C1. Create the workspace

1. **Projects** → (create e.g. **aks-labs** if you want) → **New workspace**
2. **Workflow:** **Version control workflow**
3. **Repository:** `terraform-azure-aks-clusters-project`
4. **Advanced options:**
   - **Terraform Working Directory:** `dev`  
     (Same idea as one TFE workspace per folder in `terraform-rancher-clusters-usw2`.)
   - **Terraform version:** `1.13.x` or newer (match `.terraform-version` if present)
5. Name the workspace e.g. **`aks-clusters-dev-weu`**

### C2. State and module source (already in repo)

**`dev/remote_backend.tf`** uses Terraform Cloud:

- Organization: **`PlatformForge`**
- Workspace: **`aks-clusters-dev-weu`** (create this name in TFC, or change the file to match your workspace)

**`dev/clusters.tf`** consumes the private registry module:

```hcl
module "aks" {
  source  = "app.terraform.io/PlatformForge/aks/azurerm"
  version = "1.1.0"
  # ...
}
```

Push **`main`** on the project repo after Part B publishes **`v1.1.0`**, then trigger a run.

**Local-only fallback:** `dev/remote_backend.tf.local.example` and `dev/clusters.tf.local.example` (Azure backend + sibling module path).

### C3. Local `terraform plan` against the registry

On your Mac:

```bash
terraform login
cd dev
terraform init
terraform plan
```

`terraform login` stores a token for `app.terraform.io` so init can download `aks/azurerm`.

### C4. Azure credentials for runs (required)

Create an **Azure service principal** (or use one you already have) with **Contributor** + ability to create role assignments (often **User Access Administrator** on the subscription, or **Owner** on a lab subscription).

In the workspace: **Variables** → **Workspace variables**

| Variable | Sensitive | Value |
|----------|-----------|--------|
| `ARM_SUBSCRIPTION_ID` | no | your subscription GUID |
| `ARM_TENANT_ID` | no | Entra tenant ID |
| `ARM_CLIENT_ID` | no | app (client) ID of the SP |
| `ARM_CLIENT_SECRET` | **yes** | SP secret |

Do **not** set `ARM_USE_CLI` or rely on `az login` in the workspace.

Optional (same as local): add **`TF_VAR_...`** only if you move secrets out of `terraform.tfvars`; for dev, committing non-secret `terraform.tfvars` is fine.

### C5. Trigger runs

- **Actions** → **Start new run** → **Plan** (first time: review only)
- Or push to **`main`** with **Settings → Version Control → Automatic speculative plans** enabled

Apply from the UI when the plan looks correct (~11 resources for default dev).

---

## Part D — Bootstrap workspace (optional)

`bootstrap/` creates Azure Storage for **local** `azurerm` backend. If **all** environments use TFC `cloud` backend, you can run bootstrap once from your laptop with local state, or add a **second workspace**:

| Workspace | Working directory | State |
|-----------|-------------------|--------|
| `aks-tfstate-bootstrap` | `bootstrap` | Local or its own TFC workspace |

Most learners using only TFC for `dev/` can **skip bootstrap** entirely.

---

## Part E — Adding another environment (staging, prod)

Same pattern as `terraform-rancher-clusters-usw2`:

1. Copy `dev/` → `staging/` in the project repo
2. Change `terraform.tfvars` and the **`cloud` workspace name** (or state `key` if still on Azure backend)
3. Create a **new TFC workspace** with working directory **`staging`**
4. Push → plan → apply

One workspace per folder; never share the same workspace name or state key between environments.

---

## Checklist

- [ ] GitHub connected to TFC  
- [ ] Module published; source string copied  
- [ ] Project workspace created, working directory **`dev`**  
- [ ] `dev/remote_backend.tf` uses **`cloud`** block (or conscious choice to keep Azure backend)  
- [ ] `dev/clusters.tf` uses **registry or git** module source, not `../../`  
- [ ] `ARM_*` variables set on workspace  
- [ ] First plan succeeds; apply creates AKS  

---

## Troubleshooting

| Issue | Cause / fix |
|-------|-------------|
| Module not found | Wrong registry path or git URL; private repo not linked to VCS |
| Error loading module | Tag `v1.1.0` missing on module repo |
| Authorization failed (Azure) | SP missing roles or wrong `ARM_*` |
| Workspace uses wrong directory | Set **Terraform Working Directory** to `dev` |
| Still uses old backend | Push `cloud` block; re-init not needed on TFC for VCS runs |

Official refs: [Terraform Cloud VCS](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/version-control), [Private registry](https://developer.hashicorp.com/terraform/cloud-docs/registry), [Azure provider auth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret).
