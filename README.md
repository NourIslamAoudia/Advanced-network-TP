# Containerlab Demo Lab - Quick Collaboration

## 1️⃣ Récupérer le projet

Pour récupérer le lab sur ton ordinateur :

```bash
git clone [git@github.com:NourIslamAoudia/NomDuDepot.git](https://github.com/NourIslamAoudia/Advanced-network-TP)
cd Advanced-network-TP
```

## 2️⃣ Déployer le lab Containerlab

Si le lab n'est pas encore lancé :

```bash
containerlab deploy --topo lab.clab.yml
```

Vérifie que les conteneurs sont créés :

```bash
docker ps
```

## 3️⃣ Utiliser le lab

Pour entrer dans un node :

```bash
docker exec -it clab-demo-lab-R1 /bin/sh
docker exec -it clab-demo-lab-R2 /bin/sh
```

Pour sortir d'un node :

```bash
exit
```

Pour détruire le lab :

```bash
containerlab destroy --topo lab.clab.yml
```

## 4️⃣ Travailler et partager tes changements

### a) Récupérer les dernières modifications de l'équipe :

```bash
git pull origin main
```

### b) Modifier le fichier de configuration :

```bash
nano lab.clab.yml
```

### c) Tester localement :

```bash
containerlab deploy --topo lab.clab.yml
```

### d) Pousser SEULEMENT le fichier de config :

```bash
git add lab.clab.yml
git commit -m "Description de ce que tu as changé"
git push origin main
```

---

## ✅ À PUSH

Push **uniquement** le fichier de configuration du lab :

```bash
lab.clab.yml          # Configuration principale du lab
```

⚠️ **Important** : Ne push **PAS** le dossier `clab-demo-lab/` car il est généré automatiquement par Containerlab.

---

⚡ **Astuce** : toujours `pull` avant de travailler et push après tes modifications pour que tout le monde reste à jour.
