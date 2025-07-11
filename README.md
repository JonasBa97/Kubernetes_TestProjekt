# Testprojekt zu Docker und Kubernetes (inkl. Jenkins-Pipeline)
- .gitignore --> Config-Files sollen nicht in Github gepusht werden
- https://github.com/JonasBa97/Kubernetes_TestProjekt.git

## 1. Dockerfile erstellen und Image bauen
https://hub.docker.com/_/httpd
https://docs.docker.com/reference/cli/docker/image/tag/

im Arbeitsverzeichnis folgende Schritte ausführen:
- `docker build -t skyerededucation.azurecr.io/lugx-gaming:0.1 -t skyerededucation.azurecr.io/lugx-gaming:latest .` --> Docker-Image bauen, zwei tags werden hinzugefügt: 0.1 (/Versionsnummer) und latest
- info: `docker image tag lugx-gaming:latest lugx-gaming:0.2` --> Tag hinzufügen, z.B. für Versionsnnummer
- `docker run -d -p 8080:80 lugx-gaming` --> Container starten
- `docker-compose up -d` --> container über docker-compose starten
- `docker-compose down` --> container über docker-compose stoppen

## 2. Image auf Azure Container Registry pushen

- `az login` --> bei Azure anmelden
- `az acr login --name skyerededucation` --> bei ACR anmelden
- info: `docker tag lugx-gaming:latest skyerededucation.azurecr.io/lugx-gaming:latest` --> Image taggen für ACR, nur nötig wenn vorher nicht getaggt
- `docker push -a skyerededucation.azurecr.io/lugx-gaming` --> Image auf ACR pushen
- `az acr repository list -n skyerededucation` --> Images auf ACR anzeigen
- `az acr repository show-tags` --name skyerededucation --repository lugx-gaming --> tags anzeigen

## 3. Konfigurationsverwaltung für Kubernetes
Config-Files in custom-configs kopieren
- `cp ~/OneDrive/Desktop/Unterricht/Aufgaben/Kubernetes/TestProjekt/kurs2-dev.conf ~/.kube/custom-configs/`
- `cp ~/OneDrive/Desktop/Unterricht/Aufgaben/Kubernetes/TestProjekt/kurs2-prod.conf ~/.kube/custom-configs/`

Config mergen --> jeweils alle 3 Schritte einmal mit dev und prod durchlaufen
- `export KUBECONFIG=~/.kube/config:~/.kube/custom-configs/kurs2-dev.conf` bzw. `.../kurs-prod.conf` --> exportiert die config
- `kubectl config view --flatten > ~/.kube/merged.yaml` --> flatten config to merged
- `mv ~/.kube/merged.yaml ~/.kube/config` --> merged in config umbenenen/überschreiben

## 4. deploy.yaml und service.yaml für dev und prod erstellen
- für prod und dev jeweils eine deploy.yaml und service.yaml erstellen
- für jeweilige Namespaces anpassen und eigene Ports zuweisen
- app: lugx-gaming-dev --> Name für selector anpassen (dev/prod)
- targetPorts zugehörig benennen und Port vergeben (30010-dev, 30011-prod)

## 5. Jenkins-Pipline bauen
- neue Jenkins-Pipline anlegen --> Kubernetes - TestProjekt
- `cp ~/.kube/config ./kubeconfig-jenkins` --> kubeconfig exportieren, um sie dann als SecretFile für Jenkins zu verwenden
- kubeconfig-jenkins der .gitignore hinzufügern, um den Upload in ds Repo zu verhindern
- Jenkinsfile anlegen und bearbeiten
- GitHub-Hook-Trigger einrichten, damit die Pipeline automatisch durchlaufen wird, wenn in das Repo gepusht wird

Jenkinsfile beinhaltet:
- ACR-NAme, IMAGE-Name und IMAGE-Tag
- Kubeconfig --> wird als Secretfile in Jenkins geladen
- URL für Dev und Prod
- `stage` Checkout
- `stage` Docker Build & Push to ACR --> beinhaltet automatisiert Versionierung des Images auf der ACR, Shell-Skript liest neuesten Versions-Tag aus und erhöht den Wert der Minor-Version um 1
- `stage` Deployment to kurs2-dev --> nutz Credentials aus Jenkins-Secretfile, startet das Deployment neu, wenn bereits vorhanden
- Wenn Deployment nicht vorhanden, wird deploy-dev.yaml und service-dev.yaml angewendet
- `stage` Anschließend Test auf Erreichbarkeit mit `curl` --> schlägt Anfrage fehl, wird dies bis zu 3x versucht im Abstand von 10s
- `stage` Deployment to kurs2-prod und `stage` Test on kurs2-prod werden nach erfolgreichem Test auf Dev ausgeführt und sind identisch zum Vorgehen bei Dev
- `post` always clean workspace

## 6. Kubernetes-Deployment
bei erfolgreichem Durchlauf sind Dev und Prod unter den angegebenen Ports der IP erreichbar
Dev: IP:30010
Prod: IP:30011
