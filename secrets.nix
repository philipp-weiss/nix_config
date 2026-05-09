let
  # Master identity: YubiKey (age-plugin-yubikey).
  # Replace with the recipient string printed by `age-plugin-yubikey --list`
  # (looks like `age1yubikey1...`). All secrets below are encrypted ONLY to this
  # recipient; agenix-rekey re-encrypts them per host at rekey time.
  yubikey = "age1yubikey1qvu6drnf9ea5nr0jtx2gcy7wyrved6gymuqky4v0j5v22hvhx6g5cvt8wpg";
in {
  "secrets/restic-password.age".publicKeys   = [ yubikey ];
  "secrets/restic-repository.age".publicKeys = [ yubikey ];
  "secrets/restic-htpasswd.age".publicKeys   = [ yubikey ];
}
