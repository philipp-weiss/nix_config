---
name: pweiss.org DNS wildcard
description: A wildcard A record *.pweiss.org points at bastion's public IP, so new subdomain vhosts on bastion need no DNS step
type: reference
originSessionId: 19ae9b7e-4368-4a05-9e7c-8582951a886a
---
`pweiss.org` is configured with a wildcard A record at the user's DNS provider, pointing at bastion. Any new `<sub>.pweiss.org` resolves automatically — no DNS record needs to be added when introducing a new subdomain.

**How to apply:** when adding a new nginx vhost on bastion (e.g. for a new service behind ACME), skip the "user must add a DNS record" step. ACME's HTTP-01 challenge works immediately because the wildcard already routes traffic to nginx. If unsure whether the wildcard is still in place, ask the user to run `dig +short <newname>.pweiss.org` and confirm it resolves; do not record the resulting IP.
