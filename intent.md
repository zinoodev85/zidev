# zidev — intent

Decisions on how zidev should be. Only these.
ZI<n> = one intent; ids are never reused. Replaced or dropped ones: `intent-history.md`.

## Basics

ZI1 **My place for Claude sessions.**
zidev is my place for Claude sessions; build features here, not in Neovim/Neovide.

ZI2 **Keep it simple.**

ZI3 **Light on the Mac.**
zidev is process-light: nothing polls git; the sidebar waits for file and tmux events.

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

ZI17 **First session is the main one.**
A project's first session is its main one: click / ⏎ on the project opens it, folded or not. Folding: click ▸ / ▾, or ← / →.

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

ZI28 **Always a terminal and changes.**
Every project always has a terminal and a changes tab.

ZI29 **Full screen, never split.**
Tabs are always full screen, never split — except Claude: cmd-t puts a terminal next to it (cmd-t again: away). cmd-shift-t: a new terminal tab under the project.

ZI30 **New terminal each time.**
New terminal (cmd-shift-t) opens a new terminal tab each time.

ZI31 **A file open once.**
A file is open at most once in the sidebar; opening it again shows its tab.

ZI32 **cmd-b.**
cmd-b hides / shows the sidebar.

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
Every project has a commits row under its changes tab: it folds open on the last 5 commits; the cursor on one (or a click) shows it in the changes tab.

ZI38 **Click a commit hash.**
A click on a commit hash (50ca04b) in any tab shows that commit in the floating preview, found in the pane's repo or any project's.

## Preview and editor

ZI39 **Preview keys.**
File preview: Esc closes it, Enter keeps it open, e edits (back to the preview after).

ZI40 **HTML: browser or here.**
HTML file: ask "open in browser or preview here?"; browser serves it from a simple local server.

ZI41 **Binary files in their app.**
Images and binary files (movies…): open in their default app.

ZI42 **Branch changes highlighted.**
File preview highlights what changed on this branch (vs main, incl. uncommitted).

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
