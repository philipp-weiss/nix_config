{ ... }:

{
  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 8080;
    settings = {
      server_url = "https://headscale.pweiss.org";

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      dns = {
        magic_dns = true;
        base_domain = "vpn.pweiss.org";
        nameservers.global = [ "1.1.1.1" "9.9.9.9" ];
      };

      derp.urls = [ "https://controlplane.tailscale.com/derpmap/default" ];

      disable_check_updates = true;
    };
  };

  services.nginx.virtualHosts."headscale.pweiss.org" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_buffering off;
        proxy_read_timeout 1d;
      '';
    };
  };
}
