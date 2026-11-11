<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Image vulnerabilities — `blankcut scan`

Every image the platform builds is scanned (Trivy) **before** it is pushed, and the images that are
running are re-scanned on a schedule. Only findings **with a published fix** are reported, so every
one of them is actionable.

```bash
blankcut scan            # JSON when piped -- every finding, its package, installed and fixed version
blankcut scan --app <APP>
```

To fix them:

1. **OS packages** (`"class": "os-pkgs"`) — move the Dockerfile's `FROM` to a newer patch of the same
   base image, or upgrade the package in the Dockerfile (`apk upgrade --no-cache <pkg>` /
   `apt-get install --only-upgrade <pkg>`). One base-image move usually clears most of them.
   If a rebuild leaves an Alpine finding whose `fixed` version is already published, the build
   cache reused the upgrade step: a `RUN` whose text has not changed is not run again. The
   platform's Dockerfile has `ADD https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/APKINDEX.tar.gz /tmp/apkindex.tar.gz`
   on the line before its `apk upgrade`, which makes that step re-run whenever Alpine publishes.
   Add it if yours lacks it, and keep it.
2. **App dependencies** (`"class": "lang-pkgs"`) — bump the package to the `fixed` version in the
   lockfile named by `target` (`npm install <pkg>@<fixed>`, `go get <module>@<fixed>`,
   `pip install '<pkg>>=<fixed>'`), then run the tests. Prefer the smallest bump that reaches the
   fixed version.
3. Push. The next build is scanned again; `blankcut scan` shows the new result.

Work most-severe first, and soonest **fix-by date** first. Each open CRITICAL/HIGH finding has one,
three days after the platform first saw it; `blankcut scan` prints it, or `OVERDUE since <date>`.
The **policy** in the output says whether this app's builds are blocked. Under `block`, a build is
built but **not pushed** — the CI run fails with "image scan blocked the push" — when it adds an
unwaived CRITICAL/HIGH finding, or when a finding that was already there is past its fix-by date.
A finding the running app already had does not stop the next build before its date. `running`
findings that are not in the last build are CVEs published since the image was built — a rebuild
picks up their fixes.

If a finding cannot be fixed yet — no release of the package fixes it, or the fixed release breaks
the app and you have tried — do not work around the scan. Request a **waiver** for that one finding,
with the reason, and tell the user you did:

```bash
blankcut scan waive --vuln <id> --pkg <pkg> --reason "<why it cannot be fixed yet>"
blankcut scan waivers          # this app's waivers and their status
```

`--vuln` and `--pkg` are the finding's `id` and `pkg` exactly as `blankcut scan --json` reports
them. A request changes nothing until the Blank Cut team approves it (they are notified); approvals
usually expire, so the finding comes back for review. If the finding still cannot be fixed when its
waiver is about to lapse, request it again in its last 14 days, saying why; the approval stays in
force while the renewal is reviewed. Rules:

- **Fix first.** A waiver is for what cannot be fixed, not for what is inconvenient. "The build is
  blocked" is not a reason — upgrading the package is the fix.
- **One finding per request, and only real ones.** The request is refused unless the finding is in
  the app's current scan; never request one per finding to clear a report.
- **Say what you tried.** The reason is what the reviewer decides on: name the release you need and
  why it is unavailable, or what broke when you upgraded.

Help from the Blank Cut team (billed as support time) is requested from the app's Security panel in
Meerkat.
