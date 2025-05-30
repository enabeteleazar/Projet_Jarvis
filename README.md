# JARVIS Installer

Ce dépôt contient un script bash permettant d'installer et de configurer automatiquement un assistant vocal basé sur Python, FastAPI, Whisper et Docker. Le projet a été pensé pour être utilisé facilement sur des systèmes Debian/Ubuntu ou sur un Raspberry Pi 3.

---

## 🧠 Fonctionnalités

* Vérification automatique du système (`dpkg`, mises à jour, etc.)
* Création d’un environnement virtuel Python
* Installation silencieuse des dépendances IA (torch, transformers, whisper, etc.)
* Configuration SSH sécurisée (port 2222, désactivation root/password)
* Création automatique de fichiers `Dockerfile` et `docker-compose.yml`
* Lancement de l’assistant en arrière-plan via Docker Compose
* Utilisation d’un `Makefile` pour simplifier les commandes

---

## 📦 Prérequis

* Système Debian, Ubuntu ou Raspberry Pi OS
* Connexion Internet stable (nécessaire pour télécharger les dépendances IA)
* Droits sudo

---

## 🚀 Installation

### Étape 1 : Cloner le dépôt

```bash
git clone https://github.com/enabeteleazar/Projet_Jarvis.git
cd Projet_Jarvis
```

### Étape 2 : Rendre le script exécutable

```bash
chmod +x install_jarvis.sh
```

### Étape 3 : Lancer le script avec Makefile

```bash
make install
```

> 💡 Les étapes sont silencieuses, seules les barres de progression sont visibles. En cas d’erreur, un fichier log temporaire est généré dans `/tmp/`.

---

## ⚙️ Utilisation de l’assistant

Une fois le script exécuté avec succès, l’assistant est accessible à l'adresse suivante :

```
http://localhost:8000
```

### Commandes Makefile disponibles

* `make install` — lance l'installation complète
* `make start` — démarre l'assistant avec Docker Compose
* `make stop` — arrête le conteneur
* `make clean` — supprime les fichiers générés

---

## 🔐 Configuration SSH personnalisée

* Port : `2222`
* Connexion root : désactivée
* Authentification par mot de passe : désactivée

---

## 📁 Arborescence du projet

```
.
├── Dockerfile
├── docker-compose.yml
├── install_jarvis.sh
├── Makefile
├── jarvis-env/ (environnement Python)
└── README.md
```

---

## 📄 Licence

Ce projet est distribué sous licence MIT. Voir le fichier `LICENSE` pour plus d’informations.

---

## 🛠 Auteur

Développé avec ❤️ par NABET Eleazar.

> Pour toute suggestion, ouverture d’issue ou amélioration, n’hésite pas à contribuer via GitHub !
