FROM maven:3.8.5-openjdk-17 as builder
WORKDIR /app
COPY ./app/pom.xml .
RUN mvn dependency:go-offline
COPY ./app/src/ ./src/
RUN mvn clean package -DskipTests=true

FROM gcr.io/distroless/java17-debian12
COPY --from=builder /app/target/*.jar /app/main.jar
WORKDIR /app
CMD ["main.jar"]
