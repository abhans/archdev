# Arch Linux Development Environment
#   - Neofetch (at the start of each bash session)
#   - Tensorflow & CUDA
#   - NVIDIA Drivers
#   - Python and C++ support
FROM archlinux:latest

# ----------------------- BUILD ARGS ------------------------
# Set the user and group IDs for the container
#   This allows the container to run with the same user and group IDs as the host system
#   This is useful for avoiding permission issues when mounting volumes

ARG USER=abhans
ARG GUID=1000
ARG UID=${GUID}
# Environment variables for the user
ENV HOME=/home/${USER}
ENV VENV_DIR=${HOME}/.venv
# Development directory
ARG DEV=${HOME}/.dev/

# ------------------------ USER CONFIG ------------------------
# Set the user and group IDs for the container
#  This allows the container to run with the same user and group IDs as the host system

# Select the ROOT user
USER root

# Initialize Arch Linux
RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman --noconfirm -Syu \
    && pacman -Scc --noconfirm

# Create a new user
RUN useradd --create-home --shell /bin/bash ${USER} \
    && usermod -aG wheel ${USER} \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    # Setting the user as a "sudoer"
    && sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# ------------------------ INSTALLATION (Python & Packages) ------------------------
# Install base development tools
#  This installs essential development tools such as Git, GCC, Make, and CMake

# Install essentials and "uv" package manager
RUN pacman -Sy --noconfirm cmake gcc make fastfetch openssh unzip sudo curl git vi nvim \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && pacman -Scc --noconfirm

# Append ".local/bin" to PATH
#   This ensures that binaries installed by `uv` (such as Python) are available "system-wide"
ENV PATH="/home/${USER}/.local/bin:${PATH}"

# Install Python 3.12 and create a virtual environment
RUN uv python install 3.12 \
    && uv venv --python 3.12 ${VENV_DIR}

# ------------------------ CUDA CONFIGURATION ------------------------
# Install NVIDIA Drivers and CUDA Toolkit
#  This installs the NVIDIA drivers and CUDA toolkit for GPU support
#  The `nvidia-container-toolkit` is installed to enable GPU support in Docker containers

# Install CUDA & Drivers
RUN pacman -S --noconfirm nvidia cuda cuda-toolkit \
    && pacman -S --noconfirm nvidia-container-toolkit docker opencl-nvidia \
    && pacman -Syu --noconfirm \
    && pacman -Scc --noconfirm
    
# Add the CUDA folders to the PATH
#   Adds CUDA binaries and libraries to environment variables
ENV PATH=/opt/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/cuda/lib64
# Configure the Matplotlib temporary directory
ENV MPLCONFIGDIR=/tmp/matplotlib
# Fix permissions for the .venv and cache directories
RUN chown -R ${USER}:${USER} ${VENV_DIR} /home/${USER}/.cache

# ------------------------ ENVIRONMENT ------------------------
# Sets up the environment for the container
#  This includes setting the locale, copying entrypoint scripts, and fixing permissions

# Set the locale to UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Copy entrypoint bash script & change its' permission to executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy project files and fix permissions
COPY . ${DEV}

# Fix permissions for the working directory
RUN chown -R ${USER}:${USER} ${DEV}
# Switch to user
USER ${USER}

WORKDIR ${DEV}

RUN source ${VENV_DIR}/bin/activate \
    # Initialize a `uv` project (base)
    && uv init --bare --python 3.12 -v -n base \
    && uv pip install --upgrade pip \
    && uv pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install --no-cache-dir -r requirements.txt \
    # Save the installed packages to a lock file
    && uv pip freeze > requirements.lock \
    # Clean uv cache
    && uv cache clean

# Fetching System information & activate .venv at shell startup
RUN echo "fastfetch" >> /home/${USER}/.bashrc \
    && echo "source $VENV_DIR/bin/activate" >> /home/${USER}/.bashrc

# Ensure the container starts in the user's HOME directory
WORKDIR ${HOME}

ENTRYPOINT ["/entrypoint.sh"]