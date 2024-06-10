FROM maven:3.8.1-openjdk-11-slim AS builder

# ARG ip
WORKDIR /build

COPY . .

# RUN sed -i "s/localhost/$ip/g" /build/src/main/java/com/game/config/WebsocketConfiguration.java
# RUN sed -i "s/localhost/$ip/g" /build/src/main/java/com/game/config/CorsConfig.java

RUN mvn clean package

FROM openjdk:11-jre-slim

WORKDIR /app

COPY --from=builder /build/target/tic-tac-toe-0.0.1-SNAPSHOT.jar /app/tic-tac-toe-0.0.1-SNAPSHOT.jar

EXPOSE 8080

CMD ["java", "-jar", "tic-tac-toe-0.0.1-SNAPSHOT.jar"]

FROM openjdk:19-jdk-alpine
COPY target/backend-0.0.1-SNAPSHOT.jar backend-0.0.1-SNAPSHOT.jar
ENTRYPOINT ["java","-jar","/backend-0.0.1-SNAPSHOT.jar"]

# FROM maven:3.8.7-eclipse-temurin-19 AS build
# ARG IP
# WORKDIR /backend
# COPY pom.xml .
# COPY src ./src
# RUN sed -i "s/localhost/$IP/g" ./src/main/java/com/game/config/WebsocketConfiguration.java
# RUN #sed -i "s/localhost/$IP/g" ./src/main/resources/application.properties


# RUN mvn clean package -DskipTests


# FROM eclipse-temurin:19
# WORKDIR /backend
# #ARG JAR_FILE=/spring/target/backend-0.0.1-SNAPSHOT.jar
# #COPY --from=build $JAR_FILE /app/runner.jar
# COPY --from=build /backend/target/backend-0.0.1-SNAPSHOT.jar .
# EXPOSE 8080
# CMD ["java", "-jar", "backend-0.0.1-SNAPSHOT.jar"]
