#!/usr/bin/env bash

set -u

OWNER="ieeexplorer"
APPLY=0
INCLUDE_OPTIONAL_ARCHIVES=0

archive_repos=(
  "MCP_server"
  "MCP_server_2"
  "MCP-Server"
  "CNN-Neural-Network"
  "end-to-end-Python-machine-learning-workflow"
)

optional_archive_repos=(
  "Find-Zip-Password-Pass-Finder-ZipFile"
  "Write-in-text-file-with-persian-and-english-languages-"
  "wikipediaWebScraping"
  "Neural-Network"
)

description_updates=(
  "Secure-RAG-Support-Assistant|Secure retrieval-augmented support assistant for enterprise knowledge search and response generation."
  "MCP-Powered-Data-Science-Assistant|Model Context Protocol assistant for data science workflows, analysis, and tool-driven automation."
  "Advanced-MCP-Server|Production-oriented MCP server with modular tooling, extensible architecture, and practical integration patterns."
  "Real-Time-Data-Pipeline|Real-time data pipeline project covering ingestion, transformation, and streaming-oriented processing patterns."
  "End-to-End-Python-ML-Workflow-Support-Ticket-Triage|End-to-end Python ML workflow for support ticket triage, from data preparation through evaluation and deployment artifacts."
  "CNN-Neural-Network--Image-Classification|CNN image classification project demonstrating model training, evaluation, and computer vision fundamentals."
  "Customer-Churn-Prediction-System-with-Mathematical-Foundations|Customer churn prediction project combining business-focused ML workflows with mathematical foundations and model interpretation."
  "Ai-news-sentiment-analyzer|News sentiment analysis pipeline with NLP-driven scoring and market-oriented use cases."
)

pin_repos=(
  "Secure-RAG-Support-Assistant"
  "MCP-Powered-Data-Science-Assistant"
  "Advanced-MCP-Server"
  "Real-Time-Data-Pipeline"
  "End-to-End-Python-ML-Workflow-Support-Ticket-Triage"
  "Customer-Churn-Prediction-System-with-Mathematical-Foundations"
)

manual_review_repos=(
  "JS-Python-Web-Scraping|Keep only if the README and examples are strong."
  "Machine-Learning-Types|Keep only if it reads as a polished educational repo."
  "Google_Gemini_API|Keep only if the documentation is clear and complete."
  "Gen-Ai|Rename or archive because the current name is too vague."
  "CNN-Neural-Network--Image-Classification|Keep visible even if it is not pinned."
)

failures=0

usage() {
  cat <<'EOF'
Usage:
  github_portfolio_cleanup.sh [--owner OWNER] [--apply] [--include-optional-archives]

Options:
  --owner OWNER                 GitHub owner or organization. Default: ieeexplorer
  --apply                       Execute changes. Without this flag, the script runs in dry-run mode.
  --include-optional-archives   Also archive noisier repos that still need a subjective check.
  --help                        Show this help text.

What this script does:
  - Archives clear duplicate or overlap repositories.
  - Updates descriptions for the strongest portfolio repositories.
  - Prints the six repositories that should be pinned manually on the GitHub profile.
  - Prints repos that still need a manual keep-or-hide decision.

Why pinning is manual:
  GitHub does not expose a stable supported CLI command for profile pinned repositories,
  so this script reports the exact pin set instead of attempting an unsupported API call.
EOF
}

print_auth_hint() {
  local auth_status
  auth_status="$(gh auth status 2>&1 || true)"

  echo "Auth check:"
  echo "$auth_status"

  if grep -q "GITHUB_TOKEN" <<<"$auth_status"; then
    cat <<'EOF'

The current auth source is GITHUB_TOKEN. In Codespaces this token is often read-only for
repository administration, which means archive and description edits may fail with HTTP 403.

If that happens, re-authenticate with a personal access token that has repo access and rerun:
  gh auth login -h github.com
EOF
  fi
}

run_or_preview() {
  local label="$1"
  shift

  if [[ "$APPLY" -eq 0 ]]; then
    printf '[dry-run] %s\n' "$label"
    printf '  '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  if "$@"; then
    printf '[ok] %s\n' "$label"
  else
    printf '[failed] %s\n' "$label"
    failures=$((failures + 1))
  fi
}

archive_repo() {
  local repo="$1"
  run_or_preview "Archive $OWNER/$repo" gh repo archive "$OWNER/$repo" --yes
}

update_description() {
  local repo="$1"
  local description="$2"
  run_or_preview "Set description for $OWNER/$repo" gh repo edit "$OWNER/$repo" --description "$description"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --owner)
        OWNER="$2"
        shift 2
        ;;
      --apply)
        APPLY=1
        shift
        ;;
      --include-optional-archives)
        INCLUDE_OPTIONAL_ARCHIVES=1
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
  done
}

require_tools() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh is required but not installed." >&2
    exit 1
  fi
}

main() {
  parse_args "$@"
  require_tools
  print_auth_hint

  echo
  echo "Duplicate cleanup:"
  for repo in "${archive_repos[@]}"; do
    archive_repo "$repo"
  done

  if [[ "$INCLUDE_OPTIONAL_ARCHIVES" -eq 1 ]]; then
    echo
    echo "Optional archive pass:"
    for repo in "${optional_archive_repos[@]}"; do
      archive_repo "$repo"
    done
  fi

  echo
  echo "Description updates:"
  for item in "${description_updates[@]}"; do
    local repo="${item%%|*}"
    local description="${item#*|}"
    update_description "$repo" "$description"
  done

  echo
  echo "Pin these 6 repositories manually on your GitHub profile:"
  for repo in "${pin_repos[@]}"; do
    printf '  - %s/%s\n' "$OWNER" "$repo"
  done

  echo
  echo "Manual review queue:"
  for item in "${manual_review_repos[@]}"; do
    local repo="${item%%|*}"
    local note="${item#*|}"
    printf '  - %s/%s: %s\n' "$OWNER" "$repo" "$note"
  done

  echo
  if [[ "$APPLY" -eq 0 ]]; then
    echo "Dry run complete. Re-run with --apply after authenticating with a token that can administer repositories."
    exit 0
  fi

  if [[ "$failures" -gt 0 ]]; then
    echo "Cleanup finished with $failures failed operation(s)." >&2
    exit 1
  fi

  echo "Cleanup finished successfully."
}

main "$@"