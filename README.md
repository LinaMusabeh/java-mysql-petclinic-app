
redrawing the architecture of the cluster:

![[Pasted image 20250930090839.png | 400]]

### Creating an image for the App
clone the actual java app:

```
git clone https://github.com/spring-projects/spring-petclinic.git
```

change your working directory to the directory of the project.

creating a multi-stage docker file the first stage is for the build and the other is for the runtime:

```DSL
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

`docker build -t linasaeed/petclinicapp:1.0 .`


_________________
### Deploying the app on GKE

##### Create the cluster
using the default zone `us-west1-a`, wrote the following command

```
gcloud container clusters create petclinicapp
```

the cluster is created and ready:

![[README-20250930111948864.png]]


creating two name spaces to logically separate the services and give them secrets:

```
kubectl create ns petclinic-app
kubectl create ns petclinic-db
```

we need at least one secrete per namespace, they will contain the database credentials. writing the yaml file to define the object :

the yaml file objects will be `apiVersion`,`kind`, `metadata` contains the name of the object and the namespace (write the name of the spaces you created for the app and the database), the `type` of the secret, there are different types check the docs to see the difference, `data` which is the sensitive data you want to store in the object. in our case its the database username and password encoded in BASE64.

```yml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-cred
  namespace: petclinic-app
type: Opaque
data:
  username: "user name encoded in base64"
  password: "passowrd encoded in base64"
```

```yml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-cred
  namespace: petclinic-app
type: Opaque
data:
  username: "user name encoded in base64"
  password: "passowrd encoded in base64"
```


then in the command line `gcloud`
type the apply command to create the two secretes

```
kubectl apply -f <YML_FILE_PATH>
```

two times for each file

navigate google console to the secret and config maps tab and see the created secrets

![[Pasted image 20250930121501.png]]

## Creating ConfigMaps
the config map for the file will do the following:
- Stores all application configuration in **one place** (`application.properties`).
- Allows **separating config from code**, so the same image can be used in dev/staging/prod with different ConfigMaps.
- Uses **environment variables** for sensitive info like database credentials.
- Configures database, web, JPA, i18n, actuator, logging, and caching settings for your Spring Boot Java app.
  
the configmap for the database will do the following:

- Creates the MySQL user and grants privileges.
- Sets the database to use (petclinic).
- Creates all tables needed by the app (vets, specialties, owners, pets, visits).
- Inserts demo data for testing and development.


then apply the configmap files
```
kubectl apply -f <PATH>
```

![[Pasted image 20250930142014.png]]
![[README-20250930142006933.png]]

___________________________

### Deploying MySQL service

we need to first create `StatefulSet` to manage the pods that we are going to deploy the database on. inside the same manifest file we are going to create the `Service` of the database.
the pod will be created from the `Statefulset` specs

inside the same file we create the `NodePort` service that will serve as an entry point.
the file is `mysql.yml`

![[README-20250930145851859.png]]

![[Pasted image 20250930145938.png]]


_________________________
### Deploy the Java application 

create a yaml to deploy `Deployment` and a `NodePort` service, inside the `petclinic-app` namespace, and the container will use the image we pushed to the docker hub in the first step
`linasaeed/petclinicapp:1.0`
the file includes also the creation of health tests


`kubectl apply -f <path>` again 

```
deployment.apps/java-app created
service/java-app-service created
```

![[Pasted image 20250930150656.png]]

navigate to the Workloads:
![[Pasted image 20250930150813.png]]

when i deployed i faced the following problem 
![[Pasted image 20250930151927.png]]

the jar file was not found.

i created a container on my docker desktop to see where the jar file is, and the name was different than what was in the example so be careful to that

![[README-20250930152109844.png]]
![[Pasted image 20250930152115.png]]

all you have to do, if any mistake happened and you want to modify the yaml file, write the `apply` command again 

```
deployment.apps/java-app configured
service/java-app-service unchanged
```

![[README-20250930153003356.png]]

### Deploy the HorizontalPodAutoscaler (HPA)

first create the yaml file for the `metrics-server` (if you don't have one already), apply it and check if it is working.

`kubectl top pod -n petclinic-app`

this will replay with metrics calculation of the pod if the server is working

```
NAME                        CPU(cores)   MEMORY(bytes)
java-app-7b7c99f4b8-ztxpn   11m          250Mi
```

then apply the `hpa.yml` file 

![[Pasted image 20250930173049.png]]


_______________
### Set a Firewall rule 


navigate to the network policies on your console and create a new rule.
name the rule properly, give it a priority, allow traffic from `0.0.0.0/0` and protocol `TCP:32000`.

go to the node where the app is and get the public IP address of it, access the app through the web by typing:
`node_ip_address:32000`

and good job!

![[README-20250930185158564.png]]

