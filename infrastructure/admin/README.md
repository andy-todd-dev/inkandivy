# Infra Admin Workspace

This configuration manages Terraform Cloud workspace(s) and their variables for the project. It exists to avoid the bootstrap problem of needing provider credentials (`neon_api_key`, `stripe_secret_key`) before the main infrastructure workspace can plan.

## Managed Objects

- Production workspace (`production`)
- Sensitive Terraform input variables for that workspace:
  - `neon_api_key`
  - `stripe_secret_key`
  - (optionally later) `backend_url`

## Authentication

Export a Terraform Cloud user/team token with permissions to manage workspaces and variables in the organization:

```bash
export TFE_TOKEN=xxxxx
```

The `tfe` provider automatically picks up `TFE_TOKEN`.

## Usage

```bash
cd infrastructure/admin
terraform init
terraform plan \
  -var "neon_api_key=$NEON_API_KEY" \
  -var "stripe_secret_key=$STRIPE_SECRET_KEY" \
  # -var "backend_url=https://api.example.com" (optional)
terraform apply \
  -var "neon_api_key=$NEON_API_KEY" \
  -var "stripe_secret_key=$STRIPE_SECRET_KEY"
```

Alternatively set environment variables `TF_VAR_neon_api_key` and `TF_VAR_stripe_secret_key`.

## Next Step After Apply

Run the production workspace (existing root infrastructure config):

```bash
cd ../
terraform init
terraform plan -var-file="environments/production.tfvars"
terraform apply -var-file="environments/production.tfvars"
```

(Production config will now receive the injected sensitive variables.)

## Secret Handling

- Do **not** commit real secret values.
- Consider a secrets manager or Vault if rotation frequency increases.

## Future Enhancements

- Introduce variable sets for multi-environment scaling (staging, preview).
- Add run triggers once another workspace produces outputs consumed by production.
- Add tags to workspaces for filtering (`tag_names`).
