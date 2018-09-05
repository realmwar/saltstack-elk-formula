base:
  '*':
    - common

  'minion1':
    - elk
    - beats.filebeat

  'minion2':
    - elk.common
    - beats.filebeat
