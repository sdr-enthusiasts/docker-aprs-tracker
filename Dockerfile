FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS gpsd-build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -x && \
    # install packages
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(gpsd) && \
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${KEPT_PACKAGES[@]}"

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS chrony-build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -x && \
    # install packages
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(chrony) && \
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${KEPT_PACKAGES[@]}"

# Add Container Version
FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS container-version

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN set -x && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(git) && \
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${KEPT_PACKAGES[@]}" && \
    #
    branch="##BRANCH##" && \
    { [[ "${branch:0:1}" == "#" ]] && branch="main" || true; } && \
    git clone --depth=1 -b "$branch" https://github.com/sdr-enthusiasts/docker-aprs-tracker.git && \
    cd docker-aprs-tracker && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base
LABEL org.opencontainers.image.source="https://github.com/sdr-enthusiasts/docker-aprs-tracker"

# start options presets for GPSD:
ENV GPSD_START_DAEMON="false"
ENV GPSD_OPTIONS="-n"
ENV GPSD_DEVICES="/dev/gps"
ENV GPSD_USBAUTO="true"
ENV GPSD_SOCKET="/var/run/gpsd.sock"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG VERSION_REPO="sdr-enthusiasts/docker-aprs-tracker" \
    VERSION_BRANCH="##BRANCH##"

RUN --mount=type=bind,from=gpsd-build,source=/,target=/gpsd-build/ \
    --mount=type=bind,from=chrony-build,source=/,target=/chrony-build/ \
    set -x && \
    # generic packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(bc) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(curl) && \
    # minimum config needed for GPSD:
    KEPT_PACKAGES+=(libbluetooth3) && \
    # minimum config needed for chrony:
    KEPT_PACKAGES+=(iproute2) && \
    KEPT_PACKAGES+=(ucf) && \
    # packages for direwolf
    KEPT_PACKAGES+=(direwolf) && \
    KEPT_PACKAGES+=(alsa-utils) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" \
    && \
    # copy files from build stages:
    cp /gpsd-build/usr/sbin/gpsd /usr/sbin/gpsd && \
    cp /chrony-build/usr/sbin/chronyd /usr/sbin/chronyd && \
    cp /chrony-build/etc/chrony/chrony.keys /etc/chrony/chrony.keys && \
    # Do some other stuff
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    # Add Container Version
    { [[ "${VERSION_BRANCH:0:1}" == "#" ]] && VERSION_BRANCH="main" || true; } && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(curl -ssL "https://api.github.com/repos/$VERSION_REPO/commits/$VERSION_BRANCH" | awk '{if ($1=="\"sha\":") {print substr($2,2,7); exit}}')_$VERSION_BRANCH" > /CONTAINER_VERSION && \
    cp /CONTAINER_VERSION /IMAGE_VERSION && \
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
    apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -y && \
    #
    # set CONTAINER_VERSION:
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY --from=container-version /.CONTAINER_VERSION /.CONTAINER_VERSION
COPY rootfs/ /

EXPOSE 2947

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
