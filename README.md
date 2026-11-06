# plasma-gh-widget

A small KDE Plasma 6 widget that shows your GitHub work at a glance, using the
GitHub CLI (`gh`) you're already logged in with. No extra tokens needed.

- **Review requested**: open PRs waiting for your review
- **My open PRs**: your most recently updated open PRs with CI status
  (✓ passed · ✗ failed · ● running · – no checks)
- **Notifications**: unread count (50+ when there are more), opens github.com/notifications

On the desktop it shows the full list. In a panel it's an icon with a badge:
accent colour = reviews waiting, red = your PRs with failing CI. Click any PR to
open it in your browser.

## Requirements

- KDE Plasma 6
- [`gh`](https://cli.github.com/), logged in (`gh auth login`)
- `jq`

## Install / update

```bash
./install.sh
```

Then add it: right-click the desktop or a panel → **Add or Manage Widgets…** →
search for **GitHub PRs**.

To remove: `kpackagetool6 -t Plasma/Applet -r dev.milan.ghwidget`

## Settings

Right-click the widget → **Configure GitHub PRs…**

- Refresh interval (default 5 minutes)
- Pull requests per list (default 10)

## How it works

`package/contents/code/fetch.sh` runs one GraphQL query with `gh api graphql`
(your open PRs with their latest CI rollup, plus a search for PRs requesting your
review) and reads the notifications count, then prints a single JSON object. The
QML in `package/contents/ui/` runs that script on a timer through Plasma's
`executable` data engine and renders the result.

Run the script directly to debug:

```bash
bash package/contents/code/fetch.sh 5 | jq
```

## Development

After editing, run `./install.sh` again, then restart Plasma to reload it:

```bash
systemctl --user restart plasma-plasmashell
```

Errors show up in `journalctl --user -u plasma-plasmashell -f`.
