{%- set netifaces = pillar['network']['interfaces'] %}

rm -f /etc/systemd/network/[a-z]*.netdev:
   cmd.run:
      - onlyif:
         - ls /etc/systemd/network/[a-z]*.netdev

{%- for iface in netifaces recursive %}

 {%- set filename = '20-'+iface.name+'.netdev' %}
 {%- set filepath = '/etc/systemd/network/'+filename %}

## BOND begin

    {%- if iface.type == 'bond' %}

# Bug https://github.com/saltstack/salt/issues/34236 workaround begin
ensure {{ filename }} exists with ini sections:
  cmd.run:
    - name: echo '[NetDev]' > {{ filepath }}
    - unless:
       - test -f {{ filepath }}
    - require_in:
      - ini: {{ filepath }}
    - require:
       - file: /etc/systemd/network
# Bug workaround end

{{ filepath }}:
  ini.options_present:
    - sections:
        NetDev:
          Name: "{{ iface.name }}"
          Kind: "bond"
       {%- if iface.mtu is defined %}
          MTUBytes: "{{ iface.mtu }}"
       {%- endif %}
        Bond:
          Mode: "{{ iface.mode }}"
       {%- if iface.xmit_hash_policy is defined %}
          TransmitHashPolicy: "{{ iface.xmit_hash_policy }}"
       {%- endif %}
       {%- if iface.miimon is defined %}
          MIIMonitorSec: "{{ iface.miimon }}"
       {%- else %}
          MIIMonitorSec: "1s"
       {%- endif %}
    - watch_in:
      - module: restart_systemd-networkd
    {%- endif %}
## BOND END

## VLAN begin

    {% if iface.type == 'vlan' %}

ensure {{ filename }} exists with ini sections:
# Bug https://github.com/saltstack/salt/issues/34236 workaround begin
  cmd.run:
    - name: echo '[NetDev]' > {{ filepath }}
    - unless:
       - test -f {{ filepath }}
    - require_in:
      - ini: {{ filepath }}
    - require:
       - file: /etc/systemd/network
# Bug workaround end

{{ filepath }}:
  ini.options_present:
    - sections:
        NetDev:
          Name: "{{ iface.name }}"
          Kind: "vlan"
        VLAN:
          Id: "{{ iface.tag }}"
    - watch_in:
      - module: restart_systemd-networkd
    {%- endif %}
## VLAN END
{%- endfor %}

