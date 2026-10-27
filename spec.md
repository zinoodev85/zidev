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
| S8 | A paste on the sidebar goes into what its window shows (the session), which then has the keys; never read as sidebar keys. | self + app: "a paste on the sidebar goes into the session" (app: a real cmd-v in zidev.app) |
| S9 | Close / Archive / Remove from the right-click menu act at once, no question (from cmd-k they ask: P3). | self: "right-click Archive: no question, its sessions stop, it leaves the sidebar" |
| S10 | ZI17: a click or ⏎ on a project opens its session used last (whose window was shown last), folded or not, also from another project's window; nothing switches away after. The project stays folded or unfolded. | self: "click on a project: its session used last (…)", "a folded project opens its session used last too, stays folded", "a click on a project from another window: …" |

## Palette (cmd-k)

| # | Spec | Check |
|---|------|-------|
| P1 | cmd-k (and ctrl-q, for terminals without zidev's keys) in any zidev pane opens the palette at once (~0.07 s): a popup, type to search, ⏎ picks, esc closes. Session names come from the cache the sidebar and each palette keep (`titles.json`; per transcript the one read furthest stays), not from reading whole transcripts; keys start zidev from its kept compiled code (`~/.zidev/pyc`). | self: "ctrl-q opens the palette", "the sidebar keeps Claude's names for the palette" · app: "cmd-k opens the palette", "esc closes it" |
| P2 | Empty, it shows what was picked in it last (3) and most (3) that fits here, then the common actions (new session, new project, new terminal, changes, rename session, close tab), then the projects; nothing else. | self: "the empty palette: common actions and projects, no files" |
| P1b | Like WebStorm's Search Everywhere: tabs on top, All · Files · Actions · Text · Apps · Clipboard; ⇥ / ⇧⇥ switches, what is typed stays. ⇧⇧ opens it too (A8); no other WebStorm shortcuts (no ⌘⇧O, ⌘⇧A, ⌘⇧F, ⌘E). | self: "⇥ to Text: …", "⇧⇥ to Apps: …", "⇧⇥ to Clipboard: …" |
| P2b | Typing in All searches everything: all actions (restart Claude, move, close, archive, remove, sidebar, keys), sessions, the project's tabs, archived projects (⏎ unarchives), the project's scripts (⏎ runs in a terminal tab), its files (⏎ previews) and the Mac's apps (⏎ opens; All lists the 3 best, Apps all: ZI81). Files, Actions (with the scripts) and Apps list only theirs, also empty. | self: "typing finds scripts and files", "⇧⇥ to Apps: it finds the Mac's apps", "⏎ opens the app", "typing, All lists 3 of 5 apps …" |
| P2d | Typing in All: the last row is always "Google: …"; ⏎ on it opens the Google search in the browser. | self: "typing: the last row searches Google", "⏎ on it opens the search in the browser" |
| P2f | ZI80: the letters that match what is typed are marked in the rows (for `file:line` the file's); in Text ripgrep marks the match. | self: "what is typed is marked in the rows" |
| P2e | ⏎ right after typing picks from the rows for what was typed (it waits for them), never from the rows shown before. | self: "a script from the palette runs in the terminal tab" |
| P2c | What was picked comes on top next time (a file or script only in its project). | self: "what was picked is on top next time" |
| P3 | An action that asks (rename, close, remove) asks in the sidebar, which gets the keys. | self: "palette rename asks in the sidebar" |
| P4 | `>cmd` + ⏎ runs cmd in a terminal tab. `file:line` + ⏎ opens the file at that line. | self: "palette >cmd runs it", "file:line: ⏎ opens the file at that line" |
| P4b | The Text tab searches inside the project's files as you type (ripgrep), with a preview at the line; ⏎ opens the file at that line. | self: "⇥ to Text: it finds a line in the files; ⏎ opens it there" |
| P5 | The right-click menu on a row has that row's actions. | self: "right click on a row: a menu with its actions" |

## Clipboard (zidev.app)

| # | Spec | Check |
|---|------|-------|
| K1 | zidev.app keeps the last 50 copies (text, rich text, images, files: each of their types up to 20 MB) in `~/.zidev/clips`, folder 0700, files 0600: `index.json` newest first, one `<id>.plist` per copy. The same copy again moves to the top, never twice. | app: "the clipboard put back is kept, on top, readable only by me" |
| K2 | A copy a password manager marks secret (`org.nspasteboard.ConcealedType`, `TransientType`, `AutoGeneratedType`, 1Password's) is never kept. | app: "a copy a password manager marks secret is not kept" |
| K3 | The clipboard is the only thing checked on a timer: its change count, every 0.5 s. | hand |
| K4 | The palette's Clipboard tab lists the copies, newest first, with the app and when; searchable, with a preview. ⏎ on a text in zidev types it into the tab (from the sidebar: into the tab beside it). An image or files, or any copy from the panel over another app: zidev.app pastes it into the app in front. | self: "⇧⇥ to Clipboard: it lists the copies", "⏎ on a text from the sidebar: …", "not into the sidebar", "⏎ on an image: zidev.app pastes it", "float: ⏎ on a text, …" |
| K5 | ctrl-cmd-1 … 5 paste copy 1 … 5 (1 = newest) into the app in front; ctrl-cmd-0 pastes the clipboard as plain text. A paste is cmd-v once the keys are up; 0.5 s later the clipboard is put back, the history stays as it was. Without Accessibility the copy stays on the clipboard, to paste by hand. | hand |

## Clicks in Claude (zidev.app cmd-click)

| # | Spec | Check |
|---|------|-------|
| C1 | An item line `42 y n ? : …` or `8 a b ? : …`: cmd-click on a choice adds `42y ` / `42n ` / `42? ` / `8a ` / `8b ` to the prompt, not sent. | app |
| C2 | cmd-click on the number an item line starts with (`42.`, `– 10a:`) adds just the number. | app (number) · hand (10a) |
| C3 | cmd-click on a shorthand in text (`3y`, `461k`, `k 4`, `k 1 2 3`) adds it, not sent. | app |
| C4 | cmd-click on a `! command` types it into Claude and runs it. | app |
| C4b | A `! command` whose last word moved to the next row whole (a long hash) is all of it, clicked on either row. A row that ends with a whole word at the edge (`sed`, then `-e` on the next row) keeps the space; only a word too long for a row of its own is joined without one. | app + self: "a `! command` whose row ends with a whole word at the edge: the space after it stays" |
| C4c | An inline `` `! command` `` whose `!` ends a prose row and goes on (same color) on the next rows: all of it, clicked on any of its rows. | app |
| C5 | Clicks hit the row under the mouse, also with blank rows on top or the pane scrolled back. | app (blank top row) |
| C6 | A click on a commit hash (`50ca04b`) in any tab shows that commit in the floating preview; found in the pane's repo, any project, or a repo next to one. | hand |

## zidev.app

| # | Spec | Check |
|---|------|-------|
| A1 | cmd pressed twice (each alone, < 0.3 s held, < 0.4 s apart): zidev in front → hidden; else → shown in front. | app |
| A2 | Not a double tap: two taps far apart; cmd used with a key (cmd-c) in between. | app |
| A3 | cmd-cmd works from any app: Input Monitoring allowed and the event tap on; allowed later, it starts without a restart. | app (live) |
| A4 | Config `"hotkey"`: `cmd-cmd` (default), `alt-alt`, `ctrl-ctrl`, or a combo (`ctrl-alt-z`); `""` none. shift-shift is the palette's (A8). | hand |
| A5 | Window › Float on Top keeps it above other apps; remembered. | hand |
| A6 | Builds keep their signature ("zidev local", `app/signing.sh` once), so macOS keeps Input Monitoring across builds. | hand |
| A7 | The app has zidev's keys (cmd-k, cmd-b, …): when `zidev keys` answers nothing at start (zidev being changed), it asks again (every 2 s, 1 min; and when it comes to the front). | app: "the app has zidev's keys" |
| A8 | shift-shift (shift pressed twice): zidev in front → the cmd-k palette. Another app in front → only the palette, in a small panel near the top of the screen under the mouse; that app stays in front; esc, a pick or a click elsewhere closes it. A JetBrains app in front: nothing (⇧⇧ stays its own). The panel starts zidev from its compiled code, no login shell first (`zidev palette-argv`, asked at start; through the shell when its files moved). | app: "shift-shift in zidev: the cmd-k palette", "shift-shift over another app: …", "esc closes the panel" |
| A9 | From the panel, a pick for zidev's window (a session, an action, a file) brings zidev to the front; an app or Google does not. | self: "float: something for zidev's window brings it to the front" |
| A10 | zidev.app starts at login: registered once, when it runs from Applications (`zidev app`); switched off in System Settings, it stays off. | hand |
| A11 | zidev.app keeps running without its window (ZI79): the close button hides the window, zidev stays in it. zidev ending (detached, `zidev kill`) hides it; zidev starts again when the window shows (Dock, cmd-cmd). Only Quit ends the app; `zidev app` quits the running one, then opens the new one. | app: "the close button hides the window, the app keeps running", "shown again (Dock, cmd-cmd): zidev still in it" · hand: zidev ending |

## Sessions

| # | Spec | Check |
|---|------|-------|
| N1 | A short tone when a session goes from working to done or error; config `"sound": false` mutes, a path plays that file. | hand |
| N2 | No polling git: FSEvents wake the changes list; tmux hooks wake hidden sidebars. | hand |
| N3 | ZI82: an archived project runs nothing: its sessions and tabs stop (saved, back on unarchive), and so does what they left running: all its panes started, and orphans (their parent gone) working in its folder, not in a project inside it. Never a tmux server or zidev itself. Remove stops the same; `zidev archive` on an archived project stops what still runs for it. The sidebar stops its FSEvents watch on a repo it no longer lists (archived, removed, folded). | self: "archive: its tabs stop too", "archive: what it left running stops (…)", "archive: what runs for another project keeps running", "unarchive: session and terminal back" |
