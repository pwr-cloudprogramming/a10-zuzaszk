# FROM maven:3.8.1-openjdk-11-slim AS builder

# # ARG ip
# WORKDIR /build

# COPY . .

# # RUN sed -i "s/localhost/$ip/g" /build/src/main/java/com/game/config/WebsocketConfiguration.java
# # RUN sed -i "s/localhost/$ip/g" /build/src/main/java/com/game/config/CorsConfig.java

# RUN mvn clean package

# FROM openjdk:11-jre-slim

# WORKDIR /app

# COPY --from=builder /build/target/tic-tac-toe-0.0.1-SNAPSHOT.jar /app/tic-tac-toe-0.0.1-SNAPSHOT.jar

# EXPOSE 8080

# CMD ["java", "-jar", "tic-tac-toe-0.0.1-SNAPSHOT.jar"]


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
