ARG VARIANT="22-bullseye"

FROM mcr.microsoft.com/devcontainers/javascript-node:${VARIANT}

ARG GITHUB_CLI="2.76.2"
ARG TERRAFORM_CLI="1.12.2-1"

RUN export DEBIAN_FRONTEND=noninteractive

# Base dependencies
RUN apt update && apt upgrade -y \
    && apt install -y \
    # For Version Control
    git \ 
    # For installing github cli and terraform
    wget \
    # For terraform
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh=${GITHUB_CLI} -y

# Install Terraform CLI
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null \
    && gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt install terraform=${TERRAFORM_CLI} -y

# Create dev user
RUN groupadd dev \
    && useradd -m -s /bin/bash -g dev dev \
    && echo "dev ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev