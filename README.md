# Arch Linux Development Environment

This setup utilizes Docker containers to setup Arch Linux with CUDA drivers.

It also comes with the `uv` **package manager** with a virtual environment setup, configured with **popular deep learning frameworks** such as `PyTorch`, `TensorFlow` and other useful libraries, one of which is `OpenCV`.

## The `Dockerfile`

`Dockerfile` is created to store the building process of an image, gives the ability to customize if necessary in future developments.

This setup consists of 5 main steps:

1. Arch Linux Configuration & Setup
2. `uv` Package Manager & Python Installation
3. CUDA and Nvidia Drivers Setup
4. User & Environment Configuration

### 1. Arch Linux Configuration & Setup

The latest `archlinux` image is utilized as the base image.

```Dockerfile
# Arch Linux Development Environment
#   - CUDA Support
#   - PyTorch & TensorFlow
#   - NVIDIA Drivers
#   - Python and C++ Support
#   - `uv` Package Manager

# Base Image (Archlinux)
FROM archlinux:latest
```

It can be pinned with it's digest, which is exposed with:

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

After this process is done, a new user is created from the build arguments and configured as a "sudoer":

```Dockerfile
# Create a new user
RUN useradd --create-home --shell /bin/bash ${USER} \
    && usermod -aG wheel ${USER} \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    # Setting the user as a "sudoer"
    && sed -i 's/^# %wheel/%wheel/' /etc/sudoers
```

### 2. `uv` Package Manager & Python Installation

For setting up the Python environment, a package manager is needed. For this, `uv` package manager is selected for it's speed and configuration capabilities.

`uv` is [[installed using `pacman`]](https://docs.astral.sh/uv/getting-started/installation/):

```Dockerfile
# Install essentials and "uv" package manager
RUN pacman -Sy --noconfirm fastfetch unzip sudo curl git vi nvim \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && pacman -Scc --noconfirm
```

To ensure that user-installed Python tools are accessible in the container's shell and scripts, the `/home/abhans/.local/bin` is appended to the `PATH` environment variable:

```Dockerfile
# Append ".local/bin" to PATH
#   This ensures that binaries installed by `uv` (such as Python) are available "system-wide"
ENV PATH="/home/abhans/.local/bin:${PATH}"
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

#### 3.A What is CUDA?

**CUDA** (Compute Unified Device Architecture) is a **parallel computing platform** and programming model developed by NVIDIA.

- It allows developers to use NVIDIA GPUs for **general purpose processing (GPGPU)**, enabling significant acceleration for compute-intensive applications such as deep learning, scientific computing, and image processing.

#### 3.B What are cuDNN, cuFFT, and cuBLAS?

- **cuDNN**: NVIDIA **CUDA Deep Neural Network** library.
  - Provides **highly optimized implementations for standard routines** such as forward and backward convolution, pooling, normalization, and activation layers for deep neural networks.
- **cuFFT**: NVIDIA **CUDA Fast Fourier Transform** library.
  - Delivers **GPU-accelerated FFT computations** for signal and image processing.
- **cuBLAS**: NVIDIA **CUDA Basic Linear Algebra Subprograms** library.
  - Offers **GPU-accelerated linear algebra operations**, such as matrix multiplication and vector operations.

A detailed guide for setting up CUDA in Arch can be found at [[Arch Linux Wiki: GPGPU CUDA setup]](https://wiki.archlinux.org/title/GPGPU#CUDA)

CUDA and proper drivers can be installed using `pacman`:

```Dockerfile
# Install CUDA & Drivers
RUN && pacman -S --noconfirm nvidia cuda cuda-toolkit \
    && pacman -S --noconfirm nvidia-container-toolkit docker opencl-nvidia \
    && pacman -Syu --noconfirm \
    && pacman -Scc --noconfirm
```

CUDA binaries are then added to the PATH:

```Dockerfile
# Add the CUDA folders to the PATH
#   Adds CUDA binaries and libraries to environment variables
ENV PATH=/opt/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/cuda/lib64
# Turn off oneDNN operations
ENV TF_ENABLE_ONEDNN_OPTS=0
```

To use `uv` and utilize cache properly, both paths' permissions are configured

```Dockerfile
# Fix permissions for the .venv and cache directories
RUN chown -R ${USER}:${USER} ${VENV_DIR} /home/${USER}/.cache
```

The entrypoint script `entrypoint.sh` is copied to the `/` directory and its' permission is configured to make it executable:

```Dockerfile
# Copy entrypoint bash script & change its' permission to executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
```

### 4. User & Environment Configuration

The current directory is copied as a whole to `${HOME}/dev/` to setup the working directory:

```Dockerfile
# Copy project files and fix permissions
COPY . ${HOME}/dev/
```

The copied directories' permissions are configured so changes can be made:

```Dockerfile
# Fix permissions for the working directory
RUN chown -R ${USER}:${USER} ${HOME}/dev/
```

Then, the new working directory is selected and PYPI packages are installed using both `pip3` and `requirements.txt`. Finally, state of packages are saved to a `.lock` file for future use.

```Dockerfile
# Switch to user
USER ${USER}

WORKDIR ${HOME}/dev

RUN source ${VENV_DIR}/bin/activate \
    && uv pip install --upgrade pip \
    && uv pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install --no-cache-dir -r requirements.txt \
    # Save the installed packages to a lock file
    && uv pip freeze > requirements.lock \
    # Clean uv cache
    && uv cache clean
```

For extra flavor, `fastfetch` is added to the `.bashrc`, as well as the activation command of the virtual environment, guaranteeing the activation of the environment at each startup:

```Dockerfile
# Fetching System information & activate .venv at shell startup
RUN echo "fastfetch" >> /home/${USER}/.bashrc \
    && echo "source $VENV_DIR/bin/activate" >> /home/${USER}/.bashrc
```

Lastly, the `entrypoint.sh` script is set as the **entrypoint executable** for initial checks of the container at startup:

```Dockerfile
ENTRYPOINT ["/entrypoint.sh"]
```

## How to Use

After pulling the image, it can be tested with:

```pwsh
docker run --gpus all -it --rm "archlinux/latest:cuda" bash
```

For a **localy-stored** image, remove `--rm` flag and specify a **name** for the container:

```pwsh
docker run --gpus all -it --name <NAME> "archlinux/latest:cuda" bash
```

## Customizing Build Arguments

You can customize the Docker image by altering the build arguments defined in the `Dockerfile`. For example, you can change the default username, user ID, or group ID to fit your preferences or environment.

To specify custom values during the build process, use the `--build-arg` flag with `docker build`. For example:

```pwsh
docker build --build-arg USER=<MY_USER_NAME> -D -t "archlinux/latest:cuda" .
```

This command sets the username to `MY_USER_NAME` in the resulting image.

### Logging the Build Process

For curiosity and verbose process, additional arguments can be provided to log the process to a `<BUILD_LOG>` file:

```pwsh
docker build --build-arg USER=hans -D --progress=plain -t "archlinux/latest:cuda" . *> <BUILD_LOG>
```

When this command is run, the build process is silent and instead logged to the `<BUILD_LOG>.log` file.

## Reminder to User

The whole process **takes quite a long time (over 30 min)** and the resulting image is **very large (>30 GB).** Currently thinking of an improvement on both areas.

<!--
## ToDos

- [x] Explain the  cuDNN, cuFFT and cuBLAS situation. Understand how it's related to the topic.
- [ ] Initialize `uv` to the `.dev/` directory as a project
  - Read more about projects [[here]](https://docs.astral.sh/uv/concepts/projects/)
- [ ] Find a better way to check system, done by `run.py`
  - Added `checkTorch` to `run.py`
- [ ] Properly set up OpenCV to connect the camera.

```bash
uv init --bare --python 3.12 --no-cache -v
```
-->