FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base as gpsd-build
RUN set -x && \
    # install packages
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(gpsd) && \
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}"

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base 
LABEL org.opencontainers.image.source="https://github.com/sdr-enthusiasts/docker-aprs-tracker"

# start options presets for GPSD:
ENV START_DAEMON="false"
ENV GPSD_OPTIONS="-n"
ENV DEVICES="/dev/ttyACM0"
ENV USBAUTO="true"
ENV GPSD_SOCKET="/var/run/gpsd.sock"

RUN set -x && \
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
    # packages for direwolf
    KEPT_PACKAGES+=(direwolf) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # Do some other stuff
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    #
    # clean up
    if [[ "${#TEMP_PACKAGES[@]}" -gt 0 ]]; then \
        apt-get remove -y "${TEMP_PACKAGES[@]}"; \
    fi && \
    apt-get autoremove -y && \
    #
    # set CONTAINER_VERSION:
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

COPY --from=gpsd-build /usr/sbin/gpsd /usr/sbin/gpsd

COPY rootfs/ /

# Add Container Version
RUN set -x && \
pushd /tmp && \
    branch="##BRANCH##" && \
    [[ "${branch:0:1}" == "#" ]] && branch="main" || true && \
    git clone --depth=1 -b $branch https://github.com/sdr-enthusiasts/docker-aprs-tracker.git && \
    cd docker-aprs-tracker && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION && \
popd && \
rm -rf /tmp/*

EXPOSE 2947

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]