<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Before you write code — read the environment instead of guessing

**Run this first, before writing or changing code that touches infrastructure:**

```bash
blankcut context --app <APP>
```

It reports what this app *actually* runs in — the resource envelope, how many replicas it scales to, which secret keys reach the running pod, the database engine and version and connection limit and schema, and recent traffic. Code written against an assumed architecture usually looks correct and fails in production; this is how you avoid that.

Narrow it when you only need one answer: `context env`, `context secrets`, `context data`, `context image`, `context runtime`, `context routes`, `context conventions`.

**It is always current.** Nothing is cached locally. Every run fetches live state or fails, and the `Freshness` block at the bottom tells you how old each part is. There is no refresh step to forget.

**Output is JSON automatically when it is piped**, so `blankcut context --app <APP> | ...` gives you machine-readable data, while running it in a terminal gives a readable table. Same command, same facts.

## The four things it tells you that will otherwise bite you

- **The resource envelope is enforced, not advisory.** The memory limit is a hard ceiling — exceed it and the container is killed, not throttled. Size what you build to the limit shown, not to what your laptop has.

- **Connection limits are shared across every replica of every workload.** `context data` shows `max connections` for the database; `context env` shows each workload and how far it scales. Your pool size is multiplied by the total, not by one. An app with an API at 2 replicas and two workers at 2 each has **six** processes opening connections, and a pool of 20 in each exhausts a 60-connection database on its own. This is the most common way an app that works fine in staging falls over under load.

- **"Stored" and "reaching the app" are different numbers.** A secret can exist in the platform's store and still not be delivered to the running pod — the deployment receives a specific list of keys. If `context secrets` shows a key under *not yet reaching the app*, then `process.env.THAT_KEY` is **undefined at runtime** no matter what the store contains. The secrets guide (`secrets.md`, beside this file) explains how a new key gets wired in.

- **`context data` lists the tables that actually exist**, with the columns and types. Write queries against that, not against what the ORM models imply — the two drift, and the database is the one that decides.

## Match this repo instead of introducing a new pattern

```bash
blankcut context conventions --app <APP>
blankcut context routes --app <APP>
```

`conventions` reports the patterns this repository *actually* uses — how its routes are guarded, how it reaches its database, whether environment variables are read with a fallback — each with the count behind it. These are derived from the code at the current commit, not written down by anyone, so they cannot be out of date. Read the counts: *176 of 284* is the house style and you should follow it; *3 of 20* is one corner of the repo and proves nothing. Introducing a second way to do something that already has one is how a codebase becomes two codebases.

`routes` lists every route, what guards it, and what it touches. Use it before adding a route, so the new one is guarded the same way as its neighbours.

**Read `guard not determined` as exactly that.** Route auth is derived from the code without resolving types across files, so a guard that is applied indirectly cannot always be traced to the route it protects. A route listed that way is one this tool could not follow — **it is not a route that has been shown to be unauthenticated**, and it must not be treated as a finding or "fixed" by bolting on a second check. If you need to know, open the file. The count of routes that were read and the count that could not be parsed are printed with the table for the same reason: *no unauthenticated routes found* and *found no routes* look identical if you do not check.

## When a facet says it is unavailable

Unavailable is not the same as absent, and the reason distinguishes them. *"No managed database is attached to this app"* means there is no database. *"The database schema for this app is not available yet"* means there is one and it cannot be described right now — do not conclude the app is storage-less and write around it. If you need the distinction and cannot get it, ask rather than assume.

## When something is broken

```bash
blankcut diagnose --app <APP>
```

`blankcut status` gives you the raw facts — pod counts, sync state, recent warnings. `diagnose` reads those facts and tells you what is actually wrong, so you get a cause instead of symptoms to interpret. It returns nothing to diagnose when the app is healthy.
