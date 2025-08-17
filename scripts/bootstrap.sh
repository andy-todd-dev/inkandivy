#!/bin/bash

# Ink and Ivy Infrastructure Bootstrap Script
# Hybrid approach: Personal CLI auth + generated scoped tokens

set -e

echo "🌿 Ink and Ivy Infrastructure Bootstrap"
echo "======================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
ORGANIZATION="Ink-and-Ivy"
WORKSPACE="production"
CONFIG_FILE=".bootstrap-config"

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Save configuration value
save_config() {
    local key="$1"
    local value="$2"
    
    # Remove existing key if present
    grep -v "^$key=" "$CONFIG_FILE" 2>/dev/null > "${CONFIG_FILE}.tmp" || true
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE" 2>/dev/null || touch "$CONFIG_FILE"
    
    # Add new value
    echo "$key=$value" >> "$CONFIG_FILE"
}

# Load configuration value
load_config() {
    local key="$1"
    grep "^$key=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- || echo ""
}

# Prompt for input with default
prompt_input() {
    local prompt="$1"
    local var_name="$2"

    # Check if we already have this value
    local existing_value
    existing_value=$(load_config "$var_name")

    if [[ -n "$existing_value" ]]; then
        if [[ "$is_sensitive" == "true" ]]; then
            log_info "$prompt: [Already configured]"
        else
            log_info "$prompt: $existing_value [Already configured]"
        fi
        echo "$existing_value"
        return
    fi

    local colored_prompt
    colored_prompt="${BLUE}${prompt}${NC}"
    if [[ -n "$default" ]]; then
        colored_prompt+=" [$default]"
    fi
    colored_prompt+=": "

    local input
    read -r -p "$(printf "%b" "$colored_prompt")" input

    # Save configuration
    if [[ -n "$input" ]]; then
        save_config "$var_name" "$input"
    fi

    echo "$input"
}

# Authenticate with CLI tools
authenticate_services() {
    log_step "Authenticating with services..."
    
    # Terraform Cloud
    log_info "Authenticating with Terraform Cloud..."
    local tf_creds="${HOME}/.terraform.d/credentials.tfrc.json"

    if [[ -f "$tf_creds" ]]; then
        log_success "Terraform Cloud authenticated"
    else
        if ! terraform login; then
            log_error "Failed to authenticate with Terraform Cloud"
            return 1
        fi
        log_success "Terraform Cloud authenticated"
    fi
    
    # GitHub CLI
    log_info "Authenticating with GitHub..."
    if ! gh auth status >/dev/null 2>&1; then
        gh auth login
    fi
    log_success "GitHub authenticated"

}

collect_tokens() {
    log_info "Collecting API tokens..."
    TF_API_TOKEN=$(prompt_input "Terraform Cloud API token" "tf_api_token")
    VERCEL_API_TOKEN=$(prompt_input "Vercel API token" "vercel_api_token")
    RENDER_API_KEY=$(prompt_input "Render API key" "render_api_key")
    STRIPE_SECRET_KEY=$(prompt_input "Stripe secret key" "stripe_secret_key")
    STRIPE_PUBLISHABLE_KEY=$(prompt_input "Stripe publishable key" "stripe_publishable_key")
    NEON_API_KEY=$(prompt_input "Neon API key" "neon_api_key")
    SANITY_PROJECT_ID=$(prompt_input "Sanity project ID" "sanity_project_id")
    SANITY_API_TOKEN=$(prompt_input "Sanity API token" "sanity_api_token")
    CLOUDINARY_CLOUD_NAME=$(prompt_input "Cloudinary cloud name" "cloudinary_cloud_name")
    CLOUDINARY_API_KEY=$(prompt_input "Cloudinary API key" "cloudinary_api_key")
    CLOUDINARY_API_SECRET=$(prompt_input "Cloudinary API secret" "cloudinary_api_secret")
}

# Setup Terraform Cloud workspace
setup_terraform_cloud() {
    log_step "Setting up Terraform Cloud workspace..."
    
    # Check if workspace exists
    if terraform workspace list | grep -q "$WORKSPACE" 2>/dev/null; then
        log_success "Workspace '$WORKSPACE' already exists"
        terraform workspace select "$WORKSPACE"
    else
        log_info "Creating workspace '$WORKSPACE'..."
        if terraform workspace new "$WORKSPACE"; then
            log_success "Workspace '$WORKSPACE' created"
        else
            log_error "Failed to create workspace"
            return 1
        fi
    fi
}

# Configure GitHub secrets
configure_github_secrets() {
    log_step "Configuring GitHub secrets..."
    
    # Define secrets to set: SECRET_NAME:VARIABLE_NAME
    local secrets=(
        "TF_API_TOKEN:TF_API_TOKEN"
        "VERCEL_TOKEN:VERCEL_API_TOKEN"
        "RENDER_API_KEY:RENDER_API_KEY"
        "STRIPE_PUBLISHABLE_KEY:STRIPE_PUBLISHABLE_KEY"
        "SANITY_PROJECT_ID:SANITY_PROJECT_ID"
        "SANITY_API_TOKEN:SANITY_API_TOKEN"
        "CLOUDINARY_CLOUD_NAME:CLOUDINARY_CLOUD_NAME"
        "CLOUDINARY_API_KEY:CLOUDINARY_API_KEY"
        "CLOUDINARY_API_SECRET:CLOUDINARY_API_SECRET"
    )
    
    # Set each secret
    for secret in "${secrets[@]}"; do
        local secret_name="${secret%%:*}"
        local var_name="${secret##*:}"
        local var_value="${!var_name}"
        
        if gh secret set "$secret_name" --body "$var_value" >/dev/null 2>&1; then
            log_success "Set $secret_name"
        else
            log_warning "Failed to set $secret_name"
        fi
    done
    
    log_success "GitHub secrets configured"
}

# Initialize and deploy
initialize_and_deploy() {
    log_step "Initializing Terraform..."
    
    cd infrastructure
    
    if terraform init; then
        log_success "Terraform initialized"
    else
        log_error "Terraform initialization failed"
        cd ..
        return 1
    fi
    if terraform plan -var-file="environments/production.tfvars" >/dev/null 2>&1; then
        log_success "Terraform configuration valid"
    else
        log_error "Terraform configuration invalid"
        cd ..
        return 1
    fi
    
    # Optional deployment
    echo ""
    log_warning "Ready to deploy infrastructure. This may incur costs."
    echo -n "Deploy now? (y/N): "
    read -r deploy_confirm
    
    if [[ "$deploy_confirm" == "y" || "$deploy_confirm" == "Y" ]]; then
        if terraform apply -var-file="environments/production.tfvars" -auto-approve; then
            log_success "🚀 Infrastructure deployed successfully!"
            
            # Show URLs
            echo ""
            log_info "Service URLs:"
            terraform output -raw frontend_url 2>/dev/null && echo " - Frontend: $(terraform output -raw frontend_url)"
            terraform output -raw backend_url 2>/dev/null && echo " - Backend: $(terraform output -raw backend_url)"
        else
            log_error "Deployment failed"
        fi
    else
        log_info "Deployment skipped. Deploy later with:"
        log_info "cd infrastructure && terraform apply -var-file=\"environments/production.tfvars\""
    fi
    
    cd ..
}

# Setup Sanity project
setup_sanity() {
    if [[ -d "cms" ]] && [[ -f "cms/sanity.config.ts" || -f "cms/sanity.config.js" ]]; then
        log_success "Sanity project already exists"
        return
    fi
    
    log_step "Setting up Sanity CMS project..."
    
    sanity init --project-name "ink-and-ivy" --dataset "production" --output-path "cms" --template "clean" --yes
    log_success "Sanity project created"
}

# Apply admin Terraform (workspace + sensitive variables) - standalone function
run_admin_terraform() {
    log_step "Applying admin Terraform configuration (workspace + variables)..."
    pushd infrastructure/admin >/dev/null || { log_error "Admin directory missing"; return 1; }
    export TFE_TOKEN="$TF_API_TOKEN"
    if ! terraform init -input=false >/dev/null 2>&1; then
        log_error "Admin terraform init failed"
        popd >/dev/null
        return 1
    fi
    if terraform apply -auto-approve \
        -var "neon_api_key=$NEON_API_KEY" \
        -var "stripe_secret_key=$STRIPE_SECRET_KEY" 2>&1; then
        log_success "Admin Terraform applied (workspace + variables ready)"
    else
        log_error "Admin Terraform apply failed"
        popd >/dev/null
        return 1
    fi
    popd >/dev/null
}

main() {
    authenticate_services
    collect_tokens
    setup_terraform_cloud
    run_admin_terraform
    configure_github_secrets
    initialize_and_deploy
    setup_sanity
    log_success "Bootstrap Complete!"
}

main "$@"