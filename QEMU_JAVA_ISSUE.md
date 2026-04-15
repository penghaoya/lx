# QEMU loong64 Java 运行问题

## 🔴 严重问题

从构建日志中发现：

```
#9 48.72 SR_initialize failed: Invalid argument
#9 48.72 Error: Could not create the Java Virtual Machine.
#9 48.72 Error: A fatal exception has occurred. Program will exit.
```

**这意味着 Java 无法在 QEMU 模拟的 loong64 环境中运行！**

## 问题分析

### 1. QEMU 模拟限制

QEMU 用户模式模拟 loong64 架构时，某些系统调用和 CPU 特性可能无法正确模拟，导致 Java VM 初始化失败。

### 2. 基础镜像仓库损坏

`cr.loongnix.cn/library/openjdk:8-buster` 镜像的 apt 仓库无法安装任何包：

```
E: Can't find a source to download version 'X.X.X' of 'package:loongarch64'
```

所有工具（wget, rpm2cpio, cpio）都无法安装。

### 3. 构建成功但镜像无法使用

虽然 Docker 构建"成功"了，但生成的镜像：
- ❌ Java 无法运行
- ❌ 没有 wget（无法下载 LibreOffice）
- ❌ 没有 rpm2cpio/cpio（无法解压 RPM）
- ❌ 没有 LibreOffice
- ❌ 容器启动会失败（因为 Java 不工作）

## 🔧 可能的解决方案

### 方案 1: 使用真实的 loong64 硬件 ⭐ **最佳方案**

在真实的龙芯硬件上构建，避免 QEMU 模拟问题。

**优点：**
- Java 可以正常运行
- 构建速度快
- 没有模拟限制

**缺点：**
- 需要访问龙芯硬件
- GitHub Actions 不支持

**实施方法：**
1. 获取龙芯服务器访问权限
2. 在服务器上安装 Docker
3. 本地构建镜像
4. 导出 tar 文件

### 方案 2: 使用 loong64 原生 CI/CD

使用支持 loong64 的 CI/CD 平台。

**可能的平台：**
- Loongnix 官方 CI（如果有）
- 自建 GitLab Runner（在龙芯硬件上）
- 其他支持 loong64 的 CI 服务

### 方案 3: 交叉编译 + 原生测试

在 x86_64 上交叉编译 Java 应用，然后在 loong64 上测试。

**步骤：**
1. 在 GitHub Actions (x86_64) 上编译 kkFileView jar
2. 将 jar 传输到龙芯服务器
3. 在龙芯服务器上构建 Docker 镜像
4. 导出镜像

### 方案 4: 使用预构建的 loong64 Java 镜像

寻找已经在真实硬件上构建并测试过的 loong64 Java 镜像。

**可能的来源：**
- Loongnix 官方镜像仓库
- 社区维护的镜像
- 其他已验证的镜像

### 方案 5: 修改 kkFileView 使其不依赖 LibreOffice

如果只需要基本功能，可以：
1. 修改 kkFileView 配置，禁用文档转换
2. 使用更轻量的替代方案
3. 只支持不需要转换的文件格式

## 🚫 不可行的方案

### ❌ 继续使用 QEMU 模拟

**原因：**
- Java VM 无法初始化
- 即使构建成功，容器也无法运行
- 浪费时间和资源

### ❌ 尝试修复 QEMU Java 问题

**原因：**
- 这是 QEMU 和 Java 的底层兼容性问题
- 需要修改 QEMU 或 Java 源码
- 超出项目范围

## 📋 推荐行动方案

### 短期方案（立即可行）

1. **停止使用 GitHub Actions 构建 loong64 镜像**
   - 当前方法无法产生可用的镜像

2. **寻找真实的 loong64 硬件**
   - 联系 Loongnix 社区
   - 寻找云服务提供商
   - 使用本地龙芯服务器

3. **使用方案 3：交叉编译**
   ```yaml
   # GitHub Actions: 只编译 jar
   - name: Build jar
     run: mvn package
   
   - name: Upload jar
     uses: actions/upload-artifact@v4
     with:
       name: kkFileView.jar
       path: server/target/kkFileView-*.jar
   
   # 然后在龙芯服务器上：
   # 1. 下载 jar
   # 2. 构建 Docker 镜像
   # 3. 测试运行
   ```

### 中期方案（需要准备）

1. **设置自建 Runner**
   - 在龙芯硬件上安装 GitHub Actions Runner
   - 配置为 self-hosted runner
   - 标记为 loong64 架构

2. **使用 loong64 CI 服务**
   - 研究 Loongnix 生态系统
   - 寻找支持的 CI/CD 平台

### 长期方案（最佳实践）

1. **建立 loong64 构建环境**
   - 专用的龙芯构建服务器
   - 自动化构建流程
   - 镜像仓库

2. **多架构支持**
   - 同时支持 x86_64, arm64, loong64
   - 统一的构建流程
   - 自动化测试

## 🔍 验证方法

如果你有龙芯硬件访问权限，可以验证：

```bash
# 1. 在龙芯服务器上
docker pull cr.loongnix.cn/library/openjdk:8-buster

# 2. 测试 Java
docker run --rm cr.loongnix.cn/library/openjdk:8-buster java -version

# 3. 如果 Java 工作，继续构建
docker build -f Dockerfile.loong64.flexible -t kkfileview:test .

# 4. 测试运行
docker run --rm kkfileview:test java -version
```

## 📞 需要帮助？

1. **Loongnix 社区**
   - 官网：http://www.loongnix.cn/
   - 询问关于 CI/CD 和构建环境的建议

2. **kkFileView 社区**
   - GitHub: https://github.com/kekingcn/kkFileView
   - 询问是否有其他用户成功构建 loong64 镜像

3. **龙芯开发者社区**
   - 寻找有龙芯硬件访问权限的开发者
   - 合作构建和测试

## 结论

**当前 GitHub Actions + QEMU 的方案无法产生可用的 loong64 镜像。**

必须使用真实的龙芯硬件进行构建和测试。建议：

1. ✅ 使用 GitHub Actions 编译 jar（x86_64）
2. ✅ 将 jar 传输到龙芯服务器
3. ✅ 在龙芯服务器上构建 Docker 镜像
4. ✅ 测试并导出镜像
5. ✅ 上传到镜像仓库或作为 Release 资产

这是目前唯一可行的方案。
