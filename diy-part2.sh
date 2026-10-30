#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改默认IP
sed -i 's/192.168.1.1/10.10.10.1/g' package/base-files/files/bin/config_generate

# 补充汉化       
# cp -f ./feeds/springwrt/files/udpxy.lua ./feeds/luci/applications/luci-app-udpxy/luasrc/model/cbi
cp -f ./feeds/springwrt/files/mwan3.po ./feeds/luci/applications/luci-app-mwan3/po/zh-cn

# 取消bootstrap为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

# 设置 argon-18.06 为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile

# 修改tailscale启动和配置
# sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile

# 加入作者信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='SpringWRT-$(date +%Y%m%d)'/g" package/lean/default-settings/files/zzz-default-settings

# 更改主机名
sed -i "s/hostname='.*'/hostname='SpringWRT'/g" package/base-files/files/bin/config_generate

# 调整接口菜单
# sed -i '/option Interface/d'  package/network/services/dropbear/files/dropbear.config

# Linux 6.15+ 删除了 hrtimer_init()；适配 Quectel MHI 1.3.8 驱动。
# 在 feeds 安装后、编译前修改实际使用的驱动源文件。
mhi_src="package/wwan/driver/quectel_MHI/src/devices/mhi_netdev_quectel.c"
if [ -f "$mhi_src" ]; then
  python3 - "$mhi_src" <<'PY_MHI_FIX'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
source = path.read_text()
pattern = re.compile(
    r'^(?P<indent>[ \t]*)hrtimer_init\(&priv->agg_hrtimer,\s*CLOCK_MONOTONIC,\s*HRTIMER_MODE_REL\);[ \t]*\n'
    r'(?P=indent)priv->agg_hrtimer\.function\s*=\s*rmnet_vnd_tx_agg_timer_cb;[ \t]*$',
    re.MULTILINE,
)

def replace(match):
    indent = match.group('indent')
    return '\n'.join([
        f'{indent}#if LINUX_VERSION_CODE >= KERNEL_VERSION(6, 15, 0)',
        f'{indent}hrtimer_setup(&priv->agg_hrtimer, rmnet_vnd_tx_agg_timer_cb, CLOCK_MONOTONIC, HRTIMER_MODE_REL);',
        f'{indent}#else',
        f'{indent}hrtimer_init(&priv->agg_hrtimer, CLOCK_MONOTONIC, HRTIMER_MODE_REL);',
        f'{indent}priv->agg_hrtimer.function = rmnet_vnd_tx_agg_timer_cb;',
        f'{indent}#endif',
    ])

if 'hrtimer_setup(&priv->agg_hrtimer' in source:
    print('Quectel MHI already uses hrtimer_setup')
    sys.exit(0)

updated, count = pattern.subn(replace, source)
if count == 1:
    path.write_text(updated)
    print('Patched Quectel MHI for Linux 6.15+')
else:
    raise SystemExit('ERROR: Quectel MHI source layout changed; patch not applied')
PY_MHI_FIX
else
  echo "NOTICE: Quectel MHI source not found; skip compatibility patch"
fi
