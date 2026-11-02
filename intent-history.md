# zidev — intent history

Replaced or dropped intents from `intent.md`, one dated line each, with what replaced them.

- **2026-10-20** — "Tabs (terminal, commands, git, files) belong to the project…" → the commands tab went into the palette: ZI27 "Tabs (terminal, git, files)…", ZI25.
- **2026-10-20** — "Projects can get a name (r on the project, or zidev rename-project)…" → ZI19: Rename in cmd-k or the right-click menu.
- **2026-10-20** — "…r in the sidebar renames over it until the next /rename. r never pre-fills the long first prompt." → ZI20: Rename in zidev wins over it.
- **2026-10-20** — "Close / Remove from the right-click menu acts at once, no question (x still asks)." → ZI21: from cmd-k it asks.
- **2026-10-20** — "x on a project removes it with its sessions and tabs; x x (one key each, no ⏎) confirms. Every question is one key: the same key again or y." → ZI22.
- **2026-10-20** — "…esc / x drops the list." → ZI58: esc drops the list.
- **2026-10-20** — "…Folding: click ▸ / ▾, or space." → ZI17: or ← / →.
- **2026-10-20** — "A click on a sidebar row opens it and the focus stays in the sidebar: its keys (t, g, …) work next; ⏎ moves the focus to what it opened." → ZI15: the click gives it the keyboard, a second click gives it back.
- **2026-10-20** — "`t` in the sidebar opens a new terminal tab each time." → ZI30: cmd-shift-t; ZI13: the sidebar has few keys.
- **2026-10-20** — "…So does a choice of an item line "42 y n ? : ...": its y is 42y, its number 42." → ZI59: also "8 a b ? : ...", its a is 8a.
- **2026-10-20** — "…tabs on top (All, Files, Actions, Text, Apps), ⇥ switches. Only cmd-k opens it." → ZI68: a Clipboard tab; cmd-k in zidev, shift-shift from any app (ZI73).
- **2026-10-26** — "Close / Remove from the right-click menu acts at once, no question (from cmd-k it asks)." → ZI21: Archive too.
- **2026-10-27** — "…click / ⏎ on the project opens it, folded or not." → ZI17: folded, the session used last.
- **2026-10-27** — "First session is the main one. A project's first session is its main one: click / ⏎ on the project opens it; folded, the session used last." → ZI17: its session used last, folded or not.
- **2026-10-27** — "Branch changes highlighted. File preview highlights what changed on this branch (vs main, incl. uncommitted)." → ZI42: only a green + / red − in the left bar, no green background.
- **2026-10-28** — "cmd-b. cmd-b hides / shows the sidebar." → ZI32: only cmd-b; it shows only while it asks something I started.
- **2026-10-29** — "Stripe shows active projects. Hidden, the sidebar is a thin stripe: the projects active in the last 10 minutes, …" (ZI84) → dropped: too ugly; ZI32: hidden, nothing of it shows.
- **2026-10-29** — "Only cmd-b. cmd-b hides / shows the sidebar; nothing else does. Only while it asks …" → ZI32: hidden, nothing of it shows: clean, no stripe.
- **2026-11-02** — "Done only when merged. `/zidev done` checks that the task is really done: its MR is merged. If not yet, it checks again once an hour until it is." → ZI86: no MR, or closed without merge: it asks.
