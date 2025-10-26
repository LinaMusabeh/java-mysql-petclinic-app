# java-mysql-petclinic-app
## Deploying Java app and MySQL on GKE
using the source code and the architecture of the @techiescamp pitclinic application and deploying it on Google Kubernetes Engine

### the architecture of the cluster

<img width="400" height="500" alt="image" src="https://github.com/user-attachments/assets/923b3024-4ba4-4544-b29e-13e4abc0440c" />

### Creating an image for the App
clone the actual java app:

```
git clone https://github.com/spring-projects/spring-petclinic.git
```

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

`docker build -t linasaeed/petclinicapp:1.0 .`


_________________
### Deploying the app to GKE

##### Create the cluster
using the default zone `us-west1-a`, wrote the following command

```
gcloud container clusters create petclinicapp
```

the cluster is created and ready, and we can see it in the console:

<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/be708f2a-545b-4b67-b5ce-a4f9d28d3c96" />


creating two name spaces to logically separate the services and give them Secrets:

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

navigateing google console to the secret and config maps tab and see the created secrets

<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/07445c16-3b98-4792-b6eb-71cbe6d603df" />

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


apply the configmap files
```
kubectl apply -f <PATH>
```
<img width="500" height="270" alt="image" src="https://github.com/user-attachments/assets/8ffa0b25-763a-4d2e-8bb0-5281590f4252" />


___________________________

### Deploying MySQL service

we need to first create `StatefulSet` to manage the pods that we are going to deploy the database on. inside the same manifest file we are going to create the `Service` of the database.
the pod will be created from the `Statefulset` specs

inside the same file we create the `NodePort` service that will serve as an entry point.
the file is `mysql.yml`

inside the Gateways, Services & Ingress tab: 

<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/125e3158-15d1-43d0-b120-5adbb4af877a" />

inside the Object Browser:

<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/15047f35-3ff4-448f-a19d-36f5006c049e" />



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
<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/7ae0ec2c-1a2d-4415-bd7b-23fa3c777f18" />


navigate to the Workloads:

<img width="500" height="400" alt="image" src="https://github.com/user-attachments/assets/a8595730-dc1d-4aea-82e4-37b7894e5207" />


### Deploy the HorizontalPodAutoscaler (HPA)

first create the yaml file for the `metrics-server` (if you don't have one already), apply it and check if it is working.

`kubectl top pod -n petclinic-app`

this will replay with metrics calculation of the pod if the server is working

```
NAME                        CPU(cores)   MEMORY(bytes)
java-app-7b7c99f4b8-ztxpn   11m          250Mi
```

then apply the `hpa.yml` file 

_______________
### Set a Firewall rule 


navigate to the network policies on your console and create a new rule.
name the rule properly, give it a priority, allow traffic from `0.0.0.0/0` and protocol `TCP:32000`.

go to the node where the app is and get the public IP address of it, access the app through the web by typing:
`node_ip_address:32000`

and good job!

<img width="2559" height="1052" alt="image" src="https://github.com/user-attachments/assets/51adf0df-12a4-4f9f-b39d-f4eef2c674b1" />

