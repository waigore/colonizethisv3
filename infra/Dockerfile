# ColonizeThis Daytona tools image (linux/amd64). Tools only — no app repo baked in.
# Flutter `stable` channel is fixed at image build time; rebuild the snapshot to pick up new Flutter.
#
# CT_PUBSPEC_SDK_LOWER_BOUND must stay aligned with the workspace root pubspec environment.sdk lower bound.
# CT_PUBSPEC_SDK_LOWER_BOUND=3.11.0

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        wget \
        gnupg \
        openjdk-17-jdk \
        clang \
        cmake \
        ninja-build \
        pkg-config \
        libgtk-3-dev \
        liblzma-dev \
        xvfb \
        xauth \
        lcov \
        python3 \
        python3-pip \
        python3-venv \
        python3-pil \
        gh \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 + OpenCode CLI (matches headless automation pattern; see SPEC/program/daytona-sandbox.md).
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @opencode-ai/cli

# Android SDK command-line tools (API 34 / build-tools 34).
ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

RUN mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -O /tmp/cmdline.zip \
    && unzip -q /tmp/cmdline.zip -d /tmp/android-cmdline \
    && mv /tmp/android-cmdline/cmdline-tools "${ANDROID_SDK_ROOT}/cmdline-tools/latest" \
    && rm -rf /tmp/android-cmdline /tmp/cmdline.zip \
    && yes | sdkmanager --licenses >/dev/null \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Flutter stable (shallow clone); Dart comes from the Flutter SDK and must satisfy CT_PUBSPEC_SDK_LOWER_BOUND.
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/cache/dart-sdk/bin:/root/.pub-cache/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_ROOT}" \
    && flutter config --no-analytics \
    && flutter precache --linux --android

RUN dart pub global activate melos

# Cursor CLI (headless `agent`); requires CURSOR_API_KEY at runtime (not baked into layers).
ENV HOME=/root \
    CI=1
RUN curl https://cursor.com/install -fsS | bash
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /root
