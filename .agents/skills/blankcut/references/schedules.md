<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Scheduled jobs — run one of your own endpoints on a timer

Recurring work (a nightly digest, a periodic refresh, a price check) runs as a **scheduled call into
an endpoint this app already serves**:

```bash
blankcut schedule add price-check --app <APP> \
  --cron "0 */6 * * *" --path /api/cron/price-check
blankcut schedule list --app <APP>
blankcut schedule rm price-check --app <APP>
```

**You write the endpoint; the platform only calls it.** It is reached over the cluster's internal
network, so it does **not** have to be public. Everything else — what runs the call, and the fact
that it can only reach this app — is fixed by the platform and not configurable.

**Authenticate it.** The call carries the app's own `BLANKCUT_CRON_SECRET` as
`Authorization: Bearer <value>`. Declare that key in `.env.example`, set it with
`blankcut secrets set`, and have your handler reject anything else — otherwise any traffic that
reaches the endpoint can trigger the work. `schedule add` refuses to create a job when the app has
no such key, rather than deploying one that fails on every run.

Three limits worth knowing before you design around it:

- **No more often than every 5 minutes.** An expression that fires faster is refused, as is cron
  syntax the platform cannot evaluate (`@hourly`, named weekdays, seconds fields).
- **Each app has a maximum number of jobs.** `blankcut schedule list` prints the limit alongside
  what is in use. Ask the platform if you need more.
- **A change takes a minute or two to take effect, not none.** The platform checks it and then
  deploys it, so a new job's first run is shortly after you add it and a removed one may run once
  more. `blankcut schedule list` reports what is *running*. If a check does not pass the change
  stops for a human and `list` says it is pending review — which, since the platform generates the
  whole job, normally means something about the app's deployment config needs a look.

**This is not a general job runner.** It cannot run a script, a different image, or a one-off task,
and it cannot call anything but this app. Work that does not fit that shape belongs in the app
itself — a queue, a worker process, or a request handler.
