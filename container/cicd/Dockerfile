FROM ubuntu:latest AS base

RUN apt-get update && \
    apt-get install -y sudo openssh-server && \
    apt-get install -y vim && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

ARG ROOT_PASSWORD="password"
RUN echo "root:$ROOT_PASSWORD" | chpasswd

RUN mkdir /var/run/sshd

ENTRYPOINT ["/usr/sbin/sshd", "-D"]

# ===============================================
#  for jenkins build agent
# ===============================================
FROM base AS build-agent-node
RUN apt-get update && \
    apt-get install -y openjdk-21-jdk-headless && \
    apt-get install -y git curl docker.io && \
    rm -rf /var/lib/apt/lists/*

# ===============================================
#  for ansible
# ===============================================
FROM base AS ansible-node
RUN apt-get update && \
    apt-get install -y openjdk-21-jdk-headless && \
    apt-get install -y ansible sshpass && \
    rm -rf /var/lib/apt/lists/*

# ===============================================
#  for webapp
# ===============================================
FROM base AS webapp-node
