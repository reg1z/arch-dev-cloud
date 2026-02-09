FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        qemu-base \
        qemu-img \
        edk2-ovmf \
        curl \
        unzip && \
    pacman -Scc --noconfirm

# Install Packer
ARG PACKER_VERSION=1.12.0
RUN curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o /tmp/packer.zip && \
    unzip /tmp/packer.zip -d /usr/local/bin/ && \
    rm /tmp/packer.zip && \
    chmod +x /usr/local/bin/packer

WORKDIR /build

COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

ENTRYPOINT ["/build/build.sh"]
