# 快速开始指南

## 🚀 推荐方案（最简单）

使用 **Dockerfile.loong64.openjdk8** + **cr.loongnix.cn/library/openjdk:8-buster**

### GitHub Actions 构建

1. 进入仓库的 **Actions** 标签
2. 选择 **Build kkFileView loong64 image**
3. 点击 **Run workflow**
4. 使用以下配置：

```yaml
kkfileview_version: v4.4.0
build_mode: source
base_image: cr.loongnix.cn/library/openjdk:8-buster
dockerfile: Dockerfile.loong64.openjdk8
image_name: kkfileview
```

5. 点击 **Run workflow** 开始构建
6. 等待构建完成（约 10-20 分钟）
7. 下载生成的 tar 文件

### 本地构建（如果有 loong64 环境）

```bash
# 1. 克隆仓库
git clone <your-repo>
cd <your-repo>

# 2. 准备 kkFileView.jar（选择一种方式）

# 方式 A: 从源码构建
git clone --depth 1 --branch v4.4.0 https://github.com/kekingcn/kkFileView.git
cd kkFileView
mvn package -Dmaven.test.skip=true
cp server/target/kkFileView-*.jar ../kkFileView.jar
cd ..

# 方式 B: 下载发布版本
wget https://github.com/kekingcn/kkFileView/releases/download/v4.4.0/kkFileView-4.4.0.jar -O kkFileView.jar

# 3. 构建 Docker 镜像
docker buildx build \
  --platform linux/loong64 \
  --build-arg BASE_IMAGE=cr.loongnix.cn/library/openjdk:8-buster \
  -t kkfileview:loong64-v4.4.0 \
  -f Dockerfile.loong64.openjdk8 \
  --load .

# 4. 运行容器
docker run -d \
  -p 8012:8012 \
  --name kkfileview \
  kkfileview:loong64-v4.4.0

# 5. 测试
curl http://localhost:8012
```

## 📋 三种 Dockerfile 对比

| Dockerfile | 基础镜像 | Java | 复杂度 | 成功率 | 推荐场景 |
|-----------|---------|------|--------|--------|---------|
| **Dockerfile.loong64.openjdk8** ⭐ | cr.loongnix.cn/library/openjdk:8-buster | ✅ 已包含 | 低 | ⭐⭐⭐⭐⭐ | **生产环境，首选** |
| Dockerfile.loong64 | ghcr.io/loong64/debian:trixie-slim | ❌ 需安装 | 中 | ⭐⭐⭐ | 需要最新 Debian |
| Dockerfile.loong64.minimal | 任意 | 取决于基础镜像 | 低 | ⭐⭐⭐⭐ | 调试和测试 |

## 🔧 故障排查

### 问题 1: apt-get update 失败

**错误信息：**
```
E: The repository 'http://pkg.loongnix.cn/loongnix DaoXiangHu-stable InRelease' is not signed.
```

**解决方案：**
使用 `Dockerfile.loong64.openjdk8`，它已经配置了允许未认证的包。

### 问题 2: 找不到特定版本的包

**错误信息：**
```
E: Can't find a source to download version 'X.X.X' of 'package:loongarch64'
```

**解决方案：**
使用 `Dockerfile.loong64.openjdk8`，它不依赖特定版本，而是安装可用的版本。

### 问题 3: LibreOffice 下载失败

**症状：**
构建成功但 soffice 命令不可用

**解决方案：**
1. 检查网络连接
2. Dockerfile 会自动尝试多个镜像源
3. 如果所有源都失败，容器仍可运行，但文档转换功能不可用

### 问题 4: QEMU 模拟太慢

**症状：**
构建超时或非常慢

**解决方案：**
1. 增加 GitHub Actions 的超时时间
2. 使用缓存加速构建
3. 考虑使用真实的 loong64 硬件

## 📦 使用构建的镜像

### 从 tar 文件加载

```bash
# 下载 GitHub Actions 生成的 tar 文件
docker load -i kkfileview-loong64-4.4.0.tar

# 查看镜像
docker images | grep kkfileview

# 运行
docker run -d -p 8012:8012 kkfileview:loong64-4.4.0
```

### 环境变量配置

```bash
docker run -d \
  -p 8012:8012 \
  -e SERVER_PORT=8012 \
  -e FILE_DIR=/opt/kkFileView/file \
  -v /path/to/files:/opt/kkFileView/file \
  --name kkfileview \
  kkfileview:loong64-4.4.0
```

### 验证安装

```bash
# 检查容器状态
docker ps | grep kkfileview

# 查看日志
docker logs kkfileview

# 测试 API
curl http://localhost:8012/

# 检查 LibreOffice
docker exec kkfileview which soffice
docker exec kkfileview soffice --version
```

## 🔗 相关链接

- [kkFileView 官方文档](https://kkfileview.keking.cn/)
- [kkFileView GitHub](https://github.com/kekingcn/kkFileView)
- [Loongnix 官网](http://www.loongnix.cn/)
- [详细修复说明](./DOCKER_BUILD_FIXES.md)

## 💡 提示

1. **首次构建**：推荐使用 `Dockerfile.loong64.openjdk8`
2. **网络问题**：如果在中国大陆，Loongnix 镜像源速度较快
3. **调试模式**：使用 `--progress=plain` 查看详细日志
4. **缓存利用**：分层构建可以加速后续构建

## ❓ 需要帮助？

如果遇到问题：
1. 查看 [DOCKER_BUILD_FIXES.md](./DOCKER_BUILD_FIXES.md) 了解详细信息
2. 检查 GitHub Actions 的构建日志
3. 在 Issues 中搜索类似问题
4. 提交新的 Issue 并附上完整的错误日志
