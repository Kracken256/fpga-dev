FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_HOME=/opt/rust/cargo
ENV RUSTUP_HOME=/opt/rust/rustup
ENV PATH=/opt/rust/cargo/bin:${PATH}

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bison \
    build-essential \
    ca-certificates \
    llvm-18 \
    clang \
    cmake \
    curl \
    file \
    flex \
    git \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libeigen3-dev \
    libfmt-dev \
    libftdi1-dev \
    libusb-1.0-0-dev \
    lld \
    make \
    ninja-build \
    openfpgaloader \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    xz-utils \
    yosys \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages --no-cache-dir apycula

RUN git clone --depth 1 https://github.com/YosysHQ/nextpnr.git /tmp/nextpnr \
    && cmake -S /tmp/nextpnr -B /tmp/nextpnr/build -G Ninja \
    -DARCH=himbaechel \
    -DHIMBAECHEL_UARCH=gowin \
    -DBUILD_GUI=OFF \
    -DBUILD_PYTHON=OFF \
    && cmake --build /tmp/nextpnr/build -j"$(nproc)" \
    && cmake --install /tmp/nextpnr/build \
    && rm -rf /tmp/nextpnr

RUN curl -fsSL https://sh.rustup.rs | bash -s -- -y --profile minimal \
    && /opt/rust/cargo/bin/rustup target add riscv32i-unknown-none-elf

WORKDIR /workspace

CMD ["bash"]
