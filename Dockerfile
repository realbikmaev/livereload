# ssh proxy
FROM --platform=linux/amd64 rust:1.67 as builder
WORKDIR /usr/src/proxy
COPY ./proxy .
RUN cargo install --path .

# ssh server
FROM --platform=linux/amd64 ubuntu:22.04
ARG vm_user
ARG github_user
ARG volume_path

RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt update; \
    apt install --yes --no-install-recommends \
    bind9-dnsutils iputils-ping iproute2 curl \
    openssh-server openssh-client apt-utils \
    htop wget git-core git build-essential \
    xz-utils tk-dev libffi-dev liblzma-dev \
    libreadline-dev libsqlite3-dev llvm \
    python3-openssl ca-certificates jq \
    libssl-dev zlib1g-dev libbz2-dev \
    libncurses5-dev libncursesw5-dev \
    sudo less tree locales docker.io; \
    apt clean autoclean; \
    apt autoremove --yes; \
    rm -rf /var/lib/{apt,dpkg,cache,log}/; \
    echo "installed base utils!"; \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
    locale-gen en_US.UTF-8; \
    update-locale LANG=en_US.UTF-8; \
    echo "set locale"

RUN set -eux; \
    yes | unminimize; \
    echo "unminimized ubuntu"

RUN set -eux; \
    useradd -ms /usr/bin/bash $vm_user; \
    usermod -aG sudo $vm_user; \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    echo "added user $vm_user"

RUN set -eux; \
    echo "Port 22" >> /etc/ssh/sshd_config; \
    echo "AddressFamily inet" >> /etc/ssh/sshd_config; \
    echo "ListenAddress 127.0.0.2" >> /etc/ssh/sshd_config; \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config; \
    echo "ClientAliveInterval 30" >> /etc/ssh/sshd_config; \
    echo "ClientAliveCountMax 10" >> /etc/ssh/sshd_config; \
    echo "AuthorizedKeysFile /etc/ssh/authorized_keys/%u" >> /etc/ssh/sshd_config; \
    echo "ssh server set up"

USER $vm_user
WORKDIR $volume_path
ENV LANG en_US.utf8

RUN set -eux; \
    sudo mkdir /etc/ssh/authorized_keys; \
    curl https://github.com/$github_user.keys | sudo tee -a /etc/ssh/authorized_keys/$vm_user;

COPY --from=builder /usr/local/cargo/bin/proxy /usr/local/bin/proxy
CMD ["bash", "-c", "sudo service ssh start; echo 'ssh server started'; main.sh; proxy"]