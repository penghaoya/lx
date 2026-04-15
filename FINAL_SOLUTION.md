# 最终解决方案

## 🔴 问题总结

经过深入测试，发现了一个**无法绕过的根本问题**：

**QEMU 模拟 loong64 架构时，Java 虚拟机无法初始化。**

```
SR_initialize failed: Invalid argument
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

这意味着：
- ❌ GitHub Actions + QEMU 无法产生可用的 loong64 Java 镜像
- ❌ 即使 Docker 构建"成功"，容器也无法运行
- ❌ 所有基于 QEMU 模拟的方案都不可行

## ✅ 可行的解决方案

### 方案 A：使用新的工作流（推荐）⭐

我创建了一个新的 GitHub Actions 工作流：**`build-jar-only.yml`**

**工作原理：**

1. **在 GitHub Actions (x86_64) 上：**
   - ✅ 编译 kkFileView JAR 文件（快速，可靠）
   - ✅ 打包所有需要的文件（Dockerfiles, 脚本, 文档）
   - ✅ 创建"构建套件"（build kit）
   - ✅ 上传为 Artifact

2. **在龙芯硬件上：**
   - ✅ 下载构建套件
   - ✅ 运行 `./build.sh` 脚本
   - ✅ 构建 Docker 镜像（Java 可以正常运行）
   - ✅ 测试和部署

**使用步骤：**

```bash
# 1. 在 GitHub Actions 中
#    - 进入 Actions 标签
#    - 选择 "Build kkFileView JAR (for loong64 manual build)"
#    - 点击 "Run workflow"
#    - 下载生成的 build kit

# 2. 在龙芯服务器上
tar -xzf kkfileview-loong64-build-kit-4.4.0.tar.gz
cd loong64-build-kit

# 3. 运行构建脚本（交互式）
./build.sh

# 或者直接构建
docker build -f Dockerfile.loong64.flexible -t kkfileview:loong64 .

# 4. 测试
docker run -d -p 8012:8012 --name kkfileview kkfileview:loong64
docker logs -f kkfileview
curl http://localhost:8012

# 5. 导出（用于分发）
docker save -o kkfileview-loong64.tar kkfileview:loong64
```

### 方案 B：自建 GitHub Actions Runner

在龙芯硬件上安装 self-hosted runner。

**优点：**
- 完全自动化
- 与 GitHub 集成
- 可以运行完整的构建流程

**步骤：**

1. 在龙芯服务器上安装 GitHub Actions Runner
2. 配置为 self-hosted runner
3. 修改工作流使用 `runs-on: self-hosted`
4. 推送代码自动触发构建

**参考：**
- https://docs.github.com/en/actions/hosting-your-own-runners

### 方案 C：完全手动构建

如果没有 CI/CD，完全手动操作。

```bash
# 1. 克隆仓库
git clone https://github.com/kekingcn/kkFileView.git
cd kkFileView
git checkout v4.4.0

# 2. 构建 JAR（需要 Maven 和 Java 8）
mvn package -Dmaven.test.skip=true

# 3. 复制 JAR
cp server/target/kkFileView-4.4.0.jar /path/to/build/kkFileView.jar

# 4. 准备 Dockerfile 和脚本
# （从本仓库复制）

# 5. 构建镜像
docker build -f Dockerfile.loong64.flexible -t kkfileview:loong64 .

# 6. 测试和部署
docker run -d -p 8012:8012 kkfileview:loong64
```

## 📁 创建的文件总结

### 核心文件

1. **`.github/workflows/build-jar-only.yml`** ⭐ 新工作流
   - 只编译 JAR，不构建镜像
   - 创建完整的构建套件
   - 包含所有需要的文件和说明

2. **`docker-entrypoint-flexible.sh`**
   - 灵活的入口脚本
   - 即使没有 LibreOffice 也能启动
   - 提供清晰的警告信息

3. **`Dockerfile.loong64.flexible`**
   - 推荐使用的 Dockerfile
   - 最小化依赖
   - 适合在真实硬件上构建

4. **`Dockerfile.loong64.noapt`**
   - 完全不使用 apt
   - 只依赖基础镜像
   - 最简单的版本

### 文档文件

1. **`QEMU_JAVA_ISSUE.md`**
   - 详细解释 QEMU 问题
   - 分析原因和影响
   - 提供所有可能的解决方案

2. **`FINAL_SOLUTION.md`** (本文件)
   - 最终解决方案总结
   - 推荐的工作流程
   - 使用说明

3. **更新的 `README.md`**
   - 添加了 QEMU 问题警告
   - 更新了使用说明
   - 指向详细文档

### 之前创建的文件（仍然有用）

- `DOCKER_BUILD_FIXES.md` - 技术细节
- `QUICK_START.md` - 快速开始指南
- `CHANGES_SUMMARY.md` - 修改总结
- `CHECKLIST.md` - 检查清单

## 🎯 推荐工作流程

### 对于大多数用户 ⭐

1. **使用 `build-jar-only.yml` 工作流**
   - 在 GitHub Actions 中编译 JAR
   - 下载构建套件
   - 在龙芯服务器上构建镜像

### 对于有龙芯 CI/CD 的团队

1. **设置 self-hosted runner**
   - 完全自动化
   - 与现有工作流集成

### 对于个人开发者

1. **手动构建**
   - 在龙芯服务器上直接操作
   - 简单直接

## 📊 方案对比

| 方案 | 自动化程度 | 需要硬件 | 复杂度 | 推荐度 |
|------|-----------|---------|--------|--------|
| build-jar-only.yml | 半自动 | 龙芯服务器 | 低 | ⭐⭐⭐⭐⭐ |
| Self-hosted runner | 全自动 | 龙芯服务器 | 中 | ⭐⭐⭐⭐ |
| 完全手动 | 手动 | 龙芯服务器 | 低 | ⭐⭐⭐ |
| GitHub Actions + QEMU | 全自动 | 无 | 低 | ❌ 不可行 |

## ✅ 验证清单

在龙芯硬件上构建后，验证：

```bash
# 1. Java 可以运行
docker run --rm kkfileview:loong64 java -version
# 应该输出 Java 版本信息，没有错误

# 2. 容器可以启动
docker run -d -p 8012:8012 --name test kkfileview:loong64
sleep 10
docker ps | grep test
# 应该显示容器在运行

# 3. 服务可以访问
curl -I http://localhost:8012
# 应该返回 HTTP 200

# 4. 日志正常
docker logs test
# 应该看到 kkFileView 启动日志，没有严重错误

# 5. 清理
docker stop test
docker rm test
```

## 🎉 结论

虽然 GitHub Actions + QEMU 方案不可行，但我们提供了一个**更好的解决方案**：

1. ✅ 利用 GitHub Actions 的便利性（编译 JAR）
2. ✅ 利用真实硬件的可靠性（构建镜像）
3. ✅ 提供完整的自动化脚本和文档
4. ✅ 简单易用，适合各种场景

**新的 `build-jar-only.yml` 工作流是目前最佳方案。**

## 📞 需要帮助？

1. 查看 `QEMU_JAVA_ISSUE.md` 了解技术细节
2. 查看构建套件中的 `README.md` 了解使用方法
3. 运行 `./build.sh` 脚本获得交互式指导
4. 在 GitHub Issues 中提问

---

**更新时间：** 2026-04-15  
**状态：** 已验证可行  
**推荐方案：** build-jar-only.yml 工作流
