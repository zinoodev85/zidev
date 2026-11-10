# zidev — intent

Decisions on how zidev should be. Only these.
ZI<n> = one intent; ids are never reused. Replaced or dropped ones: `intent-history.md`.

## Basics

ZI1 **My place for Claude sessions.**
zidev is my place for Claude sessions; build features here, not in Neovim/Neovide.

ZI2 **Keep it simple.**

ZI3 **Light on the Mac.**
zidev is process-light: nothing polls git; the sidebar waits for file and tmux events.

ZI94 **Idle sessions go to standby.**
A Claude session not used for 10 minutes and not busy (not working, no tool running, not waiting on a question) goes to standby: its Claude process stops, it stays listed in the sidebar as before. Clicking it resumes it (claude --resume) in place. A busy session never goes to standby.

ZI95 **Hidden sessions stay quiet.**
A Claude session whose window is not shown does not redraw or use CPU for a screen nobody sees. Claude runs without its spinner animation (prefersReducedMotion).

ZI4 **One color scheme.**
One color scheme for the whole tool (viewer, editor, changes, markdown).

ZI5 **Good in every theme.**
zidev looks good in every terminal theme, light or dark: the selection is a quiet gray bar, never a glaring block.

ZI6 **Add a project with one command.**
Add a project from any terminal with one command.

ZI7 **`zidev .`**
`zidev .` opens zidev on that folder's project, like `code .`.

ZI8 **Start with a task.**
A session can start with its task: zidev new DIR --prompt "…" sends it as Claude's first message (e.g. started from a todo).

ZI9 **A skill for agents.**
An agent skill (~/.claude/skills/zidev) explains zidev to agents; zidev rewrites it on every start so it stays current.

ZI82 **Archived runs nothing.**
An archived project takes no resources: its sessions, tabs and what they started stop; nothing watches it.

ZI85 **`/zidev done`.**
`/zidev done` in a session ends its task: its todo is marked done, its folder is deleted, its project is removed (Remove). With uncommitted or unpushed work it asks first.

ZI86 **Done only when merged.**
`/zidev done` checks that the task is really done: its MR is merged. If not yet, it checks again once an hour until it is. No MR, or closed without merge: it asks.

ZI90 **To Be Merged.**
A project whose `/zidev done` waits for its MR moves into a folded "To Be Merged" group at the bottom of the sidebar. Its sessions keep running. Once merged, it goes (ZI85).

ZI91 **MR row.**
Each project in To Be Merged has an MR row under its session. A click opens the MR in GitLab.

ZI92 **Back to projects.**
Right-click "Back to projects" takes a project out of To Be Merged.

ZI93 **Kept rebased.**
While `/zidev done` waits for its MR, each hourly check rebases the branch onto the MR's target and pushes it, once the target has moved on. The session resolves a conflict itself; if unsure, it asks.

## Done

ZD1 **Done takes an open MR.**
`/zidev done` also takes an MR that is still in review.

ZD2 **AI review first.**
It waits up to an hour for the AI review. Small points it fixes; otherwise it waits for my command.

ZD3 **Then assign.**
Once the AI review is done, it assigns the reviewer, then checks hourly and keeps the MR rebased until merged (ZI86, ZI93).

ZD4 **Reviewer up front.**
The reviewer is given at the beginning; otherwise `/zidev done` asks for it at the beginning.

ZD5 **AI review answered in the MR.**
Each AI review gets a reply in its thread saying what was fixed, then the thread is resolved; me resolving it counts too.

ZD6 **No AI review: assign anyway.**
No AI review within the hour, or none in the repo: it assigns the reviewer anyway and tells me.

ZD7 **One AI re-review.**
After its first fixes it starts the AI re-review once; its points are handled the same way, no third round.

## Links

ZL1 **Links under the session.**
A session lists its task's important links under it in the sidebar, like the MR row: MR, ticket (GitLab, Asana, Jira), mail, artifacts. A click opens it.

ZL2 **Links from its todo.**
A session working on a todo shows the todo's links and its saved mails.

ZL3 **Claude adds links.**
Claude adds a link (`zidev link URL "label"`) when it publishes an artifact, opens an MR or finds the task's ticket.

## Sidebar

ZI10 **No tab bar.**
Arc-style, everything open lives in the vertical sidebar.

ZI11 **Selected shows as selected.**
What is selected always shows as selected.

ZI12 **Shows when I am needed.**
When a human is needed (by Claude or a script), the sidebar shows it.

ZI13 **Few keys.**
The sidebar has few keys: ↑ ↓ move, ⏎ opens, ← → fold / unfold, esc. Everything else: cmd-k or the right-click menu.

ZI14 **Stays still.**
The sidebar stays still: a click opens, never folds or closes anything else; cursor and scroll stay the same when the window changes; no redraw flash.

ZI15 **Click gives the keyboard.**
A click on a session / project / tab row opens it and gives it the keyboard; a second click on it gives the keyboard back to the sidebar.

ZI16 **Right-click menu.**
Right click on a sidebar row: a menu with its actions (close, rename, …); a left click opens it.

ZI17 **A project opens its last session.**
Click / ⏎ on a project opens its session used last, folded or not. Folding: click ▸ / ▾, or ← / →.

ZI18 **Folded project still shows work.**
A folded project shows the spinner while a session in it works, ● while one waits for my answer.

ZI19 **Project names.**
Projects can get a name (Rename in cmd-k or the right-click menu, or zidev rename-project); the folder stays as it is.

ZI20 **Session names follow Claude.**
Session names follow Claude (/rename, else Claude's own title, else the first prompt); Rename in zidev wins over it until the next /rename, and never pre-fills the long first prompt.

ZI21 **Right-click acts at once.**
Close / Archive / Remove from the right-click menu act at once, no question (from cmd-k they ask).

ZI22 **Remove takes all of it.**
Removing a project removes its sessions and tabs. Every question is one key (y).

ZI23 **Short questions.**
Quick prompts ask in the bottom bar, short: save? y / n.

ZI24 **A tone when done.**
A short tone plays each time a session stops working.

## Palette

ZI25 **cmd-k everywhere.**
cmd-k, anywhere in zidev, opens the palette. It replaces the ctrl-q menu, the commands tab, the / filter and the archive popup.

ZI26 **Short and smart.**
The palette is short and smart: on top what I used last and most, then a few common simple actions, then the projects. Typing also finds the rest: other actions, sessions, the project's commands and its files.

ZI67 **Real quick.**
cmd-k opens the palette real quick, no waiting.

ZI68 **Like WebStorm.**
The palette imitates WebStorm's Search Everywhere: tabs on top (All, Files, Actions, Text, Apps, Clipboard), ⇥ switches. cmd-k opens it in zidev, shift-shift from any app.

ZI69 **Text search inside.**
The Text tab searches inside the project's files, live, with a preview; ⏎ opens at the line (no ctrl-g).

ZI88 **All finds text too.**
All searches file names and the text inside the files, like WebStorm.

ZI89 **Search term marked in the preview.**
The preview highlights the search term, not only its line.

ZI70 **Open apps.**
The palette opens apps.

ZI71 **Search Google.**
The palette searches Google: while typing, the last row is "Google: …".

ZI72 **file:line.**
Typing file:line opens the file at that line.

ZI73 **Over any app.**
shift-shift (shift pressed twice) opens only the palette over the app I am in, not the zidev window; that app stays in front. In zidev it opens the cmd-k palette; in WebStorm it stays WebStorm's.

ZI80 **Matches marked.**
The palette marks the letters that match what I type.

ZI81 **Few apps in All.**
All shows at most the 3 best apps; the Apps tab shows all.

## Clipboard

ZI74 **Clipboard history.**
zidev keeps my last 50 copies (text, rich text, images, files), readable only by me; what a password manager marks secret is never kept.

ZI75 **Clipboard tab.**
The palette's Clipboard tab lists them, like WebStorm's Paste from History: searchable, with a preview; ⏎ pastes into the app I was in.

ZI76 **Paste keys.**
ctrl-cmd-1 … 5 paste the last copies (1 = newest) into any app; ctrl-cmd-0 pastes the clipboard as plain text. Pasting changes neither the clipboard nor the history.

ZI77 **Clipboard on a timer.**
The clipboard is the only thing zidev checks on a timer, every 0.5 s.

## Tabs

ZI27 **Tabs belong to the project.**
Tabs (terminal, git, files) belong to the project, shared by all its sessions, listed under the project.

ZI28 **Starts with one Claude session.**
A new project starts with one Claude session, nothing else; a terminal comes with cmd-shift-t and closes like any tab. Changes (its tab with the commits row) are off by default; "Toggle changes" in the palette (shift-shift / cmd-k) or the right-click menu turns them on / off per project (Close on its tab: off), and that stays.

ZI29 **Full screen, never split.**
Tabs are always full screen, never split — except Claude: cmd-t puts a terminal next to it (cmd-t again: away). cmd-shift-t: a new terminal tab under the project.

ZI30 **New terminal each time.**
New terminal (cmd-shift-t) opens a new terminal tab each time.

ZI31 **A file open once.**
A file is open at most once in the sidebar; opening it again shows its tab.

ZI32 **Only cmd-b.**
cmd-b hides / shows the sidebar; nothing else does. Hidden, nothing of it shows: clean, no stripe. Only while it asks something I started (rename, close, which file) it shows, then hides again.

ZI33 **cmd-↑ / cmd-↓.**
cmd-↑ / cmd-↓ move between a project's items in the sidebar: Claude, terminals, files (not the changes tab).

## Changes and commits

ZI34 **One file's diff at a time.**
Changes tab: the diff of one changed file at a time (delta); scrolling never runs into another file; no git client (lazygit was too much). Its changed files are listed under it in the sidebar; the cursor on one shows its diff, ⏎ opens it in the viewer pop-up.

ZI35 **Changed files fold.**
Changed files under the changes tab fold like an accordion: folded at first, showing their number. ⏎ on a changed file (in the sidebar or in its diff) opens it as a file tab.

ZI36 **Last 10 changed files.**
The changes tab lists at most the 10 last changed files (newest first); its count is all of them.

ZI37 **Commits row.**
A changes tab has a commits row under it: it folds open on the last 5 commits; the cursor on one (or a click) shows it in the changes tab.

ZI38 **Click a commit hash.**
A click on a commit hash (50ca04b) in any tab shows that commit in the floating preview, found in the pane's repo or any project's.

## Preview and editor

ZI39 **Preview keys.**
File preview: Esc closes it, Enter keeps it open, e edits (back to the preview after).

ZI40 **HTML: browser or here.**
HTML file: ask "open in browser or preview here?"; browser serves it from a simple local server.

ZI41 **Binary files in their app.**
Images and binary files (movies…): open in their default app.

ZI42 **Changes as + and −.**
The file preview marks what changed on this branch (vs main, incl. uncommitted) only in the left bar: a green + on each added or changed line, a red − where lines were removed. No green background: it looks like the black editor.

ZI43 **Wrap under the indent.**
Long lines in the preview wrap under their own indentation, never into the gutter.

ZI44 **Calm viewing.**
Viewing is calm: text from the top, no ~ filler, a quiet status / keys line at the bottom; it never jumps.

ZI45 **Esc closes everywhere.**
Esc closes everywhere (preview, tabs, editor); no q. Editor asks to save when changed.

ZI46 **Mac keys in the editor.**
Editor has the usual mac keys: cmd-x / c / v, cmd-f, cmd-a, cmd-s, cmd-z / cmd-shift-z, and WebStorm's.

ZI47 **No line numbers.**
No line numbers by default (viewer, editor, changes); l shows them (alt-l in the editor).

## Keys and mouse

ZI48 **Word and line keys everywhere.**
alt / cmd + arrows and backspace move and delete by word / line everywhere (editor, Claude, shell); never stray characters.

ZI49 **Wheel scrolls what is under it.**
The wheel scrolls the pane under the mouse; over the sidebar it scrolls the list (the cursor stays).

ZI50 **Menus work with the mouse.**
Menus work with the mouse: click picks an item, moving the mouse does not close them.

## Clicks

ZI51 **Paths stay out of the browser.**
Clicking a file path never opens the browser; relative paths resolve in the session folder.

ZI52 **file:line.**
Clicking file:line opens the preview at exactly that line.

ZI87 **Line ranges.**
Clicking file:16-23 opens the preview with lines 16–23 highlighted, scrolled into view.

ZI53 **Web links: a plain click.**
A plain click on a web link opens it in the browser (no cmd-click needed).

ZI54 **`! command`: copy or type.**
A `! command` Claude suggests: a click copies it, a double click types it into Claude's prompt; I send it.

ZI55 **Wrapped paths whole.**
Clicking a path or link that wraps over several lines (also Claude's indented wrap at - or /) opens the whole thing.

ZI56 **Bare file names.**
A bare file name the AI mentions (before-table.png, Cart.ts:12) opens on click when exactly one file has it: a full path shown earlier, else the project's files.

ZI57 **Folder paths.**
A folder path (anime/v2/) is a path, not a web link: a click shows its tree in the preview.

ZI58 **Several files, one name.**
A name several files have: they list at the top of the sidebar to pick (at most 20, then "… n more"); the AI is asked in the background which one is meant, that one goes first (✦). esc drops the list.

ZI59 **Reply shorthands.**
cmd-click on a reply shorthand in Claude ("3y", "4n", "5?", "k 461") adds it to the prompt; several are sent together with ⏎. So does a choice of an item line "42 y n ? : ..." or "8 a b ? : ...": its y is 42y, its a 8a, its number 42.

ZI60 **Scrolled back too.**
Clicks read the rows shown, also when the pane is scrolled back.

## App and install

ZI61 **On Homebrew.**
zidev ships on Homebrew: one `brew install` brings it with everything it needs.

ZI62 **Its own Mac app.**
zidev is its own Mac app, its own window and Dock entry; no paying Apple. Its icon: `> zi`, plain and clean (no glow).

ZI63 **App ready built.**
The app comes with brew, ready built (no Command Line Tools); `zidev app` puts it into Applications.

ZI64 **Looks right, nothing to set up.**
The app just looks right on every Mac, nothing to set up: Claude's own colors (as outside tmux), zidev's font; a double click on its title bar maximizes it.

ZI65 **cmd-click runs.**
In the app, cmd-click on a `! command` runs it.

ZI66 **Global hotkey.**
A global hotkey shows / hides the zidev app (config "hotkey", default cmd-cmd: cmd pressed twice; or a combo like "alt-space"); Window > Float on Top keeps it above other apps.

ZI78 **Starts at login.**
zidev.app starts at login.

ZI79 **Keeps running.**
zidev.app keeps running when its window closes or zidev ends, so the clipboard and the keys keep working.

ZI83 **Says when a permission is missing.**
When macOS does not allow what shift-shift / cmd-cmd need, the app says so and opens that setting.
