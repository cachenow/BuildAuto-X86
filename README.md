##### 如编译失败，搜索RAW日志中的
```
Collected errors
```
##### 软件包之间的冲突:
1. luci-app-systools / luci-app-netspeedtest 与 speedtestcli 冲突
2. luci-app-socat 与 socat 冲突
3. dnsmasq-full 与 dnsmasq-dhcpv6 冲突，图形界面配置时，不能同时选择，否则会影响 luci-app-mwan3helper 和 luci-app-openclash 的安装（因为makefile中已声明 dnsmasq-full 依赖，会导致重复安装失败），其中 dnsmasq-full 下包含子模块 dnsmasq_full_dhcpv6 等。

##### 编译最新内核:
想要编译最新的内核，如6.1以上，要禁用config配置的 TESTING_KERNEL 两个选项。

**Note**
- 关闭其中之一即可，因为makefile中已声明依赖关系，无须重复单独安装。主要原因是，两个不同的feed源同时标注了同样的包安装，且其中重复的这个软件包（假设为B）又和另一个软件包（假设为A）存在依赖关系，且这个相互依赖的包在编译过程中已经被安装了，如果再执行一次单独的B安装，就会提示冲突。
- 如果两个依赖关系的包都可以独立使用，则在编译时安装其中一个包时，系统会自动检查并安装其依赖的包。当然，为了避免冲突，最好是遵循软件包之间的依赖关系，不要手动单独安装依赖包。这也是为什么在 OpenWrt 中，通常会将所有依赖关系都写在 makefile 中，方便系统自动检测和安装。
- 如果要使用autocore，并通过ssh-key自动获取pve宿主机温度，需要对libssh等ssh选项进行开启编译。

##### 更新:
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/cachenow/BuildAuto?style=for-the-badge&logo=appveyor&label=最新固件)](https://github.com/cachenow/BuildAuto/releases/latest)


#### 注意：
本项目是**自用**项目，如直接使用可能与你所使用的环境并不相符，会引起不必要的麻烦，请谨慎借鉴。


## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)
