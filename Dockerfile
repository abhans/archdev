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
ENV VENV_DIR=${HOME}/.base
# Development directory
ARG DEV=${HOME}/.dev/

# ------------------------ ARCH LINUX INIT & USER CONFIG ------------------------
# Initialize Arch Linux
#  This includes setting up the package manager, locale, and user permissions
# Set the user and group IDs for the container
#  This allows the container to run with the same user and group IDs as the host system

# ------------------------------------------------ [  R O O T  ] ------------------------------------------------
USER root

# Initialize Arch Linux
RUN pacman-key --init \
    && pacman -Sy --noconfirm sudo \
    && pacman-key --populate archlinux \
    && pacman --needed --noconfirm -Syu \
    # Generate en_US.UTF-8 locale
    && sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen \
    && locale-gen \
    && pacman -Scc --noconfirm \
    # Create a new user
    && useradd --create-home --shell /bin/bash ${USER} \
    && usermod -aG wheel ${USER} \
    # Setting the user as a "sudoer"
    && sed -i 's/^# %wheel/%wheel/' /etc/sudoers \
    && mkdir -p ${HOME}/.local \
    && mkdir -p ${HOME}/.cache \
    # Fix permissions for the home directory
    && chown -R ${USER}:${USER} ${HOME} \
    # ------------------------ INSTALLATION (Python & Packages) ------------------------
    # Install base development tools, essentials and CUDA
    #  This installs essential development tools such as Git, GCC, Make, and CMake
    && pacman -Sy --needed --noconfirm cmake gcc make fastfetch openssh unzip curl git vi nvim jq \
    && pacman -Sy --noconfirm nvidia cuda cudnn nccl \
    && pacman -S --noconfirm nvidia-container-toolkit opencl-nvidia \
    && pacman -Scc --noconfirm

# ------------------------ CUDA CONFIGURATION ------------------------
# Configure CUDA for the container
#  This includes setting up the CUDA toolkit and adding it to the PATH
    
# Add the CUDA folders to the PATH
#   Adds CUDA binaries and libraries to environment variables
ENV PATH=/opt/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/usr/lib:/opt/cuda/lib64
# Configure the Matplotlib temporary directory
ENV MPLCONFIGDIR=/tmp/matplotlib

# ------------------------ ENVIRONMENT ------------------------
# Sets up the environment for the container
#  This includes setting a virtual environment, downlaoding packages, 
#  copying entrypoint scripts, and fixing permissions

# Set the locale to UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Copy entrypoint bash script & change its' permission to executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
    # Create bin directory
    && mkdir -p ${HOME}/bin \
    && chown -R ${USER}:${USER} ${HOME}/bin

# Copy Oh-My-Posh theme
COPY theme.omp.json ${HOME}/bin/theme.omp.json
RUN chown ${USER}:${USER} ${HOME}/bin/theme.omp.json

# Copy project files to the home directory
COPY --chown=${USER}:${USER} . ${DEV}

# ------------------------------------------------ [  U S E R  ] ------------------------------------------------
USER ${USER}

# Installation & setup of Oh-My-Posh
RUN curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ${HOME}/bin \
    && echo 'eval "$(oh-my-posh init bash --config $HOME/bin/theme.omp.json)"' >> ${HOME}/.bashrc

# Set the working directory to the project directory
WORKDIR ${DEV}

# Append ".local/bin" to PATH
#   This ensures that binaries installed by `uv` (such as Python) are available "system-wide"
ENV PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"

# Install the "uv" package manager, Python 3.12 and create a virtual environment
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv python install 3.12 \
    && uv venv --python 3.12 ${VENV_DIR} \
    && source ${VENV_DIR}/bin/activate \
    # Initialize a `uv` project (base)
    && uv init --bare --python 3.12 -v -n base \
    && uv pip install --upgrade pip \
    && uv pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 \
    && uv pip install --no-cache-dir -r requirements.txt \
    # Save the installed packages to a lock file
    && uv pip compile requirements.txt -o uv.lock \
    # Clean uv cache
    && uv cache clean \
    # Fixing NCLL links
    && echo "Fixing NCCL library usage in PyTorch…" \
    && rm -rf ${VENV_DIR}/lib/python3.12/site-packages/torch/lib/../../nvidia/nccl \
    && ln -s /usr/lib/libnccl.so.2 ${VENV_DIR}/lib/python3.12/site-packages/torch/lib/libnccl.so.2

# Fetching System information
RUN echo "fastfetch" >> ${HOME}/.bashrc

# Ensure the container starts in the user's HOME directory
WORKDIR ${HOME}

ENTRYPOINT ["/entrypoint.sh"]