# Compte rendu

## 1.1 Why should we run the container with a flag -e to give the environment variables?
Le flag -e permet de sécuriser la connexion à la base en évitant d'écrire en dur dans un fichier les mots de passe et identifiants de la BDD.

## 1-2 Why do we need a volume to be attached to our postgres container?
Le volume permet de sauvegarder l'état de la base de données (tables créées, données ajoutées..). Ainsi les données ne sont pas perdues lorsqu'on éteint et redémarre le container.

## 1-3 Document your database container essentials: commands and Dockerfile.
```bash
docker build -t lenappartement/database .

docker run -d --name database --network app-network -e POSTGRES_DB=db -e POSTGRES_USER=usr -e POSTGRES_PASSWORD=pwd -v /home/lena/Documents/DevOps/devops/volume:/var/lib/postgresql/data -P lenappartement/database

docker run -d --name adminer --network app-network -p 8080:8080 adminer

docker rm -f database
docker rm -f adminer
```

Dockerfile :
```docker
FROM postgres:14.1-alpine

EXPOSE 5432

COPY CreateScheme.sql /docker-entrypoint-initdb.d
COPY InsertData.sql /docker-entrypoint-initdb.d
```

## 1-4 Why do we need a multistage build? And explain each step of this dockerfile.
Le multistage build permet de réduire la taille de l'image docker finale. On va dans un premier temps compiler les fichiers, puis copier uniquement les fichiers compiler dans l'image finale. Ainsi l'image aura une taille réduite.

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
- docker-compose build
- docker-compose up

## 1-7 Document docker-compose most important commands. 
- docker-compose build
- docker-compose up
- docker-compose up --build
- docker-compose down

## 1-8 Document your docker-compose file.
```yaml
version: '3.7'

services:
    backend:
        build:
          context: ./
          dockerfile: Backend.Dockerfile
        networks:
        - app-network
        depends_on:
        - database

    database:
        build:
          context: ./
          dockerfile: Database.Dockerfile
        ports:
        - 5432:5432
        environment:
        - POSTGRES_DB=db
        - POSTGRES_USER=usr
        - POSTGRES_PASSWORD=pwd
        networks:
        - app-network
        volumes:
        - /home/lena/Documents/DevOps/devops/volume:/var/lib/postgresql/data

    frontend:
        build:
          context: ./
          dockerfile: Frontend.Dockerfile
        ports:
        - 80:80
        networks:
        - app-network
        depends_on:
        - backend

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