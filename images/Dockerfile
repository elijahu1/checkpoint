# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS builder

ARG TARGETARCH=amd64

ARG TERRAFORM_VERSION=1.15.2
ARG OPENTOFU_VERSION=1.11.6
ARG PULUMI_VERSION=3.237.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build


# =========================================================
# ARCH MAPPING
# =========================================================

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) \
            TF_ARCH="amd64"; \
            TOFU_ARCH="amd64"; \
            PULUMI_ARCH="x64"; \
            ;; \
        arm64) \
            TF_ARCH="arm64"; \
            TOFU_ARCH="arm64"; \
            PULUMI_ARCH="arm64"; \
            ;; \
        *) \
            echo "unsupported architecture: ${TARGETARCH}" >&2; \
            exit 1; \
            ;; \
    esac; \
    echo "${TF_ARCH}" > /tmp/tf_arch; \
    echo "${TOFU_ARCH}" > /tmp/tofu_arch; \
    echo "${PULUMI_ARCH}" > /tmp/pulumi_arch


# =========================================================
# TERRAFORM (SHA256 verify)
# =========================================================

RUN TF_ARCH="$(cat /tmp/tf_arch)" && \
    curl -fsSLo terraform.zip \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" && \
    curl -fsSLo terraform_SHA256SUMS \
    "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    grep "terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" terraform_SHA256SUMS | sha256sum -c - && \
    unzip -q terraform.zip && \
    install -m 0755 terraform /usr/local/bin/terraform


# =========================================================
# OPENTOFU (SHA256 verify)
# =========================================================

RUN TOFU_ARCH="$(cat /tmp/tofu_arch)" && \
    curl -fsSLo tofu.zip \
    "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${TOFU_ARCH}.zip" && \
    curl -fsSLo tofu_SHA256SUMS \
    "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_SHA256SUMS" && \
    grep "tofu_${OPENTOFU_VERSION}_linux_${TOFU_ARCH}.zip" tofu_SHA256SUMS | sha256sum -c - && \
    unzip -q tofu.zip && \
    install -m 0755 tofu /usr/local/bin/tofu


# =========================================================
# PULUMI (SHA256 verify, x64 naming)
# =========================================================

RUN PULUMI_ARCH="$(cat /tmp/pulumi_arch)" && \
    curl -fsSLo pulumi.tar.gz \
    "https://github.com/pulumi/pulumi/releases/download/v${PULUMI_VERSION}/pulumi-v${PULUMI_VERSION}-linux-${PULUMI_ARCH}.tar.gz" && \
    curl -fsSLo pulumi_checksums.txt \
    "https://github.com/pulumi/pulumi/releases/download/v${PULUMI_VERSION}/pulumi-${PULUMI_VERSION}-checksums.txt" && \
    grep "pulumi-v${PULUMI_VERSION}-linux-${PULUMI_ARCH}.tar.gz" pulumi_checksums.txt | sha256sum -c - && \
    tar -xzf pulumi.tar.gz && \
    install -m 0755 pulumi/pulumi /usr/local/bin/pulumi


# =========================================================
# FINAL RUNTIME IMAGE
# =========================================================

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*


# =========================================================
# COPY BINARIES ONLY
# =========================================================

COPY --from=builder /usr/local/bin/terraform /usr/local/bin/terraform
COPY --from=builder /usr/local/bin/tofu /usr/local/bin/tofu
COPY --from=builder /usr/local/bin/pulumi /usr/local/bin/pulumi


# =========================================================
# WORKSPACE
# =========================================================

WORKDIR /workspace

CMD ["bash"]
