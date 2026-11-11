<!-- BEGIN BLANKCUT PLATFORM: rev b52a799b9155 — managed by `blankcut sync`; do not edit inside this block -->

# Blank Cut Platform

This block is written into every repo by the Blank Cut scaffolder (`blankcut init` locally, or `POST /init` from the Meerkat onboarding flow) and refreshed in place by `blankcut sync`. The content between the BLANKCUT PLATFORM markers is **identical in every onboarded repo** and is owned by the Blank Cut team at [`Blankcut/blankcut-cli`](https://github.com/Blankcut/blankcut-cli); do not edit inside the markers — changes there are overwritten on the next `init` or `sync`. Repo-specific notes live outside the block and are always preserved.

It lives in `AGENTS.md` so that every coding agent reads it; `CLAUDE.md` imports this file for Claude Code. The longer guides it points to (§ 5) are in `.agents/skills/blankcut/`, and are platform-owned in the same way.

The `rev` in the BEGIN marker identifies the revision of this block and its guides. `blankcut sync` compares them against the copies built into your CLI, so checking whether they are current costs nothing and needs no network.

If you are an LLM agent reading this file, treat the rules below as binding for the duration of any work in this checkout.

---

## This repo is scaffolded. It is NOT deployed.

`blankcut init` put this file here, and **`init` does not deploy anything.** It scaffolds the
platform layout and opens a PR. Merging that PR changes no running system, because there is nothing
running yet — and there is no build workflow in this repo at all until `promote` generates one.

Deploying is a **separate second step**:

```bash
blankcut promote --repo <THIS_REPO_URL>   # first deploy: generates CI + the deploy config
blankcut status --app <APP>               # the only honest answer to "is it live?"
```

A merged `init` PR is not a deployment. Neither is a green `promote` on its own: promote *proposes*
the change: a PR on this repo when the build workflow changes, and a deploy change on the platform
side, and **both have to land** before anything runs. The deploy guide (§ 5) has the full sequence and
what promote does server-side.

**Agents: if the user asks why their app is not up, check this first.** For a freshly onboarded
repo the answer is usually that `promote` was never run — the PR merged, CI showed green on an
unrelated workflow, and everything looked finished. `blankcut status --app <APP>` settles it in one
call; do not infer deployment from a merged PR.

---

## 0. Start of session — get current, then refresh these files

The CLI is released frequently, and **new releases add commands**. Two things can be stale: the binary you have, and the command index in § 4 of this file. Run both checks at the start of any session that will use `blankcut`:

```bash
blankcut upgrade --check   # network: reports current vs latest, and what changed. Installs nothing.
blankcut upgrade           # only if an update was reported
blankcut sync              # local, no network: rewrites the Blank Cut block here and its guides. No-op if already current.
```

`blankcut upgrade --check` lists the features added since your build, so it is the fastest way to learn what the platform can newly do. `blankcut sync` then rewrites the managed block below — **including the § 4 command index** — and the guides in `.agents/skills/blankcut/` from the binary you now have. It touches no other file in the repo and leaves everything outside the markers alone. Run it after every upgrade.

`blankcut --version` prints the build you have. If `blankcut` isn't installed yet, see § 2.

**Why this matters for you specifically:** § 4 lists what the CLI can do, and § 8 tells you not to invent commands. If this file is older than your binary, that combination will make you conclude a capability doesn't exist when it shipped weeks ago. `blankcut sync` is the cheap fix — it is local, takes no arguments, and does nothing when already current.

**Then, before you write code that touches infrastructure, run `blankcut context --app <APP>`** — the resource envelope, the database's connection limit and schema, and which secret keys actually reach the running pod. Guessing at those produces code that looks right and fails in production. The environment guide (§ 5) explains what it returns and the four things that will otherwise bite you.

**If `blankcut` isn't installed, install it (§ 2) before going further** — it needs no GitHub login or special access. If installing genuinely fails, report the exact error once and carry on with the work that doesn't need the CLI; do not look for the binary anywhere other than the channels in § 2.

---

## 1. What the Blank Cut CLI is

`blankcut` is the single CLI that connects this repo to the Blank Cut platform: AWS Parameter Store for secrets, a brokered container build that pushes to GCP Artifact Registry, EKS + ArgoCD for deploys, plus the hosted Meerkat API at `https://api.blankcut.com` (formerly `agent.blankcut.com`, which still works) that orchestrates the multi-step flows.

Broadly it covers scaffolding a repo into the platform layout, validating that the repo meets the platform's requirements, managing secrets without ever putting values in git, provisioning projects and their backing services, promoting an app to production, and reporting live status back.

**§ 4.1 has the authoritative list** of what this build actually ships — read it there rather than relying on this paragraph, which is a summary and will always lag the binary.

---

## 2. Installing the CLI

No GitHub login or special access is needed. Pick one:

```bash
# macOS or Linux with Homebrew (newer Homebrew asks you to trust the tap once):
brew install blankcut/tap/blankcut

# Anywhere with curl -- Linux, CI, containers, agent sandboxes. Fetch, THEN run:
# piping a failed download straight into bash runs an error page instead.
curl -fsSL https://raw.githubusercontent.com/Blankcut/blankcut-cli-releases/main/install.sh \
  -o /tmp/blankcut-install.sh && bash /tmp/blankcut-install.sh

# Verify
blankcut --version
```

The installer checks the download against the release's `checksums.txt`, and checks that file's
signature too when `cosign` is installed. It installs to `/usr/local/bin` (asking for sudo only if
needed); set `BLANKCUT_INSTALL_DIR=~/bin` to choose another directory. Keep it current with
`blankcut upgrade` — a Homebrew install tells you to use `brew upgrade blankcut` instead.

**The only distribution channels are the Homebrew tap and
[`Blankcut/blankcut-cli-releases`](https://github.com/Blankcut/blankcut-cli-releases).** Do not
download the binary from anywhere else.

---

## 3. Signing in

```bash
blankcut login
```

It prints a short code and opens a browser; a person approves the code there, and the CLI stores an API key in `~/.blankcut/config.json` on its own. The key is never displayed and is never copied or pasted. **Do not commit that file.**

- **If you are an agent working with a person:** you may run `blankcut login`, but you cannot approve it — they must. Relay the URL and the code to them verbatim, ask them to approve in their browser, and wait: the command polls for up to 15 minutes, so run it with a long timeout. Never try to approve it yourself or to find a key some other way.
- **In CI, or with no person present:** do not run `blankcut login`. Set `BLANKCUT_API_KEY` in the environment instead.
- **Every command acts for the organization you signed in to.** `blankcut whoami` shows which. When a command answers `API key is not authorized for app '<name>'`, run `blankcut whoami` first.

The sign-in guide (§ 5) covers machines with no browser, rotating a key, a key that was replaced, and switching organization.

---

## 4. Command reference

The CLI has two flavors of commands. **Local** commands operate purely on the working directory and need nothing but the binary (`init`, `validate`, `configure`, `sync`). **Remote** commands talk to `https://api.blankcut.com` and need a configured API key.

### 4.1 Every command the CLI ships

<!-- BEGIN GENERATED COMMAND INDEX: generated from the CLI's own command tree by `go generate` in Blankcut/blankcut-cli — edits inside this region are overwritten -->
| Command | Purpose |
|---|---|
| `blankcut configure` | Store CLI credentials at ~/.blankcut/config.json |
| `blankcut context <subcommand>` | Show the real environment this app runs in, for grounding a coding agent |
| `blankcut database <subcommand>` | Manage the app's managed Postgres |
| `blankcut deprovision` | Tear down an app: delete its secrets and remove its deployment |
| `blankcut diagnose` | Explain why a deployment is unhealthy, in plain language |
| `blankcut domains <subcommand>` | Buy, transfer and connect custom domains, and manage their DNS |
| `blankcut init` | Scaffold the platform layout here (does NOT deploy — run promote next) |
| `blankcut keys <subcommand>` | Manage an app's CI API key (the repo's BLANKCUT_API_KEY) |
| `blankcut login` | Sign in and store an API key for this machine |
| `blankcut onboard` | Connect an existing GitHub repo to Blank Cut: register the app and open its setup PR |
| `blankcut promote` | Deploy the current main of an app, and follow it until it is live |
| `blankcut provision` | Create a new project (repo + opinionated starter + backing services) |
| `blankcut redis <subcommand>` | Turn the managed Redis on or off for an app |
| `blankcut scan <subcommand>` | Show this app's image vulnerability findings and what fixes them |
| `blankcut schedule <subcommand>` | Run one of the app's endpoints on a recurring schedule |
| `blankcut secrets <subcommand>` | Manage secrets for an app in AWS Parameter Store |
| `blankcut status` | Show aggregated CI/CD/runtime status for an app |
| `blankcut storage <subcommand>` | Manage the app's file storage |
| `blankcut sync` | Refresh the Blank Cut guidance for coding agents in this repo |
| `blankcut upgrade` | Update the blankcut CLI to the latest release |
| `blankcut validate` | Run platform readiness checks against the current repository |
| `blankcut whoami` | Show which account and organization this CLI acts for |
<!-- END GENERATED COMMAND INDEX -->

**This index tells you what exists; the binary tells you how to call it.** For flags, defaults, and subcommands, run `blankcut <command> --help` — that output comes from the binary you actually have, so it cannot be out of date. Prefer it over anything written here.

If the index above looks older than your binary, run `blankcut sync` (see § 0) — it rewrites this block in place.

---

## 5. Guides — open the one for the task before you start it

The detail for each area is in a guide under `.agents/skills/blankcut/references/`, so that this file stays short enough for every agent to load in full. Together they are the `blankcut` skill: an agent that supports skills loads it when a task matches, and any agent can open a guide by its path.

**Open the guide before doing the work it covers.** The rule beside each one holds whether or not you have opened it.

| When you are about to | Guide | The rule that always holds |
|---|---|---|
| Sign in, switch organization, or fix a rejected key | `sign-in.md` | An agent never approves a login and never looks for a key another way (§ 3). |
| Write or change code that touches infrastructure (database, memory, replicas, routes) | `environment.md` | Run `blankcut context --app <APP>` first. The memory limit is a hard ceiling, and a connection pool is multiplied by every replica of every workload. |
| Add, change or read secrets and environment variables | `secrets.md` | A key must be in `.env.example` on `main` before the platform accepts a value for it. Keys are flat (no `/`). Never emit a value (§ 6). |
| Deploy, or work out why a deploy is not live | `deploy.md` | `promote` proposes a change; nothing is live until `blankcut status --app <APP>` says so. Never add registry or cloud credentials to the build workflow. |
| Store files or uploads | `storage.md` | No AWS access keys anywhere in the app, and every object key starts with `STORAGE_PREFIX`. |
| Run something on a timer | `schedules.md` | A schedule calls an endpoint this app serves, authenticated with `BLANKCUT_CRON_SECRET`, no more often than every 5 minutes. |
| Use a value in the browser (`NEXT_PUBLIC_*`) | `public-config.md` | It is compiled in at build time, so changing it needs a rebuild. Anything under that prefix is public: never a secret. |
| Fix image vulnerabilities, or a build the scan blocked | `scan.md` | Fix by upgrading the named package. Never work around the scan; request a waiver only for what cannot be fixed yet. |
| Buy, transfer or connect a domain | `domains.md` | Show the person the price and get their go-ahead before passing `--yes`. Never ask for, write down or pass on a transfer code. Never hand-edit routing config. |
| Create a new project | `new-project.md` | `blankcut provision` spends money from the moment it runs. Only when the user asks for a new project, and never retry a refusal. |

**When something is broken**, start with `blankcut status --app <APP>` for the facts and `blankcut diagnose --app <APP>` for the likely cause; `deploy.md` has the rest.

---

## 6. Hard rule — never emit secret values

Secrets must NEVER appear in any of the following channels, in any form, under any circumstance:

- chat messages or commit messages
- PR titles or descriptions
- issue, review, or thread comments
- code comments
- documentation pages, READMEs, runbooks
- error messages, log lines, stack traces
- test fixtures, snapshots, golden files
- scaffolded examples, demo data, mock payloads
- any committed file other than `.env*` files that are gitignored

If you observe a value (e.g. in a stack trace, a test fixture, an existing file), redact it before any further mention as `<REDACTED:KEY_NAME>` and do not propagate the raw value. This rule applies to outputs you generate AND to existing values you encounter in the repo.

When in doubt: don't print the value, don't paste it, don't include it. The CLI's `secrets run -- <cmd>` is the right tool when a command needs the value but you don't.

---

## 7. Supported stacks & services — the platform contract

Blank Cut runs a deliberately small, opinionated set of stacks so every app gets the same guarantees (build, deploy, health, secrets). An app is checked against this contract at onboarding; apps outside it are rejected or held for manual review.

**Supported application stacks**

- **Node.js** — Next.js and Vite are first-class; Express / Fastify / NestJS APIs run too.
- **Python** — Flask, FastAPI, Django.
- **Go**.

**Provided backing services** (use these — don't bring your own):

- **PostgreSQL**, preferably **Supabase** (managed per app).
- **Redis** (in-cluster per app).

**Rules for any work in this repo**

- Stay within the supported stack. Do **not** introduce a different language/runtime, or a framework the platform doesn't run.
- Do **not** add infrastructure the platform doesn't provide (other databases, message brokers, search engines, etc.). If you think you need one, stop and ask — it likely means this app isn't a fit, or the capability should be requested from the platform team.
- Every service runs as a container and must expose a **`/health`** endpoint that returns 200 when healthy.
- Declare every environment variable the app needs in **`.env.example`** — that file is the allowlist the platform's secret store enforces. Public (`NEXT_PUBLIC_*`) keys belong there too; the public-config guide (§ 5) says how they reach the build.
- Builds must be safe to run unattended: no piping downloaded scripts into a shell, no install-time hooks that fetch + execute, base images only from trusted registries. The onboarding gate flags these and pauses the app for review.

This keeps the fleet consistent and lets the platform actually support what you ship.

---

## 8. Where to look for more

- **Public docs — start here:** [docs.blankcut.com](https://docs.blankcut.com) — CLI reference, install/upgrade, the secrets workflow, and the supported-stack contract. For an agent, [docs.blankcut.com/llms.txt](https://docs.blankcut.com/llms.txt) lists every page with a link to a plain Markdown copy.
- **Web console:** [meerkat.blankcut.com](https://meerkat.blankcut.com) — create your account and projects, and issue the API key the CLI uses.
- **CLI releases, installer and license:** [`Blankcut/blankcut-cli-releases`](https://github.com/Blankcut/blankcut-cli-releases); Homebrew tap [`Blankcut/homebrew-tap`](https://github.com/Blankcut/homebrew-tap).
- **Architecture, service API surface, and wire contracts** (private; platform maintainers): see `docs/` and `contracts/` in [`Blankcut/blankcut-cli`](https://github.com/Blankcut/blankcut-cli).

Do not invent flags or endpoints. But **"not written above" is not proof it doesn't exist** — this file is a snapshot, and the CLI gains commands between refreshes. Before concluding the platform can't do something, check the binary, which is always authoritative:

```bash
blankcut --help              # every command this build ships
blankcut <command> --help    # its flags, defaults, and subcommands
blankcut sync                # refresh § 4 above and the guides if they look older than your binary
```

If it isn't in `blankcut --help` either, then ask rather than guessing.

<!-- END BLANKCUT PLATFORM -->
