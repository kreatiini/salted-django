developer:
  user.present:
    - home: /home/developer
    - password: "$6$86UilMBPope8TkhS$1ez8VvpYdau1mRY3tJn5hdDFFVTnUHI6pC1Ozvn6ThiEp458WK/FLTSu5KAXqRcy358SEp9prSSGGuHOprYDI1"  # Hash your own password and put it here
    - shell: /bin/bash

dependencies_install:
  pkg.installed:
    - pkgs:
      - python3
      - virtualenv
      - python3-pip

create_directory:
  file.directory:
    - name: /home/developer/project
    - user: developer
    - group: developer
    - makedirs: True

create_venv_for_django:
  cmd.run:
    - name: virtualenv -p python3 --system-site-packages /home/developer/project/env
    - creates: /home/developer/project/env/bin/activate
    - user: developer

django_install:
  cmd.run:
    - name: /home/developer/project/env/bin/pip install django
    - creates: /home/developer/project/env/bin/django-admin
    - user: developer

django_project:
  cmd.run:
    - name: /home/developer/project/env/bin/django-admin startproject myproject /home/developer/project/
    - creates: /home/developer/project/manage.py
    - user: developer

fix_it_please:
  file.directory:
    - name: /home/developer/project
    - dir_mode: '0775' # READ ALL, Write OWNER GROUP, Execute ALL
    - user: developer

managepy:
  file.managed:
    - name: /home/developer/project/manage.py
    - mode: '0755' # READ ALL, Write Owner, EXECUTE ALL
    - user: developer

create_db:
  file.managed:
    - name: /home/developer/project/db.sqlite3
    - mode: '0664' # READ all, Write: Owner Group, Execute: no
    - user: developer
