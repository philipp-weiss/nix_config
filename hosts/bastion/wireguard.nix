{ config, ... }:
{
  # Hub-and-spoke WireGuard mesh. bastion is the only peer with a public
  # endpoint; nuc, wsl, and the phone all dial in and route inter-peer
  # traffic through here. Replaces the previous headscale/tailscale setup.
  #
  # Subnet 10.42.0.0/24:
  #   .1  bastion (hub)
  #   .2  nuc
  #   .3  wsl
  #   .10 phone (peer entry added once the device's pubkey is known)

  age.secrets.wg-bastion-private.rekeyFile = ../../secrets/wg-bastion.age;

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall.allowedUDPPorts = [ 51820 ];

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.42.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wg-bastion-private.path;
    # Measured: WSL↔bastion path drops inner IP packets >1348 bytes. 1280 is
    # the IPv6 minimum MTU and leaves headroom for route changes. Without
    # this, post-quantum SSH KEX replies fragment and get silently dropped.
    mtu = 1280;

    peers = [
      {
        # nuc
        publicKey = "BKNkYpqKg85eW75N7R/11PRTq8PT0WDAQbj30j+rqgw=";
        allowedIPs = [ "10.42.0.2/32" ];
      }
      {
        # wsl
        publicKey = "Kq0pFTrJ8UxONdA02hvqRM4UTIIRF42hZWitjS/GPzw=";
        allowedIPs = [ "10.42.0.3/32" ];
      }
      {
        # phone
        publicKey = "mblrjxYiroKE66ZzzZ4/oteUfNiX1YxgCCz+y4qM7wY=";
        allowedIPs = [ "10.42.0.10/32" ];
      }
    ];
  };

  networking.extraHosts = ''
    10.42.0.1 bastion
    10.42.0.2 nuc
    10.42.0.3 wsl
  '';
}
