# KOS-lite
Linux desktop environment for Android via termux proot. 
you need to setup termux before if you hadn't already.
prerequisites:

termux [github](https://github.com/termux/termux-app) [f-droid](https://f-droid.org/en/packages/com.termux/)

termux-x11 [github-repo](https://github.com/termux/termux-x11) [release](https://github.com/termux/termux-x11/releases/tag/nightly)

termux-api [github](https://github.com/termux/termux-api) [f-droid](https://f-droid.org/en/packages/com.termux.api/)
#firstime on termux?
install termux
run these commands:
```
termux-change-repo
pkg install x11-repo
pkg update && pkg upgrade
```
then run this to install KOS-lite

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kainatquaderee/KOS-lite/refs/heads/main/Install_kos-lite.sh)"
```

or if you want to install the testing one:
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/kainatquaderee/KOS-lite/refs/heads/main/testing.sh)"
```
then run with this:
```
start-koslite
```
