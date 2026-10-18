# Commits

Shape a branch's history the way a human would: a few commits, each one a coherent step, not one commit per prompt.

- A follow-up tweak (a fix, a rename, review feedback, a polish pass) gets folded into the existing commit it belongs to: `git commit --fixup=<sha>` then `git rebase -i --autosquash` non-interactively (`GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`), or `--amend` when it's the last commit. Reword that commit's message if its scope changed.
- Make a new commit only when the change is a step of its own that you'd describe separately in the PR.
- Fold freely on feature branches, even when the commits are already pushed; update the remote with `git push --force-with-lease`. Never rewrite or force-push a trunk branch (master, staging, develop, master-hotfix and the like) or commits already merged into one.
- Every commit must still build and pass on its own after folding (no need to rerun build or tests if kinda obvious).

# Pull requests

When I ask you to file a PR, open it as a draft (`gh pr create --draft`, or the Bitbucket API's `"draft": true`). I mark it ready myself.

When I ask you to push, or to do something that needs a push (like filing a PR or updating one), push without asking.

## Descriptions

Write it like the engineer who did the work telling a teammate: plain, a bit informal, short but complete.

- Open with what was wrong and how it showed up, no heading or "This PR". Evidence if there is some (log link, payload, a concrete case, screenshot), then the fix, often one line.
- Say what the diff can't: the cause, calls you made and why (first person), what's not covered, deploy order. Skip what it shows: walkthroughs, classes touched, the tests.
- Each fact once, one clause of why. Cut any sentence a reviewer wouldn't miss.
- Length follows how many separate things there are to say; if one line covers it, write one line.
- Short paragraphs, bullets of one or two sentences. Code blocks, tables, headings or screenshots only when the content has that shape. No templates (Summary / Changes / Testing), no bold for emphasis, no emoji, no "ensures / robust / enhances", no em-dash chains, no closing recap.

# Questions and instructions

I often drop question marks, so a short line can be a question. A question gets an answer, not a change: don't edit, delete, move, commit or publish in reply to one; answer it and say what you'd do. "so?" asks for the conclusion, not a go-ahead.

Once I've given an instruction, carry it through without confirming each step or ending turns with "Want me to…?" when the next step is the obvious continuation of what I asked. Ask only when a step is destructive or outward-facing, or when a request has two readings that lead to different work ("do the 3": item 3, or all three?).

# Subagents

Do implementation, rewrites and design yourself rather than delegating them. When you do spawn subagents, use the cheapest model that fits and say which: `haiku` for bulk or mechanical work (classifying, extracting, applying a written plan), `sonnet` for read-only search, exploration and web research, and Opus only for adversarial review or code you'd otherwise write yourself. Unless I give a number, start with at most 5 agents and check with me before scaling up.

# JavaScript / TypeScript projects

Use Bun for new projects: as the runtime when the stack runs on it, and as the package manager (`bun install`, `bun add`, `bun run`, `bunx`, `bun.lock`) even when the runtime has to be Node.

- If a dependency doesn't work under Bun's runtime, say which one and why, then run on Node while keeping Bun as the package manager.
- In existing projects, use whatever package manager the lockfile shows. Switch only when asked.
