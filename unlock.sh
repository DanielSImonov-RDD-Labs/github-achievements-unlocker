#!/usr/bin/env bash
# Earns the GitHub achievements that can be automated, credited to the logged-in gh account.
set -euo pipefail

LOG_FILE="logs/log.md"
PR_TARGET=16
DELAY=40
COAUTHOR=""
TRAILER=""
REPO=""
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage:
  ./unlock.sh status
  ./unlock.sh run [--repo OWNER/NAME] [--pr-target N] [--coauthor LOGIN] [--delay SECONDS] [--dry-run]

Options:
  --repo       Public repository to open pull requests in (default: this clone's repository)
  --pr-target  Total public merged pull requests to reach (default: 16, tiers: 2 / 16 / 128 / 1024)
  --coauthor   GitHub login that agreed to co-author every pull request of this run
  --delay      Seconds between pull requests (default: 40, stays under GitHub's 500 writes per hour)
  --dry-run    Print the plan without changing anything
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

resolve_login() {
  LOGIN=$(gh api user --jq .login 2>/dev/null) ||
    die "cannot read your account. Run 'gh auth login'. The Actions GITHUB_TOKEN will not work: it acts as github-actions[bot], so nothing is credited to you."
}

# Achievements are only exposed on the profile page. Prints 0 when not earned.
achievement_tier() {
  local tier
  tier=$(curl -sL -A 'Mozilla/5.0' -H 'X-Requested-With: XMLHttpRequest' \
    "https://github.com/users/$LOGIN/achievements/$1/detail" |
    grep -oE 'tier-count="[0-9]+"' | grep -oE '[0-9]+') || tier=0
  echo "$tier"
}

public_merged_prs() {
  gh api -X GET search/issues -f q="is:pr is:merged is:public author:$LOGIN" --jq .total_count
}

best_repo_stars() {
  gh api -X GET search/repositories -f q="user:$LOGIN" -f sort=stars -f per_page=1 \
    --jq '.items[0].stargazers_count // 0'
}

# Usage: report NAME SLUG UNIT NOTE THRESHOLD...
report() {
  local name=$1 slug=$2 unit=$3 note=$4 tier mark=" " detail
  shift 4
  tier=$(achievement_tier "$slug")
  if ((tier > 0)); then
    mark="x"
  fi
  if ((tier >= $#)); then
    detail="max tier"
  else
    local thresholds=("$@")
    detail="tier $tier/$#, next at ${thresholds[$tier]} $unit"
    if [[ -n $note ]]; then
      detail+=" ($note)"
    fi
  fi
  printf '  [%s] %-20s %s\n' "$mark" "$name" "$detail"
}

cmd_status() {
  resolve_login
  echo "Achievements of $LOGIN"
  echo
  echo "Automated by './unlock.sh run':"
  report "YOLO" yolo "PR merged without review" "" 1
  report "Quickdraw" quickdraw "issue closed within 5 minutes" "" 1
  report "Pull Shark" pull-shark "merged PRs" "public so far: $(public_merged_prs)" 2 16 128 1024
  report "Pair Extraordinaire" pair-extraordinaire "co-authored PRs" "needs --coauthor" 1 10 24 48
  echo
  echo "Needs real people, not automated:"
  report "Galaxy Brain" galaxy-brain "accepted answers" "answer real questions in Discussions" 2 8 16 32
  report "Starstruck" starstruck "stars on one repo" "your best repo: $(best_repo_stars)" 16 128 512 4096
  report "Public Sponsor" public-sponsor "sponsorship" "paid, on github.com/sponsors" 1
  echo
  echo "Cannot be earned right now:"
  echo "  Heart On Your Sleeve, Open Sourcerer (disabled by GitHub)"
  echo "  Arctic Code Vault Contributor, Mars 2020 Contributor (retired)"
}

open_and_close_issue() {
  local number
  number=$(gh api "repos/$REPO/issues" -f title="Achievement unlock" \
    -f body="Automated issue for Quickdraw." --jq .number)
  gh api -X PATCH "repos/$REPO/issues/$number" -f state=closed --silent
  echo "Issue #$number opened and closed."
}

open_and_merge_pr() {
  local round=$1 branch sha file_sha content message number
  branch="achievement/round-${round}-$(date +%s)"
  sha=$(gh api "repos/$REPO/git/ref/heads/$BASE" --jq .object.sha)
  gh api "repos/$REPO/git/refs" -f ref="refs/heads/$branch" -f sha="$sha" --silent

  file_sha=$(gh api "repos/$REPO/contents/$LOG_FILE?ref=$branch" --jq .sha 2>/dev/null) || file_sha=""
  content=$(printf 'Round %s - %s\n' "$round" "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" | base64)
  message="feat: achievement round $round"
  if [[ -n $TRAILER ]]; then
    message+=$'\n\n'"$TRAILER"
  fi
  gh api -X PUT "repos/$REPO/contents/$LOG_FILE" -f message="$message" -f content="$content" \
    -f branch="$branch" ${file_sha:+-f sha="$file_sha"} --silent

  number=$(gh api "repos/$REPO/pulls" -f title="Achievement round $round" \
    -f body="Automated achievement PR - round $round." -f head="$branch" -f base="$BASE" --jq .number)
  gh api -X PUT "repos/$REPO/pulls/$number/merge" -f merge_method=merge --silent
  gh api -X DELETE "repos/$REPO/git/refs/heads/$branch" --silent
  echo "PR #$number merged."
}

resolve_coauthor() {
  local id login
  [[ $COAUTHOR =~ ^[A-Za-z0-9-]+$ ]] || die "--coauthor must be a GitHub login"
  read -r id login < <(gh api "users/$COAUTHOR" --jq '"\(.id) \(.login)"' 2>/dev/null) ||
    die "GitHub user '$COAUTHOR' not found"
  [[ $login != "$LOGIN" ]] || die "--coauthor must be another account"
  TRAILER="Co-authored-by: $login <$id+$login@users.noreply.github.com>"
}

cmd_run() {
  while (($#)); do
    case $1 in
      --repo) REPO=$2; shift 2 ;;
      --pr-target) PR_TARGET=$2; shift 2 ;;
      --coauthor) COAUTHOR=$2; shift 2 ;;
      --delay) DELAY=$2; shift 2 ;;
      --dry-run) DRY_RUN=true; shift ;;
      *) usage >&2; exit 1 ;;
    esac
  done
  [[ $PR_TARGET =~ ^[0-9]+$ ]] || die "--pr-target must be a number"
  [[ $DELAY =~ ^[0-9]+$ ]] || die "--delay must be a number"

  resolve_login
  if [[ -n $COAUTHOR ]]; then
    resolve_coauthor
  fi
  if [[ -z $REPO ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
  fi
  local private merged needed quickdraw_tier
  read -r private BASE < <(gh api "repos/$REPO" --jq '"\(.private) \(.default_branch)"')
  [[ $private == false ]] || die "$REPO is private. Use a public repository: tiers did not move for private pull requests."

  merged=$(public_merged_prs)
  needed=$((PR_TARGET > merged ? PR_TARGET - merged : 0))
  quickdraw_tier=$(achievement_tier quickdraw)
  if ((needed == 0)) && (($(achievement_tier yolo) == 0)); then
    needed=1
  fi

  echo "Account:           $LOGIN"
  echo "Repository:        $REPO ($BASE)"
  echo "Public merged PRs: $merged, target $PR_TARGET"
  echo "PRs to create:     $needed, about $((needed * (DELAY + 8) / 60 + 1)) min"
  echo "Co-author:         ${TRAILER:-none, Pair Extraordinaire will not move}"
  echo "Quickdraw:         $( ((quickdraw_tier > 0)) && echo "already earned" || echo "will open and close an issue")"
  if [[ $DRY_RUN == true ]]; then
    echo "Dry run, nothing changed."
    return
  fi

  trap 'echo "Stopped early. Run the same command again to continue." >&2' EXIT
  if ((quickdraw_tier == 0)); then
    open_and_close_issue
  fi
  local i
  for ((i = 1; i <= needed; i++)); do
    open_and_merge_pr "$i"
    if ((i < needed)); then
      sleep "$DELAY"
    fi
  done
  trap - EXIT
  echo "Done. Achievements can take up to 48 hours to appear, check with './unlock.sh status'."
}

main() {
  command -v gh >/dev/null || die "the GitHub CLI is required: https://cli.github.com"
  case ${1:-} in
    status) cmd_status ;;
    run) shift; cmd_run "$@" ;;
    *) usage ;;
  esac
}

main "$@"
