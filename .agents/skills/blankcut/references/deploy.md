<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Promotion — what `promote` actually does

`blankcut promote` is not a single API call: it starts a multi-step job on the platform and streams the phase transitions until the job reaches a terminal state. Server-side the job clones the repo, runs the analyzer to identify services + ports + container images, generates `build-and-push.yml`, opens a PR on this repo when the workflow file changes, and proposes the deploy on the platform side. **The PR and the deploy still have to land** — a green `promote` means the change is proposed, not that it is live. The platform checks a deploy and applies it, usually within minutes; `blankcut status --app <APP>` shows what is still pending, and says what to do when a deploy is waiting on you. Don't report a platform-side wait to the user as a blocker they must clear: if `status` says there is nothing to do on their side, there isn't.

**Where the build runs is the platform's choice, not this repo's.** The generated workflow holds no
cloud credentials and names no builder: it uploads the source and asks the platform to build it.
The platform resolves the backend per app and can move an app between backends without a commit
here. So do not add registry credentials, cloud roles or a builder-specific step to
`build-and-push.yml` — the workflow cannot reach the registry by design, and anything that needs to
change about the build belongs in the `Dockerfile`.

**Every image is scanned for known vulnerabilities before it is pushed, and your build output is
where you read the result.** The build job reports a line like
`Image scan: recorded - 0 critical, 3 high, 7 medium`, then each finding as
`HIGH <package> <installed> -> <fixed> (<CVE>)`, and writes the same list to the run summary on the
Actions page. Every count is a finding that **has a published fix** — the scan excludes advisories
with nothing to upgrade to, so each line is something you can act on.

Act on it by moving the named package to the named version, in this order of preference:

1. **Refresh the lockfile** — if the fixed version is inside the range your manifest already
   declares, `npm update <pkg>` / `poetry update <pkg>` reaches it with no manifest change.
2. **Raise the declared floor** when the range caps you below the fix. A caret on a `0.0.x` version
   is the usual trap: `^0.0.6` means `>=0.0.6 <0.0.7`, so a fix in `0.0.18` is unreachable until you
   widen it.
3. **Add an override** (`overrides` in package.json, or the equivalent) only for a transitive
   dependency whose parent pins it below the fix and has no newer release. Check the parent still
   works afterwards — an override forces a version its parent never declared.

If a scan reports `blocked`, the image was built but **not pushed**, so that commit cannot deploy
until the findings are resolved. If it reports `error`, the image was not checked — treat that as
unknown rather than clean, and re-run the build.

`promote` deploys apps the platform already has registered. A repo it hasn't seen before is connected with `blankcut onboard` first, which registers the app and opens its setup PR; promote answers "not authorized" until then. After that, `blankcut promote --app <APP>` deploys it, the first time and every time after; `blankcut promote --repo <GITHUB_URL>` does the same for an app named after its repository.

An app whose name differs from its repository is deployed by its name the same way. When it is one app of a repository that already builds another, its first deploy needs an entry for it in the build matrix of the repository's existing workflow (`strategy.matrix.include`, with `image_name: <APP>` and its `dockerfile`), left on the workflow's unchanged `APP_NAME`; the setup PR explains it, and `promote --app` says what is missing until it is there. Its secrets are the keys of a `.env.example` beside its Dockerfile when there is one (the repository's `.env.example` belongs to the app already there), and `blankcut secrets push --app <APP>` accepts the keys of either file.

Once such an app of a shared repository is deployed (a community in a multi-site repository), `promote --app` rebuilds only its configured image through the existing build broker. Run it from a clean checkout of the repository’s current `main`. The committed build workflow (`.github/workflows/build-and-push.yml` or `build_and_push.yml`, not both) must contain exactly one matrix entry matching the registered image, with an explicit Dockerfile, plus a literal `env.APP_NAME` identifying the selected app or its shared repository build broker. The broker must resolve to the same GitHub repository and owner; the deployment app, builder app, and image name are distinct identities. `--dry-run` prints that one-image plan without uploading or building. Only committed files are archived; local secret files are excluded. Existing ingress, secrets and other images are preserved. Infrastructure overrides are refused for this path. A pushed image is not proof of rollout: check app status and verify the public site afterward.

`blankcut status --app <APP>` aggregates live state across GitHub Actions, the deploy's sync and health, Kubernetes, and the app's pending platform changes. A source that is temporarily unreachable comes back `null` rather than failing the whole call, so a partial view is expected, not an error.

## Onboard a new repo (the path that put these files here)

1. The repo was created (or the user clicked "Onboard repo" in the Meerkat UI).
2. `blankcut init` ran (locally) or onboarding ran from Meerkat, opening a PR with the scaffolded layout, including `AGENTS.md` and these guides.
3. Merge the PR.
4. Run `blankcut validate` — if anything fails, run `blankcut validate --fix` to delegate.
5. Run `blankcut promote --repo <THIS_REPO_URL>` to set up the CI/CD pipeline + Helm chart. If `init` ran locally rather than through Meerkat, nothing is registered yet and promote answers "not authorized": run `blankcut onboard` first.
6. Land the resulting PRs.

## Promote to prod

```bash
# Trigger the full pipeline:
blankcut promote --app <APP_NAME>

# Watch the live status:
blankcut status --app <APP>
```

## Investigate a failing pipeline

```bash
blankcut status --app <APP>
```

The output shows:
- GitHub Actions: latest run conclusion, commit SHA, workflow URL
- Deploy: sync + health
- Kubernetes: pod counts + recent warning events
- Pending changes: platform changes not yet applied, and what each one needs from you (usually nothing)

**If the site loads but every data call fails, suspect build-time config before you suspect the
code.** That is the signature of a missing `NEXT_PUBLIC_*` value: the bundle compiled with nothing
where the value should be, so the page renders and each request goes nowhere. `public-config.md` (beside this file) has the fix, and
it needs a rebuild rather than a restart.

**If the run failed with "image scan blocked the push"**, the image was built but not pushed, so
nothing new deployed. Run `blankcut scan` and fix the packages it lists (`scan.md`, beside this file).

For a reading of those facts rather than the facts themselves, run `blankcut diagnose --app <APP>` — it names the likely cause instead of leaving you to infer it from pod counts and warnings.

If a GHA run is red and the failure looks structural, `blankcut validate --fix` will reconcile what it can (build infrastructure drift, missing AWS secrets, missing platform files) within a bounded auto-fix loop.
