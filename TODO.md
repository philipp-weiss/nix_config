# TODO

Open items that aren't blocking but should be tackled eventually.

## DNS for VPN hostnames (phone has none)

NixOS hosts on the WG mesh resolve `bastion` / `nuc` / `wsl` via
`networking.extraHosts`. The phone has no equivalent — it reaches services
by raw IP (`http://10.42.0.2:8123` for HA, `http://10.42.0.1:8080` for
gatus). That's fine while the addressing is stable, but bookmarks and the
HA companion app config break the moment any IP changes.

Likely fix: small DNS resolver on bastion (unbound or dnsmasq), serving an
internal zone like `vpn.pweiss.org` that maps to the WG IPs. Push it to
phone clients via the WG `DNS = 10.42.0.1` line in their tunnel config —
the WireGuard app installs that resolver only while the tunnel is up, so
off-VPN DNS stays unchanged.
