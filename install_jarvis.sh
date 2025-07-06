#!/bin/bash
# v2.0.0

# --- Nettoyage écran (clear)
clear

# --- Détection automatique de la prise en charge des couleurs ---
NO_COLOR=0
if [ "${NO_COLOR:-0}" -eq 0 ] && [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "${spinstr}"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

set -e


## ---  VERIFICATION DPKG
    echo -e "${BLUE}🔧 Vérification de l’état du gestionnaire de paquets...${NC}"
    if sudo dpkg --configure -a > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Gestionnaire de paquets OK.${NC}"
    else
        echo -e "${RED}❌ Problème détecté, tentative de correction...${NC}"
        sudo dpkg --configure -a > /dev/null 2>&1 &
        spinner $!
        echo -e "${GREEN}✅ Correction effectuée.${NC}"
    fi

install_jarvis() {

# --- Nettoyage écran (clear)
clear

echo -e "${BLUE}📦 Installation de JARVIS version Dockerisée (Web + vocal)${NC}"

# Étape 1 : Mise à jour du système
echo -e "${BLUE}\n🔄 Mise à jour du système...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null 2>&1 & spinner $!
echo -e "${GREEN}✅ apt-get update terminé.${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1 & spinner $!
echo -e "${GREEN}✅ apt-get upgrade terminé.${NC}"

# Étape 2 : Vérification des dépendances
echo -e "${BLUE}\n🔍 Vérification des paquets nécessaires...${NC}"
REQUIRED_CMDS=(python3 python3-pip docker ffmpeg curl git)
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}❌ $cmd est manquant. Installation...${NC}"
        sudo apt install -y $cmd -qq > /dev/null 2>&1 & spinner $!
        echo -e "${GREEN}✅ $cmd est installé${NC}"
    else
        echo -e "${GREEN}✅ $cmd est installé${NC}"
    fi
done

# Étape 3 : Création de la structure du projet
echo -e "${BLUE}\n📁 Création de la structure du projet...${NC}"
mkdir -p jarvis/{app,webapp}

# server.py
echo -e "${YELLOW}\n📄 Création de server.py...${NC}"
cat > jarvis/app/server.py << 'EOF'
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import whisper, subprocess, uuid, os
from transformers import pipeline

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

@app.get("/")
async def root():
    return {"message": "Jarvis est en ligne"}

whisper_model = whisper.load_model("base")
llm = pipeline("text-generation", model="distilgpt2")

@app.post("/speech")
async def transcribe(file: UploadFile = File(...)):
    raw = f"/tmp/{uuid.uuid4()}.webm"
    wav = raw.replace(".webm", ".wav")
    with open(raw, "wb") as f: f.write(await file.read())

    subprocess.run(["ffmpeg", "-y", "-i", raw, wav],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    text = whisper_model.transcribe(wav)["text"]
    os.remove(raw); os.remove(wav)

    response = llm(text, max_new_tokens=100)[0]["generated_text"]
    return {"text": response}
EOF
echo -e "${GREEN}✅ server.py créé.${NC}"

# requirements.txt
echo -e "${YELLOW}\n📄 Création de requirements.txt...${NC}"
cat > jarvis/app/requirements.txt << EOF
fastapi
uvicorn[standard]
whisper
ffmpeg-python
python-multipart
transformers
torch
EOF
echo -e "${GREEN}✅ requirements.txt créé.${NC}"

# index.html
echo -e "${YELLOW}\n📄 Création de index.html...${NC}"
cat > jarvis/webapp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>JARVIS</title></head>
<body>
  <h1>🎤 Parlez à JARVIS</h1>
  <button id="record">Parler</button>
  <p id="result"></p>
<script>
const btn = document.getElementById('record');
btn.onclick = async () => {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  const mediaRecorder = new MediaRecorder(stream);
  const audioChunks = [];
  mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
  mediaRecorder.onstop = async () => {
    const blob = new Blob(audioChunks, { type: 'audio/webm' });
    const fd = new FormData(); fd.append("file", blob, "audio.webm");
    const res = await fetch("http://" + location.hostname + ":8000/speech", { method: "POST", body: fd });
    const data = await res.json();
    document.getElementById("result").textContent = "JARVIS: " + data.text;
    speechSynthesis.speak(new SpeechSynthesisUtterance(data.text));
  };
  mediaRecorder.start(); setTimeout(() => mediaRecorder.stop(), 5000);
};
</script>
</body>
</html>
EOF
echo -e "${GREEN}✅ index.html créé.${NC}"

# Dockerfile
echo -e "${YELLOW}\n📄 Création de Dockerfile...${NC}"
cat > jarvis/Dockerfile << 'EOF'
FROM python:3.10-slim

RUN apt update && apt install -y ffmpeg git curl && apt clean

WORKDIR /app
COPY app /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
echo -e "${GREEN}✅ Dockerfile créé.${NC}"

# Makefile
echo -e "${YELLOW}\n📄 Création de Makefile...${NC}"
cat > jarvis/Makefile << 'EOF'
run:
	docker build -t jarvis .
	docker run -it --rm -p 8000:8000 --name jarvis jarvis

build:
	docker build -t jarvis .

stop:
	docker stop jarvis || true
	docker rm jarvis || true
EOF
echo -e "${GREEN}✅ Makefile créé.${NC}"

# Étape 4 : Build et lancement
cd jarvis
echo -e "${BLUE}\n🚀 Construction de l'image Docker...${NC}"
docker build -t jarvis . 

echo -e "${BLUE}🔌 Lancement du conteneur...${NC}"
docker run -d --name jarvis -p 8000:8000 jarvis

# Vérification
if docker ps | grep -q jarvis; then
    echo -e "${GREEN}✅ Le conteneur JARVIS tourne correctement.${NC}"
else
    echo -e "${RED}❌ Le conteneur JARVIS ne tourne PAS.${NC}"
fi

if curl -s http://localhost:8000 | grep -q "Jarvis"; then
    echo -e "${GREEN}✅ API JARVIS accessible sur http://localhost:8000${NC}"
else
    echo -e "${RED}❌ API JARVIS inaccessible.${NC}"
    echo -e "${YELLOW}🔄 Vérifie les logs avec :${NC} docker logs jarvis"
fi

# Fin
echo -e "\n${GREEN}🎉 JARVIS est prêt !${NC}"
echo -e "${BLUE}📱 Accède à la WebApp : http://$(hostname -I | awk '{print $1}')/webapp/index.html${NC}"

}
 


check_jarvis() {
    echo -e "${BLUE}🔍 Vérification de l'environnement JARVIS...${NC}"

    echo -e "\n⚙️  Vérification des outils système..."
    for tool in python3 pip docker ffmpeg curl; do
        if command -v $tool >/dev/null 2>&1; then
            echo -e "✅ $tool est installé."
        else
            echo -e "❌ $tool est manquant."
        fi
    done

   
    echo -e "\n🐍 Vérification des bibliothèques Python..."
    for pkg in torch transformers whisper fastapi uvicorn python-multipart; do
        python -c "import $pkg" >/dev/null 2>&1 && echo -e "✅ Package Python '$pkg' installé." || echo -e "❌ Package Python '$pkg' NON installé."
    done

    echo -e "\n📂 Vérification de la structure du projet..."
    for file in server.py Dockerfile Makerfile; do
        [ -f "$file" ] && echo -e "✅ $file présent." || echo -e "❌ $file manquant."
    done

    echo -e "\n🐳 Vérification du conteneur Docker..."
    if docker ps --filter "name=jarvis" --filter "status=running" | grep jarvis >/dev/null; then
        echo -e "✅ Conteneur 'jarvis' trouvé. Statut : running"
    else
        echo -e "❌ Conteneur 'jarvis' non trouvé ou arrêté."
    fi

    echo -e "\n🎙️ Test du chargement du modèle Whisper..."
    python -c "import whisper; whisper.load_model('base')" >/dev/null 2>&1 && echo -e "✅ Modèle Whisper chargé avec succès." || echo -e "❌ Échec du chargement du modèle Whisper."

    echo -e "\n🌐 Test de l'API JARVIS (http://localhost:8000)..."
    if curl --max-time 5 -s http://localhost:8000 | grep -q 'Jarvis est en ligne'; then
        echo -e "✅ API JARVIS répond bien sur le port 8000."
    else
        echo -e "❌ API JARVIS ne répond pas sur http://localhost:8000 (le conteneur est peut-être arrêté ou crashé)."
    fi

    echo -e "\n🧪 Fin des vérifications."
}


# --- Appel direct depuis la ligne de commande ou Make ---
if [[ "$1" == "install" ]]; then
    install_jarvis
    exit 0
elif [[ "$1" == "check" ]]; then
    check_jarvis
    exit 0
fi

# --- Menu ---
while true; do
    echo -e "\n${YELLOW}==== Menu JARVIS ====${NC}"
    echo "1) Installer / Réinstaller JARVIS"
    echo "2) Vérifier l'installation actuelle"
    echo "3) Quitter"
    read -rp "Choisis une option (1-3) : " choice
    case $choice in
        1) install_jarvis ;;
        2) check_jarvis ;;
        3) echo "Bye !" ; exit 0 ;;
        *) echo -e "${RED}Option invalide.${NC}" ;;
    esac
done
