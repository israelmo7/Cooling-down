# Shop computer image. The shop PC runs this container and does not need Dart.
FROM dart:3.13.5 AS build

WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY bin bin
COPY lib lib
RUN dart build cli -o /out

FROM dart:3.13.5

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates tzdata \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /out/bundle /opt/cooling-down
WORKDIR /data
EXPOSE 8080
ENTRYPOINT ["/opt/cooling-down/bin/server"]
