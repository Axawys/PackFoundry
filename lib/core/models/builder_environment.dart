enum BuilderEnvironmentId { debBookworm, rpmFedora }

class BuilderEnvironment {
  const BuilderEnvironment({
    required this.id,
    required this.title,
    required this.imageTag,
    required this.baseImage,
    required this.cacheVolume,
    required this.dockerfile,
    required this.estimatedInstallSeconds,
  });

  final BuilderEnvironmentId id;
  final String title;
  final String imageTag;
  final String baseImage;
  final String cacheVolume;
  final String dockerfile;
  final int estimatedInstallSeconds;

  static const debBookworm = BuilderEnvironment(
    id: BuilderEnvironmentId.debBookworm,
    title: 'DEB Builder',
    imageTag: 'packfoundry/deb-builder:bookworm-flutter-stable-v1',
    baseImage: 'debian:bookworm',
    cacheVolume: 'packfoundry-pub-cache',
    dockerfile: _debBookwormDockerfile,
    estimatedInstallSeconds: 900,
  );

  static const rpmFedora = BuilderEnvironment(
    id: BuilderEnvironmentId.rpmFedora,
    title: 'RPM Builder',
    imageTag: 'packfoundry/rpm-builder:fedora-flutter-stable-v1',
    baseImage: 'fedora:latest',
    cacheVolume: 'packfoundry-pub-cache',
    dockerfile: _rpmFedoraDockerfile,
    estimatedInstallSeconds: 900,
  );
}

const _debBookwormDockerfile = r'''
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    clang \
    cmake \
    curl \
    dpkg-dev \
    file \
    git \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    ninja-build \
    pkg-config \
    unzip \
    xz-utils \
    zip \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter \
  && git config --global --add safe.directory /opt/flutter \
  && flutter config --enable-linux-desktop \
  && flutter precache --linux

WORKDIR /work
''';

const _rpmFedoraDockerfile = r'''
FROM fedora:latest

ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN dnf install -y \
    ca-certificates \
    clang \
    cmake \
    curl \
    desktop-file-utils \
    file \
    git \
    gtk3-devel \
    libstdc++ \
    ninja-build \
    pkgconf-pkg-config \
    rpm-build \
    unzip \
    xz \
    zip \
  && dnf clean all

RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter \
  && git config --global --add safe.directory /opt/flutter \
  && flutter config --enable-linux-desktop \
  && flutter precache --linux

WORKDIR /work
''';
