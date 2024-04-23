ARG distro=ubuntu
ARG tag=latest
ARG repo=https://github.com/open5gs/open5gs.git
ARG version=v2.7.1
ARG arch=aarch64

FROM ${distro}:${tag} as builder
ARG repo
ARG version

# install tools
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        ninja-build \
        build-essential \
        flex \
        bison \
        git \
        cmake \
        meson \
        libsctp-dev \
        libgnutls28-dev \
        libgcrypt-dev \
        libssl-dev \
        libidn11-dev \
        libmongoc-dev \
        libbson-dev \
        libyaml-dev \
        libmicrohttpd-dev \
        libcurl4-gnutls-dev \
        libnghttp2-dev \
        libtins-dev \
        libtalloc-dev \
        iproute2 \
        ca-certificates \
        netbase \
        pkg-config && \
    apt-get clean

# clone codes and build
RUN git clone ${repo} /open5gs
WORKDIR /open5gs
RUN git checkout ${version}

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /wait
RUN chmod +x /wait

# start building open5gs
RUN meson build && ninja -C build install

# production image
FROM ${distro}:${tag}

# install utils
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        libsctp-dev \
        libgnutls28-dev \
        libgcrypt-dev \
        libssl-dev \
        libidn11-dev \
        libmongoc-dev \
        libbson-dev \
        libyaml-dev \
        libmicrohttpd-dev \
        libcurl4-gnutls-dev \
        libnghttp2-dev \
        libtins-dev \
        libtalloc-dev \
        iproute2 \
        ca-certificates \
        netbase

# install tools
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
        iputils-ping \
        netcat

# copy common libraries that open5gs use
ARG arch
ENV LIBPATH=/usr/local/lib/${arch}-linux-gnu
COPY --from=builder ${LIBPATH} ${LIBPATH}
RUN ldconfig

# copy binaries & configuration files
COPY --from=builder /open5gs/build/src/*/open5gs-*d /usr/local/bin/
COPY --from=builder /open5gs/build/configs/open5gs/* /etc/open5gs/
COPY --from=builder /open5gs/build/configs/freeDiameter/* /etc/open5gs/freeDiameter/
