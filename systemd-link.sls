{%- set netifaces = pillar['network']['interfaces'] %}

rm -f /etc/systemd/network/[a-z]*.link:
   cmd.run:
      - onlyif:
         - ls /etc/systemd/network/[a-z]*.link

 {% for iface in netifaces recursive %}

### Ethernet begin
    {% if iface.type == 'eth' %}
      {% set filename = '10-'+iface.name+'.link' %}
      {% set filepath = '/etc/systemd/network/'+filename %}

      {% set ifudev = salt['udev.info']('/sys/class/net/'+iface.name) %}
      {% if ifudev.E.SUBSYSTEM == 'net' %}

# Bug https://github.com/saltstack/salt/issues/34236 workaround begin
ensure {{ filename }} exists with ini sections:
  cmd.run:
    - name: echo '[Match]' > {{ filepath }}
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
        Match:
      {%- if ifudev.E.ID_PATH is defined %}
          Path: "{{ ifudev.E.ID_PATH }}"
      {%- else %}
          MACAddress: "{{ grains['hwaddr_interfaces:'+ifudev.E.INTERFACE] }}"
      {%- endif %}
        Link:
      {%- if salt['cmd.run_stdout']("ethtool "+iface.name+"|awk '/Speed:/{print $2}'|grep -oP '\d+'", python_shell=True)|int > 5000 and grains['virtual'] == "physical" %}
          MTUBytes: "9000"
      {%- else %}
          MTUBytes: "1500"
      {%- endif %}
          Name: "{{ ifudev.E.INTERFACE }}"
    - watch_in:
      - module: restart_systemd-networkd
     {% endif %}
    {% endif %}
 {% endfor %}
### Ethernet end

