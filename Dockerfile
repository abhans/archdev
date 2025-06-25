# Arch Linux Development Environment
#   - Fastfetch (at the start of each bash session)
#   - Tensorflow & CUDA
#   - NVIDIA Drivers
#   - Python and C++ support
FROM archlinux:latest

# ----------------------- BUILD ARGS ------------------------
# Set the user and group IDs for the container
#   This allows the container to run with the same user and group IDs as the host system
#   This is useful for avoiding permission issues when mounting volumes

ARG USER=hans
ARG GUID=1000
ARG UID=${GUID}
# Environment variables for the user
ENV HOME=/home/${USER}
ENV VENV_DIR=${HOME}/.venv
# Development directory
ARG DEV=${HOME}/.dev/

# ------------------------ ARCH LINUX INIT & USER CONFIG ------------------------
# Initialize Arch Linux
#  This includes setting up the package manager, locale, and user permissions
# Set the user and group IDs for the container
#  This allows the container to run with the same user and group IDs as the host system

USER root

# Initialize Arch Linux
RUN pacman-key --init \
    && pacman -Sy --noconfirm sudo \ 
    && pacman-key --populate archlinux \
    && pacman --noconfirm -Syu \
    # Generate en_US.UTF-8 locale
    && sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
    && locale-gen \
    && pacman -Scc --noconfirm

# Create a new user
RUN useradd --create-home --shell /bin/bash ${USER} \
    && usermod -aG wheel ${USER} \
    # Setting the user as a "sudoer"
    && sed -i 's/^# %wheel/%wheel/' /etc/sudoers \
    # Fix permissions for the home directory
    && chown -R ${USER}:${USER} /home/${USER}

# ------------------------ INSTALLATION (Python & Packages) ------------------------
# Install base development tools
#  This installs essential development tools such as Git, GCC, Make, and CMake

# Install essentials, CUDA and "uv" package manager
RUN pacman -Sy --noconfirm cmake gcc make fastfetch openssh unzip sudo curl git vi nvim \
    && pacman -S --noconfirm nvidia cuda cuda-toolkit \
    && pacman -S --noconfirm nvidia-container-toolkit docker opencl-nvidia \
    # Install the "uv" package manager
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && pacman -Scc --noconfirm

# Append ".local/bin" to PATH
#   This ensures that binaries installed by `uv` (such as Python) are available "system-wide"
ENV PATH="/home/${USER}/.local/bin:${PATH}"

# ------------------------ CUDA CONFIGURATION ------------------------
# Configure CUDA for the container
#  This includes setting up the CUDA toolkit and adding it to the PATH
    
# Add the CUDA folders to the PATH
#   Adds CUDA binaries and libraries to environment variables
ENV PATH=/opt/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# Configure the Matplotlib temporary directory
ENV MPLCONFIGDIR=/tmp/matplotlib

# ------------------------ ENVIRONMENT ------------------------
# Sets up the environment for the container
#  This includes setting a virtual environment, downlaoding packages, copying entrypoint scripts, and fixing permissions

# Set the locale to UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Copy entrypoint bash script & change its' permission to executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy project files to the home directory
COPY . ${DEV}

USER ${USER}
WORKDIR ${DEV}

# Install Python 3.12 and create a virtual environment
RUN uv python install 3.12 \
    && uv venv --python 3.12 ${VENV_DIR} \
    && source ${VENV_DIR}/bin/activate \
    # Initialize a `uv` project (base)
    && uv init --bare --python 3.12 -v -n base \
    && uv pip install --upgrade pip \
    && uv pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install --no-cache-dir -r requirements.txt \
    # Save the installed packages to a lock file
    && uv pip compile requirements.txt --output uv.lock \
    # Clean uv cache
    && uv cache clean

# Fetching System information
RUN echo "fastfetch" >> /home/${USER}/.bashrc

# Ensure the container starts in the user's HOME directory
WORKDIR ${HOME}

ENTRYPOINT ["/entrypoint.sh"]