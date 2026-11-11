<!-- Managed by Blank Cut: written by `blankcut init` and refreshed by `blankcut sync`. Edits to this file are overwritten. -->

# Custom domains — `blankcut domains`

A domain of the client's own (rather than the `<app>.blankcut.app` host the platform assigns) is
bought, moved in, and connected to an app with `blankcut domains`:

```bash
blankcut domains search <name>                 # availability and the price per year
blankcut domains buy <domain> --app <APP>      # register it and serve it from the app
blankcut domains attach <domain> --app <APP>   # serve a domain from the app (connects one registered elsewhere too)
blankcut domains status <domain>               # certificate, DNS records, registration
blankcut domains list                          # every domain, and orders still in progress
```

**A domain registered somewhere else moves in three steps, in order:**

```bash
blankcut domains transfer check <domain>              # can it move, and what is in the way
blankcut domains transfer dns <domain>                # copy its DNS records over first
blankcut domains transfer start <domain> --app <APP>  # needs the current registrar's transfer code
```

Copy the DNS first and set the nameservers `transfer dns` prints at the current registrar: that is
what keeps the site and the domain's email working while it moves.

**Connecting a domain to an app is automatic.** Once the domain's certificate is issued, the
platform adds the domain to the app's deployment itself. Never hand-edit `ingressRoute.hosts` or
any other deployment config to serve a client domain — `attach` and `detach` are the switches, and
`blankcut domains status <domain>` shows how far along it is. When the domain is live, update any
site-URL setting the app reads (for example `NEXT_PUBLIC_SITE_URL`) with `blankcut secrets set`;
that is the app's own config, not routing.

**DNS for a domain the platform hosts** is managed with `blankcut domains records <domain>`,
`records set` and `records rm`. Records marked as managed by Blank Cut (certificate validation,
routing to the app) cannot be changed there; everything else — mail, verification TXT records — is
the client's to edit.

**Money and control.** Domains are registered at cost and charged to the organization's card in
Billing, and renew yearly unless `blankcut domains auto-renew <domain> off` is set. A registrant
contact (`blankcut domains contact set`) is required before the first purchase or transfer.
Buying, transferring in, auto-renew and the contact need the **organization owner's** key. Moving a
domain *out* to another registrar is done in Meerkat by a signed-in owner (Domains → the domain →
Transfer out), never from the CLI: `blankcut domains release` only points there.

Rules for agents:

- **Show the person the price** `buy` or `transfer start` prints and get their explicit go-ahead
  before passing `--yes`. Without `--yes` and without a terminal to ask on, these commands stop
  instead of spending money; that is the intended behaviour, not something to work around.
- **The transfer code is the person's to supply.** Have them run `transfer start` themselves (it
  asks without echoing), or set `BLANKCUT_DOMAIN_AUTH_CODE` in their own shell. Never ask for it in
  the conversation.
- **Moving a domain away is the person's to do in Meerkat.** No command hands out a domain's
  transfer code, by design: whoever holds it can take the domain. Don't look for another way to get
  one, and never ask for, write down or pass on a transfer code in either direction.
