---
description: Rebase-sync a base branch onto a target branch, with a safety backup that is dropped only when the result is provably clean
argument-hint: <base-branch> <target-branch>
allowed-tools: Bash(git status:*), Bash(git fetch:*), Bash(git checkout:*), Bash(git branch:*), Bash(git rebase:*), Bash(git log:*), Bash(git diff:*), Bash(git range-diff:*), Bash(git add:*), Bash(git merge-base:*), Bash(GIT_EDITOR=true git rebase --continue), Read, Edit
---

Rebase-sync `$1` (the base branch) onto `$2` (the target branch): move `$1`'s commits on top of the latest `$2`. Make a backup first, diff against it at the end, and drop it only when the result is provably clean.

If `$1` or `$2` is missing, ask me for it before doing anything.

Steps:

1. **Pre-flight.** `git status` — the working tree must be clean. If it's dirty, STOP and tell me; don't stash without asking. Confirm both `$1` and `$2` exist (`git branch --list`, `git rev-parse --verify`).

2. **Fetch.** `git fetch --all --prune` so `$2` is up to date. If `$2` has a remote tracking branch, sync against `origin/$2`; otherwise use the local `$2`. If it's ambiguous which one I mean, ask.

3. **Backup.** Check out `$1`, then create a backup pointing at its current tip:
   `git branch backup/$1-rebase-sync $1`
   If that branch name already exists, STOP and ask before overwriting it.

4. **Rebase.** From `$1`, run `git rebase $2` (or `origin/$2`). For each conflict:
   - Read both sides and understand the intent.
   - Prefer keeping **both** intents unless one clearly supersedes the other.
   - Resolve, `git add` the file, then `GIT_EDITOR=true git rebase --continue`.
   - If you are genuinely unsure how to resolve a conflict, STOP and show it to me — do not guess.

5. **Compare.** When the rebase finishes, diff the result against the backup to surface what actually changed:
   - `git diff backup/$1-rebase-sync..$1 --stat`, then inspect the meaningful diffs.
   - Flag anything that looks unintended: dropped commits, files that changed beyond conflict resolution, formatting-only churn, stray debug code.

6. **Decide on the backup.** Run `git range-diff <old-base>..backup/$1-rebase-sync $2..$1`, where `<old-base>` is `git merge-base backup/$1-rebase-sync $2` (use `origin/$2` if that's what you rebased onto). Delete the backup with `git branch -D backup/$1-rebase-sync` only if ALL of these hold:
   - the rebase had no conflicts;
   - every commit shows as `=` in the range-diff (same patch, nothing dropped, nothing added);
   - step 5 flagged nothing suspicious.
   Otherwise keep it and say which condition failed.

7. **Report.** Summarize: which commits were replayed, which files conflicted and how you resolved each, the ⚠️ suspicious changes (if any) from step 5, and whether the backup was deleted or kept (and why). Do NOT force-push — I'll do that once I've reviewed.
