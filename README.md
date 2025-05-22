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

# Base Image (Archlinux)
FROM archlinux:latest
```

This setup consists of 5 main steps:

1. Arch Linux Configuration & Setup
2. `uv` Package Manager & Python Installation
3. CUDA and Nvidia Drivers Setup
4. User & Environment COnfiguration
5. Development Setup

### 1. Arch Linux Configuration & Setup

The latest `archlinux` image is utilized as a base image. It can be pinned with it's digest, which is exposed with:

```pwsh
docker pull archlinux:latest
docker images archlinux:latest --format '{{.Digest}}'
```

To simplify the rest of the building process, build arguments are created:

```Dockerfile
# Build arguments
ARG USER=abhans
ARG GUID=1000
ARG UID=${GUID}
ENV HOME=/home/${USER}
ENV VENV_DIR=${HOME}/.venv
```

This ensures a proper initialization of the environment while also making it configurable.

Then, in root, signature keys are populated to avoid signature errors. System is updated and missing dependencies are installed:

```Dockerfile
# Select the ROOT user
USER root

# Initialize Arch Linux
RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman --noconfirm -Syu
```

### 2. `uv` Package Manager & Python Installation

For setting up the Python environment, a package manager is needed. For this, `uv` package manager is selected for it's speed and configuration capabilities.

`uv` is [installed using `pacman`](https://docs.astral.sh/uv/getting-started/installation/):

```Dockerfile
# Install essentials and "uv" package manager
RUN pacman -Sy --noconfirm unzip sudo curl git vi nvim \
    && curl -LsSf https://astral.sh/uv/install.sh | sh
```

After the installation of `uv`, it can be used to install specific Python version as the **base Python interpreter.**

After installing the base interpreter, a **virtual environment** can be created in the specified path:

```Dockerfile
# Install Python 3.12 and create a virtual environment
RUN uv python install 3.12 \
    && uv venv --python 3.12 ${VENV_DIR}
```

### 3. CUDA and Nvidia Drivers Setup

To utilize GPU acceleration and parallel computation, **CUDA** must be set up and configured for deep learning frameworks such as TensorFlow, PyTorch etc.

More detailed guide for setting up CUDA in Arch can be found [here.](https://wiki.archlinux.org/title/GPGPU#CUDA)

CUDA and proper drivers can be installed using `pacman`:

```Dockerfile
# Install CUDA & Drivers
RUN && pacman -S --noconfirm nvidia cuda cuda-toolkit \
    && pacman -S --noconfirm nvidia-container-toolkit docker opencl-nvidia \
    && pacman -Sy neofetch \
    && pacman -Scc --noconfirm \
    && pacman -Syu --noconfirm
```

<!---
TODO: Explain the  cuDNN, cuFFT and cuBLAS situation. Understand how it's related to the topic.
-->