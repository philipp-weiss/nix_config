# TODO

Open items that aren't blocking but should be tackled eventually.

## MagicDNS doesn't resolve from WSL or Android

After moving services behind the headscale-managed tailnet, the only working
way to reach `nuc` / `testy` from non-Linux-desktop peers is via their raw
tailnet IPs (e.g. `http://<nuc-tailnet-ip>:8123` for Home Assistant,
`http://<testy-tailnet-ip>:8080` for gatus). The MagicDNS short-names
(`nuc`, `testy.vpn.pweiss.org`) don't resolve:

- **WSL:** `tailscale status` reports `/etc/resolv.conf overwritten` — WSL's
  network layer keeps clobbering DNS so tailscaled can't install its
  100.100.100.100 resolver. Likely needs NixOS-WSL `wsl.wslConf.network` tuning
  or a stub-resolver shim.
- **Android:** enabling "Use Tailscale DNS" in the Android Tailscale app kills
  outbound DNS entirely (looks like "no internet"). The phone currently runs
  with that toggle off, which keeps internet working but disables MagicDNS.
  Likely fix is switching `nameservers.global` in
  `hosts/testy/headscale.nix` to a resolver that works through the tunnel
  reliably, or accepting per-app DNS bypass.

Until this is fixed, the raw tailnet IPs are baked into the HA companion
app and any bookmarks. They're effectively stable because headscale uses
`allocation = "sequential"` and no node has been removed, but renumbering
is possible.
