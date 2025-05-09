# TODO: Arch Linux Development Environment
#   - Neofetch (at the start of each bash session)
#   - Tensorflow & CUDA
#   - NVIDIA Drivers
#   - Python and C++ support

# Base Image
FROM archlinux:latest

# Build Arguments
ARG USER=abhans
ARG GUID=1000
ARG UID=${GUID}
ENV HOME=/home/${USER}
ENV ENV_DIR=${HOME}/.venv
ENV CUDA_VISIBLE_DEVICES=0

# Switch to root if it's not already
USER root

# Populating Signature Keys
RUN pacman-key --init && \
    pacman-key --populate archlinux

# System Updates
RUN --mount=type=cache,target=/var/cache/pacman/pkg \
    pacman -Syu --noconfirm --needed base-devel sudo git \
    # Python Installation
    python-pip python-virtualenv \
    neofetch \
    # NVIDIA Drivers & CUDA
    nvidia nvidia-utils nvidia-settings nvidia-container-toolkit && \
    # cuda cudnn cuda-tools && \
    # Cleanup
    pacman -Scc --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# Configuring groups and users
RUN useradd --create-home --shell /bin/bash ${USER} && \
    usermod -aG wheel ${USER} && \
    # Setting the user as a "sudoer"
    sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# Installing AUR helper (yay) and Python 3.11
USER ${USER}

RUN git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si --noconfirm && \
    yay -S --noconfirm python311 && \
    # Cleanup
    rm -rf /tmp/yay && \
    # Creating virtual environment with Python 3.11
    /usr/bin/python3.11 -m venv ${ENV_DIR}

WORKDIR ${HOME}

# Installing PyPI packages
COPY requirements.txt run.py ${HOME}/

RUN source ${ENV_DIR}/bin/activate && \
    pip3 install --upgrade pip && \
    # Download PyTorch
    pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    # python3 -m pip install 'tensorflow[and-cuda]' && \
    pip3 install --no-cache-dir -r /requirements.txt && \
    # Fetching System information at shell startup
    echo "neofetch" >> /home/${USER}/.bashrc

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]