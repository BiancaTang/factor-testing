# factor-testing

人格-量化因子适配测试器（静态单页应用）

## 部署到云服务器

### 1. 推送代码到 GitHub

```bash
git add .
git commit -m "add static tester and deploy script"
git push
```

### 2. 登录服务器并拉取代码

```bash
# 首次部署
git clone https://github.com/BiancaTang/factor-testing.git
cd factor-testing

# 以后更新
cd factor-testing && git pull
```

### 3. 运行部署脚本

```bash
chmod +x deploy.sh
sudo bash deploy.sh
```

### 4. 浏览器访问

```
http://你的公网IP/
```

### 注意事项

- 请在网易云控制台的安全组中放行 **TCP 80** 端口
- 脚本会自动安装 Nginx、复制页面为 `index.html` 并完成配置
- 更新页面后：重新 `git pull`，再执行 `sudo bash deploy.sh`
