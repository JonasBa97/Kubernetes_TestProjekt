#!/bin/bash

# Azure-Login über Identity und ACR-Login
az login --identity >> /dev/null
az acr login --name skyerededucation >> /dev/null

# Hole alle Tags des Images
latest_tag=$(az acr repository show-tags --name skyerededucation --repository lugx-gaming --output tsv | grep -v latest | sort -V | tail -n 1)
echo "$latest_tag"

if [ -z "$latest_tag" ]; then
  echo "Keine vorhandene Version gefunden. Starte mit 0.1.0"
  export new_version="0.1.0"
else
  # Extrahiere Haupt- und Nebenversion
  major=$(echo "$latest_tag" | cut -d. -f1)
  minor=$(echo "$latest_tag" | cut -d. -f2)
  revision=$(echo "$latest_tag" | cut -d. -f3)

  # Erhöhe die Nebenversion um 1
  new_minor=$((minor + 1))
  export new_version="$major.$new_minor.$revision"
fi
