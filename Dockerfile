FROM archlinux:latest

# Select the ROOT user
USER root

# Initialize Arch Linux
RUN pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman --noconfirm -Syu

# Create a new user
RUN useradd --create-home --shell /bin/bash ${USER} \
    && usermod -aG wheel ${USER} \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    # Setting the user as a "sudoer"
    && sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# Build arguments for the user
ARG USER=abhans
ARG GUID=1000
ARG UID=${GUID}
ENV HOME=/home/${USER}
ENV VENV_DIR=${HOME}/.venv

# Install essentials and "uv" package manager
RUN pacman -Sy --noconfirm unzip sudo curl git vi nvim \
    && curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12 and create a virtual environment
RUN uv python install 3.12 \
    && uv venv --python 3.12 ${VENV_DIR}

# Install CUDA & Drivers
RUN && pacman -S --noconfirm nvidia cuda cuda-toolkit \
    && pacman -S --noconfirm nvidia-container-toolkit docker opencl-nvidia \
    && pacman -Sy neofetch \
    && pacman -Scc --noconfirm \
    && pacman -Syu --noconfirm

# Add the CUDA folders to the PATH
ENV PATH=/opt/cuda/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH=/opt/cuda/lib64

# Change to user
USER ${USER}

# Add directory to the machine
COPY . ${HOME}/dev/

WORKDIR ${HOME}/dev

RUN source ${VENV_DIR}/bin/activate \
    && uv pip install --upgrade pip \
    && uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install --no-cache-dir -r requirements.txt

# Fetching System information at shell startup
RUN echo "neofetch" >> /home/${USER}/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]