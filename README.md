# terraform-azure-aks-clusters-project

Terraform project that deploys AKS clusters in **West Europe**. **`dev/`** calls the module from **Terraform Cloud**:

`app.terraform.io/PlatformForge/aks/azurerm` **1.1.0**

State and runs use org **PlatformForge**, workspace **`aks-clusters-dev-weu`**. See [docs/terraform-cloud.md](docs/terraform-cloud.md).

```text
AKS_project/
├── terraform-azurerm-aks/           ← the module (like terraform-aws-upwork-eks-clusters)
└── terraform-azure-aks-clusters-weu/     ← this repo (like terraform-rancher-clusters-usw2)
    ├── bootstrap/          one-time: storage account that holds Terraform state
    ├── backend.hcl         generated from bootstrap; shared by all environments (gitignored)
    └── dev/                one environment = one folder = one state file
        ├── remote_backend.tf   Terraform Cloud (PlatformForge / aks-clusters-dev-weu)
        ├── provider.tf
        ├── variables.tf
        ├── terraform.tfvars    ← everything that differs between environments
        ├── locals.tf           naming and tags
        ├── common.tf           resource group
        ├── network.tf          VNet + one subnet per cluster
        ├── clusters.tf         module "aks" (one instance per entry in `clusters`)
        ├── outputs.tf
        └── tests/plan.tftest.hcl   offline plan test of this environment
```

| `terraform-rancher-clusters-usw2` | This repo |
|---|---|
| Terraform Enterprise workspace per folder | Terraform Cloud workspace per folder (`cloud` block in `remote_backend.tf`) |
| Workspace variables in TFE | `terraform.tfvars` in the folder |
| `remote_state_network.tf` (VPC from another workspace) | `network.tf` (the environment owns its VNet for now) |
| `cluster-<name>.tf`, one module block per cluster | `clusters.tf`, one module instance per entry in `clusters` |
| `locals.tf` with `_clusters_base` | `terraform.tfvars` → `clusters` map |
| `.terraform-version` | same |

---

## 1. Install the tools (macOS, once)

```bash
brew install azure-cli
brew install Azure/kubelogin/kubelogin
brew tap hashicorp/tap && brew install hashicorp/tap/terraform
brew install kubectl        # skip if you already have kubectl
```

Check: `az version`, `terraform version` (must be ≥ 1.9), `kubelogin --version`, `kubectl version --client`.

`kubelogin` is required: the clusters accept Entra ID logins only, and kubectl uses kubelogin to get the token.

## 2. Prepare your Azure account (once)

1. Sign in at <https://portal.azure.com> and make sure you have a subscription (a free account or pay-as-you-go). You need **Owner** on it, which you have by default on a personal subscription. Contributor is not enough, because the module creates role assignments.
2. Log in from the terminal and select the subscription:

   ```bash
   az login
   az account list -o table
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```

3. Register the resource providers this project uses (takes a few minutes the first time):

   ```bash
   for ns in Microsoft.ContainerService Microsoft.Network Microsoft.Compute Microsoft.Storage \
             Microsoft.ManagedIdentity Microsoft.OperationalInsights Microsoft.Insights; do
     az provider register --namespace "$ns" --wait
   done
   ```

4. Check that you have vCPU quota for the node size (one `Standard_B2s` node plus one temporary node during upgrades = 4 vCPUs):

   ```bash
   az vm list-usage --location westeurope -o table | grep -Ei "total regional|standard bs"
   ```

   If quota is 0, or `Standard_B2s` is not offered in your region, change `system_vm_size` in `dev/terraform.tfvars` (for example to `Standard_D2s_v5`) or request quota in the portal (**Quotas** → **Compute**).

## 3. Every new terminal session

```bash
az login                                   # if your token expired
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
az account show --query "{name:name, id:id}" -o table   # confirm it is the right subscription
```

Terraform reads the subscription from `ARM_SUBSCRIPTION_ID` and your credentials from `az login`, so nothing secret is stored in the repo.

## 4. Create the state storage (once per subscription)

```bash
cd bootstrap
terraform init
terraform apply                             # review, then type yes
terraform output -raw backend_hcl > ../backend.hcl
cd ..
```

This creates the resource group `rg-tfstate` with a storage account named `tfstate<12 characters of your subscription ID>`. The account has versioning, 14 days of soft delete, and a delete lock, so a bad apply can't lose your state. It costs cents per month. The bootstrap's own state stays on your laptop in `bootstrap/terraform.tfstate`; keep that file (it is gitignored).

## 5. Deploy the dev environment

```bash
cd dev
terraform init -backend-config=../backend.hcl
terraform test                              # offline check of terraform.tfvars, ~5 s
terraform plan -out=tfplan                  # read it: 11 to add, 0 to change, 0 to destroy
terraform apply tfplan                      # 10-15 minutes
```

Always apply a saved plan (`-out=tfplan`, then `apply tfplan`). Terraform then does exactly what you reviewed and nothing else.

## 6. Connect with kubectl

```bash
terraform output clusters                   # names and the get-credentials command
az aks get-credentials --resource-group rg-aks-dev-weu --name aks-dev-01-weu --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
```

If kubectl says **Forbidden** right after the first apply, wait 2–5 minutes: Azure RBAC role assignments take a while to propagate.

Smoke test with a public app:

```bash
kubectl create deployment hello --image=nginx:alpine
kubectl expose deployment hello --port=80 --type=LoadBalancer
kubectl get service hello --watch           # wait for EXTERNAL-IP, then open it in a browser
kubectl delete service hello && kubectl delete deployment hello
```

Delete LoadBalancer services before destroying the cluster, so Azure releases their public IPs cleanly.

## 7. Stop paying when you are done

```bash
cd dev
terraform plan -destroy -out=tfplan && terraform apply tfplan
```

This removes the cluster, its node resource group, the VNet and the environment's resource group. The state storage from step 4 stays; it is cheap, and you need it for the next `apply`.

To remove the bootstrap too: delete the lock (`az lock delete --name protect-terraform-state --resource-group rg-tfstate --resource-type Microsoft.Storage/storageAccounts --resource "$(terraform -chdir=bootstrap output -raw storage_account_name)"`), then run `terraform destroy` in `bootstrap/`.

---

## Add a new environment

Example: `staging`.

```bash
cp -R dev staging
rm -rf staging/.terraform staging/.terraform.lock.hcl staging/tfplan
```

Then edit two files in `staging/`:

1. `remote_backend.tf`: change `key` to `"aks-clusters-weu/staging.tfstate"`. **This step is essential**: if two folders share a key, they overwrite each other's state.
2. `terraform.tfvars`: set `environment = "staging"`, a VNet range that doesn't overlap other environments (`10.20.0.0/16`), and cluster subnets inside it (`10.20.0.0/22`).

Deploy it the same way:

```bash
cd staging
terraform init -backend-config=../backend.hcl
terraform test
terraform plan -out=tfplan && terraform apply tfplan
```

Suggested ranges: dev `10.10.0.0/16`, staging `10.20.0.0/16`, prod `10.30.0.0/16`.

## Add a cluster to an environment

Add an entry to `clusters` in that environment's `terraform.tfvars`, with its own subnet:

```hcl
clusters = {
  "01" = { subnet_cidr = "10.10.0.0/22" }
  "02" = { subnet_cidr = "10.10.4.0/22", system_vm_size = "Standard_D2s_v5" }
}
```

Removing an entry destroys that cluster. The plan shows it clearly; read it before applying.

## Turn on more features

Each entry in `clusters` exposes the most useful module inputs (`aks_cluster_version`, `sku_tier`, `node_pools_config`, `admins`, `read_only`, `ns_admins`, `enable_node_auto_provisioning`, `control_plane_logs_enabled`, `api_server_authorized_ip_ranges`). To use another module input, add it to the `clusters` type in `variables.tf` and pass it through in `clusters.tf`. Run `terraform test` before `plan`.

## Module version

**`dev/clusters.tf`** pins the registry module:

```hcl
source  = "app.terraform.io/PlatformForge/aks/azurerm"
version = "1.1.0"
```

Bump **`version`** per environment after you publish a new module tag in TFC (dev first, then staging/prod).

---

## Costs (rough, West Europe, pay-as-you-go)

| Item | Approx. |
|---|---|
| AKS control plane, Free tier | 0 |
| 1 × `Standard_B2s` node + 64 GB managed disk | ~1.2 USD/day |
| Standard load balancer + public IP | ~0.6 USD/day |
| State storage | < 0.1 USD/month |

Destroy the environment at the end of a study session (step 7) and the daily cost goes to zero.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `subscription ID could not be determined` | `export ARM_SUBSCRIPTION_ID=...` (step 3) |
| `terraform init`: storage account not found / 403 | Run step 4 and regenerate `../backend.hcl`; make sure you are logged into the same subscription |
| `AuthorizationFailed` creating role assignments | You need Owner (or User Access Administrator) on the subscription |
| `QuotaExceeded` / `SkuNotAvailable` | Change `system_vm_size` or region, or request quota (step 2.4) |
| kubectl: `Forbidden` | Wait for RBAC propagation; check `az account show` is the account that ran apply |
| kubectl: `exec: executable kubelogin not found` | Install kubelogin and run `kubelogin convert-kubeconfig -l azurecli` |
| Destroy fails on `rg-tfstate` | Expected: it is locked on purpose (see step 7) |
| A plan wants to **replace** the cluster | Stop. Read which attribute forces it; most are named in the module's variable descriptions |
