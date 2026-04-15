# ✅ 部署检查清单

## 📋 提交前检查

- [ ] 所有 Dockerfile 文件已创建
  - [ ] `Dockerfile.loong64.openjdk8` ⭐
  - [ ] `Dockerfile.loong64`
  - [ ] `Dockerfile.loong64.minimal`
  - [ ] `Dockerfile.loong64.alternative`
- [ ] GitHub Actions 工作流已更新
  - [ ] 添加了 `dockerfile` 选择器
  - [ ] 添加了 `base_image` 选择器
  - [ ] 更新了默认值
- [ ] 文档已创建
  - [ ] `DOCKER_BUILD_FIXES.md`
  - [ ] `QUICK_START.md`
  - [ ] `CHANGES_SUMMARY.md`
  - [ ] `CHECKLIST.md`（本文件）

## 🚀 GitHub Actions 构建检查

### 第一次构建（推荐配置）

- [ ] 进入 GitHub Actions
- [ ] 选择 "Build kkFileView loong64 image"
- [ ] 点击 "Run workflow"
- [ ] 配置参数：
  - [ ] `kkfileview_version`: `v4.4.0`
  - [ ] `build_mode`: `source`
  - [ ] `base_image`: `cr.loongnix.cn/library/openjdk:8-buster`
  - [ ] `dockerfile`: `Dockerfile.loong64.openjdk8`
  - [ ] `image_name`: `kkfileview`
- [ ] 点击 "Run workflow" 开始构建

### 构建过程监控

- [ ] 查看构建日志
- [ ] 确认 Java 版本检测成功
- [ ] 确认 QEMU 设置成功
- [ ] 确认 jar 文件准备成功
- [ ] 确认 Docker 构建开始
- [ ] 监控依赖安装步骤
- [ ] 监控 LibreOffice 安装步骤
- [ ] 确认镜像导出成功
- [ ] 确认 artifact 上传成功

### 构建成功标志

- [ ] 构建状态显示绿色 ✅
- [ ] 生成了 tar 文件
- [ ] tar 文件大小合理（500MB - 1.5GB）
- [ ] 可以下载 artifact

## 🧪 测试检查

### 下载和加载镜像

- [ ] 从 GitHub Actions 下载 tar 文件
- [ ] 解压（如果需要）
- [ ] 使用 `docker load` 加载镜像
- [ ] 使用 `docker images` 确认镜像存在

### 基础功能测试

```bash
# 设置镜像名称
IMAGE_NAME="kkfileview:loong64-4.4.0"

# 1. 检查镜像信息
docker inspect $IMAGE_NAME

# 2. 测试 Java
docker run --rm $IMAGE_NAME java -version

# 3. 检查工具
docker run --rm $IMAGE_NAME which wget
docker run --rm $IMAGE_NAME which rpm2cpio
docker run --rm $IMAGE_NAME which cpio

# 4. 检查 LibreOffice
docker run --rm $IMAGE_NAME which soffice
docker run --rm $IMAGE_NAME soffice --version

# 5. 检查 jar 文件
docker run --rm $IMAGE_NAME ls -lh /app/kkFileView.jar

# 6. 检查入口脚本
docker run --rm $IMAGE_NAME cat /usr/local/bin/docker-entrypoint.sh
```

- [ ] Java 版本正确（OpenJDK 8）
- [ ] wget 可用
- [ ] rpm2cpio 可用（或显示警告）
- [ ] cpio 可用（或显示警告）
- [ ] soffice 可用（或显示警告）
- [ ] kkFileView.jar 存在且大小正常
- [ ] docker-entrypoint.sh 存在且可执行

### 运行测试

```bash
# 启动容器
docker run -d \
  -p 8012:8012 \
  --name kkfileview-test \
  $IMAGE_NAME

# 等待启动
sleep 15

# 检查容器状态
docker ps | grep kkfileview-test

# 查看日志
docker logs kkfileview-test

# 测试 HTTP 访问
curl -I http://localhost:8012

# 测试 API（如果有）
curl http://localhost:8012/

# 清理
docker stop kkfileview-test
docker rm kkfileview-test
```

- [ ] 容器成功启动
- [ ] 容器保持运行状态
- [ ] 日志无严重错误
- [ ] HTTP 端口可访问
- [ ] 返回正常响应

### 文档转换测试（如果 LibreOffice 可用）

```bash
# 启动容器
docker run -d \
  -p 8012:8012 \
  -v $(pwd)/test-files:/test-files \
  --name kkfileview-test \
  $IMAGE_NAME

# 测试文档转换（根据 kkFileView API）
# 具体测试方法参考 kkFileView 文档

# 清理
docker stop kkfileview-test
docker rm kkfileview-test
```

- [ ] 可以上传文档
- [ ] 可以预览文档
- [ ] 转换功能正常

## 🔄 备选方案测试

如果第一次构建失败，尝试其他配置：

### 方案 2: Debian Trixie

- [ ] 使用 `base_image`: `ghcr.io/loong64/debian:trixie-slim`
- [ ] 使用 `dockerfile`: `Dockerfile.loong64`
- [ ] 重复上述测试步骤

### 方案 3: 最小化版本

- [ ] 使用 `base_image`: `cr.loongnix.cn/library/openjdk:8-buster`
- [ ] 使用 `dockerfile`: `Dockerfile.loong64.minimal`
- [ ] 重复上述测试步骤

## 📝 问题记录

如果遇到问题，记录以下信息：

### 构建失败

- [ ] 失败的步骤名称
- [ ] 完整错误信息
- [ ] 使用的配置（base_image, dockerfile）
- [ ] 构建日志（完整）

### 运行失败

- [ ] 容器启动命令
- [ ] 容器日志
- [ ] 错误信息
- [ ] 系统环境信息

## ✅ 最终确认

- [ ] 至少一个 Dockerfile 配置构建成功
- [ ] 生成的镜像可以正常运行
- [ ] Java 功能正常
- [ ] kkFileView 服务可访问
- [ ] 文档已完善
- [ ] 代码已提交到 GitHub

## 🎉 部署完成

- [ ] 镜像已上传到镜像仓库（如果需要）
- [ ] 文档已更新
- [ ] 团队成员已通知
- [ ] 使用说明已分享

---

## 📊 构建结果记录

### 构建 1

- **日期：** ___________
- **配置：** 
  - base_image: ___________
  - dockerfile: ___________
- **结果：** ⬜ 成功 / ⬜ 失败
- **备注：** ___________

### 构建 2

- **日期：** ___________
- **配置：** 
  - base_image: ___________
  - dockerfile: ___________
- **结果：** ⬜ 成功 / ⬜ 失败
- **备注：** ___________

### 构建 3

- **日期：** ___________
- **配置：** 
  - base_image: ___________
  - dockerfile: ___________
- **结果：** ⬜ 成功 / ⬜ 失败
- **备注：** ___________

---

**提示：** 打印此清单并在执行过程中勾选，确保不遗漏任何步骤。
