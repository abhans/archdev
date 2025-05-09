# Arch Linux Development Environment

This setup utilizes Docker containers to setup Arch Linux with CUDA drivers.

## The `Dockerfile`

`Dockerfile` is created to store the building process of an image, gives the ability to customize if necessary in future developments.

```Dockerfile
# TODO: Arch Linux Development Environment
#   - Neofetch (at the start of each bash session)
#   - Tensorflow & CUDA
#   - NVIDIA Drivers
#   - Python and C+ support

# Base Image (Archlinux with SHA256 Digest)
FROM archlinux:latest@sha256:69b59e60bb8594d8c4bf375e9beee186e4b3426ec4f50a65d92e7f36ce5e7113
```

This setup consists of 5 main steps:

1. Arch Linux Configuration & Setup
2. CUDA and Nvidia Drivers Setup
3. User & Environment COnfiguration
4. Python Setup
5. Development Setup

### 1. Arch Linux Configuration & Setup

The base `archlinux` image is utilized as a base image. It's pinned with it's digest, which is exposed with:

```pwsh
docker pull archlinux:latest
docker images archlinux:latest --format '{{.Digest}}'
```

To simplify the rest of the building proecess, build arguments are created:

```Dockerfile
# Build Arguments
ARG USER=abhans
ARG GUID=1000
ARG UID=${GUID}
ENV HOME=/home/${USER}
```

This ensures a proper initialization of the environment while making it configurable.

Then, in root, signature keys are populated to avoid signature errors. System is updated and missing dependencies are installed:

```Dockerfile
# Switching to root if it's not already
USER root

# Populating Signature Keys
RUN pacman-key --init && \
    pacman-key --populate archlinux

# System Updates
RUN pacman -Syu --noconfirm

RUN pacman -Sy --noconfirm --needed base-devel sudo vi nvim git && \
    pacman -Sy --noconfirm python-pip python-virtualenv && \
    pacman -Sy --noconfirm neofetch && \
    rm -rf /var/cache/pacman/pkg/*
```

### 2. CUDA and Nvidia Drivers Setup

For the environment to support CUDA and GPU acceleration, a proper setup of CUDA drivers and libraries must be made.

Related NVIDIA and CUDA packages are installed with `pacman`:

```Dockerfile
# Installing CUDA drivers
RUN pacman -Sy --noconfirm --needed nvidia opencl-nvidia cuda cuda-tools
```
<!---
TODO: Explain the  cuDNN, cuFFT and cuBLAS situation. Understand how it's related to the topic.
-->

Then a new user is created and configured as a "sudoer":

```Dockerfile
# Configuring groups and users
RUN useradd --create-home --shell /bin/bash ${USER} && \
    usermod -aG wheel ${USER}

# Setting the user as a "sudoer"
RUN sed -i 's/^# %wheel/%wheel/' /etc/sudoers
```

...

```Dockerfile
# Setup CUDA and Drivers
# TODO: Resolve this issue

WORKDIR ${HOME}

# Switching to the user
USER ${USER}

# Setting up the main Python environment
RUN python3 -m venv ~/.venv

# Installing PyPI packages
COPY requirements.txt /requirements.txt
RUN source ~/.venv/bin/activate && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir -r /requirements.txt

# Fetching System information at shel lstartup
RUN echo "neofetch" >> /home/${USER}/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```
