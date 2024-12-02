# Tests and creation
Here is the step-by-step approach and report of creating the file. I have been playing around with Django a bit on my spare time. The manual installation is pretty clear to me and the structure of Django projects. I just started to read Salt and Django documentation to combine these in to an automated version. The hardest thing is idempotency.

## Django module
I started the creation of the django module and figured out the dependencies. Before creating virtualenv you need `python3` `virtualenv` and `python3-pip`. So the first dictionary will be for dependencies. After that you can create the virtualenv and install Django. After installing Django you need to create the project and make migrations. Then we have Django set up. 

### First version:
First version was created with four dictionaries. It ends after creating the Django project. I did a test run on it and three succeeded one failed. The failed one was creation of my project. Until that point the state succeeded. Here is a screenshot of the error code:

![image](https://github.com/user-attachments/assets/ac7f3e79-1b02-4be4-8ce4-693d13d0bc99)

After going to the project directory the env is there but no myproject directory. I 
#### First dictionary: Dependencies
So here we install the dependencies for Django. Nothing too complicated.

~~~
dependencies_install:
  pkg.installed:
   - pkgs:
     - python3
     - virtualenv
     - python3-pip

~~~

#### Second dictionary: Creating the virtualenv

I
~~~
create_venv_for_django:
  cmd.run:
    - name: virtualenv -p python3 --system-site-packages  /home/kreatiini/project/env
    - creates: /home/kreatiini/project/env/bin/activate

~~~

#### Third dictionary: Installing Django

~~~
django_install:
  cmd.run:
    - name: /home/kreatiini/project/env/bin/pip install django
    - creates: /home/kreatiini/project/env/bin/django-admin
~~~

#### Fourth dictionary: Create Django project

~~~
django_project:
  cmd.run:
    - name: /home/kreatiini/project/env/bin/django-admin startproject myproject /home/kreatiini/project/myproject
    - creates: /home/kreatiini/project/myproject/manage.py
~~~
