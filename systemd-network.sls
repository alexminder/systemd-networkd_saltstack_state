{%- set netifaces = pillar['network']['interfaces'] %}
{%- set netdevs = netifaces|map(attribute="name")|list %}

rm -f /etc/systemd/network/[a-z]*.network:
   cmd.run:
      - onlyif:
         - ls /etc/systemd/network/[a-z]*.network

  {%- for iface in netifaces recursive %}
## IP {{ iface.name }} begin
/etc/systemd/network/20-{{ iface.name }}.network:
  file.managed:
    - user: systemd-network
    - group: systemd-network
    - file_mode: 644
    - dir_mode: 755
    - source: salt://{{ tpldir }}/files/systemd-networkd.network
    - template: jinja
    - defaults:
        iface: {{ iface }}
{%- if iface.subnet_id is defined %}
{%- set subnet = pillar['network']['subnets'][iface.subnet_id] %}
        subnet: {{ subnet }}
{%- endif %}
    - require:
       - file: /etc/systemd/network
    - watch_in:
      - module: restart_systemd-networkd
    - require_in:
       - pkg: NetworkManager
       - service: NetworkManager
## IP {{ iface.name }} END
  {% endfor %}

