<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Secrets — the platform rules `--help` won't tell you

All `secrets` subcommands require `--app <APP>` where `<APP>` is the lowercased repo name. The platform resolves where that app's secrets live in AWS Parameter Store — you never specify a path.

The rules below are platform behavior, not CLI flags, so they are worth reading even after `blankcut secrets --help`:

- **`.env.example` is the gate.** A key must already be declared in this repo's `.env.example` on `main` before the platform will accept a value for it (`not_in_env_example`). `blankcut secrets sync-example` copies key names — **never values** — from your local `.env` into it.
- **Writes are reconcile-safe.** If a key already holds a *different* value the write is held back (`skipped` / `would_overwrite`) rather than clobbering it; re-run with `--force` only if overwriting is intended.
- **`diff` exits 1 on drift** so CI can gate on it, and only ever compares key *names* — values are never sent or printed.

**Keys must be flat.** A secret key may not contain `/` (the platform rejects it) — use `_` (`DB_PASSWORD`, not `DB/PASSWORD`).

**Linux exposure caveat for `run`:** for the duration of the wrapped command, any same-UID process can read its env via `/proc/PID/environ`. This is standard Linux behavior; if a stricter boundary is needed, prefer `pull` to a `0600` `.env` and source it explicitly.

**Deployed apps — a new key reaches the app through a platform change.** Once your app runs in production, its pods receive only the secrets on a per-app allowlist. When you set a key that is **new** to that app, the platform adds it to that allowlist on its own, usually within minutes, and the pod picks up the value on its next sync. So a brand-new production secret follows: declare it in `.env.example` (→ merge) → `set`/`push` the value → the platform adds it → the pod has it. Updating an **existing** key needs nothing more — the new value syncs on its own. If a new secret isn't reaching a running pod, `blankcut status --app <APP>` shows whether that change is still pending.

## Fresh clone — pull existing secrets

```bash
git clone <REPO_URL> && cd <REPO_NAME>
blankcut secrets pull --app <APP>   # writes .env with mode 0600
```

If a key in `.env` already has a different value, the pull refuses by default. Inspect the diff and re-run with `--force` only if intentional.

## Add a new environment variable

**First: is this value read in the browser?** If the key is named `NEXT_PUBLIC_*`, read `public-config.md` (beside this file) — it
is compiled into the bundle at build time, so it also needs a rebuild to take effect, and a GitHub
repo variable is often the simpler route. The steps below are correct for it either way; step 4 is
what differs, because a public value does not wait on a platform change to reach the browser.

1. Declare the key in `.env.example` (names only): add it with an empty value, e.g. `STRIPE_API_KEY=`, or run `blankcut secrets sync-example` to copy missing key names from your local `.env`.
2. Open a PR with the `.env.example` change and merge it to `main`. **This gate must merge first** — otherwise the write is rejected with `not_in_env_example`.
3. Set the value: `blankcut secrets set --app <APP> STRIPE_API_KEY <value>` (or update local `.env` and run `blankcut secrets push --app <APP>`). If the platform already holds a different value, the write is held back as `skipped` / `would_overwrite` — re-run with `--force` only if you intend to overwrite.
4. **If the app is deployed:** the platform adds the new key to your deployment on its own (see "Deployed apps" above), and the pod gets the value on its next sync.
5. `blankcut secrets diff --app <APP>` should report the key as present in both.

## Run the dev server with platform secrets

Prefer this over a hand-edited `.env` in ephemeral environments (CI runners, fresh sandboxes):

```bash
blankcut secrets run --app <APP> -- npm run dev
```

The wrapped process inherits the secrets via env; no file is written. The CLI's own auth credentials (`BLANKCUT_API_KEY`, `AWS_*`) are stripped from the child env.
