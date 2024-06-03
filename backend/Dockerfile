FROM maven:3.8.1-openjdk-11-slim AS builder

WORKDIR /build

COPY . .

RUN mvn clean package

FROM openjdk:11-jre-slim

WORKDIR /app

COPY --from=builder /build/target/tic-tac-toe-0.0.1-SNAPSHOT.jar /app/tic-tac-toe-0.0.1-SNAPSHOT.jar

EXPOSE 8080

CMD ["java", "-jar", "tic-tac-toe-0.0.1-SNAPSHOT.jar"]