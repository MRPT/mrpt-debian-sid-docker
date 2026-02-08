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

# Update apt and install build dependencies for MRPT
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    lsb-release \
    sudo \
    software-properties-common \
    git-buildpackage && \
    rm -rf /var/lib/apt/lists/*

# Add the source line to the sources.list
RUN echo "deb-src https://deb.debian.org/debian/ unstable main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get build-dep -y mrpt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
