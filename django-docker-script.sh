#!/bin/bash

set -e

################################################################################
# Valid command checks
################################################################################

# Check for single name parameter
if [[ $# -ne 1 ]]; then
    echo "Only pass the project name as a parameter, spaces not allowed"
    exit
fi

# Set project name
PROJECT_NAME=$1


if [ -d $PROJECT_NAME ]
then
    echo "Directory for project name '${PROJECT_NAME}' already exists"
    exit
fi

################################################################################
# Check for commands
################################################################################

# Docker
if ! command -v docker &> /dev/null
then
    echo "docker could not be found"
    exit
fi

if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found"
    exit
fi

if ! command -v pip3 &> /dev/null
then
    echo "pip3 could not be found"
    exit
fi

################################################################################
# Create project directory
################################################################################

mkdir $PROJECT_NAME

################################################################################
# Create Django project
################################################################################

echo "Creating Django project"

mkdir $PROJECT_NAME/app
cd $PROJECT_NAME/app

echo "\tCopying over base files..."

# Copy Django base files
cp ../../django-base/Dockerfile .
cp ../../django-base/Dockerfile.prod .
cp ../../django-base/entrypoint.sh .
cp ../../django-base/entrypoint.prod.sh .
cp ../../django-base/requirements.txt .

# Setup python virtual environment with imports
echo "\tCreate python virtual environment..."
python3 -m venv env
source env/bin/activate

echo "\tInstalling pip requirements into virtual environment..."
pip3 install -r requirements.txt 1>/dev/null

echo "\tCreating project..."
# Create project
django-admin startproject $PROJECT_NAME .

# Replace Django settings with os retrievals
cd $PROJECT_NAME

echo "\tReplacing defaults settings.py values with os imports..."

DJANGO_IMPORT="from pathlib import Path\nimport os"
DJANGO_SECRET_KEY="SECRET_KEY = os.environ.get('SECRET_KEY')"
DJANGO_DEBUG="DEBUG = int(os.environ.get('DEBUG', default=0))"
DJANGO_ALLOWED_HOSTS="ALLOWED_HOSTS = os.environ.get('DJANGO_ALLOWED_HOSTS').split(' ')"

sed -i '' "s/from pathlib import Path/${DJANGO_IMPORT}/" settings.py
sed -i '' "s/SECRET_KEY.*/${DJANGO_SECRET_KEY}/" settings.py
sed -i '' "s/DEBUG.*/${DJANGo_DEBUG}/" settings.py
sed -i '' "s/ALLOWED_HOSTS.*/${DJANGO_ALLOWED_HOSTS}/" settings.py

DJANGO_DATABASE_ENGINE_REPLACE="'ENGINE': 'django.db.backends.sqlite3',"
DJANGO_DATABASE_NAME_REPLACE="'NAME': BASE_DIR \\/ 'db.sqlite3',"

DJANGO_DATABASE_ENGINE="'ENGINE': os.environ.get('SQL_ENGINE', 'django.db.backends.sqlite3'),"
DJANGO_DATABASE_NAME="'NAME': os.environ.get('SQL_DATABASE', os.path.join(BASE_DIR, 'db.sqlite3')),"
DJANGO_DATABASE_USER="\t'USER': os.environ.get('SQL_USER', 'user'),"
DJANGO_DATABASE_PASSWORD="\t'PASSWORD': os.environ.get('SQL_PASSWORD', 'password'),"
DJANGO_DATABASE_HOST="\t'HOST': os.environ.get('SQL_HOST', 'localhost'),"
DJANGO_DATABASE_PORT="\t'PORT': os.environ.get('SQL_PORT', '5432'),"

DJANGO_DATABASE_NAME+="\n"
DJANGO_DATABASE_NAME+="${DJANGO_DATABASE_USER}"
DJANGO_DATABASE_NAME+="\n"
DJANGO_DATABASE_NAME+="${DJANGO_DATABASE_PASSWORD}"
DJANGO_DATABASE_NAME+="\n"
DJANGO_DATABASE_NAME+="${DJANGO_DATABASE_HOST}"
DJANGO_DATABASE_NAME+="\n"
DJANGO_DATABASE_NAME+="${DJANGO_DATABASE_PORT}"

sed -i '' "s/$DJANGO_DATABASE_ENGINE_REPLACE/$DJANGO_DATABASE_ENGINE/" settings.py
sed -i '' "s/$DJANGO_DATABASE_NAME_REPLACE/$DJANGO_DATABASE_NAME/" settings.py

DJANGO_STATIC_URL="STATIC_URL = '\\/staticfiles\\/'"
DJANGO_STATIC_ROOT="STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')"
DJANGO_STATIC_REPLACE="${DJANGO_STATIC_URL}\n${DJANGO_STATIC_ROOT}"

sed -i '' "s/STATIC_URL.*/${DJANGO_STATIC_REPLACE}/" settings.py

# Exit and deactive python virtual environment
cd ..
deactivate
cd ..

################################################################################
# Create nginx
################################################################################

echo "Creating nginx configuration"

mkdir nginx
cd nginx

echo "\tCopying over base files..."

# Copy base files
cp ../../nginx-base/Dockerfile .
cp ../../nginx-base/nginx.conf .

echo "\tReplacing default values with project name..."

sed -i '' "s/<PROJECT-NAME>/${PROJECT_NAME}/" nginx.conf

cd ..

################################################################################
# Create environment files
################################################################################

echo "Creating environment files"

echo "\tCopying over base files..."

cp ../env-base/.env.dev .
cp ../env-base/.env.prod .
cp ../env-base/.env.prod.db .

echo "\tGenerating Django secrets..."

DEBUG_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe())")
PROD_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe())")

echo "\tReplacing default values..."

sed -i '' "s/<DEV-SECRET-KEY-TEMPLATE>/${DEBUG_SECRET}/" .env.dev
sed -i '' "s/<SQL-DATABASE-TEMPLATE>/${PROJECT_NAME}_dev/" .env.dev
sed -i '' "s/<SQL-USER-TEMPLATE>/${PROJECT_NAME}/" .env.dev
sed -i '' "s/<SQL-PASSWORD-TEMPLATE>/${PROJECT_NAME}/" .env.dev

sed -i '' "s/<PROD-SECRET-KEY-TEMPLATE>/${PROD_SECRET}/" .env.prod
sed -i '' "s/<SQL-DATABASE-TEMPLATE>/${PROJECT_NAME}_prod/" .env.prod
sed -i '' "s/<SQL-USER-TEMPLATE>/${PROJECT_NAME}/" .env.prod
sed -i '' "s/<SQL-PASSWORD-TEMPLATE>/${PROJECT_NAME}/" .env.prod

sed -i '' "s/<POSTGRES-USER-TEMPLATE>/${PROJECT_NAME}/" .env.prod.db
sed -i '' "s/<POSTGRES-PASSWORD-TEMPLATE>/${PROJECT_NAME}/" .env.prod.db
sed -i '' "s/<POSTGRES-DB-TEMPLATE>/${PROJECT_NAME}_prod/" .env.prod.db

################################################################################
# Create docker-compose files
################################################################################

echo "Creating docker-compose files"

echo "\tCopying over base files..."

cp ../docker-compose-base/docker-compose.yml .
cp ../docker-compose-base/docker-compose.prod.yml .

echo "\tReplacing default values..."

sed -i '' "s/<POSTGRES-USER-TEMPLATE>/${PROJECT_NAME}/" docker-compose.yml
sed -i '' "s/<POSTGRES-PASSWORD-TEMPLATE>/${PROJECT_NAME}/" docker-compose.yml
sed -i '' "s/<POSTGRES-DB-TEMPLATE>/${PROJECT_NAME}_dev/" docker-compose.yml

sed -i '' "s/<PROJECT-NAME>/${PROJECT_NAME}/" docker-compose.prod.yml

################################################################################
# Building containers from docker-compose
################################################################################

echo "Building and starting dev docker-compose"

docker compose build
docker-compose -f docker-compose.prod.yml build

################################################################################
# Done
################################################################################

echo "Done!"
