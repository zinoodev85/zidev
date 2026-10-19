# zidev — spec

What each feature does, exactly, and the check that proves it. `intent.md` says why; this says what.
A feature is done when its row here has a passing check. Change the row first, then the code.

Checks: **self** = `zidev selftest` (throwaway tmux server, ~3 min) · **app** = `zidev apptest` (the running
zidev.app, through its probe) · **hand** = no automatic check yet: try it, then make it one.

## Sidebar

| # | Spec | Check |
|---|------|-------|
| S1 | `t` on a session opens a new terminal tab for its project, every time (never reuses one). | self: "t opens a terminal tab", "t in the second session opens another terminal" |
| S2 | Under a project's changes tab: a "changes" row with its changed files, at most the 10 newest by mtime. | self: "its changed files are folded" |
| S3 | A separate "commits" row under it; ⏎ / click folds it open: the last 5 commits (`sha subject`). | self: "⏎ on commits: the last commits under it" |
| S4 | Click or ⏎ on a commit row: the changes tab shows `git show --stat -p` of it. | self: "a click on a commit", "⏎ on a commit too" |
| S5 | A click on a row keeps the keyboard in the sidebar (t, g, c work right after). | hand |
| S6 | cmd-click in the sidebar is a plain click. | hand |

## Clicks in Claude (zidev.app cmd-click)

| # | Spec | Check |
|---|------|-------|
| C1 | An item line `42 y n ? : …`: cmd-click on y / n / ? adds `42y ` / `42n ` / `42? ` to the prompt, not sent. | app |
| C2 | cmd-click on the number an item line starts with (`42.`, `– 10a:`) adds just the number. | app (number) · hand (10a) |
| C3 | cmd-click on a shorthand in text (`3y`, `461k`, `k 4`, `k 1 2 3`) adds it, not sent. | app |
| C4 | cmd-click on a `! command` types it into Claude and runs it. | app |
| C4b | A `! command` whose last word moved to the next row whole (a long hash) is all of it, clicked on either row. | app |
| C4c | An inline `` `! command` `` whose `!` ends a prose row and goes on (same color) on the next rows: all of it, clicked on any of its rows. | app |
| C5 | Clicks hit the row under the mouse, also with blank rows on top or the pane scrolled back. | app (blank top row) |
| C6 | A click on a commit hash (`50ca04b`) in any tab shows that commit in the floating preview; found in the pane's repo, any project, or a repo next to one. | hand |

## zidev.app

| # | Spec | Check |
|---|------|-------|
| A1 | cmd pressed twice (each alone, < 0.3 s held, < 0.4 s apart): zidev in front → hidden; else → shown in front. | app |
| A2 | Not a double tap: two taps far apart; cmd used with a key (cmd-c) in between. | app |
| A3 | cmd-cmd works from any app: Input Monitoring allowed and the event tap on; allowed later, it starts without a restart. | app (live) |
| A4 | Config `"hotkey"`: `cmd-cmd` (default), `alt-alt`, `ctrl-ctrl`, `shift-shift`, or a combo (`ctrl-alt-z`); `""` none. | hand |
| A5 | Window › Float on Top keeps it above other apps; remembered. | hand |
| A6 | Builds keep their signature ("zidev local", `app/signing.sh` once), so macOS keeps Input Monitoring across builds. | hand |

## Sessions

| # | Spec | Check |
|---|------|-------|
| N1 | A short tone when a session goes from working to done or error; config `"sound": false` mutes, a path plays that file. | hand |
| N2 | No polling git: FSEvents wake the changes list; tmux hooks wake hidden sidebars. | hand |
