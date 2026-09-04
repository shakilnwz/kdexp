FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    bash \
    git \
    curl \
    jq \
    tmux \
    fzf \
    bat \
    fd-find \
    ripgrep \
    x11-xkb-utils \
    xcape \
    neovim \
    sudo \
    ca-certificates \
    libkf6config-bin \
    && rm -rf /var/lib/apt/lists/*

# Create non-root test user to simulate multi-user environment
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER testuser
ENV HOME=/home/testuser
WORKDIR /home/testuser/dotfiles

CMD ["/bin/bash"]
