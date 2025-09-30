# Deploying Java + MySQL Application on GKE
this project is done using the guid of the @techiescamp and source code of the application 
__________________________________________________________________________________________________
redrawing the architecture of the cluster:

<img width="400" height="600" alt="image" src="https://github.com/user-attachments/assets/4c680feb-dd57-4dd2-b0d6-c8069aad3e6c" />


### Creating an image for the App
clone the actual java app:

```
git clone https://github.com/spring-projects/spring-petclinic.git
```

change your working directory to the directory of the project.

creating a multi-stage docker file the first stage is for the build and the other is for the runtime:

```shell
FROM maven:4.0.0-rc-4-eclipse-temurin-25-noble AS builder
WORKDIR /app  
ENV MAVEN_OPTS="-Xmx2048m"
COPY pom.xml .
COPY src ./src
RUN mvn clean install -DskipTests -e -X

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar ./PetClinicApp.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "PetClinicApp.jar"]
```

added environment variable to increase the memory during the build of the app.

building the image from the Dockerfile:

```
docker build -t linasaeed/petclinicapp:1.0 .
```


_________________
### Deploying the app on GKE

##### Create the cluster
using the default zone `us-west1-a`, wrote the following command

```
gcloud container clusters create petclinicapp
```
cluster is created

<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/0536638c-6832-41e8-af68-6263f2247dcf" />