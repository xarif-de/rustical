# xarif fork of RustiCal

This is a modified version of [RustiCal](https://github.com/lennart-k/rustical) by
Lennart Kämmle, licensed under the AGPL-3.0-or-later like the original.
**Modified by xarif since 2026-10-16.** The changes are listed in
[`.xarif/series`](.xarif/series); each one is the ref `refs/xarif/patch/<topic>`.

The fork exists for changes that the upstream project has not taken yet. Each change
is also offered upstream as a pull request. Once upstream releases it, the fork drops
it again.

| Where | What |
|---|---|
| [git.xarif.de/docker/rustical](https://git.xarif.de/docker/rustical) | working repository |
| [github.com/xarif-de/rustical](https://github.com/xarif-de/rustical) | published copy (source of every fork release) |
| `registry.gitlab.com/xarif/docker/rustical:<tag>` | container image (linux/amd64, linux/arm64) |

## Branches and tags

| Ref | Meaning |
|---|---|
| `xarif` | default branch: an upstream release + every patch topic + this infra layer. Changes only through pull requests. |
| `refs/xarif/patch/<topic>` | one change, shaped like an upstream pull request (no xarif files). Not a branch: a branch push would run the upstream's own workflows on our runner. A `patch/*` branch is refused and never used |
| `sync/next` | the next candidate, written by the bot `fork-bot` |
| `v<upstream>-xarif.<n>` | a fork release, for example `v0.16.6-xarif.1` |

## How a release happens

1. `fork-sync` runs every 6 hours. It takes the newest upstream release that is at
   least 24 hours old, rebases the patch topics onto it in series order and adds this
   infra layer. If the result differs from `xarif`, it pushes `sync/next` and opens or
   updates one pull request.
2. `fork-check` runs on that pull request. It recomputes the candidate (it must be
   identical) and runs the upstream test suite: fmt, clippy, tests, cargo-vet,
   cargo-deny.
3. When the checks pass, Forgejo merges the pull request by fast-forward.
4. `fork-tag` tags `xarif` with the next `v<upstream>-xarif.<n>`; `ci` builds and
   publishes the image.

If something needs a human, `fork-bot` opens an issue labelled `fork-blocked` (the sync
stopped) or `fork-advisory` (a security advisory; the sync continues). Each issue says
what happened and what to do. Unlike upstream's CI, a cargo-deny advisory does not fail
the check here: it is reported, and fixed with a topic (e.g. `rustls-update`) or by
the next upstream release. Both kinds close themselves once the cause is gone. Closing a
`fork-advisory` issue by hand while the advisory stands only lasts until the next sync pull
request: its check opens a new one.

## Change a patch topic

[`.xarif/pr.sh`](.xarif/pr.sh) (from `base/dagger-modules` `templates/fork/`, values in
[`.xarif/pr.env`](.xarif/pr.env)) `get <topic>` checks the topic out as the local branch
`patch/<topic>`; commit, then `save <topic>` stores it. A checked-out topic is upstream code without
`.xarif/`: run the script once from `xarif`, it copies itself to `.git/xarif-pr.sh`, and use that copy
while a topic is checked out (it prints the path). The next `fork-sync` picks it up (or
start it by hand: Actions → fork-sync → Run workflow). `push` / `pull` send a topic upstream
as a pull request and take the maintainer's fixups back (shown for review first).

## Database migrations

RustiCal checks the checksum of every migration it has applied and refuses to start if
one changed or disappeared. A fork migration must therefore stay byte-identical, and
there is **no rollback** to an older release once a newer one migrated the database:
fix forward. `fork-sync` stops if upstream takes a migration in a different form.

Every program that opens the database must come from the same fork release, and
`rustical serve` must have run its migrations before anything else reads the new columns
(PractiCal waits for RustiCal's `/ping` for this reason).

## Automation details

`dagger-ci.yaml` (`fork:` section) and the functions in
[base/dagger-modules](https://git.xarif.de/base/dagger-modules) (`docs/fork.md`).
