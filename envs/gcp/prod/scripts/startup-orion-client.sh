#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/orion-client-startup.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  git \
  git-lfs \
  gettext-base \
  netcat-openbsd \
  procps \
  zstd \
  fuse3 \
  libssl3 \
  build-essential \
  pkg-config \
  cmake \
  clang \
  llvm-dev \
  libclang-dev \
  libssl-dev \
  libfuse3-dev \
  protobuf-compiler \
  rsync

echo "user_allow_other" >> /etc/fuse.conf || true

mkdir -p \
  /opt/orion-client \
  /opt/orion-client/src \
  /opt/orion-client/bin \
  /opt/orion-client/log \
  /data/scorpio/store \
  /data/scorpio/antares/upper \
  /data/scorpio/antares/cl \
  /data/scorpio/antares/mnt \
  /workspace/mount \
  /home/orion/orion-runner

# Ensure orion exists before chown (metadata ssh-keys may create it later; avoid set -e exit here).
if ! id -u orion &>/dev/null; then
  useradd -m -s /bin/bash orion
fi

chown -R orion:orion /home/orion/orion-runner

# 条件设置权限（首次部署时文件可能不存在，等待 CI 部署）
if [ -f /home/orion/orion-runner/run.sh ]; then
    chmod +x /home/orion/orion-runner/run.sh
fi
if [ -f /home/orion/orion-runner/orion ]; then
    chmod +x /home/orion/orion-runner/orion
fi

# Install Rust toolchain if missing
if ! command -v rustc >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
export PATH="/root/.cargo/bin:${PATH}"

# Install Buck2
BUCK2_VERSION="latest"
ARCH="x86_64-unknown-linux-musl"
curl -fsSL -o /usr/local/bin/buck2.zst "https://github.com/facebook/buck2/releases/download/${BUCK2_VERSION}/buck2-${ARCH}.zst"
zstd -d /usr/local/bin/buck2.zst -o /usr/local/bin/buck2
chmod +x /usr/local/bin/buck2


cat <<EOF > /etc/systemd/system/orion-runner.service
[Unit]
Description=Orion Runner and Scorpio Service (Managed by script)
After=network.target

[Service]
# 指定运行服务的用户和组
User=orion
Group=orion

# 加载 .env 文件中的环境变量
WorkingDirectory=/home/orion/orion-runner

# 启动命令：直接执行我们的主控脚本
ExecStart=/bin/bash run.sh
# 停止逻辑: systemd 会向 ExecStart 启动的进程（即 manage-orion.sh）发送 SIGTERM 信号。
# 脚本内的 `trap` 命令会处理这个信号，优雅地关闭后台进程。
# 我们不再需要一个独立的 ExecStop 脚本了。

# 定义服务在失败时自动重启
Restart=on-failure
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin"
Environment="RUST_BACKTRACE=1"
LimitNOFILE=10485760
LimitNPROC=1048576

# 脚本的标准输出和错误追加到文件（orion/scorpio 的日志在 run.sh 内单独重定向）
StandardOutput=append:/var/log/orion-runner.log
StandardError=append:/var/log/orion-runner.log

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable orion-runner


systemctl restart orion-runner || echo "Note: Service start failed (waiting for CI deployment)"

echo "===== Orion startup finished ====="
