<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# File storage — how your app actually reaches it

`blankcut storage add --app <APP>` gives the app somewhere to keep files: images, video, uploads, anything too big or too binary for a database row. It is opt-in on every tier and billed per GB stored, so an app that never asks for it gets nothing and is billed nothing.

Run `blankcut context storage --app <APP>` to see the live answer for **this** app. The rest of this section is the part that will not be obvious from the output.

**It is ordinary S3, reached with the pod's own identity.** You do not need a new client library or a platform-specific API. What you must not do is give that client credentials.

**There are no access keys, and adding some breaks it.** The deployment's service account carries an IAM role scoped to your app's own prefix, and every major AWS SDK's *default* credential chain finds it with no configuration. But that chain checks explicit and environment credentials **first** — so an `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` left in the app's settings or secrets wins, the role is never assumed, and every call fails on a bucket those keys have no grant on. Construct the client with no credential arguments, and remove any AWS keys the app used to carry.

**After the next `promote`, the pod receives:**

| Variable | Meaning |
|---|---|
| `STORAGE_BUCKET` | the bucket to address |
| `STORAGE_PREFIX` | your app's key prefix, **with a trailing slash** (e.g. `myapp/`) |
| `STORAGE_PUBLIC_BASE_URL` | the public address, **only when the platform CDN is configured** — treat it as optional |

Read the bucket and prefix from the environment rather than hardcoding them; both change if the app is renamed or moved. `AWS_REGION` is deliberately **not** among them — carry your own default in config.

**Every key must start with `STORAGE_PREFIX`.** The role is scoped to that prefix and nothing else, so a key outside it is refused. Two areas live underneath it:

- **`public/`** — served from a stable public URL, for anything meant to be seen.
- **`private/`** — reachable only through a time-limited link your app generates.

```python
import os, boto3

# No credentials, no region argument beyond your own default.
s3 = boto3.client("s3", region_name=settings.aws_region)

bucket = os.environ["STORAGE_BUCKET"]
prefix = os.environ["STORAGE_PREFIX"]          # "myapp/"

key = f"{prefix}private/uploads/{filename}"    # NOT f"uploads/{filename}"
s3.put_object(Bucket=bucket, Key=key, Body=data)
```

The same two rules — no explicit credentials, always prefix the key — hold for every language; only the client construction differs.

**Two waits, and they are different things.** `storage add` returns before the app can use it: setting up the identity takes a minute or two on its own, and *then* you need a `blankcut promote` for the running app to receive the binding at all. `blankcut context storage --app <APP>` reports `provisioning` until the identity is ready and `ready` once it is — promote before it says `ready` and the deployment comes up clean without storage.

**If it stays `provisioning`, re-run `blankcut storage add --app <APP>`.** That command is a repair as well as a create: re-running re-asserts every piece rather than allocating a second lot, so it is safe to run whenever the state looks wrong.

**`blankcut storage rm` permanently deletes the app's files.** It requires `--yes` because nothing about it is recoverable.
