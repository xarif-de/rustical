# xarif fork of RustiCal

This is a modified version of [RustiCal](https://github.com/lennart-k/rustical) by
Lennart Kämmle, licensed under the AGPL-3.0-or-later like the original.
**Modified by xarif since 2026-10-16.** The changes are listed in
[`.xarif/series`](.xarif/series); each one is a branch `patch/<topic>`.

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
| `patch/<topic>` | one change, shaped like an upstream pull request (no xarif files) |
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
what happened and what to do.

## Change a patch topic

Push to `patch/<topic>`; the next `fork-sync` picks it up (or start it by hand:
Actions → fork-sync → Run workflow). To send a topic upstream or take the
maintainer's fixups back, use [`.xarif/pr.sh`](.xarif/pr.sh) (`push` / `pull`).

## Database migrations

RustiCal checks the checksum of every migration it has applied and refuses to start if
one changed or disappeared. A fork migration must therefore stay byte-identical, and
there is **no rollback** to an older release once a newer one migrated the database:
fix forward. `fork-sync` stops if upstream takes a migration in a different form.

## Automation details

`dagger-ci.yaml` (`fork:` section) and the functions in
[base/dagger-modules](https://git.xarif.de/base/dagger-modules) (`docs/fork.md`).
