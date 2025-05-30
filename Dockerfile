ARG CANTALOUPE_VERSION=5.0.7

# Build
FROM ubuntu:noble@sha256:6015f66923d7afbc53558d7ccffd325d43b4e249f41a6e93eef074c9505d2233 AS build

ARG DEBIAN_FRONTEND=noninteractive
ARG CANTALOUPE_VERSION

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

# Grab source code and patch
RUN curl --silent --fail -OL https://github.com/cantaloupe-project/cantaloupe/archive/refs/tags/v$CANTALOUPE_VERSION.zip
RUN unzip v$CANTALOUPE_VERSION.zip
RUN mv cantaloupe-$CANTALOUPE_VERSION cantaloupe-src

# Add our patches to the source
COPY ./patches ./
RUN cd cantaloupe-src/ && patch -p1 < /add-WebIdentityTokenFileCredentialsProvider-to-credentials-chain.patch

# Install application dependencies
RUN cd cantaloupe-src/ && mvn --quiet dependency:resolve

# Build
RUN cd cantaloupe-src/ && mvn clean package -DskipTests



# Package
FROM ubuntu:noble@sha256:6015f66923d7afbc53558d7ccffd325d43b4e249f41a6e93eef074c9505d2233 AS image
LABEL org.opencontainers.image.source="https://github.com/elifesciences/cantaloupe-image"

ARG CANTALOUPE_VERSION
ENV CANTALOUPE_VERSION=$CANTALOUPE_VERSION

EXPOSE 8182

# Update packages and install tools
RUN apt-get update -qy && apt-get dist-upgrade -qy && \
    apt-get install -qy --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless adduser && \
    apt-get -qqy autoremove && apt-get -qqy autoclean

# Run non privileged
RUN adduser --system cantaloupe

# Get and unpack Cantaloupe release archive

COPY --from=build /cantaloupe-src/target/cantaloupe-$CANTALOUPE_VERSION.zip ./opt
RUN cd /opt \
    && unzip cantaloupe-$CANTALOUPE_VERSION.zip \
    && ln -s cantaloupe-$CANTALOUPE_VERSION cantaloupe \
    && rm cantaloupe-$CANTALOUPE_VERSION.zip \
    && mkdir -p /var/log/cantaloupe /var/cache/cantaloupe

RUN chown -R cantaloupe /opt/cantaloupe-$CANTALOUPE_VERSION /var/log/cantaloupe /var/cache/cantaloupe

# Allow overridable config file path
ENV CANTALOUPE_CONFIG_PATH=/opt/cantaloupe/cantaloupe.properties.sample

USER cantaloupe
CMD ["sh", "-c", "java -Dcantaloupe.config=\"$CANTALOUPE_CONFIG_PATH\" -Dsoftware.amazon.awssdk.http.service.impl=software.amazon.awssdk.http.urlconnection.UrlConnectionSdkHttpService -jar /opt/cantaloupe/cantaloupe-$CANTALOUPE_VERSION.jar"]
