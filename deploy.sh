#!/usr/bin/env bash
# 一键部署「人格-量化因子适配测试器」到 Nginx
# 用法（在服务器上，项目根目录执行）:
#   chmod +x deploy.sh
#   sudo bash deploy.sh

set -euo pipefail

APP_NAME="factor-testing"
WEB_ROOT="/var/www/${APP_NAME}"
HTML_SOURCE="personality-quantitative-tester.html"
NGINX_CONF="/etc/nginx/conf.d/${APP_NAME}.conf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "[deploy] $*"; }
die() { echo "[deploy] 错误: $*" >&2; exit 1; }

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "请使用 root 运行: sudo bash deploy.sh"
fi

if [[ ! -f "${SCRIPT_DIR}/${HTML_SOURCE}" ]]; then
  die "找不到 ${HTML_SOURCE}，请在项目根目录执行此脚本"
fi

detect_pkg_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  else
    die "未检测到 apt / yum / dnf，请手动安装 Nginx 后重试"
  fi
}

install_nginx() {
  local pkg
  pkg="$(detect_pkg_manager)"

  if command -v nginx >/dev/null 2>&1; then
    log "Nginx 已安装: $(nginx -v 2>&1)"
    return
  fi

  log "正在安装 Nginx..."
  case "${pkg}" in
    apt)
      apt-get update -y
      apt-get install -y nginx
      ;;
    yum)
      yum install -y epel-release || true
      yum install -y nginx
      ;;
    dnf)
      dnf install -y nginx
      ;;
  esac
}

deploy_files() {
  log "部署静态文件到 ${WEB_ROOT} ..."
  mkdir -p "${WEB_ROOT}"
  cp "${SCRIPT_DIR}/${HTML_SOURCE}" "${WEB_ROOT}/index.html"
  if [[ -d "${SCRIPT_DIR}/pic" ]]; then
    mkdir -p "${WEB_ROOT}/pic"
    cp -R "${SCRIPT_DIR}/pic/." "${WEB_ROOT}/pic/"
    log "已复制 pic 图片目录"
  fi
  chown -R nginx:nginx "${WEB_ROOT}" 2>/dev/null || chown -R www-data:www-data "${WEB_ROOT}" 2>/dev/null || true
  chmod 644 "${WEB_ROOT}/index.html"
  find "${WEB_ROOT}/pic" -type f -exec chmod 644 {} \; 2>/dev/null || true
}

write_nginx_config() {
  log "写入 Nginx 配置 ${NGINX_CONF} ..."
  cat > "${NGINX_CONF}" <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root ${WEB_ROOT};
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \\.(html|css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)\$ {
        expires 1h;
        add_header Cache-Control "public";
    }
}
EOF
}

start_nginx() {
  log "检查 Nginx 配置..."
  nginx -t

  log "启动并重载 Nginx..."
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable nginx
    systemctl restart nginx
  else
    nginx -s reload 2>/dev/null || nginx
  fi
}

print_result() {
  local ip=""
  if command -v curl >/dev/null 2>&1; then
    ip="$(curl -fsS --max-time 3 http://100.96.0.96/metadata/v1/public-ipv4 2>/dev/null \
      || curl -fsS --max-time 3 ifconfig.me 2>/dev/null \
      || curl -fsS --max-time 3 ip.sb 2>/dev/null \
      || true)"
  fi

  echo ""
  echo "=========================================="
  echo " 部署成功"
  echo "=========================================="
  echo "网站目录: ${WEB_ROOT}"
  echo "配置文件: ${NGINX_CONF}"
  if [[ -n "${ip}" ]]; then
    echo "访问地址: http://${ip}/"
  else
    echo "访问地址: http://<你的公网IP>/"
  fi
  echo ""
  echo "若无法访问，请到网易云控制台检查安全组是否放行 TCP 80 端口。"
  echo "=========================================="
}

main() {
  install_nginx
  deploy_files
  write_nginx_config
  start_nginx
  print_result
}

main "$@"
