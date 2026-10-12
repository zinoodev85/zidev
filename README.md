# zidev

A cmux-style sidebar for Claude Code sessions, on its own tmux server (`tmux -L zidev`).
Projects in a vertical sidebar (Arc-style, no tab bar): each project lists its Claude sessions with live
status, and its tabs: terminals, changes, commands, files. The selected item fills the rest of the window.

Sessions keep running when the terminal closes; after a reboot `zidev` restarts every saved session
with `claude --resume`. Decisions on how zidev should behave: [intent.md](intent.md).

## Install

```
brew install zinoodev85/zidev/zidev
brew install --cask claude-code   # if not there yet
```

Needs macOS and iTerm. Brings tmux, Python and the viewers (bat, delta, glow, micro, eza, fd, fzf, rg).
`zidev doctor` checks the setup. From source: link `zidev` into your PATH (`ln -s $PWD/zidev ~/.local/bin/`).

## App

**zidev.app**: zidev in a window of its own, with its own Dock icon. `brew install` brings it ready built (no Xcode tools needed); `zidev app` puts it
into `~/Applications` and opens it (from source: `app/build.sh` first). Every cmd / alt key reaches zidev directly
(no iTerm profile needed); its colors and font (MesloLGS NF, comes with it) are zidev's iTerm profile's, light or dark as macOS is; a double click on the title bar fills the screen; cmd-click on a `! command` runs it. Built on your Mac, it
runs without an Apple developer account. Closing it leaves the sessions running.

## Start

- `zidev` in iTerm: opens zidev in a new tab with the `zidev` profile (installed by zidev; *Profiles > zidev*
  opens it directly). The profile sends the cmd keys below to zidev; other tabs keep iTerm's own.
- `zidev .` (or any folder): opens zidev on that project, its first session; a new project if it is none.
- `zidev new [dir] [--prompt TEXT]` from any terminal: a new session (and project) for that folder; TEXT is sent as Claude's first message.

## Sidebar

| key | |
|---|---|
| `⏎` / click | show session (Claude) / tab; a project: its first session (folded or not) |
| `space` / click `▸` | fold / unfold a project or the changed files (folded: a spinner while a session in it works) |
| right click | menu of the row: close tab · rename / restart / close session · rename / new session / archive / remove project |
| `j` / `k`, arrows | move; the wheel scrolls the list, the cursor stays |
| `n` / `p` | new session in project / new project (folder) |
| `r` / `x` | rename / close session, tab or project (a project with its sessions); `x x` confirms |
| `R` | restart Claude (resumes its conversation) |
| `J` / `K` | move session down / up |
| `t` / `g` / `c` | terminal tab / changes tab / commands tab |
| `w` | next session that needs you |
| `/`, `esc` | filter sessions, clear filter |
| `h` / `←` | go up: session, project |
| `a` / `A` | archive project / archived: search, unarchive |
| `?` | all keys |

Session names follow Claude: its `/rename`, else the title Claude gives it, else the first prompt.
`r` names it in zidev (empty: Claude's name again) until the next `/rename`. The right-click menu's Close / Remove
don't ask.
Status: spinner working · yellow `●` needs you · green `●` finished, not seen yet · `○` idle.
A terminal tab gets a yellow `●` too when its script stops on a question (`(y/N)`, `password:`, `?`) for 2 s.
macOS notifications when a session off screen needs you or finishes (`{"notify": false}` in `~/.zidev/config.json` turns them off).
Dragging the sidebar border saves its width (`sidebar_w`).
Cursor and scroll are the same in every window (`~/.zidev/view.json`): switching sessions keeps the list still.

## Everywhere

| key | |
|---|---|
| `cmd-b` | hide / show the sidebar |
| `cmd-↑` / `cmd-↓` | item above / below in the project: Claude, terminals, files (not the changes tab) |
| `cmd-t` | terminal next to Claude (again: away) |
| `cmd-shift-t` | new terminal tab under the project |
| `cmd-w` | close the tab or preview |
| `esc` | closes preview, viewer, changes, commands, editor (no `q` anywhere) |
| `ctrl-q` | menu (again: sidebar ⇄ tab) |
| wheel | scrolls the pane under the mouse |

Tabs are full screen; only Claude can have a terminal next to it (`cmd-t`).

## Files

- Click a path in Claude (`src/a.ts:12`, `./notes.md`, a `file://` link): a floating preview at that line.
  Relative paths resolve in the session folder. A bare name (`before-table.png`, `Cart.ts:12`) opens when one file has it: a full path shown earlier, else in the project.
  Several files with it: they list at the top of the sidebar (at most 20); Claude (haiku, in the background) guesses
  which one is meant, that one goes first with `✦`. `⏎` opens, `esc` drops the list. A folder (`anime/v2/`) shows its tree. A plain click on a web link opens the browser.
  A `! command` Claude suggests: a click copies it, a double click types it into Claude's prompt (bash mode), `⏎` is yours. In zidev.app a cmd-click runs it.
- Preview: `esc` closes, `⏎` keeps it as a tab, `e` edits (back to the preview after), `l` line numbers,
  `/` search. Lines changed on this branch (vs main, incl. uncommitted) are marked. Text starts at the top, keys in a gray line at the bottom.
- A file is open at most once in the sidebar; opening it again shows its tab.
- HTML: asks browser or preview. Images and other binary files open in their default app.
- Editor (micro): usual mac keys (cmd-x / c / v, cmd-f, cmd-a, cmd-s, cmd-z / cmd-shift-z), `alt-l` line numbers,
  `esc` leaves and asks `save? y / n` when changed.
- WebStorm keys in the editor: `alt-←/→` word (with shift: select), `cmd-←/→` line start / end (with shift: select),
  `alt-⌫` delete word, `cmd-⌫` / `cmd-y` delete line, `cmd-d` duplicate, `alt-shift-↑/↓` move line, `cmd-/` comment,
  `cmd-l` go to line, `cmd-r` replace, `cmd-g` / `cmd-shift-g` next / previous match.
  alt / cmd arrows and `⌫` also work in Claude's prompt and shells (word / line), no stray characters.
- One color scheme for everything: Dracula (bat, delta, micro, glow).
- `zidev open FILE[:LINE] [--tab]` from any zidev pane.

## Changes tab

The diff of one changed file at a time (delta); scrolling never runs into another file.
Its changed files fold under it in the sidebar (folded at first, with their number): `⏎` on the shown
changes tab unfolds / folds them. The cursor on one shows its diff, `⏎` opens the file as a tab. In the diff: `⏎` opens the file as a tab, `n` / `N` next / previous change, `l` line numbers.

## Commands tab

One fuzzy list: package scripts (pnpm / yarn / bun / npm from the lockfile), `make` targets, then every file
(respects .gitignore), with a live preview.

- `⏎` on a script: runs it in the terminal · `>any command` + `⏎`: runs it
- `⏎` on a file: markdown viewer / editor · `ctrl-e` edit · `ctrl-v` view · `ctrl-g` grep (ripgrep)
- a new name + `⏎` creates the file · recently used first

## CLI

| command | |
|---|---|
| `zidev` | start (restoring saved sessions) or attach |
| `zidev new [dir] [--prompt TEXT]` | new session in dir, TEXT as its first message |
| `zidev rename-project [DIR] NAME` | show a project under NAME (`""`: folder name again); DIR defaults to this session's project |
| `zidev archive DIR` / `unarchive DIR` | hide a project (its sessions stop) / bring it back |
| `zidev list [--json]`, `zidev status` | sessions and their status |
| `zidev start` | server only, no attach |
| `zidev kill` | stop the server; sessions stay saved |
| `zidev reload` | load new code; Claude and terminals keep running |
| `zidev doctor` | check tools, hook settings, state |
| `zidev logs [-f]` | error log |
| `zidev selftest` | end-to-end test on a throwaway tmux server with a fake Claude |

## Developing

- Edit `zidev`, run `zidev selftest` (own socket and home, never touches your sessions), then `zidev kill`
  and open a new zidev window (or `zidev reload`).
- By hand without touching real sessions: `ZIDEV_SOCKET=zidevtest ZIDEV_HOME=/tmp/zh zidev`;
  `ZIDEV_CLAUDE=/path/to/fake` swaps the claude binary.
- Contract for other hosts: run claude with `--settings ~/.zidev/claude-settings.json` and env `ZIDEV_ID=<id>`;
  `zidev hook` writes `~/.zidev/status/<id>.json` (`state`: idle, working, waiting, done, error, exited;
  `detail`, `since`, `claude_id`, `prompt`). `ZIDEV_NOTIFY=0` skips zidev's notification.

## How it works

- `~/.zidev/sessions.json`: projects and sessions. Each session is a tmux window: sidebar + `zidev run ID` (Claude).
- Tabs belong to the project; hidden ones wait in a parked window and swap in when shown.
- Claude gets `--settings ~/.zidev/claude-settings.json` with hooks (`zidev hook`); your global settings stay untouched.

## Limits

- Esc to interrupt Claude fires no hook: the session shows "working" until the next prompt.
- Selection is tmux's (mouse mode): copied on release; iTerm's own cmd-f / cmd-a don't apply inside zidev.
