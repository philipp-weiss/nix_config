let
  phip  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHgCqkVI/LR3FFI9z1JLnQylOsteuCg3fP2UXAf/Bnzu";
  nuc   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdwE7xHYwdbM2IETm3fIH+rxrVeY24Ofnc49Qb/siZb";
  testy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILnyW+Axdl5aI0Q3mXVTgjqIH7XZpvJP0H8XiEmS5suV";
in {
  # Shared between client (nuc) and server (testy) — same restic encryption passphrase
  "secrets/restic-password.age".publicKeys   = [ phip nuc testy ];

  # nuc-only (client side)
  "secrets/restic-repository.age".publicKeys = [ phip nuc ];

  # testy-only (server side)
  "secrets/restic-htpasswd.age".publicKeys   = [ phip testy ];
}
