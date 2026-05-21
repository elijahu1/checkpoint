#!/usr/bin/env bash
# what is this?
# checksum-verification.sh
# called by checkpoint.yml checksum-guard-02
# verifies terraform (GPG + SHA256), pulumi (GPG + SHA256), opentofu (SHA256 only)
# exits non-zero on any failure — pipeline stops immediately

set -euo pipefail

# ── versions ──────────────────────────────────────────────────────────────────
TF_VERSION="1.15.2"
PULUMI_VERSION="3.230.0"
TOFU_VERSION="1.11.6"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " checksum-guard-02 starting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── helper ────────────────────────────────────────────────────────────────────
fail() { echo ""; echo "  ✗ FAIL: $*"; echo ""; exit 1; }
pass() { echo "  ✓ PASS: $*"; }

# ── resolve keys/ dir relative to repo root ───────────────────────────────────
# GITHUB_WORKSPACE is set automatically on all github actions runners
KEYS_DIR="${GITHUB_WORKSPACE}/keys"

[ -f "$KEYS_DIR/terraform-public.gpg" ] || fail "terraform-public.gpg not found in keys/"
[ -f "$KEYS_DIR/pulumi-public.gpg"    ] || fail "pulumi-public.gpg not found in keys/"

# ── 01 terraform ──────────────────────────────────────────────────────────────
echo ""
echo "── terraform v${TF_VERSION} ──────────────────────────────────────────────"

TF_BASE="https://releases.hashicorp.com/terraform/${TF_VERSION}"
TF_ZIP="terraform_${TF_VERSION}_linux_amd64.zip"
TF_SUMS="terraform_${TF_VERSION}_SHA256SUMS"
TF_SIG="terraform_${TF_VERSION}_SHA256SUMS.sig"

curl -fsSLO "${TF_BASE}/${TF_ZIP}"
curl -fsSLO "${TF_BASE}/${TF_SUMS}"
curl -fsSLO "${TF_BASE}/${TF_SIG}"

# step 1 — import hashicorp public key into runner gpg keyring
gpg --import "$KEYS_DIR/terraform-public.gpg" 2>/dev/null

# step 2 — gpg verify: proves the SHA256SUMS file was signed by hashicorp
#           if an attacker swapped both the binary AND the checksum file,
#           this step catches it because they don't have hashicorp's private key
gpg --verify "${TF_SIG}" "${TF_SUMS}" \
  || fail "terraform GPG signature verification failed"
pass "terraform GPG signature verified"

# step 3 — sha256 verify: proves the binary matches the now-trusted checksum file
grep "${TF_ZIP}" "${TF_SUMS}" | sha256sum -c - \
  || fail "terraform SHA256 checksum mismatch"
pass "terraform SHA256 checksum verified"

# ── 02 pulumi ─────────────────────────────────────────────────────────────────
echo ""
echo "── pulumi v${PULUMI_VERSION} ────────────────────────────────────────────"

PULUMI_BASE="https://get.pulumi.com/releases/sdk"
PULUMI_TAR="pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz"
PULUMI_SUMS="pulumi-${PULUMI_VERSION}-checksums.txt"
PULUMI_SIG="pulumi-${PULUMI_VERSION}-checksums.txt.sig"

curl -fsSLO "${PULUMI_BASE}/${PULUMI_TAR}"
curl -fsSLO "${PULUMI_BASE}/${PULUMI_SUMS}"
curl -fsSLO "${PULUMI_BASE}/${PULUMI_SIG}"

# step 1 — import pulumi public key
gpg --import "$KEYS_DIR/pulumi-public.gpg"

# step 2 — gpg verify the checksum file
gpg --verify "${PULUMI_SIG}" "${PULUMI_SUMS}" \
  || fail "pulumi GPG signature verification failed"
pass "pulumi GPG signature verified"

# step 3 — sha256 verify the binary
grep "${PULUMI_TAR}" "${PULUMI_SUMS}" | sha256sum -c - \
  || fail "pulumi SHA256 checksum mismatch"
pass "pulumi SHA256 checksum verified"

# ── 03 opentofu ───────────────────────────────────────────────────────────────
echo ""
echo "── opentofu v${TOFU_VERSION} ────────────────────────────────────────────"

# NOTE: opentofu does ship a SHA256SUMS.gpgsig on github releases (for cosign),
# but the opentofu-public.gpg key in keys/ is for cosign/sigstore verification,
# not classic GPG. the tooling to use it in CI without cosign installed is not
# straightforward — this is documented and intentional. SHA256 only for now.
# revisit when cosign becomes a standard ubuntu-22.04 runner package.

TOFU_BASE="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}"
TOFU_ZIP="tofu_${TOFU_VERSION}_linux_amd64.zip"
TOFU_SUMS="tofu_${TOFU_VERSION}_SHA256SUMS"

curl -fsSLO "${TOFU_BASE}/${TOFU_ZIP}"
curl -fsSLO "${TOFU_BASE}/${TOFU_SUMS}"

# sha256 only — no GPG step
grep "${TOFU_ZIP}" "${TOFU_SUMS}" | sha256sum -c - \
  || fail "opentofu SHA256 checksum mismatch"
pass "opentofu SHA256 checksum verified"

# ── done ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " all 3 tools verified — checksum-guard-02 passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
