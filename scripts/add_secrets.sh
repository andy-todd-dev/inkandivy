#!/usr/bin/env bash
set -euo pipefail

# add_secrets.sh
#
# Purpose:
# - Read a repository-level `secrets.json` (root of the repo) that defines
#   the secrets to configure. `secrets.json` must be a JSON array of objects
#   with { "name": "GITHUB_SECRET_NAME", "prompt": "Prompt text" }.
# - For each secret: check the repo-local cache file (`.local_secrets`) for
#   a saved value.
# - If missing or if the user chooses to replace it, securely prompt for the
#   secret value (hidden input) and save it to the repo cache.
# - Upload the secret value to GitHub using the `gh` CLI (`gh secret set`).

declare -A SECRET_PROMPTS
declare -A SECRET_NAMES

# Locate repository root (git top-level) so we can look for a repo-level
# secrets.json. Fall back to script parent dir when not in a git repo.
repo_root()
{
	if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
		printf "%s" "$git_root"
	else
		printf "%s" "$(cd "$(dirname "$0")/.." && pwd)"
	fi
}

REPO_ROOT="$(repo_root)"
CONFIG_FILE="$REPO_ROOT/secrets.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
	>&2 echo "secrets.json not found at $CONFIG_FILE"
	exit 2
fi

SECRETS_JSON="$(cat "$CONFIG_FILE")"

# Parse JSON into tab-separated lines: name, prompt
while IFS=$'\t' read -r name prompt; do
	[[ -z "$name" ]] && continue
	SECRET_PROMPTS["$name"]="$prompt"
	# keep SECRET_NAMES for compatibility; key and GH name are the same
	SECRET_NAMES["$name"]="$name"
done < <(printf '%s' "$SECRETS_JSON" | jq -r '.[] | [.name, .prompt] | @tsv')


# ------------------------------
# Internal helpers
# ------------------------------

# Save the cache file in the repository root directory
CACHE_FILE="$REPO_ROOT/.local_secrets"

declare -A CACHE

load_cache()
{
	if [[ -f "$CACHE_FILE" ]]; then
		while IFS='=' read -r k v; do
			# skip empty lines and comments
			[[ -z "$k" || "$k" =~ ^# ]] && continue
			CACHE["$k"]="$v"
		done < <(sed -n '1,${p;}' "$CACHE_FILE" 2>/dev/null || cat "$CACHE_FILE")
	fi
}

save_cache()
{
	# Ensure directory exists
	local tmpfile
	tmpfile=$(mktemp)
	for k in "${!CACHE[@]}"; do
		# write key=value; values may contain '=' but this simple format is fine
		printf '%s=%s\n' "$k" "${CACHE[$k]}" >> "$tmpfile"
	done
	mv "$tmpfile" "$CACHE_FILE"
	chmod 600 "$CACHE_FILE" || true
}


prompt_for_secret()
{
	# Securely prompt until a non-empty value is provided. Returns value on stdout.
	local prompt="$1"
	local val
	while true; do
		read -r -s -p "$prompt: " val
		echo
		if [[ -n "$val" ]]; then
			printf '%s' "$val"
			return 0
		else
			echo "Value cannot be empty."
		fi
	done
}


set_github_secret()
{
	local gh_name="$1"
	local value="$2"

	# Use gh to set the repo secret. gh will encrypt automatically.
	# We pass the body via --body so newlines are preserved.
	if gh secret set "$gh_name" --body "$value" 2>/dev/null; then
		return 0
	else
		# Retry once capturing stderr for diagnostics
		>&2 echo "Failed to set GitHub secret '$gh_name' with gh CLI." 
		return 1
	fi
}


# ------------------------------
# Main flow
# ------------------------------

echo "Checking and uploading configured secrets to GitHub..."
load_cache

any_fail=0

for key in "${!SECRET_PROMPTS[@]}"; do
	prompt="${SECRET_PROMPTS[$key]}"
	gh_name="${SECRET_NAMES[$key]}"

	if [[ -z "$gh_name" ]]; then
		echo "Skipping '$key' - no GitHub secret name configured." >&2
		continue
	fi

	value=""
	if [[ -n "${CACHE[$key]:-}" ]]; then
		read -r -p "Found a saved value for '$prompt'. Reuse it? [Y/n]: " use_saved
		use_saved="${use_saved:-Y}"
		if [[ "$use_saved" =~ ^([yY]|)$ ]]; then
			value="${CACHE[$key]}"
		else
			value=$(prompt_for_secret "$prompt")
			CACHE[$key]="$value"
			save_cache
		fi
	else
		# no saved value — prompt
		value=$(prompt_for_secret "$prompt")
		CACHE[$key]="$value"
		save_cache
	fi

	echo "Uploading '$gh_name' to GitHub..."
		if set_github_secret "$gh_name" "$value"; then
		echo "Uploaded $gh_name"
	else
		echo "Failed to upload $gh_name" >&2
		any_fail=1
	fi
done

if [[ "$any_fail" -ne 0 ]]; then
	echo "One or more secrets failed to upload." >&2
	exit 1
fi

echo "All configured secrets processed."
