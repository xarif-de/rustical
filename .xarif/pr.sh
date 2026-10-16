#!/usr/bin/env bash
# Upstream PRs for patch topics (XARIF.md "Change a patch topic"). Run in a checkout of the fork,
# by a human with push rights on the user fork. Topics and PR branches: .xarif/series.
#   .xarif/pr.sh pull <topic>   take maintainer fixups from the PR head into patch/<topic> (fast-forward only)
#   .xarif/pr.sh push <topic>   publish patch/<topic> as the PR head (refuses to drop commits the PR head has)
set -euo pipefail
USER_FORK=${USER_FORK:-https://github.com/ThomasSteinbach/rustical}
UPSTREAM=${UPSTREAM:-lennart-k/rustical}
FORGEJO=${FORGEJO:-https://git.xarif.de/docker/rustical.git}
cmd=${1:?pull|push}; topic=${2:?topic}
# the series as it is NOW (not a stale local remote-tracking ref)
git fetch -q "$FORGEJO" "+refs/heads/xarif:refs/remotes/origin/xarif"
line=$(git show origin/xarif:.xarif/series | awk -v t="$topic" '$1==t')
[ -n "$line" ] || { echo "topic $topic is not in the series" >&2; exit 1; }
pr=$(sed -n 's/.* pr=\([^ ]*\).*/\1/p' <<<"$line")
[ "$pr" != local ] || { echo "topic $topic is local (no upstream PR)" >&2; exit 1; }
git fetch -q "$FORGEJO" "+refs/heads/patch/$topic:refs/remotes/origin/patch/$topic"
# the PR head, if the branch exists yet (exit 2 = no such branch; anything else is a real error)
if git ls-remote --exit-code "$USER_FORK" "refs/heads/$pr" >/dev/null; then
  git fetch -q "$USER_FORK" "+refs/heads/$pr:refs/pr-head/$topic"
else
  rc=$?; [ "$rc" = 2 ] || { echo "cannot read $USER_FORK (exit $rc)" >&2; exit 1; }
  git update-ref -d "refs/pr-head/$topic" 2>/dev/null || true
fi
ours=refs/remotes/origin/patch/$topic theirs=refs/pr-head/$topic
case "$cmd" in
  pull)
    git rev-parse -q --verify "$theirs" >/dev/null || { echo "no PR head $USER_FORK $pr" >&2; exit 1; }
    if git merge-base --is-ancestor "$theirs" "$ours"; then echo "patch/$topic already contains the PR head"; exit 0; fi
    git merge-base --is-ancestor "$ours" "$theirs" || { echo "PR head and patch/$topic diverged: rebase by hand" >&2; exit 1; }
    git push "$FORGEJO" "$theirs:refs/heads/patch/$topic"
    echo "patch/$topic fast-forwarded to the PR head; the next fork-sync picks it up" ;;
  push)
    seen=$(git rev-parse -q --verify "$theirs" || true)
    if [ -n "$seen" ] && ! git merge-base --is-ancestor "$seen" "$ours"; then
      echo "the PR head has commits patch/$topic lacks (maintainer fixups?): run '$0 pull $topic' first" >&2; exit 1
    fi
    git push --force-with-lease="refs/heads/$pr:$seen" "$USER_FORK" "$ours:refs/heads/$pr"
    owner=$(sed -E 's#^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)##; s#/.*##' <<<"$USER_FORK")
    [ -n "$seen" ] || echo "open the PR: gh pr create -R $UPSTREAM --head $owner:$pr --base main --fill" ;;
  *) echo "usage: $0 pull|push <topic>" >&2; exit 2 ;;
esac
