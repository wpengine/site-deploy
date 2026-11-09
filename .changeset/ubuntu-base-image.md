---
"@wpengine/site-deploy": major
---

Switch base image from Alpine 3.24 to Ubuntu 26.04 LTS for security policy compliance; add WP Engine image labels

Tool versions change as follows. Check any custom `FLAGS` or `PHP_LINT` usage against them:

- rsync 3.5.2 (protocol 33) -> 3.4.1 (protocol 32). This is a downgrade, so options added in rsync 3.5.x will no longer work.
- PHP 8.5.12 -> 8.5.4 (Ubuntu backports security fixes without bumping the version)
- OpenSSH 10.3p1 -> 10.2p1
- bash 5.3.9 (unchanged)
