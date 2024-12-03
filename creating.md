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

So now we have a basic install for Django that is idempotent.

## Django-Apache module
After creating and saving the first module I will now make edits for postgresql database. Few days ago I did a manual setup on my own pc so I have a pretty clear idea how this works. Salt has some kind of commands for postgresql so I want to use them as much as I can. What I know I need:
- Postgresql
- Postgresql-server
- Psycopg
- Edit Django settings.py file with the Postgresql info
- Create Postgresql user and database
### First version (local)
I checked to see what is the syntax of database setup in Django so I can replace that part. First I was thinking about creating a new settings.py but Salt has an option to put your text in to specific place. The syntax for the command was hard one to create. After setting the initial version up I started to think that I might need to implement some kind of watch. So Django will  make migrations after changes. After adding the things previously I had a few errors:

![image](https://github.com/user-attachments/assets/0c859574-7200-45f4-8501-cfb9e3d5fef8)

I had some spelling mistakes on my .pkgs so it did not install postgresql or its dependencies correctly. After running it again:

![image](https://github.com/user-attachments/assets/0928d43e-32ac-4189-abcc-3ec8ce3f4302)

And it was pretty fast I think. Now I will delete the vagrant machines and run it again 3 times. After running it 3 times I will log to minion machine and check if it works. 

### Second version(minion)
Now I ran it with maseter to minion. First run succeeded. Two more times with no changes:

![image](https://github.com/user-attachments/assets/683638e8-8493-4732-b00c-7d29f176a2b3)


![image](https://github.com/user-attachments/assets/546cc9ae-c0af-4f66-b76d-ae7de8087c14)

![image](https://github.com/user-attachments/assets/1486d714-9f91-43d6-8e32-12b66fe154ed)

So it is idempotent. Now I will try it out on minion.

Postgresql daemon is running:

![image](https://github.com/user-attachments/assets/d222a0a0-2446-495d-be1d-174eb174ad36)

Settings.py is not correctly configured:

![image](https://github.com/user-attachments/assets/68fa0d34-8359-42d2-b19c-61573144e447)

Migrating gives the same error as on the pure Django install in the beginning. It worked fine earlier. Before checking this I will fix the settings.py issue:

![image](https://github.com/user-attachments/assets/00436587-435b-4871-a05f-109b9dcb393e)

### Third version

After messing with the config a bit I got it to write over the settings.py. Now it shows the changes on Salt. I also need to add the psycopg to the virtualenv and also found a module for pip in Salt. So I changed the Django install for pip. When I ran it I had some issues:

![image](https://github.com/user-attachments/assets/1c2a907c-3f5d-46ac-8c38-25405b1bbff7)

I did not find any mentions of the `-r` flag in salt documentation for `pip.installed`. I have to do some more searching. I read the documentation again and there is a `requirements: ` key. I used that and it worked. Now all commands ran succesfully. But it seems to change the settings.py every time somehow. I did some research but the pattern matching was too hard for me so I decided to just replace the settings.py file with salt. 
I did not get to test it since I can't use pip.installed correctly. It has something to do with privileges. It wont install anything if the user is defined as developer. If I don't define it user can't edit anything. 

After all editing this is my current init.sls. I did not even try to implement the settings.py thing since the installation of Django with pip.installed did not work. 

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
      - postgresql
      - postgresql-client
      - libpq-dev

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

requirements:
  file.managed:
    - name: /home/developer/project/requirements.txt
    - contents: |
        Django
        psycopg2
    - user: developer

requirements_install:
  pip.installed:
    - requirements: /home/developer/project/requirements.txt
    - bin_env: /home/developer/project/env/bin/pip
    - user: developer

postgresql_settings:
  postgres_user.present:
    - name: dev
    - password: "secret"
  postgres_database.present:
    - name: my_db
    - owner: dev

django_project:
  cmd.run:
    - name: /home/developer/project/env/bin/django-admin startproject myproject /home/developer/project/
    - creates: /home/developer/project/manage.py
    - user: developer

#add_postgresql_to_django:
#  file.managed:
  #  - name: /home/developer/project/myproject/settings.py
 #   - source: salt://djangres/settings.py
#    - user: developer

~~~

## End product

So all in all I am disappointed. The only working thing here was the pure Django install with nothing else. Just a boring cmd.run script basicly.
Final test for it with empty machine with three runs:
![image](https://github.com/user-attachments/assets/b95ff786-a4c2-4ece-835e-397002a40552)

![image](https://github.com/user-attachments/assets/6ca8811f-5ec1-4b8f-b53a-f022f348d293)

![image](https://github.com/user-attachments/assets/ace2f932-a1ec-413c-850f-eec083923c2f)

So idempotent as it should be. Next over to the slave. The files etc. have been created BUT the sqlite cant connect again. It worked earlier when I just created it with the user developer. Now it wont work. Also I cant edit the files as a user. So the permissions are issue again. 

After going through my notes I see I didn't test it well earlier. I got it to work locally on my own vm but I did not test it with master-minion. 

![image](https://github.com/user-attachments/assets/1bd27b08-5965-48cf-8c65-a5a1277ea6e5)

As you can see it works to a point but Django files are created with only root writing permissions. I can't understand why, maybe it has something to do with the virtualenv. I found a file.directory module and tried to use it. Commands ran succesfully but I doubt this. 

Testing shows that permissions are fine except manage.py was not executable so I added another module for it. I also added a module to make the database file before running migrations. I am guessing the issue is that I can change to user developer since I don't provide a password Debian will still ask for it... 

I added a hashed password for the user so I can switch to it but nope.. The terminal goes crazy like this:

![image](https://github.com/user-attachments/assets/b79138ff-884f-4f08-808f-a16f732534f3)

Now I declared the shell for /bin/bash. And su works fine. Also ./manage.py migrate works fine. So this might work.. The salt script is now bloated very badly with useless code or that is my guess. No time to fix it. Embrace the Chaos. I also now see that I cant test it since I am running it with one ssh connection. I have no setup to check the Django servers web page. Well it is what it is. Also in the end I have to say this report is bad. I did not report some(quite a few) things I tried and failed with the syntax. It took me about 6 hours to fix this after I saw that it did not work. Well now I have learned the lesson(s). Start small. Trust your gut feeling.  This is the end result:

~~~
developer:
  user.present:
    - home: /home/developer
    - password: "$6$86UilMBPope8TkhS$1ez8VvpYdau1mRY3tJn5hdDFFVTnUHI6pC1Ozvn6ThiEp458WK/FLTSu5KAXqRcy358SEp9prSSGGuHOprYDI1"
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
    - recurse:
        - user
        - group
        - mode
    - user: developer
    - group: developer
    - file_mode: '644'
    - dir_mode: '755'

managepy:
  file.managed:
    - name: /home/developer/project/manage.py
    - user: developer
    - group: developer
    - mode: '755'
create_db:
  file.managed:
    - name: /home/developer/project/db.sqlite3
    - user: developer
    - group: developer
    - mode: '664'
    - makedirs: True

sqlite_permissions:
  file.directory:
    - name: /home/developer/project
    - user: developer
    - group: developer
    - mode: '775'
~~~

