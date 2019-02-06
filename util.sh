#!/bin/bash
config_property() {
  local PROPERTY="$1"
  local CONFIG="$2"
  while IFS= read LINE; do
    KEY=`echo "$LINE" | awk -F= ' { print $1 } '`
    if [ "$KEY" == "$PROPERTY" ]; then
      PROPERTY=`echo "$LINE" | awk -F= ' { print $2 } '`
      break
    fi
  done < "$CONFIG"
  if [ "$PROPERTY" != "$1" ]; then
    echo "$PROPERTY"
  else
    echo ""
  fi
}

trim() {
    [[ "$1" =~ [^[:space:]](.*[^[:space:]])? ]]
    printf "%s" "$BASH_REMATCH"
}

deploy_plugins() {
cat <<EOF |
`find "$LIBRARIES" | sed -En 's/(\/.*)(libQt[0-9][a-zA-Z]*)(\.so.[0-9])/\2/ p'`
EOF
while IFS= read lib; do
  if [ "$lib" == "libQt5Gui" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" platforms/libqxcb.so platforminputcontexts xcbglintegrations imageformats
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5OpenGL" -o "$lib" == "libQt5XcbQpa" -o "$lib" == "libxcb-glx" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" xcbglintegrations
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5Svg" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" iconengines/libqsvgicon.so imageformats/libqsvg.so
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5PrintSupport" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" printsupport/libcupsprintersupport.so
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5Network" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" bearer
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5Sql" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" sqldrivers
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5Positioning" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" position
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5Multimedia" ]; then
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" mediaservice audio
    if [ $? -eq 1 ]; then
      return 1
    fi
  elif [ "$lib" == "libQt5WebEngineCore" ]; then
    mkdir -p "$PLUGINS../libexec"
    mkdir -p "$PLUGINS../resources"
    mkdir -p "$PLUGINS../translations"
    ./deploy-plugins.sh "$PLUGINS" "$QT_SOURCE_PLUGINS" ../libexec ../resources ../translations
    if [ $? -eq 1 ]; then
      return 1
    fi
  fi
done
}
