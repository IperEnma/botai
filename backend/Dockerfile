# Build + runtime (Oracle ARM / Render / cualquier host con Docker).
# En la VM: docker compose -f docker-compose.prod.yml build backend

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN groupadd -r botai && useradd -r -g botai botai
COPY --from=build /app/target/*.jar app.jar
RUN chown botai:botai /app/app.jar
USER botai
EXPOSE 8080
# Heap: Render ~384m (JAVA_OPTS). Oracle VM: JAVA_OPTS=-Xmx3g en docker-compose.prod.yml
ENTRYPOINT ["sh","-c","exec java ${JAVA_OPTS:--Xmx512m} -XX:+UseContainerSupport -jar app.jar"]
