#!/usr/bin/env bash
# Prints one JSON object with the data the widget shows:
#   { ok, login, mine: {total, items[]}, reviews: {total, items[]}, notifications, notificationsMore, error }
# Uses the GitHub CLI (`gh`), so it reuses your existing `gh auth login`.
set -o pipefail
LIMIT="${1:-10}"

fail() { jq -cn --arg e "$1" '{ok:false, error:$e}'; exit 0; }

command -v gh >/dev/null || fail "GitHub CLI (gh) is not installed"
command -v jq >/dev/null || fail "jq is not installed"

query='
query($limit: Int!) {
  viewer {
    login
    pullRequests(first: $limit, states: OPEN, orderBy: {field: UPDATED_AT, direction: DESC}) {
      totalCount
      nodes {
        number title url isDraft
        repository { nameWithOwner }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
      }
    }
  }
  reviews: search(query: "is:pr is:open review-requested:@me archived:false sort:updated-desc", type: ISSUE, first: $limit) {
    issueCount
    nodes { ... on PullRequest { number title url isDraft repository { nameWithOwner } author { login } } }
  }
}'

if ! prs=$(gh api graphql -F limit="$LIMIT" -f query="$query" 2>&1); then
  fail "$(printf '%s' "$prs" | head -c 300)"
fi
notes=$(gh api 'notifications?per_page=50' --jq 'length' 2>/dev/null || echo -1)

printf '%s' "$prs" | jq -c --argjson notes "$notes" '
  .data as $d | {
    ok: true,
    login: $d.viewer.login,
    mine: {
      total: $d.viewer.pullRequests.totalCount,
      items: [ $d.viewer.pullRequests.nodes[] | {
        number, title, url, draft: .isDraft,
        repo: .repository.nameWithOwner,
        ci: (.commits.nodes[0].commit.statusCheckRollup.state // "NONE")
      } ]
    },
    reviews: {
      total: $d.reviews.issueCount,
      items: [ $d.reviews.nodes[] | select(.url != null) | {
        number, title, url, draft: .isDraft,
        repo: .repository.nameWithOwner,
        author: (.author.login // "")
      } ]
    },
    notifications: $notes,
    notificationsMore: ($notes >= 50)
  }'
