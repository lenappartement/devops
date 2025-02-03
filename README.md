# Compte rendu

## 1.1 Why should we run the container with a flag -e to give the environment variables?
Le flag -e permet de sécuriser la connexion à la base en évitant d'écrire en dur dans un fichier les mots de passe et identifiants de la BDD.

## 1-2 Why do we need a volume to be attached to our postgres container?
Le volume permet de sauvegarder l'état de la base de données (tables créées, données ajoutées..). Ainsi les données ne sont pas perdues lorsqu'on éteint et redémarre le container.

## 1-3 Document your database container essentials: commands and Dockerfile.
```
docker build -t lenappartement/database .

docker run -d --name database --network app-network -e POSTGRES_DB=db -e POSTGRES_USER=usr -e POSTGRES_PASSWORD=pwd -v /home/lena/Documents/DevOps/devops/volume:/var/lib/postgresql/data -P lenappartement/database

docker run -d --name adminer --network app-network -p 8080:8080 adminer

docker rm -f database
docker rm -f adminer
```

## 1-4 Why do we need a multistage build? And explain each step of this dockerfile.
Le multistage build permet de réduire la taille de l'image docker finale. On va dans un premier temps compiler les fichiers, puis copier uniquement les fichiers compiler dans l'image finale. Ainsi l'image aura une taille réduite.

Description du dockerfile :
```
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