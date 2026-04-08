# LAB 5.3 — Sécurisation de base et accès SSH

| Info | Valeur |
|------|--------|
| **Module** | 5 — Security Fundamentals / 4 — IP Services |
| **Topics couverts** | 5.3 — Configure device access control using local passwords ; 4.8 — Configure and verify DHCP/DNS/SSH |
| **Difficulté** | Débutant |
| **Durée estimée** | 30 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                    ┌────────────┐
                    │  PC-ADMIN  │
                    │ .100       │
                    └─────┬──────┘
                          │
                   ┌──────┴──────┐
                   │    SW1      │
                   │   .2        │
                   └──────┬──────┘
                          │
                   ┌──────┴──────┐
                   │     R1      │
                   │    .1       │
                   └─────────────┘

                  192.168.1.0/24
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle |
|----------|-----------|------------|--------|------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — |
| SW1 | VLAN 1 | 192.168.1.2 | 255.255.255.0 | 192.168.1.1 |
| PC-ADMIN | NIC | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 |

---

## Objectifs

1. Sécuriser l'accès console et le mode privilégié avec des mots de passe
2. Configurer un utilisateur local et le protocole SSH version 2
3. Restreindre l'accès distant (VTY) au protocole SSH uniquement
4. Tester la connexion SSH depuis le PC d'administration
5. Appliquer la même sécurisation sur le switch SW1
6. Vérifier l'ensemble avec les commandes `show` appropriées

---

## Prérequis

- Savoir naviguer entre les modes user, privilégié et configuration globale
- Connaître la différence entre un accès console (câble physique) et un accès distant (Telnet/SSH)
- Comprendre les bases du chiffrement (pourquoi un mot de passe en clair est un problème)

---

## Configuration de départ

Copiez-collez ces configurations **avant de commencer le lab**.

### R1 — Configuration initiale

```
enable
configure terminal
hostname R1
no ip domain-lookup

interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
exit

end
write memory
```

### SW1 — Configuration initiale

```
enable
configure terminal
hostname SW1
no ip domain-lookup

interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1

end
write memory
```

### PC-ADMIN

Configurez manuellement via l'interface graphique :
- IP : 192.168.1.100
- Masque : 255.255.255.0
- Passerelle : 192.168.1.1

### Vérification préalable

Depuis **PC-ADMIN** :

```
ping 192.168.1.1
ping 192.168.1.2
```

Les deux pings doivent réussir avant de continuer.

---

## Partie 1 : Sécurisation de base — Mots de passe et bannière

Un routeur ou switch Cisco sorti d'usine n'a **aucun** mot de passe. N'importe qui avec un accès physique (console) ou réseau (Telnet) peut entrer en mode privilégié et modifier la configuration. C'est la première chose à corriger.

### Étape 1.1 — Configurer le mot de passe enable secret

Sur **R1** :

```
configure terminal
enable secret Cisco@Enable1
```

> **Pourquoi `enable secret` et pas `enable password` ?**
>
> C'est une question classique de l'examen CCNA. La différence est fondamentale :
> - `enable password` stocke le mot de passe **en clair** (ou avec un chiffrement de type 7, réversible en quelques secondes avec des outils gratuits)
> - `enable secret` stocke le mot de passe avec un **hash MD5** (type 5), irréversible. Même si quelqu'un lit le fichier de configuration, il ne peut pas retrouver le mot de passe original.
>
> Si les deux sont configurés simultanément, `enable secret` a la priorité. La bonne pratique est de n'utiliser **que** `enable secret`.

### Étape 1.2 — Sécuriser l'accès console

```
line console 0
 password Cisco@Console1
 login
 logging synchronous
 exec-timeout 5 0
exit
```

Décortiquons :
- `password Cisco@Console1` : définit le mot de passe pour la ligne console.
- `login` : active l'authentification par mot de passe sur cette ligne. **Sans `login`, le mot de passe est défini mais jamais demandé.** C'est un piège classique.
- `logging synchronous` : empêche les messages syslog d'interrompre la saisie de commandes. Confort d'utilisation.
- `exec-timeout 5 0` : déconnexion automatique après 5 minutes d'inactivité. Évite qu'une session oubliée reste ouverte indéfiniment.

### Étape 1.3 — Activer le chiffrement des mots de passe

```
service password-encryption
```

> **Ce que fait cette commande :** elle applique un chiffrement de type 7 à tous les mots de passe en clair dans la configuration (comme le mot de passe console). Attention : le chiffrement type 7 est **faible** (réversible facilement). C'est une protection minimale pour éviter qu'un coup d'oeil sur la config ne révèle les mots de passe, mais ce n'est pas un vrai chiffrement robuste.
>
> **Ce qu'elle ne fait pas :** elle n'affecte pas `enable secret`, qui utilise déjà un hash MD5 bien plus solide.

Vérifiez l'effet :

```
do show running-config | include password
```

**Output attendu :**

```
service password-encryption
enable secret 5 $1$mERr$hx5rVt7rPNoS4wqbXKX7m0
password 7 045802150C2E1D1C5A
```

Le mot de passe console est maintenant affiché en type 7 (chiffré), et le enable secret en type 5 (hashé MD5).

### Étape 1.4 — Configurer la bannière MOTD

```
banner motd #
============================================
  ATTENTION : Acces reserve au personnel
  autorise uniquement. Toute tentative
  d'acces non autorise sera poursuivie.
============================================
#
```

> **Pourquoi une bannière ?** Au-delà de l'aspect dissuasif, une bannière légale est juridiquement importante. Dans de nombreuses juridictions, pour pouvoir poursuivre un intrus, il faut prouver qu'il était prévenu que l'accès n'était pas autorisé. La bannière sert de preuve. L'examen CCNA teste la commande `banner motd` et son délimiteur (ici le `#`).

### Étape 1.5 — Vérifier la sécurisation de base

Sortez complètement de la session et reconnectez-vous :

```
end
exit
```

**Résultat attendu :** à la reconnexion, la bannière s'affiche et un mot de passe est demandé pour la console. Entrez `Cisco@Console1`. Puis tapez `enable` : un mot de passe est demandé pour le mode privilégié. Entrez `Cisco@Enable1`.

---

## Partie 2 : Création d'un utilisateur local et configuration SSH

Telnet envoie tout en **clair**, y compris les mots de passe. N'importe qui capable de capturer le trafic réseau (avec Wireshark par exemple) peut lire les identifiants. SSH chiffre toute la communication. C'est obligatoire dans un réseau professionnel.

### Étape 2.1 — Créer un utilisateur local

Sur **R1** :

```
configure terminal
username admin privilege 15 secret Cisco@CCNA!
```

Décortiquons :
- `username admin` : crée un utilisateur nommé "admin".
- `privilege 15` : lui donne le niveau de privilège maximum (accès direct au mode privilégié sans taper `enable`). Le niveau 15 est l'équivalent de "root" ou "administrateur".
- `secret` : le mot de passe sera stocké avec un hash MD5 (comme `enable secret`). On aurait pu écrire `password` au lieu de `secret`, mais le mot de passe serait en clair.

### Étape 2.2 — Configurer le nom de domaine

SSH a besoin d'un nom de domaine pour générer la paire de clés RSA :

```
ip domain-name lab.local
```

> **Pourquoi un nom de domaine ?** La clé RSA est identifiée par un nom au format `hostname.domain`. Ici, la clé sera nommée `R1.lab.local`. Sans nom de domaine, la commande `crypto key generate rsa` échoue.

### Étape 2.3 — Générer la paire de clés RSA

```
crypto key generate rsa general-keys modulus 2048
```

**Output attendu :**

```
The name for the keys will be: R1.lab.local
% The key modulus size is 2048 bits
% Generating 2048 bit RSA keys, keys will be non-exportable...[OK]
```

> **Point exam :** SSH version 2 requiert une clé RSA d'au moins **768 bits**. On utilise 2048 bits car c'est le standard actuel de sécurité. Une clé de 1024 bits est considérée comme faible depuis plusieurs années.

### Étape 2.4 — Activer SSH version 2

```
ip ssh version 2
```

> **SSH v1 vs v2 :** SSH version 1 a des vulnérabilités connues (attaques man-in-the-middle). SSH version 2 est plus sécurisé et supporte des algorithmes de chiffrement plus robustes. Il faut toujours forcer la version 2.

### Étape 2.5 — Configurer les paramètres SSH optionnels

```
ip ssh time-out 60
ip ssh authentication-retries 3
```

- `time-out 60` : le serveur SSH coupe la connexion si l'authentification n'est pas terminée en 60 secondes.
- `authentication-retries 3` : l'utilisateur a 3 tentatives pour entrer le bon mot de passe avant d'être déconnecté.

### Étape 2.6 — Vérifier la configuration SSH

```
do show ip ssh
```

**Output attendu :**

```
R1#show ip ssh
SSH Enabled - version 2.0
Authentication timeout: 60 secs; Authentication retries: 3
```

---

## Partie 3 : Restriction des VTY à SSH uniquement

Les lignes VTY (Virtual Terminal Lines) sont les "portes d'entrée" pour l'accès distant. Par défaut, elles acceptent Telnet et parfois SSH. On va les restreindre à SSH uniquement.

### Étape 3.1 — Configurer les lignes VTY

Sur **R1** :

```
configure terminal

line vty 0 4
 transport input ssh
 login local
 exec-timeout 10 0
exit
```

Décortiquons :
- `line vty 0 4` : configure les 5 lignes VTY (0 à 4), ce qui autorise jusqu'à 5 sessions SSH simultanées.
- `transport input ssh` : n'accepte **que** le protocole SSH. Telnet est refusé. C'est la commande clé de ce lab.
- `login local` : utilise la base d'utilisateurs locale (celle qu'on a créée avec `username admin`) pour l'authentification. Sans `login local`, les VTY utiliseraient le simple mot de passe de ligne (moins sécurisé, pas de traçabilité utilisateur).
- `exec-timeout 10 0` : déconnexion après 10 minutes d'inactivité.

> **`login` vs `login local` :**
> - `login` : demande le mot de passe de la ligne (`password` configuré sur la VTY). Pas de notion d'utilisateur.
> - `login local` : demande un nom d'utilisateur et un mot de passe, vérifiés dans la base locale (`username`). Permet de savoir **qui** s'est connecté.

### Étape 3.2 — Configurer la protection contre le brute force (optionnel)

```
login block-for 120 attempts 3 within 60
```

Cette commande bloque les tentatives de connexion pendant **120 secondes** si **3 échecs** sont détectés en **60 secondes**. C'est une protection simple mais efficace contre les attaques par force brute.

### Étape 3.3 — Vérifier que Telnet est bien bloqué

Depuis **PC-ADMIN**, essayez une connexion Telnet :

```
telnet 192.168.1.1
```

**Résultat attendu :** la connexion est **refusée**. Le message sera similaire à :

```
Trying 192.168.1.1 ...
% Connection refused by remote host
```

C'est le comportement attendu : `transport input ssh` refuse tout ce qui n'est pas SSH.

### Étape 3.4 — Sauvegarder la configuration

```
end
write memory
```

---

## Partie 4 : Test de connexion SSH depuis PC-ADMIN

### Étape 4.1 — Se connecter en SSH

Depuis **PC-ADMIN**, ouvrez le Command Prompt (Desktop > Command Prompt) et tapez :

```
ssh -l admin 192.168.1.1
```

> **Le flag `-l`** spécifie le nom d'utilisateur (login). La syntaxe est `ssh -l <username> <adresse_ip>`.

Le système vous demande le mot de passe. Entrez `Cisco@CCNA!`.

**Output attendu :**

```
C:\>ssh -l admin 192.168.1.1

Password:

============================================
  ATTENTION : Acces reserve au personnel
  autorise uniquement. Toute tentative
  d'acces non autorise sera poursuivie.
============================================

R1#
```

Vous êtes directement en mode privilégié (`R1#`) car l'utilisateur `admin` a le privilege level 15.

### Étape 4.2 — Vérifier la session SSH active

Sur **R1** (via la session SSH), vérifiez qui est connecté :

```
show users
```

**Output attendu :**

```
R1#show users
    Line       User       Host(s)              Idle       Location
*  2 vty 0     admin      idle                 00:00:00   192.168.1.100

  Interface    User               Mode         Idle     Peer Address
```

La colonne `Location` montre l'adresse IP du client SSH (192.168.1.100 = PC-ADMIN). L'astérisque `*` indique votre session active.

### Étape 4.3 — Vérifier les sessions SSH

```
show ssh
```

**Output attendu :**

```
R1#show ssh
Connection Version Mode Encryption  Hmac         State                 Username
0          2.0     IN   aes256-cbc  hmac-sha1    Session started       admin
0          2.0     OUT  aes256-cbc  hmac-sha1    Session started       admin
```

On voit bien SSH version 2.0 avec un chiffrement AES-256. La colonne `Username` confirme que c'est l'utilisateur `admin`.

### Étape 4.4 — Vérifier les lignes VTY

```
show line vty 0 4
```

Pour voir la configuration des VTY :

```
show running-config | section line vty
```

**Output attendu :**

```
line vty 0 4
 exec-timeout 10 0
 login local
 transport input ssh
```

---

## Partie 5 : Appliquer la même sécurisation sur SW1

La sécurisation n'a de sens que si elle est appliquée sur **tous** les équipements. Un switch non sécurisé est une porte d'entrée pour un attaquant même si le routeur est blindé.

### Étape 5.1 — Se connecter à SW1

Depuis PC-ADMIN, accédez à SW1 via sa console (cliquez sur SW1 dans Packet Tracer > onglet CLI).

### Étape 5.2 — Appliquer la sécurisation complète

Sur **SW1** :

```
configure terminal

! --- Mot de passe enable ---
enable secret Cisco@Enable1

! --- Sécurisation console ---
line console 0
 password Cisco@Console1
 login
 logging synchronous
 exec-timeout 5 0
exit

! --- Chiffrement des mots de passe ---
service password-encryption

! --- Bannière ---
banner motd #
============================================
  ATTENTION : Acces reserve au personnel
  autorise uniquement. Toute tentative
  d'acces non autorise sera poursuivie.
============================================
#

! --- Utilisateur local ---
username admin privilege 15 secret Cisco@CCNA!

! --- SSH ---
ip domain-name lab.local
crypto key generate rsa general-keys modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! --- VTY ---
line vty 0 15
 transport input ssh
 login local
 exec-timeout 10 0
exit

! --- Protection brute force ---
login block-for 120 attempts 3 within 60

end
write memory
```

> **Notez `line vty 0 15`** sur le switch, contre `line vty 0 4` sur le routeur. Les switches Cisco ont 16 lignes VTY (0 à 15) par défaut, alors que les routeurs en ont généralement 5 (0 à 4). Il faut sécuriser **toutes** les lignes, sinon un attaquant pourrait utiliser une ligne non protégée.

### Étape 5.3 — Tester la connexion SSH vers SW1

Depuis **PC-ADMIN** :

```
ssh -l admin 192.168.1.2
```

Entrez le mot de passe `Cisco@CCNA!`.

**Résultat attendu :** connexion réussie, bannière affichée, accès direct au mode privilégié.

### Étape 5.4 — Vérifier la configuration SSH de SW1

Sur **SW1** :

```
show ip ssh
```

**Output attendu :**

```
SW1#show ip ssh
SSH Enabled - version 2.0
Authentication timeout: 60 secs; Authentication retries: 3
```

---

## Partie 6 : Vérification complète

### Étape 6.1 — Commandes de vérification essentielles

| Commande | Ce qu'elle montre |
|----------|-------------------|
| `show ip ssh` | Version SSH, timeout, retries |
| `show ssh` | Sessions SSH actives (version, chiffrement, utilisateur) |
| `show users` | Utilisateurs connectés (console et VTY) avec leur IP source |
| `show line vty 0 4` | État des lignes VTY |
| `show running-config \| section line` | Configuration des lignes (console, VTY) |
| `show running-config \| include username` | Utilisateurs locaux configurés |

### Étape 6.2 — Récapitulatif des couches de sécurité

| Couche de sécurité | Commande clé | Protection apportée |
|--------------------|-------------|---------------------|
| Mot de passe privilégié | `enable secret` | Protège le mode configuration (hash MD5) |
| Mot de passe console | `line console 0` + `password` + `login` | Protège l'accès physique |
| Chiffrement config | `service password-encryption` | Masque les mots de passe en clair (type 7) |
| Bannière | `banner motd` | Avertissement légal |
| Utilisateur local | `username ... privilege 15 secret` | Authentification nominative + hash MD5 |
| SSH | `crypto key generate rsa` + `ip ssh version 2` | Chiffrement des sessions distantes |
| VTY restreint | `transport input ssh` | Bloque Telnet, n'autorise que SSH |
| Anti-brute force | `login block-for` | Temporisation après échecs d'authentification |
| Timeout | `exec-timeout` | Fermeture automatique des sessions inactives |

---

## Vérification finale

Cochez chaque critère pour valider la réussite du lab :

- [ ] Le mode privilégié est protégé par `enable secret` sur R1 et SW1
- [ ] La console demande un mot de passe sur les deux équipements
- [ ] `service password-encryption` est actif (les mots de passe sont masqués dans la config)
- [ ] La bannière s'affiche à la connexion
- [ ] L'utilisateur `admin` existe avec privilege 15 et un hash secret
- [ ] SSH version 2 est actif avec une clé RSA de 2048 bits
- [ ] Telnet est refusé sur les lignes VTY (`transport input ssh`)
- [ ] La connexion SSH depuis PC-ADMIN vers R1 fonctionne
- [ ] La connexion SSH depuis PC-ADMIN vers SW1 fonctionne
- [ ] `show ip ssh` confirme la version 2 sur les deux équipements
- [ ] `show users` affiche la session SSH avec l'IP source du client

---

## Questions de réflexion

### Question 1 — Pourquoi utiliser `enable secret` plutôt que `enable password` ?

<details>
<summary>Voir la réponse</summary>

`enable password` stocke le mot de passe en clair dans la configuration, ou au mieux avec un chiffrement de type 7 (si `service password-encryption` est activé). Le type 7 est réversible en quelques secondes avec des outils disponibles gratuitement en ligne (comme "Cisco Type 7 Password Decryptor").

`enable secret` utilise un hash MD5 (type 5) qui est à sens unique : on ne peut pas retrouver le mot de passe original à partir du hash. C'est une protection bien plus solide.

Si les deux sont configurés en même temps, `enable secret` a toujours la priorité. La bonne pratique est de ne configurer que `enable secret` et de supprimer tout `enable password` existant.

</details>

### Question 2 — Que se passe-t-il si on essaie de générer les clés RSA sans avoir configuré `ip domain-name` ?

<details>
<summary>Voir la réponse</summary>

La commande `crypto key generate rsa` échoue avec un message d'erreur :

```
% Please define a domain-name first.
```

Le nom de domaine est obligatoire car Cisco IOS nomme la paire de clés RSA au format `hostname.domain` (par exemple `R1.lab.local`). Sans nom de domaine, le système ne peut pas créer l'identifiant de la clé. C'est un prérequis incontournable pour SSH.

</details>

### Question 3 — Un administrateur configure `line vty 0 4` avec `transport input ssh` et `login local`, mais oublie de configurer `line vty 5 15` sur un switch. Quel est le risque ?

<details>
<summary>Voir la réponse</summary>

Les lignes VTY 5 à 15 restent avec leur configuration par défaut, qui autorise généralement Telnet sans mot de passe. Un attaquant pourrait se connecter en Telnet sur l'une de ces lignes non sécurisées, contournant complètement la protection SSH mise en place sur les lignes 0-4. Il suffit que les 5 premières connexions soient occupées pour que la suivante tombe sur une ligne non protégée.

C'est pourquoi il faut toujours configurer **toutes** les lignes VTY : `line vty 0 15` sur un switch (16 lignes) ou `line vty 0 4` sur un routeur (5 lignes).

</details>

### Question 4 — Quelle est la taille minimale de clé RSA pour SSH version 2, et pourquoi utilise-t-on 2048 bits ?

<details>
<summary>Voir la réponse</summary>

La taille minimale pour SSH version 2 est de **768 bits**. Avec une clé inférieure à 768 bits, IOS refuse d'activer SSH v2 et revient à la version 1 (si la clé fait au moins 512 bits).

On utilise 2048 bits car :
- Les clés de 768 et 1024 bits sont considérées comme vulnérables aux attaques par factorisation avec les capacités de calcul modernes.
- 2048 bits est le standard recommandé par le NIST (National Institute of Standards and Technology) pour une sécurité suffisante jusqu'en 2030.
- 4096 bits serait encore plus sécurisé mais augmente le temps de traitement, ce qui peut poser problème sur des routeurs d'entrée de gamme.

</details>

### Question 5 — Vous vous connectez en SSH à un routeur et vous voyez `Router>` au lieu de `Router#`. Que s'est-il passé et comment corriger ?

<details>
<summary>Voir la réponse</summary>

Le prompt `Router>` indique que vous êtes en mode utilisateur (user EXEC), pas en mode privilégié. Cela signifie que l'utilisateur avec lequel vous vous êtes connecté n'a pas le privilege level 15.

Deux possibilités :

1. L'utilisateur a été créé sans `privilege 15` : par exemple `username admin secret Cisco@CCNA!` (sans la mention du privilege level). Par défaut, le niveau est 1 (user EXEC). Correction : `username admin privilege 15 secret Cisco@CCNA!`.

2. L'utilisateur a un privilege level intermédiaire (ex: 7). Correction : modifier le privilege level à 15.

En attendant, vous pouvez taper `enable` et entrer le mot de passe `enable secret` pour passer manuellement en mode privilégié, mais l'idéal est de corriger le niveau de privilège pour un accès direct.

</details>

---

## Solution complète

<details>
<summary>Voir la solution complète de R1</summary>

```
enable
configure terminal

hostname R1
no ip domain-lookup

! --- Interface ---
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
exit

! --- Sécurisation de base ---
enable secret Cisco@Enable1
service password-encryption

banner motd #
============================================
  ATTENTION : Acces reserve au personnel
  autorise uniquement. Toute tentative
  d'acces non autorise sera poursuivie.
============================================
#

! --- Console ---
line console 0
 password Cisco@Console1
 login
 logging synchronous
 exec-timeout 5 0
exit

! --- Utilisateur local ---
username admin privilege 15 secret Cisco@CCNA!

! --- SSH ---
ip domain-name lab.local
crypto key generate rsa general-keys modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! --- VTY : SSH uniquement ---
line vty 0 4
 transport input ssh
 login local
 exec-timeout 10 0
exit

! --- Protection brute force ---
login block-for 120 attempts 3 within 60

end
write memory
```

</details>

<details>
<summary>Voir la solution complète de SW1</summary>

```
enable
configure terminal

hostname SW1
no ip domain-lookup

! --- Management ---
interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1

! --- Sécurisation de base ---
enable secret Cisco@Enable1
service password-encryption

banner motd #
============================================
  ATTENTION : Acces reserve au personnel
  autorise uniquement. Toute tentative
  d'acces non autorise sera poursuivie.
============================================
#

! --- Console ---
line console 0
 password Cisco@Console1
 login
 logging synchronous
 exec-timeout 5 0
exit

! --- Utilisateur local ---
username admin privilege 15 secret Cisco@CCNA!

! --- SSH ---
ip domain-name lab.local
crypto key generate rsa general-keys modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3

! --- VTY : SSH uniquement (16 lignes sur un switch) ---
line vty 0 15
 transport input ssh
 login local
 exec-timeout 10 0
exit

! --- Protection brute force ---
login block-for 120 attempts 3 within 60

end
write memory
```

</details>
