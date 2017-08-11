# SaltStack states to configure network managed by `systemd-networkd`.

Install and configure `systemd-networkd`.

See `pillar.example` for network interface configuration definition.

Warning: state will remove `NetworkManager` if it installed after success `systemd-networkd` configure!
