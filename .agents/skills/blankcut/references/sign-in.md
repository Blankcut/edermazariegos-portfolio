<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Signing in

```bash
blankcut login
```

That is the whole setup. It prints a short code and opens your browser; you approve the code there, and the CLI collects an API key on its own into `~/.blankcut/config.json`. **The key is never displayed, and you never copy or paste it** — which is the point, because a key that is never on a clipboard cannot end up in shell history, a screenshot, or an agent transcript.

On a machine with no browser (a server, a container), `blankcut login --no-browser` prints the URL to open somewhere else. The code is short and expires in 15 minutes.

The key covers every project in your workspace, including ones created after you signed in. Rotate it whenever you like with `blankcut keys refresh`. **Do not commit `~/.blankcut/config.json`.**

**Every command acts for the organization you signed in to.** Nothing asks which organization a project belongs to or how it is billed: a project belongs to the organization that created or connected it, and that organization's plan decides its billing. `blankcut whoami` shows which organization this machine is signed in to. To act for a different one, run `blankcut login` again and choose it there. When a command answers `API key is not authorized for app '<name>'`, run `blankcut whoami` first: the usual cause is a project that belongs to an organization this key is not for, or one that has not been connected with `blankcut onboard` yet.

**If you are an agent working with a person:** you may run `blankcut login`, but you cannot approve it — they must. It prints a URL and a short code: relay both to them verbatim, ask them to approve in their browser, and wait. The command keeps polling for up to 15 minutes and finishes on its own once they approve, so run it with a long timeout (or in the background) rather than letting it be killed. Never try to approve it yourself or to find a key some other way.

**In CI, or with no person present:** do not run `blankcut login`. Set `BLANKCUT_API_KEY` in the environment instead — every remote command reads it, and no config file is needed. `BLANKCUT_ENDPOINT` is optional and defaults to `https://api.blankcut.com`.

If a command fails with `This API key has been replaced`, the key on this machine was rotated or revoked from the console. Each machine signs in with its own key, so run `blankcut login` again to get back in.

`blankcut configure --api-key ... --endpoint ...` still exists for the case where you were handed a key directly. Prefer `blankcut login` when you can: `configure` means a raw key passed through a human, and that is the failure mode signing in exists to remove.
