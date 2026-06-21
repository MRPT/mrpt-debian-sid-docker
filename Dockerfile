# Start from the Debian Sid base image
FROM debian:sid

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Allow passing user info from host
ARG USERNAME
ARG USER_UID
ARG USER_GID

# Default to 'developer' if not provided
ENV USERNAME=${USERNAME:-developer}
ENV USER_UID=${USER_UID:-1000}
ENV USER_GID=${USER_GID:-1000}

# Update apt and install base tooling + Debian packaging / gbp toolchain
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    lsb-release \
    sudo \
    software-properties-common \
    dpkg-dev \
    debhelper \
    devscripts \
    equivs \
    git-buildpackage \
    pristine-tar \
    quilt \
    fakeroot \
    lintian \
    && rm -rf /var/lib/apt/lists/*

# Install MRPT build dependencies, as listed in debian/control (Build-Depends)
RUN apt-get update && apt-get install -y \
    dh-sequence-python3 \
    chrpath \
    pkgconf \
    perl \
    colcon \
    python3-colcon-cmake \
    python3-colcon-defaults \
    python3-colcon-ros \
    python3-colcon-recursive-crawl \
    python3-colcon-package-information \
    python3-colcon-package-selection \
    python3-colcon-parallel-executor \
    python3-colcon-output \
    python3-colcon-library-path \
    python3-colcon-metadata \
    libeigen3-dev \
    libglfw3-dev \
    libgl-dev \
    libglu1-mesa-dev \
    libxrandr-dev \
    libxxf86vm-dev \
    libassimp-dev \
    libcli11-dev \
    libzstd-dev \
    libwxgtk3.2-dev \
    wx-common \
    qtbase5-dev \
    libqt5opengl5-dev \
    libsimpleini-dev \
    libicu-dev \
    libnanoflann-dev \
    libfyaml-dev \
    libtinyxml2-dev \
    liboctomap-dev \
    zlib1g-dev \
    libgtest-dev \
    libglew-dev \
    fonts-roboto-fontface \
    pybind11-dev \
    python3-all-dev \
    python3-numpy \
    python3-setuptools \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libdc1394-dev \
    libopenni2-dev \
    libpcap-dev \
    libusb-1.0-0-dev \
    libftdi1-dev \
    xauth \
    xvfb \
    libexprtk-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create the same user as on the host
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# Set work directory
WORKDIR /tmp/mrpt_build

# Use the new user
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Optional: Preconfigure git defaults (useful if .gitconfig isn’t mounted)
RUN git config --global user.name "${USERNAME}" && \
    git config --global user.email "${USERNAME}@example.com"

# Define mount points (generic)
# These don't hardcode host paths but define mountable dirs
VOLUME ["/tmp/mrpt_build", "/home/${USERNAME}/.gitconfig", "/home/${USERNAME}/.ssh"]

CMD ["/bin/bash"]
