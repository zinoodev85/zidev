# zidev — spec

What each feature does, exactly, and the check that proves it. `intent.md` says why; this says what.
A feature is done when its row here has a passing check. Change the row first, then the code.

Checks: **self** = `zidev selftest` (throwaway tmux server, ~3 min) · **app** = `zidev apptest` (the running
zidev.app, through its probe) · **hand** = no automatic check yet: try it, then make it one.

## Sidebar

| # | Spec | Check |
|---|------|-------|
| S1 | New terminal (cmd-k, cmd-shift-t) opens a new terminal tab for the project, every time (never reuses one). | self: "new terminal: a terminal tab", "new terminal in the second session: another terminal" |
| S2 | Under a project's changes tab: a "changes" row with its changed files, at most the 10 newest by mtime. | self: "its changed files are folded" |
| S3 | A separate "commits" row under it; ⏎ / click folds it open: the last 5 commits (`sha subject`). | self: "⏎ on commits: the last commits under it" |
| S4 | Click or ⏎ on a commit row: the changes tab shows `git show --stat -p` of it. | self: "a click on a commit", "⏎ on a commit too" |
| S5 | A click on a session / project / tab row shows it and gives it the keyboard (type at once). A click on what is shown already, or on a changed file / commit, leaves the keyboard in the sidebar. | self + app: "a click on a session row: typing goes there" (app: real clicks in zidev.app), "a click on it again: the sidebar has the keys" |
| S6 | cmd-click in the sidebar is a plain click. | hand |
| S7 | Sidebar keys: ↑ ↓ move, ⏎ opens, → unfolds / ← folds (a project, changes, commits; ← on a row under a project: to the project, folded), esc drops a pick list. Any other key does nothing. | self: "letters do nothing in the sidebar", "← folds, → unfolds" |

## Palette (cmd-k)

| # | Spec | Check |
|---|------|-------|
| P1 | cmd-k (and ctrl-q, for terminals without zidev's keys) in any zidev pane opens the palette: a popup, type to search, ⏎ picks, esc closes. | self: "ctrl-q opens the palette" · app: "cmd-k opens the palette", "esc closes it" |
| P2 | Empty, it shows what was picked in it last (3) and most (3) that fits here, then the common actions (new session, new project, new terminal, changes, rename session, close tab), then the projects; nothing else. | self: "the empty palette: common actions and projects, no files" |
| P2b | Typing searches everything: all actions (restart Claude, move, close, archive, remove, sidebar, keys), sessions, the project's tabs, archived projects (⏎ unarchives), the project's scripts (⏎ runs in a terminal tab) and files (⏎ previews). | self: "typing finds scripts and files" |
| P2c | What was picked comes on top next time (a file or script only in its project). | self: "what was picked is on top next time" |
| P3 | An action that asks (rename, close, remove) asks in the sidebar, which gets the keys. | self: "palette rename asks in the sidebar" |
| P4 | `>cmd` + ⏎ runs cmd in a terminal tab; ctrl-g greps the project for the typed text. | self: "palette >cmd runs it" |
| P5 | The right-click menu on a row has that row's actions. | self: "right click on a row: a menu with its actions" |

## Clicks in Claude (zidev.app cmd-click)

| # | Spec | Check |
|---|------|-------|
| C1 | An item line `42 y n ? : …` or `8 a b ? : …`: cmd-click on a choice adds `42y ` / `42n ` / `42? ` / `8a ` / `8b ` to the prompt, not sent. | app |
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
| A7 | The app has zidev's keys (cmd-k, cmd-b, …): when `zidev keys` answers nothing at start (zidev being changed), it asks again (every 2 s, 1 min; and when it comes to the front). | app: "the app has zidev's keys" |

## Sessions

| # | Spec | Check |
|---|------|-------|
| N1 | A short tone when a session goes from working to done or error; config `"sound": false` mutes, a path plays that file. | hand |
| N2 | No polling git: FSEvents wake the changes list; tmux hooks wake hidden sidebars. | hand |
