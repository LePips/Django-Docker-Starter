# Django-Docker-Starter

Bash script that will create a Django project in Docker based upon the tutorial by [Michael Herman](https://testdriven.io/blog/dockerizing-django-with-postgres-gunicorn-and-nginx/), excluding the Media Files section.

This is meant as a quick template for creating Django projects in Docker and highly recommend reading the tutorial and other resources for deploying in a production environment.

# Usage

Simply run the script with a single parameter as the project name. This will create the entire project in the same directory with a folder with the project name.
The script will end by building the containers for the dev and prod environments. Collecting the static files for the prod environment must still be done manually.

```bash
sh django-docker-script.sh hello_django
```

# Development

- I would personally like to explore the option to hot-swap databases as I would like to experiment with using a MySql database
- Expanding the script to the next tutorial in the series: [Securing a Containerized Django Application with Let's Encrypt](https://testdriven.io/blog/django-lets-encrypt/)
- Implement the ability to add custom front end servers (like React/Vue) in the case the backend is used as a REST api (since djangorestframework is provided in requirements.txt)
- Ensure portability to other OS's
- Better print outs
- Package as a brew formula and/or debian package
