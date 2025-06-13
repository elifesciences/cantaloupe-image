ARG BUILD_SOURCE=release
# or, as and example of building locally:
#ARG BUILD_SOURCE=local
ARG CANTALOUPE_VERSION=5.0.7

# Build
FROM ubuntu:noble@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f AS base

ARG DEBIAN_FRONTEND=noninteractive

# Install various dependencies:
# * ca-certificates is needed by wget
# * ffmpeg is needed by FfmpegProcessor
# * wget download stuffs in this dockerfile
# * libopenjp2-tools is needed by OpenJpegProcessor
# * All the rest is needed by GrokProcessor
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    openjdk-21-jdk-headless \
    ffmpeg \
    maven \
    wget \
    libopenjp2-tools \
            liblcms2-dev \
            libpng-dev \
            libzstd-dev \
            libtiff-dev \
            libjpeg-dev \
            zlib1g-dev \
            libwebp-dev \
            libimage-exiftool-perl \
            libgrokj2k1 \
            grokj2k-tools \
            curl \
            unzip \
            patch

FROM base AS release
ARG CANTALOUPE_VERSION
# Grab source code and patch if build release
RUN curl --silent --fail -OL "https://github.com/cantaloupe-project/cantaloupe/archive/refs/tags/v$CANTALOUPE_VERSION.zip"
RUN unzip v$CANTALOUPE_VERSION.zip
RUN mv cantaloupe-$CANTALOUPE_VERSION cantaloupe-src

# Add our patches to the source
COPY ./patches ./
RUN cd cantaloupe-src/ && patch -p1 < /add-WebIdentityTokenFileCredentialsProvider-to-credentials-chain.patch

FROM base AS local
# Grab source code from local checkout
COPY ./cantaloupe-src cantaloupe-src


FROM $BUILD_SOURCE AS build
# Install application dependencies
RUN cd cantaloupe-src/ && mvn --quiet dependency:resolve

# Build
RUN cd cantaloupe-src/ && mvn clean package -DskipTests



# Package
FROM ubuntu:noble@sha256:b59d21599a2b151e23eea5f6602f4af4d7d31c4e236d22bf0b62b86d2e386b8f AS image
LABEL org.opencontainers.image.source="https://github.com/elifesciences/cantaloupe-image"

EXPOSE 8182

# Update packages and install tools
RUN apt-get update -qy && apt-get dist-upgrade -qy && \
    apt-get install -qy --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless adduser && \
    apt-get -qqy autoremove && apt-get -qqy autoclean

# Run non privileged
RUN adduser --system cantaloupe

# Get and unpack Cantaloupe release archive

COPY --from=build /cantaloupe-src/target/*.zip ./opt/

RUN cd /opt \
    && unzip cantaloupe-*.zip \
    && rm cantaloupe-*.zip \
    && ln -s cantaloupe-* cantaloupe \
    && mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && cd /opt/cantaloupe \
    && ln -s cantaloupe-*.jar cantaloupe.jar

RUN chown -R cantaloupe /opt/cantaloupe-* /var/log/cantaloupe /var/cache/cantaloupe

# Allow overridable config file path
ENV CANTALOUPE_CONFIG_PATH=/opt/cantaloupe/cantaloupe.properties.sample

USER cantaloupe
CMD ["sh", "-c", "java -Dcantaloupe.config=\"$CANTALOUPE_CONFIG_PATH\" -Dsoftware.amazon.awssdk.http.service.impl=software.amazon.awssdk.http.urlconnection.UrlConnectionSdkHttpService -jar /opt/cantaloupe/cantaloupe.jar"]
