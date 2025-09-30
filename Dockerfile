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
