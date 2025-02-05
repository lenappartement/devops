# Compte rendu

## 1.1 Why should we run the container with a flag -e to give the environment variables?
Le flag -e permet de sécuriser la connexion à la base en évitant d'écrire en dur dans un fichier les mots de passe et identifiants de la BDD. On peut faire passer les différentes variables d'environnement avec ce flag.

## 1-2 Why do we need a volume to be attached to our postgres container?
Le volume permet de sauvegarder l'état de la base de données (tables créées, données ajoutées..). Ainsi les données ne sont pas perdues lorsqu'on éteint et redémarre le container.

## 1-3 Document your database container essentials: commands and Dockerfile.
```bash
# Pour build une image
docker build -t lenappartement/database .

# Run le container avec l'image de la database, passe les paramètres avec -e, le network et utilisation d'un volume
docker run -d --name database --network app-network -e POSTGRES_DB=db -e POSTGRES_USER=usr -e POSTGRES_PASSWORD=pwd -v devops-volume:/var/lib/postgresql/data -P lenappartement/database

# Run le container adminer sur le même network que la database, on mappe sur le port 8080
docker run -d --name adminer --network app-network -p 8080:8080 adminer

# Supprime et éteint les containers
docker rm -f database
docker rm -f adminer
```

Dockerfile :
```docker
FROM postgres:14.1-alpine

# Expose le port de la BDD
EXPOSE 5432

# Copie les fichiers sql pour charger le schéma et les data dans la base
COPY CreateScheme.sql /docker-entrypoint-initdb.d
COPY InsertData.sql /docker-entrypoint-initdb.d
```

## 1-4 Why do we need a multistage build? And explain each step of this dockerfile.
Le multistage build permet de réduire la taille de l'image docker finale. On va dans un premier temps compiler les fichiers, puis copier uniquement les fichiers compiler dans l'image finale. Ainsi l'image finale aura une taille réduite.

Description du dockerfile :
```docker
# On utilise amazoncorretto avec maven pour compiler le projet 
FROM maven:3.9.9-amazoncorretto-21 AS myapp-build
# Répertoire où sera stocké le projet
ENV MYAPP_HOME=/opt/myapp 
WORKDIR $MYAPP_HOME
# On copie les fichiers utile à la compilation
COPY pom.xml .
COPY src ./src
# Compilation
RUN mvn package -DskipTests

# Utilisation de amazoncorretto sans maven 
FROM amazoncorretto:21
# Répertoire où sera stocké le projet
ENV MYAPP_HOME=/opt/myapp 
WORKDIR $MYAPP_HOME
# On copie depuis la première image, uniquement le dossier compilé .jar
COPY --from=myapp-build $MYAPP_HOME/target/*.jar $MYAPP_HOME/myapp.jar
```

## 1-5 Why do we need a reverse proxy?
Un reverse proxy permet d'assurer la sécurité en masquant l'adresse ip du serveur backend. Cela permet aussi de chiffrer la communication entre le front et le back. Dans le cas où l'on a plusieurs serveurs backend on peut aussi se servir du reverse proxy pour rediriger sur les différents serveurs et assurer la haute disponibilité avec le load balancing.

## 1-6 Why is docker-compose so important?
Il permet un gain de temps. L'ensemble des commandes sont réalisées en une seule, on peut build et démarrer les containers en 2 commandes :
- `docker-compose build`
- `docker-compose up`
Ou bien avec la commande `docker-compose up --build` directement

## 1-7 Document docker-compose most important commands. 
- `docker-compose build`
- `docker-compose up`
- `docker-compose up --build`
- `docker-compose down`

## 1-8 Document your docker-compose file.
```yaml
version: '3.7'

services:
    backend:
        build:
          # Dossier où se trouve le dockerfile
          context: ./backend
          # Nom du dockerfile
          dockerfile: Backend.Dockerfile
        networks:
        - app-network
        # Variables d'environnement de connexion à la BDD
        environment:
        - DB_NAME=${DB_NAME}
        - DB_HOST=${DB_HOST}
        - DB_USER=${DB_USER}
        - DB_PASSWORD=${DB_PASSWORD}
        # Le backend doit se lancer après la database
        depends_on:
        - database
        # Fichier avec les variables d'environnement
        env_file: ".env"

    database:
        build:
          context: ./database
          dockerfile: Database.Dockerfile
        # On mappe le port 5432 sur le port 5432
        ports:
        - 5432:5432
        environment:
        - POSTGRES_DB=${DB_NAME}
        - POSTGRES_USER=${DB_USER}
        - POSTGRES_PASSWORD=${DB_PASSWORD}
        networks:
        - app-network
        # Volume où sont stockées les données de la base
        volumes:
        - /home/lena/Documents/DevOps/devops/volume:/var/lib/postgresql/data
        env_file: ".env"

    frontend:
        build:
          context: ./frontend
          dockerfile: Frontend.Dockerfile
        # On mappe le port 80 sur le port 80
        ports:
        - 80:80
        networks:
        - app-network
        # Le frontend doit se lancer après le backend
        depends_on:
        - backend

# Network
networks:
    app-network:
```

## 1-9 Document your publication commands and published images in dockerhub.
Création des tag :
- docker tag lenappartement/frontend lenappartement/frontend:1.0
- docker tag lenappartement/backend lenappartement/backend:1.0
- docker tag lenappartement/database lenappartement/database:1.0

Publication :
- docker push lenappartement/frontend:1.0
- docker push lenappartement/backend:1.0
- docker push lenappartement/database:1.0

## 1-10 Why do we put our images into an online repo?
Cela permet de les partager avec d'autres personnes, de pouvoir y accéder depuis n'importe où et de gérer les différentes versions du container.

## 2-1 What are testcontainers?
Ce sont des containeurs d'une librairie java. Ils permettent de lancer des tests sur différentes parties du projet lors du lancement de la commande `mvn clean verify`. Dans notre projet il y en a un pour postgresql et jdbc afin de valider que la connexion à la base de données est correcte.

## 2-2 Document your Github Actions configurations.
```yml
name: CI devops 2025
on:
  # Lance les tests sur les branches main et develop
  push:
    branches: 
      - main
      - develop
  pull_request: 

jobs:
  test-backend: 
    runs-on: ubuntu-22.04
    steps:
     # Récupère les fichiers avec un git checkout
      - uses: actions/checkout@v2.5.0

     # Met en place java avec la distribution et version choisie
      - name: Set up JDK 21
        uses: actions/setup-java@v3
        with:
          distribution: 'corretto'
          java-version: '21'

     # Build le projet avec maven le fichier de config pom.xml
      - name: Build and test with Maven
        run: mvn clean verify --file backend/pom.xml
```

## 2-3 For what purpose do we need to push docker images?
Cela permet de mettre à jour nos images sur le docker hub, cela peut servir si on partage nos images avec d'autres personnes, ou afin de déployer une version à jour tout simplement.

## 2-4 Document your quality gate configuration.
```yml
run: mvn -B verify sonar:sonar -Dsonar.projectKey=lenappartement_devops -Dsonar.organization=lenadevops -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=${{ secrets.SONAR_TOKEN }}  --file ./backend/pom.xml

```
Dans le `pom.xml`, on ajoute ces deux lignes pour lier à notre organisation :
```yml
<sonar.organization>lenadevops</sonar.organization>
<sonar.host.url>https://sonarcloud.io</sonar.host.url>
``` 

Pour récupérer la version du projet du pom.xml : `mvn help:evaluate -Dexpression=project.version -q -DforceStdout --file backend/pom.xml`

## 3-1 Document your inventory and base commands
```yml
all: # Groupe contenant les hosts
 vars: # Variables utiles à la connexion
   ansible_user: admin # User sur le serveur
   ansible_ssh_private_key_file: /home/lena/Documents/DevOps/id_rsa # Chemin d'accès à ma clé rsa pour la connexion ssh
 children:
   prod: # Groupe production
     hosts: lena.iglesis.takima.cloud # Serveur
```

Commande permettant de lister les informations sur l'OS de notre serveur :
```bash
ansible all -i inventories/setup.yml -m setup -a "filter=ansible_distribution*"
```
Commande permettant de lancer une commande apt, ici apt remove pour désinstaller apache. L'option `--become` permet d'obtenir les privilèges admin :
```bash
ansible all -i inventories/setup.yml -m apt -a "name=apache2 state=absent" --become
``` 
Commande pour vérifier si l'installation de docker est ok :
```bash
ansible all -m service -a "name=docker state=started" --private-key=id_rsa -u admin --become
``` 

## 3-2 Document your playbook
On conserve uniquement le dossier tasks :
```
ansible/
│-- inventories
│-- playbook.yml
│-- roles/
│   ├── docker/
│       ├── tasks/
│       │   ├── main.yml
```

```yml
---
# Installation des prérequis pour Docker avec la commande apt install
- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - python3-venv
    state: latest
    update_cache: yes


# On ajoute la clé GPG de docker avec la commande apt-key add
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/debian/gpg
    state: present


# On ajoute le repository de docker avec add-apt-repository
- name: Add Docker APT repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/debian {{ ansible_facts['distribution_release'] }} stable"
    state: present
    update_cache: yes


# Installe Docker avec apt install
- name: Install Docker
  apt:
    name: docker-ce
    state: present


# Installe Python3 et pip3 avec apt install
- name: Install Python3 and pip3
  apt:
    name:
      - python3
      - python3-pip
    state: present


# Crée un environnement virtuel Python packages
- name: Create a virtual environment for Docker SDK
  command: python3 -m venv /opt/docker_venv
  args:
    creates: /opt/docker_venv  # Commande se lance uniquement si le dossier n'existe pas


# Installe Docker SDK pour l'environnement virtuel
- name: Install Docker SDK for Python in virtual environment
  command: /opt/docker_venv/bin/pip install docker


# Vérifie si docker est démarré
- name: Make sure Docker is running
  service:
    name: docker
    state: started
  tags: docker
```

## 3-3 Document your docker_container tasks configuration.
Roles :
* app : déploie l'image docker du backend 
* database : déploie l'image docker de la bdd
* docker : installe docker
* env : copie le fichier .env local sur le serveur
* network : crée les deux networks utilisés par l'application
* volume : crée le volume de la base de données
* proxy : déploie l'image docker du proxy