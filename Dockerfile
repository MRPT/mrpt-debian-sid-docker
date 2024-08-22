# Start from the Debian Sid base image
FROM debian:sid

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update apt and install build dependencies for MRPT
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    lsb-release \
    sudo \
    software-properties-common

RUN apt-get install -y \
    git-buildpackage

# Add the source line to the sources.list
RUN echo "deb-src https://deb.debian.org/debian/ unstable main contrib non-free" >> /etc/apt/sources.list

# Update the package list
RUN apt-get update


RUN apt-get build-dep -y mrpt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory inside the container
WORKDIR /mrpt_build

# Link the external host directory $HOME/code/mrpt to /mrpt_build in the container
VOLUME ["$HOME/code/mrpt:/mrpt_build"]

# Build MRPT using CMake
CMD cmake . && make -j$(nproc) && make test_legacy && bash
