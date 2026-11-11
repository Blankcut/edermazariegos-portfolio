<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Browser-visible config (`NEXT_PUBLIC_*`) — build-time, not runtime

This is the single most common way a deploy goes wrong, and it fails in a shape that looks like a
broken app rather than missing config: **the page renders and every data call fails.**

`next build` compiles `NEXT_PUBLIC_*` values **into the browser bundle**. They must exist when the
image is built. Nothing injected at runtime can reach them — a value the pod receives after the
image was built is invisible to code already compiled, so **changing one needs a rebuild**, not a
restart.

Two routes reach the build, and you can use either:

| Route | How | Reaches |
|---|---|---|
| `blankcut secrets set --app <APP> NEXT_PUBLIC_FOO <value>` | Same `.env.example` gate as any other key | Build **and** the running pod |
| A GitHub repo **variable** (or secret) named `NEXT_PUBLIC_FOO` | Picked up automatically — no workflow edit, no fixed list | Build only |

If both define a key, the repo's value wins when it is non-empty.

**Whatever the platform provisioned for you is already supplied.** If the platform created this
app's database, its URL and public key reach every build without you setting anything. Set only the
keys that are yours — an app id, a feature flag, your own public API base.

**`NEXT_PUBLIC_` is a publication decision, not a naming convention.** Anything under that prefix is
readable by anyone who opens the site. Never give a service-role key, admin token or private API key
a `NEXT_PUBLIC_` name — the prefix is what publishes it. Those belong in `blankcut secrets` under
their ordinary names, where they reach the server and stop there.
