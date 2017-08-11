{%- if grains['init'] == 'systemd' and pillar['network']['is_managed'] == True %}

{%- from tpldir+"/map.jinja" import confmap with context -%}

systemd-networkd:
  pkg.latest:
     - normalize : False
     - pkgs:
        - {{ confmap.pkgs }}
  service:
    - enabled
    - names:
      - systemd-networkd
      - systemd-networkd-wait-online
    - require:
      - pkg: systemd-networkd

/etc/systemd/network:
  file.directory:
    - user: systemd-network
    - group: systemd-network
    - file_mode: 644
    - dir_mode: 755
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: systemd-networkd

restart_systemd-networkd:
  module.wait:
    - name: service.restart
    - m_name: systemd-networkd
    - require:
       - file: /etc/systemd/network
    - require_in:
       - pkg: NetworkManager
       - service: NetworkManager
       - file: /etc/udev/rules.d/60-net.rules
       - file: /etc/udev/rules.d/80-net-name-slot.rules
       - file: /etc/udev/rules.d/71-biosdevname.rules
       - file: /etc/udev/rules.d/90-eno-fix.rules

include:
   - {{ tpldir }}/systemd-link
   - {{ tpldir }}/systemd-netdev
   - {{ tpldir }}/systemd-network

 {% for netservice in [confmap.legacynetsvc, 'NetworkManager', 'NetworkManager-wait-online'] %}
# make sure conflicting services are stopped before systemd-networkd takes over
disable-netservice-{{ netservice }}:
  service.disabled:
    - name: {{ netservice }}
    - require_in:
      - module: restart_systemd-networkd
    - require:
      - pkg: systemd-networkd
    #    - onlyif:
      #       - systemctl list-unit-files|grep "{{ netservice }}\."
 {% endfor %}

NetworkManager:
   service:
      - dead
      - onlyif:
         - systemctl list-unit-files|grep NetworkManager
   pkg.purged:
      - pkgs:
         - {{ confmap.NMpkg }}

/etc/udev/rules.d/60-net.rules:
  file.symlink:
    - target: /dev/null
    - force: True
    - onlyif:
       - test -f /usr/lib/udev/rules.d/60-net.rules

/etc/udev/rules.d/80-net-name-slot.rules:
  file.symlink:
    - target: /dev/null
    - force: True
    - onlyif:
       - test -f /usr/lib/udev/rules.d/80-net-name-slot.rules

/etc/udev/rules.d/71-biosdevname.rules:
  file.symlink:
    - target: /dev/null
    - force: True
    - onlyif:
       - test -f /usr/lib/udev/rules.d/71-biosdevname.rules

/etc/udev/rules.d/90-eno-fix.rules:
  file.absent

{%- endif %}
