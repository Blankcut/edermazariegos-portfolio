<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Create a NEW project (not the one you are in)

`blankcut init` scaffolds the repo you are **already** in. `blankcut provision` creates a **brand-new** repo from scratch, seeds a runnable starter, registers the app, and provisions its backing services. Reach for it only when the user asks for a new project — never to try the platform out.

```bash
blankcut provision --name <NAME> --owner <GITHUB_ORG>
```

- `--owner` is the GitHub **organization** the Blank Cut GitHub App is installed on. The installation is looked up from it, so you do not need an installation id.
- The project is attributed to the organization your API key belongs to. A key cannot create projects for a different organization.
- **Personal GitHub accounts are not supported from the CLI.** They need a browser consent step the CLI cannot host — create those at [meerkat.blankcut.com](https://meerkat.blankcut.com).

**This one spends money.** It creates a real repository, a build project, a Kubernetes namespace and usually a database, all of which bill from the moment they exist. Do not run it speculatively, and do not retry a refusal — these are answers, not failures:

- **402 or 403 with a plan reason** — the organization's plan, trial, card or account status does not allow another project. Relay the message as given; it is not something you can work around from here.
- **503 `provisioning_not_enabled`** — this deployment has not enabled project creation from the CLI. Use the web console instead.

On success it prints the new repo and clone URL and seeds the starter in the background. Clone it and work inside **its** `AGENTS.md`, not this one; deploy it with `blankcut promote --app <NAME>`.
