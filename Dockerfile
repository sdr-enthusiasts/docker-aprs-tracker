FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-direwolf"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    # generic packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(bc) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(curl) && \
    # packages for GPSD
    KEPT_PACKAGES+=(gpsd) && \
    KEPT_PACKAGES+=(gpsd-clients) && \
    KEPT_PACKAGES+=(libgps-dev) && \
    KEPT_PACKAGES+=(libgps28) && \
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

COPY rootfs/ /

# Add Container Version
RUN set -x && \
pushd /tmp && \
    branch="##BRANCH##" && \
    [[ "${branch:0:1}" == "#" ]] && branch="main" || true && \
    git clone --depth=1 -b $branch https://github.com/sdr-enthusiasts/docker-direwolf.git && \
    cd docker-direwolf && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(git rev-parse --short HEAD)_$(git branch --show-current)" > /.CONTAINER_VERSION && \
popd && \
rm -rf /tmp/*

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh
