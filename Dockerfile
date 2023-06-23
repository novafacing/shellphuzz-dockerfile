FROM ubuntu:16.04 AS tfuzz
SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONIOENCODING=utf8 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

RUN sed -i 's/^# deb-src /deb-src /g' /etc/apt/sources.list
RUN cat /etc/apt/sources.list
RUN apt-get -y update && \
    apt-get -y build-dep qemu-system && \
    apt-get install -y \
    autoconf \
    automake \
    bison \
    build-essential \
    clang \
    cmake \
    curl \
    debian-archive-keyring \
    debian-keyring \
    debootstrap \
    flex \
    gcc-multilib \
    git \
    git \
    libacl1-dev \
    libexpat1-dev \
    libtool \
    libtool-bin \
    llvm-dev \
    pkg-config \
    python3 \
    python3-pip \
    python3-virtualenv \
    software-properties-common \
    unzip \
    wget \
    zlib1g-dev \
    ubuntu-keyring


RUN git clone https://github.com/radare/radare2.git /radare2
RUN git clone https://github.com/novafacing/shellphish-afl /shellphish-afl
RUN git clone https://github.com/HexHive/T-Fuzz /T-Fuzz

WORKDIR /shellphish-afl
RUN sed -i 's#"aarch64", "x86_64", "i386", "arm", "ppc", "ppc64", "mips", "mipsel", "mips64"#"x86_64"#' setup.py &&\
    sed -i 's#self.execute(_setup_cgc, (), msg="Setting up AFL-cgc")##' setup.py && \
    sed -i 's/fetcharch armhf ubuntu trusty/#fetcharch armhf ubuntu trusty/' fetchlibs.sh &&\
    sed -i 's/fetcharch armel debian jessie/#fetcharch armel debian jessie/' fetchlibs.sh &&\
    sed -i 's/fetcharch powerpc ubuntu trusty/#fetcharch powerpc ubuntu trusty/' fetchlibs.sh &&\
    sed -i 's/fetcharch mips debian jessie/#fetcharch mips debian jessie/' fetchlibs.sh &&\
    sed -i 's/fetcharch mipsel debian jessie/#fetcharch mipsel debian jessie/' fetchlibs.sh && \
    sed -i 's/fetcharch mipsel debian jessie/#fetcharch mipsel debian jessie/' fetchlibs.sh && \
    sed -i 's/stretch/buster/' fetchlibs.sh && \
    python3 setup.py build &&\
    python3 setup.py install

RUN python3 -m pip install -U pip &&\
    python3 -m pip install -U git+https://github.com/shellphish/fuzzer &&\
    python3 -m pip install -U git+https://github.com/shellphish/driller &&\
    python3 -m pip install -U git+https://github.com/angr/tracer &&\
    cp -R -v /shellphish-afl/bin/afl-unix /usr/bin/

COPY resource/shellphuzz /usr/local/bin/shellphuzz
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

RUN sed -i 's/if not "core" in f.read():/if f.read().startswith("|"):/' /usr/local/lib/python3.5/dist-packages/fuzzer/fuzzer.py

WORKDIR /T-Fuzz
RUN python3 -m pip install -U pip &&\
    cd T-Fuzz && sed -i 's/shellphish-afl==1.1//g' req.txt &&\
    python3 -m pip install -r req.txt &&\
    python3 -m pip install -U git+https://github.com/shellphish/fuzzer.git

COPY resource/create_dict.py /usr/local/bin/create_dict.py
COPY resource/tfuzz_sys.py /T-Fuzz/tfuzz/tfuzz_sys.py
COPY resource/issue14.patch /T-Fuzz/issue14.patch
RUN git apply issue14.patch

RUN sed -i 's/if not "core" in f.read():/if f.read().startswith("|"):/' /usr/local/lib/python2.7/dist-packages/fuzzer/fuzzer.py

