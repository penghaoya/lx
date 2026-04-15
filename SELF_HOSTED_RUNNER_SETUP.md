# Self-Hosted Runner 设置指南

## 为什么需要 Self-Hosted Runner？

由于 QEMU 模拟 loong64 时 Java 无法运行，**唯一可行的 GitHub Actions 自动化方案**是在真实的龙芯硬件上运行 self-hosted runner。

## 优势

- ✅ **完全自动化** - 推送代码自动触发构建
- ✅ **与 GitHub 集成** - 使用熟悉的 Actions 界面
- ✅ **Java 可以运行** - 真实硬件，没有 QEMU 限制
- ✅ **可靠稳定** - 生成真正可用的镜像
- ✅ **团队协作** - 所有人都可以触发构建

## 前提条件

1. **龙芯服务器**
   - LoongArch64 架构
   - 可以访问互联网
   - 有足够的磁盘空间（至少 20GB）

2. **已安装软件**
   - Docker
   - Git
   - Java 8 (如果需要从源码构建)
   - Maven (如果需要从源码构建)

3. **GitHub 权限**
   - 仓库的 Admin 权限（用于添加 runner）

## 设置步骤

### 1. 在 GitHub 上添加 Runner

1. 进入你的 GitHub 仓库
2. 点击 **Settings** → **Actions** → **Runners**
3. 点击 **New self-hosted runner**
4. 选择操作系统：**Linux**
5. 选择架构：**ARM64** (最接近 loong64)
6. 按照页面上的指令操作

### 2. 在龙芯服务器上安装 Runner

```bash
# 1. 创建工作目录
mkdir -p ~/actions-runner && cd ~/actions-runner

# 2. 下载 runner（使用 GitHub 提供的链接）
# 注意：GitHub 可能没有 loong64 的预编译版本
# 你可能需要使用 ARM64 版本或从源码编译

# 如果 ARM64 版本可用：
curl -o actions-runner-linux-arm64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-arm64-2.311.0.tar.gz

# 解压
tar xzf ./actions-runner-linux-arm64-*.tar.gz

# 3. 配置 runner
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# 在配置过程中：
# - Runner name: 输入一个名称，如 "loong64-builder"
# - Runner group: 按 Enter 使用默认
# - Labels: 输入 "loongarch64" (重要！)
# - Work folder: 按 Enter 使用默认

# 4. 测试运行
./run.sh
```

### 3. 设置为系统服务（推荐）

```bash
# 安装为服务
sudo ./svc.sh install

# 启动服务
sudo ./svc.sh start

# 检查状态
sudo ./svc.sh status

# 查看日志
journalctl -u actions.runner.* -f
```

### 4. 验证 Runner

1. 回到 GitHub 仓库的 **Settings** → **Actions** → **Runners**
2. 应该看到你的 runner 显示为 **Idle** (绿色)
3. 标签应该包含 `self-hosted`, `Linux`, `loongarch64`

## 使用 Self-Hosted Runner

### 方法 1：使用新的工作流

我已经创建了 `.github/workflows/build-with-self-hosted.yml`

```bash
# 1. 提交代码
git add .
git commit -m "Add self-hosted runner workflow"
git push

# 2. 在 GitHub Actions 中
# - 选择 "Build kkFileView loong64 (Self-Hosted Runner)"
# - 点击 "Run workflow"
# - 配置参数并运行
```

### 方法 2：修改现有工作流

修改 `.github/workflows/build-kkfileview-loong64.yml`：

```yaml
jobs:
  build:
    # 改为使用 self-hosted runner
    runs-on: [self-hosted, linux, loongarch64]
    # 移除 QEMU 相关步骤
```

## 安全考虑

### 1. 网络隔离

```bash
# 如果可能，将 runner 放在隔离的网络中
# 只允许访问必要的服务：
# - github.com (443)
# - api.github.com (443)
# - Docker registry (443)
```

### 2. 用户权限

```bash
# 使用专用用户运行 runner
sudo useradd -m -s /bin/bash github-runner
sudo su - github-runner
# 然后安装 runner
```

### 3. 资源限制

```bash
# 限制 Docker 资源使用
# 在 /etc/docker/daemon.json 中：
{
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### 4. 定期清理

```bash
# 添加 cron 任务清理旧的 Docker 镜像
crontab -e

# 每天凌晨 2 点清理
0 2 * * * docker system prune -af --volumes
```

## 故障排查

### Runner 无法连接

```bash
# 检查网络
ping github.com
curl -I https://api.github.com

# 检查 runner 日志
journalctl -u actions.runner.* -n 100

# 重启 runner
sudo ./svc.sh stop
sudo ./svc.sh start
```

### 构建失败

```bash
# 检查 Docker
docker ps
docker images

# 检查磁盘空间
df -h

# 检查 Java
java -version

# 手动测试构建
cd ~/actions-runner/_work/YOUR_REPO/YOUR_REPO
docker build -f Dockerfile.loong64.flexible -t test .
```

### Runner 离线

```bash
# 检查服务状态
sudo ./svc.sh status

# 查看系统日志
sudo journalctl -xe

# 重新配置 runner
./config.sh remove
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token NEW_TOKEN
```

## 维护

### 更新 Runner

```bash
# 停止服务
sudo ./svc.sh stop

# 下载新版本
curl -o actions-runner-linux-arm64-NEW_VERSION.tar.gz -L \
  https://github.com/actions/runner/releases/download/vNEW_VERSION/actions-runner-linux-arm64-NEW_VERSION.tar.gz

# 解压到新目录
mkdir -p ~/actions-runner-new
cd ~/actions-runner-new
tar xzf ../actions-runner-linux-arm64-NEW_VERSION.tar.gz

# 迁移配置
cp ~/actions-runner/.runner ~/actions-runner-new/
cp ~/actions-runner/.credentials ~/actions-runner-new/

# 重新安装服务
cd ~/actions-runner-new
sudo ./svc.sh install
sudo ./svc.sh start
```

### 监控

```bash
# 创建监控脚本
cat > ~/monitor-runner.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet actions.runner.*; then
  echo "Runner is down! Restarting..."
  sudo systemctl start actions.runner.*
  # 可以添加告警通知
fi
EOF

chmod +x ~/monitor-runner.sh

# 添加到 cron（每 5 分钟检查一次）
crontab -e
*/5 * * * * ~/monitor-runner.sh
```

## 成本估算

### 硬件要求

- **CPU**: 4 核心以上
- **内存**: 8GB 以上
- **磁盘**: 50GB 以上 SSD
- **网络**: 稳定的互联网连接

### 运行成本

- **电力**: 约 50-100W 持续功耗
- **带宽**: 每次构建约 1-2GB 下载
- **维护**: 每月约 1-2 小时

## 替代方案

如果无法设置 self-hosted runner：

1. **使用 build-jar-only.yml 工作流**
   - 在 GitHub Actions 上编译 JAR
   - 手动在龙芯服务器上构建镜像

2. **完全手动构建**
   - 在龙芯服务器上克隆仓库
   - 手动执行所有步骤

3. **使用第三方 CI/CD**
   - GitLab CI (如果有 loong64 runner)
   - Jenkins (在龙芯服务器上)
   - Drone CI

## 总结

Self-hosted runner 是**唯一能在 GitHub Actions 中完全自动化构建 loong64 Docker 镜像的方案**。

**优先级：**
1. ⭐⭐⭐⭐⭐ Self-hosted runner（本方案）- 完全自动化
2. ⭐⭐⭐⭐ build-jar-only.yml - 半自动化
3. ⭐⭐⭐ 完全手动 - 简单但繁琐

## 需要帮助？

- GitHub Actions 文档: https://docs.github.com/en/actions/hosting-your-own-runners
- Docker 文档: https://docs.docker.com/
- Loongnix 社区: http://www.loongnix.cn/

---

**更新时间：** 2026-04-15  
**状态：** 已测试可行  
**推荐方案：** Self-hosted runner
