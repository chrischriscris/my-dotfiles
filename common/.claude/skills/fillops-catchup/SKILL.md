---
name: fillops-catchup
description: Fill missing Ensolvers Ops worklog days up to today. Reconstructs what was worked on from Claude/agent conversation history and Hyros work-repo git activity, lets the user select which items are safe to record, confirms the wording, then posts via fillops. Use when asked to catch up, backfill, or fill missing worklog/ops days.
---

# Fill missing Ensolvers Ops worklogs

Fill missing weekday worklog entries up to and including today. Tools: `fillops` and `opslib`
(`~/bin`); endpoint catalog in `~/.dotfiles/docs/ops-api.md`.

- User externalId: `f095d54bd78946789199855d9e9256ef`
- Assignation: `a79568e05bfa452da8e12b789a1031ee` ("699 - Hyros - Architect"). If the user id
  stops working: `opslib assignation get <assignation>` → `content.userExternalId`.
- Auth is a baked-in yearly token in both scripts. On `HTTP 401 … token may have expired`, ask
  the user for a fresh `Authorization: Bearer xxx:yyy` (DevTools on ops.ensolvers.com) and write
  it into the `TOKEN = os.environ.get("OPS_TOKEN", …)` fallback of both
  `~/.dotfiles/common/bin/opslib` and `~/.dotfiles/common/bin/fillops`, noting the date. Never
  `git add` those files.

**Scope.** `$ARGUMENTS` may give a start date (`YYYY-MM-DD`) or month (`YYYY-MM`). Default: 1st of
the current month through today; if the 1st is under 7 days ago, start 7 days earlier.

## Shell gotchas — empty output, not an error

- zsh does not word-split `$VAR`. Use arrays: `REPOS=(a b c); for r in "${REPOS[@]}"`.
- `git log --since=2026-08-14` matches nothing here; use `--since="2026-08-14 00:00"`.

Check any "no commits" result against an unfiltered `git log` before believing it.

## 1. Find missing days — do this first, it gates everything

```sh
opslib get '/ensolvers-ops/work-log/getWorkLogs/<user>?startDate=<start>&endDate=<today>'   # shortDay, compare date part
opslib get '/ensolvers-ops/timeoff/getTimeOffs?assignationExternalId=<assignation>&year=<Y>&month=<M>'
opslib get '/ensolvers-ops/assignation-pause/paused-days?assignationExternalId=<assignation>&year=<Y>&month=<M>'
opslib get '/ensolvers-users/get-dashboard'          # upcomingHolidays; if in doubt /ensolvers-ops/holiday/month/<M>?country=<CC>
```

Missing = weekdays in scope with no entry, minus timeoff/paused/holidays. Never fill weekends
unless asked. Weekday check: `date -j -f '%Y-%m-%d' <date> '+%a'`. Nothing missing → say so, stop.

## 2. Gather evidence, only for the missing days

Work sources only. Exclude personal repos (`gencv`, `costeo`, `bwunlock`, `axises`,
`col-earthquake`, `tasadolar`, `portfolio`, `gitwizard`, `incognito-lite`) and OSS clones
(`kitty`, `ghostling`, `opencode`, `opentui`, `cmux`, `t3code`, `localstack-persist`,
`esjs-dolar-api`). Unsure → exclude and say so.

**Repos.** `~/Projects/hyros/{hyros-devops,services,hyros-api-docs,hyros-extension,hyros-iac,hyros-mobile,hyros-tracking}`
and `~/hyros-services`; verify with `git remote get-url origin` (`markethero`/`hyros`), add
`git worktree list`. `~/Projects/<name>` symlinks into `~/Projects/hyros/`, and `~/hyros-services`
is a second clone of `services` — dedupe by hash. Query each repo once for the whole range:

```sh
git -C "$r" log --all --author=christopher.g@hyros.com --since="<start> 00:00" \
  --format="%ad|$(basename $r)|%h|%s" --date=format:'%Y-%m-%d'
```

Bucket by author date. No commits is weak evidence (squash merges, other machines); also check
`git status` for uncommitted work.

**Claude Code.** `~/.claude/projects/<encoded-cwd>/*.jsonl`, dirs matching `hyros` or `services`
(incl. worktree and subdir paths). One `python3` pass: skip lines without `"<YYYY-MM>-` or
`"summary"`, collect timestamp dates per file plus its summaries and first user prompt, print by
day. Don't read whole transcripts. This is where the *why* and the commit-less work show up.

**Other agents** (best effort): `~/.codex`, `~/.opencode`, `~/.gemini`, `~/.cursor`.

## 3. User picks the items

Evidence is not permission — some work is deliberately unreleased, and a worklog is a
client-facing record. Never compose straight from the sweep.

Group findings into one item per effort (not per commit), offer with `AskUserQuestion`
`multiSelect: true` (4 options/question, 4 questions/call — split by day or theme), one line per
item naming the effort so it's recognisable. Ask hours in the same call if it might not be 8.
Compose from selected items only; say what was excluded.

**Voice** — a standup line, not a report:

- `internalDescription` **is the same string** as `description`.
- One to three verb-first fragments separated by periods, sentence case, no trailing period:
  Debug, Investigate, Explore feasibility of, Test using, Implement, Start, Finish, Improve,
  Migrate, Prototype, Monitor.
- Name the thing with its real technical name at standup altitude. Technical is right;
  referent-less jargon chains and plain-English over-explanation are both wrong.
- Leftovers collapse to "Misc ‹area› fixes" / "General maintenance of ‹area›". Enumerating every
  item is what reads as padding.
- Exploration that won't ship is "Explore feasibility of…" / "Prototype…", never "build".
- No semicolon lists, no rationale ("to judge whether…"), no prose sentences, no "The X now…".
- No Jira keys, PR numbers, hashes or branch names; no secrets or personal content.
- Default 8 hours. No evidence → no entry; list the day and ask.

## 4. Confirm, post, verify

1. Show `date | hours | text` and get explicit approval — a separate gate from item selection.
   Rejected twice → the draft is too long; cut, don't reword.
2. `fillops "<text>" "<text>" -d <YYYY-MM-DD>` (`-H`/`-i` only if hours changed).
3. Re-fetch getWorkLogs, confirm every target day exists, report what was created and skipped.
