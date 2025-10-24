FROM dart:stable AS build

# Set working directory
WORKDIR /server

# Create necessary directories
RUN mkdir backend shared bin

# Copy dependency files
COPY packages/backend/pubspec.* ./backend/
COPY packages/shared/pubspec.* ./shared/
COPY docker/pubspec.yaml ./pubspec.yaml

# Resolve dependencies
WORKDIR /server/backend
RUN dart pub get
COPY packages/backend ./
RUN dart pub get --offline

WORKDIR /server/shared
RUN dart pub get
COPY packages/shared ./
RUN dart pub get --offline

# Compile the Dart application
WORKDIR /server
RUN dart compile exe backend/bin/main.dart -o bin/server

# Build minimal runtime image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /server/bin/server /server/bin/

# Expose port and set entrypoint
EXPOSE 3000
CMD ["/server/bin/server"]
