# Use a newer supported Alpine base image instead 
# (replacing alpine:3.12 from the initial baseline)
FROM alpine:3.21

# Install only the Ruby runtime actually needed by healthcheck.rb.
# `apk add --no-cache` fetches the package index for this step and
# does not keep the APK cache afterwards in the final image layer.
RUN apk add --no-cache ruby

# Create a dedicated unprivileged runtime identity ('app') for the container process.
# - addgroup -S app      = create a system group named `app`
# - adduser  -S -G app app = create a system user named `app` in group `app`
RUN addgroup -S app && adduser -S -G app app

# Use a dedicated working directory instead of placing files directly in / 
WORKDIR /app

# Copy the script into the image and assign ownership directly to the new 'app' user.
COPY --chown=app:app healthcheck.rb /app/healthcheck.rb

# Run the container as the unprivileged `app` user instead of root.    
# This is safer: If something goes wrong inside the container, 
# the process has fewer privileges and can do less harm
USER app

# Run the healthcheck script directly via the Ruby interpreter.
ENTRYPOINT ["ruby", "/app/healthcheck.rb"]