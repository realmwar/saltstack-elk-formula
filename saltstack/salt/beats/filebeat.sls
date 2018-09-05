filebeat_group:
  group.present:
    - name: filebeat
    - gid: 4000

# Create a filebeat user that has the privileged groups 'adm' and 'root'.
# The filebeat user needs these group permissions to read log files.
filebeat_user:
  user.present:
    - name: filebeat
    - fullname: FileBeat
    - shell: /usr/sbin/nologin
    - home: /home/filebeat
    - uid: 4000
    - gid: 4000
    - groups:
      - adm
      - root

filebeat_apt_source:
  file.managed:
    - name: /etc/apt/sources.list.d/filebeat.list
    - require:
      - file: elastic_public_key
    - contents: deb {{ salt['pillar.get']('elk:filebeat:apt_source') }} stable main

filebeat_install:
  archive.extracted:
    - name: /opt
    - source: {{ salt['pillar.get']('elk:filebeat:source') }}
    - source_hash: {{ salt['pillar.get']('elk:filebeat:source_hash') }}
    - archive_format: tar
    - tar_options: xzvf
    - user: root
    - group: root
    - if_missing: {{ salt['pillar.get']('elk:filebeat:dir') }}

filebeat_install_1:
  pkg.installed:
    - name: filebeat
    - refresh: True
    - user: filebeat
    - group: filebeat
    - if_missing: {{ salt['pillar.get']('elk:filebeat:dir') }}

# {% if not salt['pillar.get']('elk:filebeat:dir') %}
# filebeat_directory_create:
#   file.directory:
#     - name:  {{ salt['pillar.get']('elk:filebeat:dir') }}
#     - user:  filebeat
#     - group:  filebeat
#     - makedirs: True
#     - recurse:
#         - user
#         - group
#         - mode
# {% else %}
#   cmd.run:
#     - name: echo "Directory exists"
# {% endif %}
#
# Vagrant is showing weird file permissions, run this check to fix:
# filebeat_check_permissions:
#     file.directory:
#     - name: {{ salt['pillar.get']('elk:filebeat:dir') }}
#     - user: filebeat
#     - group: filebeat
#     - recurse:
#         - user
#         - group
#         - mode
    # - require:
    #   - file: {{ salt['pillar.get']('elk:filebeat:dir') }}

filebeat_symlink:
  file.symlink:
    - name: /opt/filebeat
    - target: {{ salt['pillar.get']('elk:filebeat:dir') }}
    - force: True

{% set nodename_paths = 'filebeat:nodes:' + salt['grains.get']('nodename') + ':paths' %}
# Ex: filebeat:nodes:saltminion1:paths

filebeat_conf:
  file.managed:
    - name: {{ salt['pillar.get']('elk:filebeat:dir') }}/filebeat.yml
    - source: salt://beats/files/filebeat/filebeat.yml
    - template: jinja
    - logstash_hosts: {{ ','.join(salt['pillar.get']('filebeat:logstash:hosts')) }}
    - paths: {{ salt['pillar.get']('filebeat:paths') }}
    - custom_paths_nodename: {{ nodename_paths }}
    {% if salt['pillar.get'](nodename_paths) is defined %}
    - paths_node: {{ salt['pillar.get'](nodename_paths) }}
    {% endif %}

filebeat_init:
  file.managed:
    - name: /etc/init/filebeat.conf
    - source: salt://beats/files/filebeat/filebeat_upstart.conf


filebeat_service:
  service.running:
    - name: filebeat
    - enable: True
    - reload: True
    - watch:
      - file: {{ salt['pillar.get']('elk:filebeat:dir') }}/filebeat.yml
