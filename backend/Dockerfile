FROM maven:3.8.7-eclipse-temurin-19 AS build

WORKDIR /backend
COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests


FROM eclipse-temurin:19
WORKDIR /backend
COPY --from=build /backend/target/tic-tac-toe-0.0.1-SNAPSHOT.jar .
EXPOSE 8080
CMD ["java", "-jar", "tic-tac-toe-0.0.1-SNAPSHOT.jar"]
