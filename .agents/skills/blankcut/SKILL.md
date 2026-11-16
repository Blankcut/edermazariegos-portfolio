---
name: blankcut
description: How to work in a repository that is deployed on the Blank Cut platform with the `blankcut` CLI. Use when deploying or promoting the app, checking why it is not live, adding or reading secrets and environment variables, using NEXT_PUBLIC_ values, storing files or uploads, scheduling a recurring job, fixing image vulnerability findings or a build the scan blocked, buying or connecting a domain, creating a new project, or before writing code that touches the database, memory limits or routes.
---
<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Working on the Blank Cut platform

The binding rules for this repository are in `AGENTS.md` at the repository root (Claude Code loads it through `CLAUDE.md`). Read it first if you have not. It covers installing and signing in to the CLI, the list of commands, the rule against emitting secret values, and the supported stacks.

This skill holds the longer guides. **Open the guide for the task before you start it.** Each one is a file in `.agents/skills/blankcut/references/`, from the repository root.

| When you are about to | Guide |
|---|---|
| Sign in, switch organization, or fix a rejected key | `.agents/skills/blankcut/references/sign-in.md` |
| Write or change code that touches infrastructure (database, memory, replicas, routes) | `.agents/skills/blankcut/references/environment.md` |
| Add, change or read secrets and environment variables | `.agents/skills/blankcut/references/secrets.md` |
| Deploy, or work out why a deploy is not live | `.agents/skills/blankcut/references/deploy.md` |
| Store files or uploads | `.agents/skills/blankcut/references/storage.md` |
| Run something on a timer | `.agents/skills/blankcut/references/schedules.md` |
| Use a value in the browser (`NEXT_PUBLIC_*`) | `.agents/skills/blankcut/references/public-config.md` |
| Fix image vulnerabilities, or a build the scan blocked | `.agents/skills/blankcut/references/scan.md` |
| Buy, transfer or connect a domain | `.agents/skills/blankcut/references/domains.md` |
| Create a new project | `.agents/skills/blankcut/references/new-project.md` |

For a command's flags, defaults and subcommands, run `blankcut <command> --help`. That output comes from the binary you have, so it cannot be out of date.
