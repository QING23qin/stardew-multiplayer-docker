#!/bin/bash
export HOME=/config
export DISPLAY=:0

if [ ! -f "/data/Stardew/Stardew Valley/StardewValley" ]; then
    echo "[初始化] /data 为空，正在拷贝默认游戏文件..."
    cp -r /opt/default_data/* /data/
    chown -R 1000:1000 /data
fi

for modPath in /data/Stardew/Stardew\ Valley/Mods/*/
do
  mod=$(basename "$modPath")

  # Normalize mod name ot uppercase and only characters, eg. "Always On Server" => ENABLE_ALWAYSONSERVER_MOD
  var="ENABLE_$(echo "${mod^^}" | tr -cd '[A-Z]')_MOD"

  # Remove the mod if it's not enabled
  if [ "${!var}" != "true" ]; then
    echo "Removing ${modPath} (${var}=${!var})"
    rm -rf "$modPath"
    continue
  fi

  if [ -f "${modPath}/config.json.template" ]; then
    echo "Configuring ${modPath}config.json"

    # Seed the config.json only if one isn't manually mounted in (or is empty)
    if [ "$(cat "${modPath}config.json" 2> /dev/null)" == "" ]; then
      envsubst < "${modPath}config.json.template" > "${modPath}config.json"
    fi
  fi
done

# Run extra steps for certain mods
/opt/configure-remotecontrol-mod.sh

/opt/tail-smapi-log.sh &

# Ready to start!

cd "/data/Stardew/Stardew Valley"
echo "启动 Stardew Valley..."

if [ -f "StardewValley.exe" ]; then
    exec mono StardewValley.exe
elif [ -f "StardewValley" ]; then
    exec ./StardewValley
else
    echo "找不到 Stardew Valley 可执行文件！"
    sleep infinity
fi
