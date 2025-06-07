# Build stage
FROM gradle:8.14.1-jdk21-alpine AS build
WORKDIR /app

# Copy only gradle files first for better caching
COPY gradle gradle/
COPY gradlew gradlew.bat build.gradle settings.gradle ./

# Download dependencies (this layer will be cached)
RUN gradle dependencies --no-daemon

# Copy source code
COPY src src/

# Build the application
RUN gradle bootJar --no-daemon


# Runtime stage
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Install curl for healthcheck and create non-root user
RUN apk add --no-cache curl
RUN addgroup -S prudentia && adduser -S prudentia -G prudentia

# Copy the built jar
COPY --from=build /app/build/libs/*.jar app.jar

# Change ownership
RUN chown prudentia:prudentia app.jar

# Switch to non-root user
USER prudentia

# Expose port
EXPOSE 8080

# Improved healthcheck using curl
 HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Application startup
ENTRYPOINT ["java", "-jar", "app.jar"]