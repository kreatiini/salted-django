# Tests and creation
Here is the step-by-step approach and report of creating the file. I have been playing around with Django a bit on my spare time. The manual installation is pretty clear to me and the structure of Django projects. I just started to read Salt and Django documentation to combine these in to an automated version. The hardest thing is idempotency.

## Django module
I started the creation of the django module and figured out the dependencies. Before creating virtualenv you need `python3` `virtualenv` and `python3-pip`. So the first dictionary will be for dependencies. After that you can create the virtualenv and install Django. After installing Django you need to create the project and make migrations. Then we have Django set up. 

### First version (local)
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

#### Third dictionary: Installing Django (

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

### Second Version (local)
I remembered that I had the same issue on manual installation in the previous course. Meaning I made the directory messy creating same directories on top of each other. Since Django creates the `myproject` and all necessary directories I just changed the path to `project` directory:
~~~
django_project:
  cmd.run:
    - name: /home/kreatiini/project/env/bin/django-admin startproject myproject /home/kreatiini/project/
    - creates: /home/kreatiini/project/myproject/manage.py
~~~

Now the test run worked:

![image](https://github.com/user-attachments/assets/21b8132f-91c5-4b29-8e37-34887f11fde2)

So basically as you can see the other commands were idempotent. I am using the [`creates`](https://docs.saltproject.io/en/latest/ref/states/all/salt.states.cmd.html)  to check if the specific folder exists and if not it will run the command. The checks besides `django_install` are self-explanatory. Since the installation is done in the `virtualenv` the django-admin directory will be in env directory. So if Django is installed it can be found there. Now after testing to activate it and checking the `pip`:

![image](https://github.com/user-attachments/assets/0dde8ef4-9f89-4be7-8d23-b2806754428d)

It seems to be in correct location. After testing it had errors:

![image](https://github.com/user-attachments/assets/85a3eda7-e610-4328-a86e-5632bc18e336)

After checking `settings.py` which was correct I started to do some Google research. Django has very good Documentation and the problem was permissions. [Djangoproject](https://code.djangoproject.com/wiki/NewbieMistakes#DjangosaysUnabletoOpenDatabaseFilewhenusingSQLite3). I ran the `ls -ld myproject`:

![image](https://github.com/user-attachments/assets/c1e4fab2-6ee6-43e3-8a16-cbe31fb8a96b)

So only `root` was able to do anything with this directory. The same was true with `project` directory. So the directories must be created with user privileges. Salt always runs with root privileges so it must be declared in the command. It seems like in Salt you can either use `user:` or `group:` to declare the owner. It must be declared with `file.directory`. I wanted to be able later add Postgres or Apache if the user wants to so I decided to find out what kind of user privileges they need. The permission thing is hard for me to get a grasp on. Since I don't want any security risks maybe I should just create a new group like "project" and add Apache, user and postgres there. Maybe first I will just try to create them as user and see if that works so I wont complicate it too much.

### Third version (Local)
So now I have changed to run the commands and creating the directory as user. I did not add `file.directory` at this point to test this approach first.

The run worked fine, all five succeeded. Next I will try to run the test server and migrations manually.

`./manage.py runserver`:
![image](https://github.com/user-attachments/assets/e5f6f1c2-b680-4a02-8b47-3eb6b075d465)
![image](https://github.com/user-attachments/assets/d7cd1ade-c5bd-452a-8cdc-1103c7922057)

`./manage.py migrate` and `./manage.py makemigrations`:

![image](https://github.com/user-attachments/assets/fcb2482e-9d15-471a-8e54-0f4c9fdfaf6a)

So the third version works fine when running commands as user and creating directory `project` as user. Here is the full version now:

~~~
dependencies_install:
  pkg.installed:
    - pkgs:
      - python3
      - virtualenv
      - python3-pip

create_directory:
  file.directory:
    - name: /home/kreatiini/project
    - user: kreatiini
    - makedirs: True

create_venv_for_django:
  cmd.run:
    - name: virtualenv -p python3 --system-site-packages /home/kreatiini/project/env
    - creates: /home/kreatiini/project/env/bin/activate
    - user: kreatiini

django_install:
  cmd.run:
    - name: /home/kreatiini/project/env/bin/pip install django
    - creates: /home/kreatiini/project/env/bin/django-admin
    - user: kreatiini

django_project:
  cmd.run:
    - name: /home/kreatiini/project/env/bin/django-admin startproject myproject /home/kreatiini/project/
    - creates: /home/kreatiini/project/myproject/manage.py
    - user: kreatiini

~~~

When testing the idempotency of the state I got an error:

![image](https://github.com/user-attachments/assets/4194e71a-86c3-4162-8b56-6e4fa668f59e)

I did had the path for `manage.py` wrong so it did not work. After fixing it to `/home/kreatiini/project/manage.py` the V3.1 works fine now:

![image](https://github.com/user-attachments/assets/490a28a7-e356-436b-b14f-1660ef6511b7)

#### Fourth version (master-minion)
So now I am able to create Django environment successfully. I am not sure how far should I automate it. I could also automate migrations. I am not sure if that is smart to automate since user will make the changes and should migrate after that.. 

I ran these tests locally on my own user. Next I should try it out on Vagrant and create user for development. That means I need to change some variables on it. If that works smoothly I will add version for Apache2. So now I created a version to run with `master-minion`:

~~~
developer:
  user.present:
    - home: /home/developer


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
~~~

First run succeeded and changed 6. I ran it twice and this is the third one:

![image](https://github.com/user-attachments/assets/d7698fa7-d5bd-4a72-8bdd-8768b92b169c)

So now we have a basic install for Django that is idempotent. Now I will figure out how I can set it up with apache. Basic idea is clear, install apache and modwsgi, create myproject.conf file that points to myproject and restart apache. Then we should be rocking. 
