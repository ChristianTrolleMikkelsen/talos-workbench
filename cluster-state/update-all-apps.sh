#!/bin/bash
appDir="apps-templates"

echo "Updating helm repos"
helm repo update > /dev/null

echo "Generating templates for apps"
mkdir -p $appDir

for folder in "."/*; do
  if [ -d "$folder" ]; then
    folder_name=$(basename "$folder")

    if [ "$folder_name" != "$appDir" ]; then
        echo "Updating environment: $folder"
        mkdir -p "$folder/apps"
        cp -rf "$appDir"/* "$folder/apps"
    fi   
  fi
done

rm -r "$appDir"