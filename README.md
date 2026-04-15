# kkFileView loong64 GitHub Actions 构建

⚠️ **重要提示：QEMU 模拟 loong64 存在 Java 运行问题**

经过测试发现，使用 GitHub Actions + QEMU 模拟 loong64 架构时，Java 虚拟机无法正常初始化（`SR_initialize failed: Invalid argument`）。这意味着：

- ❌ 虽然 Docker 镜像可以构建，但 **Java 无法运行**
- ❌ 生成的镜像 **无法启动 kkFileView 服务**
- ❌ 当前方案 **无法产生可用的镜像**

**推荐方案：** 使用真实的龙芯硬件进行构建。详见 [QEMU_JAVA_ISSUE.md](./QEMU_JAVA_ISSUE.md)

---

这个仓库用于在 GitHub Actions 上构建可运行于 LoongArch64 服务器的 kkFileView Docker 镜像，并导出为离线部署所需的 tar 文件。

镜像内会安装 kkFileView 文档预览所需的 LibreOffice，并在容器启动时自动探测 `office.home`，避免因路径配置错误导致服务启动失败。

## ⚠️ 已知问题

### QEMU 模拟 loong64 的 Java 问题

**问题描述：**
```
SR_initialize failed: Invalid argument
Error: Could not create the Java Virtual Machine.
```

**影响：**
- GitHub Actions 使用 QEMU 模拟 loong64 时，Java 无法初始化
- 构建的镜像无法运行 kkFileView
- 容器启动会失败

**解决方案：**

1. **使用真实龙芯硬件** ⭐ 推荐
   ```bash
   # 在龙芯服务器上
   git clone <your-repo>
   cd <your-repo>
   
   # 下载或构建 jar
   wget https://github.com/kekingcn/kkFileView/releases/download/v4.4.0/kkFileView-4.4.0.jar -O kkFileView.jar
   
   # 构建镜像
   docker build -f Dockerfile.loong64.flexible -t kkfileview:loong64 .
   
   # 测试
   docker run -d -p 8012:8012 kkfileview:loong64
   ```

2. **混合方案：GitHub Actions + 龙芯服务器**
   - 在 GitHub Actions 上编译 jar（快速）
   - 将 jar 传输到龙芯服务器
   - 在龙芯服务器上构建 Docker 镜像（可用）

3. **自建 Runner**
   - 在龙芯硬件上安装 GitHub Actions self-hosted runner
   - 配置工作流使用 self-hosted runner

详细信息请查看：[QEMU_JAVA_ISSUE.md](./QEMU_JAVA_ISSUE.md)

## 🚀 快速开始（推荐方案）

### 方案 A：使用构建套件工作流 ⭐ **最佳方案**

这是目前**唯一可行且推荐的方案**。

**步骤 1：在 GitHub Actions 中生成构建套件**

1. 进入仓库的 **Actions** 标签
2. 选择 **"Build kkFileView JAR (for loong64 manual build)"**
3. 点击 **"Run workflow"**
4. 配置参数：
   - `kkfileview_version`: `v4.4.0`
   - `build_mode`: `source` 或 `release`
5. 等待构建完成（约 5-10 分钟）
6. 下载生成的 **build kit** artifact

**步骤 2：在龙芯服务器上构建镜像**

```bash
# 1. 解压构建套件
tar -xzf kkfileview-loong64-build-kit-4.4.0.tar.gz
cd loong64-build-kit

# 2. 运行构建脚本（推荐）
./build.sh

# 或者手动构建
docker build -f Dockerfile.loong64.flexible -t kkfileview:loong64 .

# 3. 测试运行
docker run -d -p 8012:8012 --name kkfileview kkfileview:loong64
docker logs -f kkfileview
curl http://localhost:8012

# 4. 导出镜像（可选）
docker save -o kkfileview-loong64.tar kkfileview:loong64
```

### 方案 B：完全手动构建

如果你有龙芯硬件和完整的开发环境：

```bash
# 1. 克隆 kkFileView
git clone --depth 1 --branch v4.4.0 https://github.com/kekingcn/kkFileView.git
cd kkFileView

# 2. 构建 JAR
mvn package -Dmaven.test.skip=true

# 3. 复制文件
cp server/target/kkFileView-4.4.0.jar /path/to/build/kkFileView.jar
# 同时复制 Dockerfile 和 entrypoint 脚本

# 4. 构建镜像
docker build -f Dockerfile.loong64.flexible -t kkfileview:loong64 .
```

详细说明请查看：[FINAL_SOLUTION.md](./FINAL_SOLUTION.md)

## 🚀 快速开始（真实硬件）

**推荐配置（最稳定）：**

1. 进入 GitHub Actions
2. 选择 "Build kkFileView loong64 image"
3. 使用以下配置：
   - `kkfileview_version`: `v4.4.0`
   - `build_mode`: `source`
   - `base_image`: `cr.loongnix.cn/library/openjdk:8-buster` ⭐
   - `dockerfile`: `Dockerfile.loong64.openjdk8` ⭐
   - `image_name`: `kkfileview`

📖 **详细指南：** 查看 [QUICK_START.md](./QUICK_START.md)

## 📋 Dockerfile 选项

本仓库提供了多个 Dockerfile 以应对不同的构建环境和需求：

| Dockerfile | 基础镜像 | 推荐度 | 说明 |
|-----------|---------|--------|------|
| **Dockerfile.loong64.openjdk8** | cr.loongnix.cn/library/openjdk:8-buster | ⭐⭐⭐⭐⭐ | **强烈推荐**，最稳定，已包含 Java 8 |
| Dockerfile.loong64 | ghcr.io/loong64/debian:trixie-slim | ⭐⭐⭐ | 支持最新 Debian，需要安装 Java |
| Dockerfile.loong64.minimal | 任意 | ⭐⭐⭐⭐ | 最小化版本，用于调试 |
| Dockerfile.loong64.alternative | 任意 | ⭐⭐⭐ | 详细日志版本 |

## 工作流能力

- ✅ 支持 `release` 模式：直接下载官方发布的 jar，速度更快
- ✅ 支持 `source` 模式：从源码编译 jar
- ✅ 仅面向 `kkFileView v4.x` 构建
- ✅ 固定使用 JDK 8 构建 `v4.x`
- ✅ 使用 `docker buildx` + QEMU 构建 `linux/loong64` 镜像
- ✅ 自动导出 `docker save` 生成的 tar 包并作为 Actions Artifact 上传
- ✅ **新增：** 支持选择不同的 Dockerfile
- ✅ **新增：** 支持选择不同的基础镜像
- ✅ **新增：** 完善的错误处理和日志输出

## 使用方法

### GitHub Actions 构建

1. 将当前目录推送到 GitHub 仓库
2. 打开仓库的 Actions 页面
3. 可以 push 到 `main` 自动触发，也可以手动运行 `Build kkFileView loong64 image` 工作流
4. 根据需要填写输入参数：

**参数说明：**

- `kkfileview_version`：例如 `v4.4.0`
- `build_mode`：`release` 或 `source`，默认建议 `source`
- `base_image`：选择基础镜像
  - `cr.loongnix.cn/library/openjdk:8-buster` ⭐ 推荐
  - `ghcr.io/loong64/debian:trixie-slim`
- `dockerfile`：选择 Dockerfile
  - `Dockerfile.loong64.openjdk8` ⭐ 推荐
  - `Dockerfile.loong64`
  - `Dockerfile.loong64.minimal`
- `image_name`：默认 `kkfileview`

工作流会校验版本号，只有 `v4.x` 会继续执行；如果误填 `v5.x` 或其他版本，会在开始阶段直接失败并提示。

### 本地构建（可选）

```bash
# 准备 kkFileView.jar
wget https://github.com/kekingcn/kkFileView/releases/download/v4.4.0/kkFileView-4.4.0.jar -O kkFileView.jar

# 构建镜像
docker buildx build \
  --platform linux/loong64 \
  --build-arg BASE_IMAGE=cr.loongnix.cn/library/openjdk:8-buster \
  -t kkfileview:loong64-v4.4.0 \
  -f Dockerfile.loong64.openjdk8 \
  --load .
```

## 产物说明

构建完成后，Artifact 中会生成类似下面的文件：

```text
kkfileview-loong64-4.4.0.tar
```

下载后可拷贝到离线龙芯服务器，再执行：

```bash
# 加载镜像
docker load -i kkfileview-loong64-4.4.0.tar

# 运行容器
docker run -d \
  --name kkfileview \
  -p 8012:8012 \
  -v /usr/share/fonts:/usr/share/fonts \
  kkfileview:loong64-4.4.0

# 查看日志
docker logs -f kkfileview

# 测试访问
curl http://localhost:8012
```

## 🔧 故障排查

### 常见问题

1. **apt-get 失败**
   - 使用 `Dockerfile.loong64.openjdk8`，它已配置允许未认证的包

2. **GPG 签名错误**
   - 使用 `Dockerfile.loong64.openjdk8`，它会自动处理签名问题

3. **LibreOffice 安装失败**
   - 容器仍可运行，但文档转换功能不可用
   - 检查网络连接和仓库可用性

4. **构建超时**
   - QEMU 模拟较慢，这是正常现象
   - 考虑使用缓存或真实 loong64 硬件

📖 **详细排查指南：** 查看 [DOCKER_BUILD_FIXES.md](./DOCKER_BUILD_FIXES.md)

## 📚 文档

- [QUICK_START.md](./QUICK_START.md) - 快速开始指南
- [DOCKER_BUILD_FIXES.md](./DOCKER_BUILD_FIXES.md) - 详细的问题分析和解决方案
- [CHANGES_SUMMARY.md](./CHANGES_SUMMARY.md) - 修改总结
- [CHECKLIST.md](./CHECKLIST.md) - 部署检查清单

## 注意事项

- ⚠️ 上游 `v4.4.0` Release 没有公开 jar 资产，`release` 模式下载失败时会自动回退到源码编译
- ⚠️ 本仓库当前工作流只处理 `v4.x`，不考虑 `v5.x` 及更高版本
- ⚠️ kkFileView 常依赖宿主机字体，离线服务器建议挂载 `/usr/share/fonts`
- ⚠️ 镜像已包含 LibreOffice；如果启动日志仍提示 `找不到office组件`，通常说明镜像不是由当前仓库最新 Dockerfile 构建出来的
- ⚠️ 默认容器端口为 `8012`，如有冲突可改为 `-p 18012:8012`
- ✅ **新增：** 推荐使用 `Dockerfile.loong64.openjdk8` + `cr.loongnix.cn/library/openjdk:8-buster` 组合，成功率最高

## 🔗 相关链接

- [kkFileView 官方文档](https://kkfileview.keking.cn/)
- [kkFileView GitHub](https://github.com/kekingcn/kkFileView)
- [Loongnix 官网](http://www.loongnix.cn/)

## 📝 更新日志

### 2026-04-15
- ✨ 新增 `Dockerfile.loong64.openjdk8`（推荐使用）
- ✨ 新增 `Dockerfile.loong64.minimal` 和 `Dockerfile.loong64.alternative`
- 🔧 修复 apt GPG 签名验证问题
- 🔧 修复包版本不可用问题
- 📖 完善文档和使用指南
- 🚀 GitHub Actions 支持选择 Dockerfile 和基础镜像
