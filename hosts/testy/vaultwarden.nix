{ ... }:
{
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";
    config = {
      SIGNUPS_ALLOWED = false;
      ADMIN_TOKEN = "$argon2id$v=19$m=4096,t=3,p=1$emZrU3doYlVpRHRtK1JqaG1WOUVadlhWdWNZZzFTRnVWb05JR28rbEV6RT0$Fj6CIfAAGbYuKvu9jB490gFeTGrN1rlCjNChUejq8cU";
      DOMAIN = "https://vaultwarden.pweiss.org";
      ROCKET_PORT = 8222;
    };
  };
}
