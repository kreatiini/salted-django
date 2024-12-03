# Instructions
Simple to use. I am assuming you have SaltStack setup already. If not refer to SaltStack documentation. 

1. Create directory on master for Salt module `mkdir -p /srv/salt/django`
2. Go to the directory `cd /srv/salt/django`
3. Create a file `sudoedit init.sls` and copypaste the init.sls from this repo
4. Create SHA-512 hashed password for example with CLI-tool `mkpasswd` -> `mkpasswd -m SHA-512 yourpassword`
5. Edit line 4 `password: ` and replace the string  with your own hashed password
6. Run `salt '*' state.apply django`
7. After finishing the run get on the minion
8. `su developer` and enter your password
9. Go to directory `cd /home/developer/project`
10. Run `source /env/bin/activate`
11. Run `./manage.py migrate`
12. Run `./manage.py makemigrations`
13. Start the server with `./manage.py runserver`
14. Time to create web apps
