# Module 5 — Security Fundamentals

> **Domain** : 5 — Security Fundamentals | **Poids examen** : 15%
> **Durée estimée** : 1,5 semaine | **Prérequis** : Modules 1 à 4
> **Topics couverts** : 5.1 à 5.11

## Objectif du module

À l'issue de ce module, vous serez capable de :
- Identifier les menaces, vulnérabilités et vecteurs d'attaque courants dans un réseau d'entreprise
- Configurer le contrôle d'accès aux équipements (mots de passe, SSH, AAA)
- Rédiger et appliquer des ACLs standard et étendues avec maîtrise des wildcard masks
- Déployer les mécanismes de sécurité Layer 2 (port security, DHCP snooping, DAI)
- Décrire les protocoles de sécurité Wi-Fi et les principes du ML appliqué à la sécurité réseau

---

## 5.1 — Concepts fondamentaux de sécurité

> **Exam topic 5.1** : _Define_ — Key security concepts (threats, vulnerabilities, exploits, and mitigation techniques)
> **Niveau** : Define

### Contexte

Chaque réseau d'entreprise est une cible. Que ce soit un hôpital, une PME ou un data center cloud, les attaquants cherchent le maillon faible — un serveur non patché, un mot de passe par défaut, un port ouvert oublié. Avant de configurer quoi que ce soit, il faut parler le même langage que les professionnels de la sécurité.

### Théorie

#### La triade CIA

La sécurité réseau repose sur trois piliers, souvent appelés **triade CIA** :

| Pilier | Anglais | Objectif | Exemple concret |
|--------|---------|----------|-----------------|
| **Confidentialité** | Confidentiality | Seules les personnes autorisées accèdent aux données | Chiffrement VPN entre deux sites |
| **Intégrité** | Integrity | Les données ne sont pas altérées en transit ou au repos | Hachage MD5/SHA pour vérifier un fichier IOS |
| **Disponibilité** | Availability | Les services restent accessibles aux utilisateurs légitimes | Redondance HSRP, liens EtherChannel |

Pensez à un coffre-fort dans une banque : la **confidentialité**, c'est la serrure qui empêche les non-autorisés d'ouvrir le coffre. L'**intégrité**, c'est le scellé qui prouve que personne n'a touché au contenu. La **disponibilité**, c'est le fait que la banque ouvre bien ses portes aux heures prévues.

#### Menaces, vulnérabilités, exploits

Ces trois termes forment une chaîne logique :

```
  Vulnérabilité              Exploit                 Menace réalisée
  (faille existante)  --->  (outil/technique   --->  (impact sur le
                             qui l'utilise)            réseau)

  Exemple :
  Telnet transmet         Un sniffer capture       L'attaquant obtient
  en clair (vuln.)        les credentials          l'accès admin au routeur
                          (exploit)                (menace)
```

**Menace (Threat)** — Tout événement potentiel susceptible de compromettre la CIA. Les menaces peuvent être :
- **Internes** : un employé mécontent qui copie la base clients
- **Externes** : un groupe de hackers qui lance un ransomware
- **Environnementales** : une inondation qui détruit la salle serveur

**Vulnérabilité (Vulnerability)** — Une faiblesse dans un système, un protocole ou une configuration qu'un attaquant peut exploiter. Quelques exemples réseau :
- Un switch avec le mot de passe console par défaut
- Un serveur web sans mise à jour de sécurité depuis 6 mois
- Les community strings SNMP `public`/`private` en SNMPv1 (voir Module 4, section 4.4)
- Un réseau Wi-Fi ouvert sans chiffrement

**Exploit** — Le mécanisme concret qui tire parti d'une vulnérabilité. Un exploit peut être un logiciel, un script, ou même une manipulation sociale (phishing).

#### Types d'attaques courantes

| Catégorie | Attaque | Description | Cible CIA |
|-----------|---------|-------------|-----------|
| Reconnaissance | Scan de ports (nmap) | Cartographie des services ouverts | Prépare une attaque |
| Accès | Brute force | Test systématique de mots de passe | Confidentialité |
| Accès | Phishing | E-mail frauduleux pour voler des identifiants | Confidentialité |
| Man-in-the-Middle | ARP spoofing | L'attaquant se fait passer pour la passerelle | Confidentialité, Intégrité |
| Man-in-the-Middle | DHCP rogue server | Faux serveur DHCP distribue une fausse passerelle | Confidentialité |
| DoS/DDoS | SYN flood | Saturation de la table de connexions TCP | Disponibilité |
| DoS/DDoS | DHCP starvation | Épuisement du pool DHCP | Disponibilité |
| Malware | Ransomware | Chiffrement des données et demande de rançon | Disponibilité, Confidentialité |
| Social Engineering | Pretexting | Usurpation d'identité par téléphone | Confidentialité |

#### Techniques de mitigation

La sécurité ne repose jamais sur un seul mécanisme — on parle de **défense en profondeur** (defense in depth). Chaque couche ajoute un obstacle supplémentaire :

| Couche | Mécanisme | Exemple |
|--------|-----------|---------|
| Physique | Contrôle d'accès, caméras | Badge pour entrer en salle serveur |
| Réseau | Firewalls, ACLs, IPS | ACL bloquant le trafic non autorisé (topic 5.6) |
| Hôte | Antivirus, patching, hardening | Désactiver les services inutiles sur un routeur |
| Application | WAF, input validation | Filtrage des requêtes SQL malveillantes |
| Données | Chiffrement, backup | VPN IPsec pour les données en transit (topic 5.5) |
| Politique | Formation, procédures | Sensibilisation au phishing (topic 5.2) |

### Mise en pratique CLI

Sur un routeur Cisco, la première mesure de sécurité consiste à vérifier les services actifs inutiles :

```cisco
R1# show control-plane host open-ports
Active internet connections (servers and established)
Prot        Local Address       Foreign Address        Service    State
 tcp                 *:22                  *:0           SSH-Server  LISTEN
 tcp                 *:23                  *:0           Telnet      LISTEN
 udp                 *:161                 *:0           SNMP        LISTEN
 udp                 *:67                  *:0           DHCPD       LISTEN
```

**Interprétation** : Telnet (port 23) est actif — c'est une vulnérabilité puisque les identifiants transitent en clair. SNMP écoute sur le port 161, potentiellement avec les community strings par défaut. Ces deux services devraient être sécurisés ou désactivés.

```cisco
R1(config)# no ip http server
R1(config)# line vty 0 4
R1(config-line)# transport input ssh
R1(config-line)# exit
```

### Point exam

> **Piège courant** : Ne confondez pas **menace** et **vulnérabilité**. Un serveur non patché est une *vulnérabilité* ; un hacker qui cible ce serveur est une *menace*. L'examen teste souvent cette distinction avec des scénarios où il faut classifier correctement.
>
> **À retenir** : La triade CIA est le fondement de toute question de sécurité. Si on vous demande "quel est l'impact d'une attaque DDoS ?", la réponse touche la **disponibilité** — pas la confidentialité.

### Exercice 5.1 — Classification des scénarios de sécurité

**Contexte** : L'entreprise NetCorp subit plusieurs incidents de sécurité. Le RSSI vous demande de classifier chaque scénario.

**Consigne** : Pour chaque situation, indiquez s'il s'agit d'une menace, d'une vulnérabilité ou d'un exploit, et précisez quel pilier de la CIA est visé.

1. Le firmware du switch n'a pas été mis à jour depuis 2 ans
2. Un employé reçoit un e-mail qui imite la page de connexion Office 365
3. Un scanner nmap identifie le port 23 (Telnet) ouvert sur le routeur edge
4. Un attaquant utilise Hydra pour tester 10 000 mots de passe sur le VPN
5. Le mot de passe enable est `cisco123`
6. Une coupure de courant rend le data center inaccessible pendant 4 heures
7. Un ver réseau se propage via une faille SMBv1 non patchée
8. L'accès Wi-Fi visiteur utilise WEP
9. Un technicien copie la base de données clients sur une clé USB personnelle
10. Un script Python envoie 50 000 requêtes DHCP Discover en boucle

**Indice** : <details><summary>Voir l'indice</summary>Une vulnérabilité est une faiblesse passive (elle existe même sans attaquant). Un exploit est l'action qui utilise cette faiblesse. Une menace est la conséquence potentielle ou l'acteur malveillant.</details>

<details>
<summary>Solution</summary>

| # | Type | Pilier CIA | Explication |
|---|------|-----------|-------------|
| 1 | Vulnérabilité | — (pas encore exploitée) | Firmware obsolète = faille potentielle |
| 2 | Exploit (phishing) | Confidentialité | Technique active pour voler des identifiants |
| 3 | Vulnérabilité | Confidentialité (potentielle) | Le port ouvert est la faiblesse, le scan est de la reconnaissance |
| 4 | Exploit (brute force) | Confidentialité | Attaque active contre le mécanisme d'authentification |
| 5 | Vulnérabilité | Confidentialité | Mot de passe faible = faiblesse de configuration |
| 6 | Menace (environnementale) | Disponibilité | Événement qui impacte l'accès aux services |
| 7 | Exploit + menace | Disponibilité, Intégrité | Le ver exploite la faille SMBv1 |
| 8 | Vulnérabilité | Confidentialité | WEP est cassé depuis 2004 — chiffrement inefficace |
| 9 | Menace (interne) | Confidentialité | Exfiltration de données par un insider |
| 10 | Exploit (DHCP starvation) | Disponibilité | Épuisement volontaire du pool DHCP |

</details>

### Voir aussi

- Topic 4.4 dans Module 4 (SNMP community strings = vulnérabilité courante)
- Topic 4.5 dans Module 4 (Syslog pour la détection d'incidents)
- Topic 5.7 dans ce module (mitigation des attaques L2 : DHCP snooping, DAI)

---

## 5.2 — Programmes de sécurité

> **Exam topic 5.2** : _Describe_ — Security program elements (user awareness, training, and physical access control)
> **Niveau** : Describe

### Contexte

La technologie seule ne suffit pas. Le pare-feu le plus sophistiqué n'empêchera pas un employé de cliquer sur un lien de phishing ou de coller son mot de passe sur un Post-it. Un programme de sécurité efficace combine des mesures techniques, organisationnelles et humaines.

### Théorie

#### Les trois piliers d'un programme de sécurité

Un programme de sécurité d'entreprise s'articule autour de trois axes complémentaires :

**1. Sensibilisation des utilisateurs (User Awareness)**

La majorité des incidents de sécurité commencent par une erreur humaine. La sensibilisation vise à transformer chaque employé en première ligne de défense :
- Campagnes de phishing simulé (envoyer de faux e-mails et mesurer le taux de clic)
- Affichage de bonnes pratiques (verrouiller son poste, ne pas brancher de clés USB inconnues)
- Procédure de signalement des incidents (à qui écrire si on reçoit un e-mail suspect ?)

L'analogie est celle d'un immeuble : même avec un digicode à l'entrée, si un résident tient la porte ouverte à un inconnu, toute la sécurité s'effondre.

**2. Formation (Training)**

Plus ciblée que la sensibilisation, la formation s'adresse à des rôles spécifiques :
- Les administrateurs réseau apprennent à durcir les configurations (hardening)
- Les développeurs suivent des formations sur le codage sécurisé (OWASP Top 10)
- Les équipes SOC s'entraînent sur des simulations d'incidents (tabletop exercises)

La formation doit être continue — pas un événement ponctuel annuel — car les menaces évoluent constamment.

**3. Contrôle d'accès physique (Physical Access Control)**

Le contrôle physique empêche un attaquant d'accéder directement aux équipements :

| Mesure | Description | Exemples |
|--------|-------------|----------|
| **Périmètre** | Première barrière physique | Clôtures, portail avec badge, gardien |
| **Bâtiment** | Contrôle d'entrée du bâtiment | Badge RFID, interphone, sas de sécurité |
| **Salle serveur** | Accès restreint aux personnels autorisés | Serrure biométrique, caméra, journal d'accès |
| **Équipement** | Protection individuelle des appareils | Verrou sur le rack, câble antivol, port console protégé |
| **Environnemental** | Protection contre les sinistres | Climatisation, détecteur incendie, onduleur (UPS) |

#### Politiques et procédures

Un programme de sécurité formalisé inclut plusieurs documents :

- **Politique de sécurité (Security Policy)** : document de haut niveau définissant les règles, les responsabilités et les sanctions
- **Politique d'utilisation acceptable (AUP)** : ce que les employés peuvent et ne peuvent pas faire avec les ressources IT
- **Plan de réponse aux incidents (IRP)** : qui fait quoi quand un incident survient (détection → confinement → éradication → restauration → leçons apprises)
- **Plan de reprise d'activité (DRP/BCP)** : comment maintenir les opérations critiques après un sinistre majeur

### Mise en pratique CLI

La sécurité physique du port console d'un routeur est souvent négligée. Voici comment la renforcer :

```cisco
R1(config)# line console 0
R1(config-line)# password S3cur3C0ns0l3!
R1(config-line)# login
R1(config-line)# exec-timeout 5 0
R1(config-line)# logging synchronous
R1(config-line)# exit
```

```cisco
R1# show line console 0
   Tty Typ     Tx/Rx    A Modem  Roty AccO AccI   Uses   Noise  Overruns  Int
     0 CTY                  -      -    -    -        3       0     0/0       -

Line 0, Location: "", Type: ""
Length: 24 lines, Width: 80 columns
Baud rate (TX/RX) is 9600/9600
  ...
  Timeout: 00:05:00
  ...
  Allowed input transports are none.
  Allowed output transports are pad telnet rlogin lapb-ta mop v120 ssh.
```

**Interprétation** : Le timeout est bien réglé à 5 minutes. Si un administrateur oublie de se déconnecter de la console, la session expire automatiquement — une mesure qui limite le risque d'accès non autorisé par quelqu'un qui passerait physiquement devant l'équipement.

### Point exam

> **Piège courant** : L'examen peut proposer une question où toutes les réponses sont des mesures techniques (firewall, ACL, IPS, chiffrement). Si la question porte sur un "security program element", cherchez la réponse non technique : sensibilisation, formation ou contrôle d'accès physique.
>
> **À retenir** : Les trois éléments d'un programme de sécurité sont : **user awareness**, **training** et **physical access control**. Pas de firewall ni d'ACL dans cette liste.

### Exercice 5.2 — Mini-politique de sécurité

**Contexte** : Vous êtes consultant pour la PME AlphaLogistics (45 employés, 2 sites reliés par VPN). Le directeur vous demande de rédiger les grandes lignes d'un programme de sécurité.

**Consigne** : Pour chaque axe (sensibilisation, formation, accès physique), proposez au moins deux mesures concrètes adaptées à une PME avec un budget limité.

**Indice** : <details><summary>Voir l'indice</summary>Une PME n'a pas les moyens d'un SOC 24/7. Pensez à des mesures simples et peu coûteuses : campagnes e-mail internes, tutoriels vidéo, badges d'accès, verrouillage automatique des postes.</details>

<details>
<summary>Solution</summary>

**Sensibilisation :**
- Campagne trimestrielle de phishing simulé avec un outil gratuit (GoPhish)
- Newsletter sécurité mensuelle (2 pages max) avec les menaces récentes et les bonnes pratiques
- Affichage dans les espaces communs : "Verrouillez votre poste (Win+L)", "Ne branchez pas de clés USB inconnues"

**Formation :**
- Session annuelle de 2h pour tous les employés (reconnaître un phishing, signaler un incident)
- Formation technique semestrielle pour l'équipe IT (hardening Cisco, gestion des patches)
- Documentation de procédure de réponse aux incidents (même simplifiée : qui appeler, quoi isoler)

**Accès physique :**
- Badge RFID pour l'accès au bâtiment et à la salle serveur (investissement unique ~500€)
- Journal d'accès à la salle serveur (registre papier ou badge électronique)
- Câbles antivol sur les laptops des bureaux ouverts
- Verrouillage automatique des postes après 5 minutes d'inactivité (GPO Windows)

</details>

### Voir aussi

- Topic 5.4 dans ce module (politiques de mots de passe — composante d'un programme de sécurité)
- Topic 5.8 dans ce module (AAA — contrôle d'accès logique)

---

## 5.3 — Contrôle d'accès par mots de passe locaux

> **Exam topic 5.3** : _Configure and verify_ — Device access control using local passwords
> **Niveau** : Configure/Verify

### Contexte

Un routeur ou un switch Cisco fraîchement déballé n'a aucune protection. N'importe qui avec un câble console peut prendre le contrôle total de l'équipement. La première action d'un administrateur réseau, avant même de configurer une adresse IP, c'est de verrouiller les accès.

### Théorie

#### Les points d'accès à sécuriser

Un équipement Cisco possède plusieurs "portes d'entrée" :

```
                          ┌──────────────────────┐
   Console (port série) ──┤                      │
                          │     Routeur/Switch    │
   VTY (SSH/Telnet)    ──┤     Cisco IOS         │
                          │                      │
   AUX (modem dial-up) ──┤                      │
                          │   Mode enable        │
   HTTP/HTTPS (GUI)    ──┤   (privilège 15)      │
                          └──────────────────────┘
```

Chaque point d'accès doit être protégé indépendamment.

#### Hiérarchie des mots de passe

Cisco IOS propose plusieurs types de mots de passe, avec des niveaux de sécurité différents :

| Commande | Protège | Stockage | Sécurité |
|----------|---------|----------|----------|
| `enable password` | Accès au mode enable | Clair dans `running-config` | Faible (obsolète) |
| `enable secret` | Accès au mode enable | Haché MD5 ou SHA-256 | Forte |
| `line console 0` → `password` | Accès console | Clair (ou `service password-encryption`) | Moyenne |
| `line vty 0 4` → `password` | Accès distant (Telnet/SSH) | Clair (ou `service password-encryption`) | Moyenne |
| `username X secret Y` | Authentification locale nommée | Haché MD5/SHA-256 | Forte |

Si `enable password` et `enable secret` coexistent, **`enable secret` prend toujours le dessus**. Cisco recommande de n'utiliser que `enable secret`.

#### `service password-encryption`

Cette commande applique un chiffrement de type 7 (algorithme Vigenère réversible) à tous les mots de passe en clair dans la configuration. C'est mieux que rien, mais c'est facilement cassable — des dizaines d'outils en ligne déchiffrent un mot de passe type 7 en une seconde. Son rôle principal : empêcher la lecture par-dessus l'épaule (shoulder surfing) quand on affiche la running-config.

#### Utilisateurs locaux

Plutôt que de partager un mot de passe unique sur les lignes VTY (qui ne permet pas de savoir *qui* s'est connecté), on crée des comptes utilisateurs locaux :

```cisco
R1(config)# username admin privilege 15 secret Str0ngP@ss2026!
R1(config)# username technicien privilege 1 secret Tech$upport1
```

Le niveau de privilège (0 à 15) détermine les commandes accessibles :
- **Privilège 0** : logout, enable, disable, help, exit
- **Privilège 1** : mode utilisateur standard (show basiques)
- **Privilège 15** : accès complet (mode enable)

### Mise en pratique CLI

Configuration complète de la sécurité d'accès sur un routeur :

```cisco
! Étape 1 : Mot de passe enable (haché)
R1(config)# enable secret C1sc0SecretP@ss!

! Étape 2 : Sécuriser la console
R1(config)# line console 0
R1(config-line)# login local
R1(config-line)# exec-timeout 5 0
R1(config-line)# logging synchronous
R1(config-line)# exit

! Étape 3 : Sécuriser les lignes VTY
R1(config)# line vty 0 4
R1(config-line)# login local
R1(config-line)# transport input ssh
R1(config-line)# exec-timeout 10 0
R1(config-line)# exit

! Étape 4 : Créer les utilisateurs locaux
R1(config)# username admin privilege 15 secret @dminP@ss2026
R1(config)# username operator privilege 1 secret 0pR3ad0nly!

! Étape 5 : Chiffrement cosmétique des mots de passe restants
R1(config)# service password-encryption

! Étape 6 : Bannière d'avertissement légale
R1(config)# banner motd #
*** ACCES RESERVE AU PERSONNEL AUTORISE ***
*** Toute tentative d'acces non autorise sera poursuivie ***
#
```

**Vérification :**

```cisco
R1# show running-config | section line
line con 0
 exec-timeout 5 0
 logging synchronous
 login local
line aux 0
line vty 0 4
 exec-timeout 10 0
 login local
 transport input ssh
```

```cisco
R1# show running-config | include username
username admin privilege 15 secret 9 $14$WxKz$...(haché)...
username operator privilege 1 secret 9 $14$RtPm$...(haché)...
```

**Interprétation** : Les mots de passe `secret` apparaissent sous forme hachée (type 9 = SHA-256 sur les IOS récents, type 5 = MD5 sur les anciens). La ligne `login local` sur console et VTY signifie que l'authentification utilise la base locale de usernames. `transport input ssh` bloque Telnet sur les lignes VTY.

### Point exam

> **Piège courant** : Si une question vous montre une config avec `enable password cisco` ET `enable secret class`, le mot de passe pour accéder au mode enable est **class** (enable secret gagne toujours). L'examen teste régulièrement cette priorité.
>
> **À retenir** : `login` seul = utilise le mot de passe de la ligne (`password`). `login local` = utilise la base de données `username`. Ne confondez pas les deux — c'est une erreur classique.

### Exercice 5.3 — Sécurisation d'un routeur neuf

**Contexte** : Le routeur R-Branch vient d'être installé dans la succursale de Lyon. Il est encore en configuration usine. Vous devez le sécuriser avant de le mettre en production.

**Consigne** :
1. Configurez un enable secret `Ly0nBr@nch2026`
2. Créez deux utilisateurs : `admin` (privilège 15, secret `@dminLy0n!`) et `helpdesk` (privilège 1, secret `H3lpD3sk$`)
3. Sécurisez la console avec `login local` et un timeout de 3 minutes
4. Sécurisez les VTY (0 à 4) en SSH uniquement avec `login local` et un timeout de 10 minutes
5. Activez le chiffrement des mots de passe
6. Ajoutez une bannière MOTD d'avertissement

**Indice** : <details><summary>Voir l'indice</summary>N'oubliez pas que `transport input ssh` nécessite au préalable un hostname, un domain-name et une clé RSA (voir Module 4, section 4.8). Pour cet exercice, concentrez-vous sur les commandes de sécurité d'accès.</details>

<details>
<summary>Solution</summary>

```cisco
R-Branch(config)# enable secret Ly0nBr@nch2026
R-Branch(config)# username admin privilege 15 secret @dminLy0n!
R-Branch(config)# username helpdesk privilege 1 secret H3lpD3sk$
R-Branch(config)# line console 0
R-Branch(config-line)# login local
R-Branch(config-line)# exec-timeout 3 0
R-Branch(config-line)# logging synchronous
R-Branch(config-line)# exit
R-Branch(config)# line vty 0 4
R-Branch(config-line)# login local
R-Branch(config-line)# transport input ssh
R-Branch(config-line)# exec-timeout 10 0
R-Branch(config-line)# exit
R-Branch(config)# service password-encryption
R-Branch(config)# banner motd #
*** ACCES RESERVE - Succursale Lyon ***
*** Les acces non autorises sont interdits et traces ***
#
```

**Explication** : `login local` sur les deux lignes force l'authentification par username/password. Le timeout console à 3 minutes est plus court que le VTY (10 min) car l'accès physique à la console implique qu'on se trouve dans la salle serveur — une session oubliée y est plus risquée. La bannière MOTD a un rôle juridique : elle avertit que l'accès est restreint, ce qui est requis dans certaines juridictions pour poursuivre un intrus.

</details>

### Voir aussi

- Topic 4.8 dans Module 4 (configuration complète de SSH — prérequis pour `transport input ssh`)
- Topic 5.4 dans ce module (politiques de complexité des mots de passe)
- Topic 5.8 dans ce module (AAA — alternative plus scalable à l'authentification locale)

---

## 5.4 — Politiques de mots de passe et alternatives

> **Exam topic 5.4** : _Describe_ — Security password policies elements (management, complexity, password alternatives — MFA, certificates, biometrics)
> **Niveau** : Describe

### Contexte

Un mot de passe `admin123` protège autant qu'une porte en carton. Mais imposer des mots de passe de 25 caractères changés tous les 15 jours pousse les utilisateurs à les écrire sur des Post-it. Une bonne politique de mots de passe trouve l'équilibre entre sécurité et utilisabilité.

### Théorie

#### Éléments d'une politique de mots de passe

| Élément | Recommandation | Justification |
|---------|---------------|---------------|
| **Longueur minimale** | 12 caractères (NIST SP 800-63B) | Résistance au brute force |
| **Complexité** | Mélange majuscules, minuscules, chiffres, symboles | Augmente l'espace de recherche |
| **Rotation** | Uniquement en cas de compromission (NIST 2024) | Le changement forcé régulier encourage les mots de passe faibles |
| **Historique** | Interdire la réutilisation des 5-10 derniers | Empêche le recyclage |
| **Verrouillage** | Après 5 tentatives, verrouillage temporaire (15-30 min) | Anti-brute force |
| **Stockage** | Hachage avec sel (bcrypt, SHA-256) | Protège la base en cas de vol |

Sur un équipement Cisco, la longueur minimale se configure avec :

```cisco
R1(config)# security passwords min-length 10
```

Cette commande refuse tout mot de passe de moins de 10 caractères lors de la prochaine configuration.

#### Gestion des mots de passe (Management)

La gestion couvre le cycle de vie complet :
- **Création** : respect des règles de complexité
- **Distribution** : ne jamais envoyer un mot de passe en clair par e-mail
- **Stockage** : gestionnaire de mots de passe (pas un fichier Excel)
- **Rotation** : changement immédiat si compromission suspectée
- **Révocation** : désactiver les comptes des employés qui quittent l'entreprise

#### Alternatives aux mots de passe

Les mots de passe seuls sont de plus en plus insuffisants. Trois alternatives majeures les complètent ou les remplacent :

**MFA — Multi-Factor Authentication**

L'authentification multifacteur combine au moins deux facteurs parmi trois catégories :

| Facteur | "Ce que..." | Exemples |
|---------|------------|----------|
| **Connaissance** | ...vous savez | Mot de passe, PIN, réponse secrète |
| **Possession** | ...vous avez | Smartphone (appli TOTP), token matériel (YubiKey), badge |
| **Inhérence** | ...vous êtes | Empreinte digitale, reconnaissance faciale, iris |

Le principe : même si un attaquant vole votre mot de passe (facteur connaissance), il lui faut aussi votre téléphone (facteur possession) pour s'authentifier. C'est la même logique qu'un distributeur de billets qui exige la carte *et* le code PIN.

**Certificats numériques**

Un certificat X.509 est une pièce d'identité numérique émise par une autorité de certification (CA). Il contient :
- L'identité du titulaire
- Sa clé publique
- La signature de la CA
- La période de validité

Les certificats sont utilisés pour l'authentification VPN (IPsec), le 802.1X sur les réseaux filaires et Wi-Fi, et le HTTPS. Leur avantage : pas de mot de passe à mémoriser ni à transmettre.

**Biométrie**

La biométrie utilise des caractéristiques physiques uniques :
- Empreinte digitale (le plus courant, rapport coût/fiabilité)
- Reconnaissance faciale (de plus en plus répandue sur les smartphones)
- Scan rétinien/iris (haute sécurité, coût élevé)

Limitation importante : contrairement à un mot de passe, une empreinte digitale ne peut pas être changée si elle est compromise. La biométrie est donc toujours combinée avec un autre facteur.

### Mise en pratique CLI

Configuration de la longueur minimale et d'un mécanisme anti-brute force sur les lignes VTY :

```cisco
R1(config)# security passwords min-length 10
R1(config)# login block-for 120 attempts 3 within 60
```

**Vérification :**

```cisco
R1# show login
  A login delay of 1 second is applied.
  Quiet-Mode access list is not configured.

  Router enabled to watch for login Attacks.
  If more than 3 login failures occur in 60 seconds or less,
  further login attempts will be blocked for 120 seconds.

  Router presently in Normal-Mode.
  Current Watch Window
    Time remaining: 42 seconds.
    Login failures for current window: 0.
```

**Interprétation** : Si quelqu'un échoue 3 fois en moins de 60 secondes, les lignes VTY se verrouillent pendant 2 minutes. C'est une protection efficace contre le brute force, sans nécessiter de serveur AAA externe.

### Point exam

> **Piège courant** : L'examen peut demander combien de facteurs MFA sont utilisés dans un scénario donné. Un mot de passe + un code PIN = **un seul facteur** (connaissance × 2). Un mot de passe + un code TOTP sur smartphone = **deux facteurs** (connaissance + possession). C'est le *type* de facteur qui compte, pas le nombre d'éléments.
>
> **À retenir** : Les trois catégories MFA sont : quelque chose que vous **savez**, quelque chose que vous **avez**, quelque chose que vous **êtes**. Deux éléments de la même catégorie ne font pas du MFA.

### Exercice 5.4 — Comparaison des méthodes d'authentification

**Contexte** : Le DSI de MedTech (clinique de 200 employés) souhaite renforcer l'accès au réseau interne et aux dossiers patients.

**Consigne** : Complétez le tableau suivant en indiquant les avantages et inconvénients de chaque méthode, puis recommandez une solution pour chaque cas d'usage.

| Méthode | Avantage principal | Inconvénient principal | Cas d'usage recommandé |
|---------|-------------------|----------------------|----------------------|
| Mot de passe seul | | | |
| MFA (mot de passe + TOTP) | | | |
| Certificat X.509 | | | |
| Biométrie + PIN | | | |

**Indice** : <details><summary>Voir l'indice</summary>Pensez au contexte médical : les médecins changent souvent de poste de travail, le temps d'authentification doit être court, et les données patients sont soumises à des réglementations strictes.</details>

<details>
<summary>Solution</summary>

| Méthode | Avantage principal | Inconvénient principal | Cas d'usage recommandé |
|---------|-------------------|----------------------|----------------------|
| Mot de passe seul | Simple, pas de matériel supplémentaire | Vulnérable au phishing et brute force | Wi-Fi visiteur (réseau isolé, données non sensibles) |
| MFA (mot de passe + TOTP) | Résistant au vol de mot de passe | Nécessite un smartphone ou token | VPN d'accès distant pour le télétravail |
| Certificat X.509 | Pas de mot de passe à mémoriser, fort | Gestion complexe (PKI, révocation, renouvellement) | Authentification 802.1X des postes fixes |
| Biométrie + PIN | Rapide et difficile à usurper | Coûteux, empreinte non révocable | Accès physique à la salle des dossiers patients |

**Explication** : Dans un contexte médical, le MFA est indispensable pour l'accès distant aux dossiers patients. Les certificats conviennent aux postes fixes car ils s'installent une fois. La biométrie est adaptée aux accès physiques critiques. Le mot de passe seul ne devrait être réservé qu'aux ressources non sensibles.

</details>

### Voir aussi

- Topic 5.3 dans ce module (configuration pratique des mots de passe Cisco)
- Topic 5.8 dans ce module (AAA — centralisation de l'authentification)
- Topic 5.9 dans ce module (WPA2-Enterprise utilise 802.1X avec certificats ou MFA)

---

## 5.5 — VPNs IPsec

> **Exam topic 5.5** : _Describe_ — IPsec remote access and site-to-site VPNs
> **Niveau** : Describe

### Contexte

Quand une entreprise connecte ses bureaux via Internet ou permet à ses employés de travailler depuis chez eux, les données traversent un réseau public non fiable. Le VPN (Virtual Private Network) crée un "tunnel" chiffré à travers Internet — comme un tube opaque au milieu d'une pièce transparente. IPsec est le standard de l'industrie pour ces tunnels.

### Théorie

#### Deux architectures VPN

```
  Site-to-Site VPN                        Remote Access VPN

  ┌──────┐   Tunnel IPsec   ┌──────┐     ┌──────────┐
  │ Site │═══════════════════│ Site │     │ Employé  │   Tunnel
  │  A   │   (permanent)    │  B   │     │ distant  │═══════╗
  │ R1   │                  │ R2   │     │ (laptop) │       ║
  └──┬───┘                  └──┬───┘     └──────────┘       ║
     │                         │                         ┌──╩───┐
  ┌──┴───┐                  ┌──┴───┐                     │ HQ   │
  │ LAN  │                  │ LAN  │                     │ R1   │
  │ A    │                  │ B    │                     └──┬───┘
  └──────┘                  └──────┘                     ┌──┴───┐
                                                         │ LAN  │
                                                         └──────┘
```

| Caractéristique | Site-to-Site | Remote Access |
|----------------|-------------|---------------|
| **Endpoints** | Routeur ↔ Routeur (ou firewall) | Client logiciel ↔ Routeur/Firewall |
| **Initiation** | Permanent ou on-demand | À la demande (l'utilisateur se connecte) |
| **Usage** | Relier deux sites d'entreprise | Télétravail, employés mobiles |
| **Authentification** | Pre-shared key (PSK) ou certificats | Username/password + certificat ou MFA |
| **Exemple** | Siège Paris ↔ Succursale Lyon via Internet | Commercial en déplacement → réseau d'entreprise |
| **Protocole typique** | IPsec (IKEv2) | IPsec, SSL/TLS (AnyConnect) |

#### Les composants d'IPsec

IPsec n'est pas un protocole unique mais une **suite de protocoles** qui travaillent ensemble :

**IKE (Internet Key Exchange)** — Phase de négociation
- **IKE Phase 1** : les deux pairs s'authentifient mutuellement et négocient un canal sécurisé (ISAKMP SA). Ils se mettent d'accord sur les algorithmes de chiffrement, de hachage, la méthode d'authentification et le groupe Diffie-Hellman.
- **IKE Phase 2** : à l'intérieur du canal sécurisé de Phase 1, les pairs négocient les paramètres du tunnel de données (IPsec SA). Ils définissent quel trafic sera protégé (via des ACLs crypto) et les algorithmes utilisés.

**Protocoles de protection des données :**

| Protocole | Fonction | Chiffrement | Intégrité | IP Protocol # |
|-----------|----------|-------------|-----------|---------------|
| **AH** (Authentication Header) | Intégrité + authentification | Non | Oui | 51 |
| **ESP** (Encapsulating Security Payload) | Chiffrement + intégrité + authentification | Oui | Oui | 50 |

Dans la pratique, **ESP est quasi toujours utilisé** car il fournit le chiffrement. AH ne chiffre pas les données — il garantit seulement qu'elles n'ont pas été modifiées.

**Modes de fonctionnement :**

| Mode | Chiffre quoi ? | Usage |
|------|---------------|-------|
| **Transport** | Seulement le payload IP (pas l'en-tête) | Communication hôte-à-hôte |
| **Tunnel** | Le paquet IP entier (nouvel en-tête IP ajouté) | Site-to-site (le plus courant) |

#### Algorithmes utilisés

| Fonction | Algorithmes courants | Notes CCNA |
|----------|---------------------|------------|
| Chiffrement | AES-128, AES-256, 3DES (obsolète) | AES-256 = recommandé |
| Hachage/Intégrité | SHA-256, SHA-384, MD5 (obsolète) | SHA-256 = recommandé |
| Authentification | PSK, certificats RSA | PSK = plus simple, certificats = plus sûr |
| Échange de clés | DH Group 14 (2048 bits), DH Group 19 (ECP 256) | Plus le groupe est élevé, plus c'est sûr (et lent) |

#### GRE over IPsec

IPsec seul ne transporte que du trafic unicast IP. Pour du multicast (OSPF, EIGRP) ou du trafic non-IP, on encapsule d'abord dans un tunnel GRE, puis on chiffre avec IPsec :

```
  Paquet OSPF → GRE encapsule → IPsec chiffre → Internet → IPsec déchiffre → GRE décapsule → OSPF
```

C'est la combinaison standard pour les VPN site-to-site qui doivent transporter du trafic de routage dynamique.

### Mise en pratique CLI

L'examen CCNA ne demande pas de *configurer* IPsec, mais vous devez comprendre les concepts. Voici un `show` typique pour illustrer :

```cisco
R1# show crypto isakmp sa
IPv4 Crypto ISAKMP SA
dst             src             state          conn-id status
203.0.113.1     198.51.100.1    QM_IDLE           1001 ACTIVE

R1# show crypto ipsec sa

interface: GigabitEthernet0/0
    Crypto map tag: VPN-MAP, local addr 198.51.100.1

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (192.168.1.0/255.255.255.0/0/0)
   remote ident (addr/mask/prot/port): (10.1.1.0/255.255.255.0/0/0)
   current_peer 203.0.113.1 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 1842, #pkts encrypt: 1842, #pkts digest: 1842
    #pkts decaps: 1756, #pkts decrypt: 1756, #pkts verify: 1756
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0

     inbound esp sas:
      spi: 0xA3B2C1D4(2746679764)
        transform: esp-aes 256 esp-sha256-hmac ,
        in use settings ={Tunnel, }
```

**Interprétation** :
- **ISAKMP SA** : Phase 1 établie entre 203.0.113.1 et 198.51.100.1, état `QM_IDLE` = tunnel actif, prêt à transmettre
- **IPsec SA** : Le trafic entre 192.168.1.0/24 (local) et 10.1.1.0/24 (distant) est protégé
- **Compteurs** : 1842 paquets chiffrés envoyés, 1756 reçus — le tunnel fonctionne
- **Transform** : `esp-aes 256 esp-sha256-hmac` = chiffrement AES-256 + intégrité SHA-256, mode Tunnel

### Point exam

> **Piège courant** : On vous demande la différence entre AH et ESP. AH fournit uniquement l'intégrité et l'authentification — **pas de chiffrement**. ESP fournit les trois (chiffrement + intégrité + authentification). Si la question mentionne la confidentialité, la réponse est ESP.
>
> **À retenir** : IPsec utilise **IKE Phase 1** (négociation du canal sécurisé) et **IKE Phase 2** (négociation du tunnel de données). Le mode **Tunnel** encapsule le paquet entier (site-to-site), le mode **Transport** ne chiffre que le payload (hôte-à-hôte).

### Exercice 5.5 — Identification des composants IPsec

**Contexte** : L'entreprise DuoTech relie son siège (Paris, 198.51.100.0/24) à sa succursale (Lyon, 203.0.113.0/24) via un VPN site-to-site IPsec sur Internet.

**Consigne** : Sur le schéma ci-dessous, identifiez :
1. Les deux endpoints du tunnel
2. Le type de VPN (site-to-site ou remote access)
3. Le protocole IPsec probable (AH ou ESP) et pourquoi
4. Le mode IPsec probable (tunnel ou transport) et pourquoi
5. Quel trafic sera protégé par le tunnel

```
  [LAN Paris]──[R-Paris]════Internet════[R-Lyon]──[LAN Lyon]
  198.51.100.0/24                              203.0.113.0/24
```

**Indice** : <details><summary>Voir l'indice</summary>Entre deux routeurs via Internet, on veut chiffrer ET authentifier. Le paquet IP entier doit être encapsulé car les adresses privées ne sont pas routables sur Internet.</details>

<details>
<summary>Solution</summary>

1. **Endpoints** : R-Paris et R-Lyon (leurs interfaces publiques respectives)
2. **Type** : Site-to-site (deux routeurs reliés de façon permanente)
3. **Protocole** : ESP — car on a besoin de chiffrement (confidentialité) en plus de l'intégrité. AH ne chiffre pas.
4. **Mode** : Tunnel — le paquet IP entier (y compris les adresses sources/destination privées) est encapsulé dans un nouveau paquet IP avec les adresses publiques des routeurs. Indispensable car les adresses 198.51.100.x et 203.0.113.x ne sont pas routables directement via Internet dans un scénario réel avec RFC 1918.
5. **Trafic protégé** : Tout le trafic entre 198.51.100.0/24 et 203.0.113.0/24 (défini par une ACL crypto sur chaque routeur)

</details>

### Voir aussi

- Topic 1.5 dans Module 1 (TCP vs UDP — IPsec utilise UDP 500 pour IKE et UDP 4500 pour NAT-T)
- Topic 4.1 dans Module 4 (NAT — NAT-Traversal est nécessaire quand IPsec traverse du NAT)
- Topic 5.9 dans ce module (WPA2-Enterprise peut utiliser un tunnel TLS)

---

## 5.6 — Listes de contrôle d'accès (ACLs)

> **Exam topic 5.6** : _Configure and verify_ — Access control lists
> **Niveau** : Configure/Verify

### Contexte

Les ACLs sont les gardes-barrières du réseau. Elles décident, paquet par paquet, qui peut entrer et qui doit rester dehors. C'est l'un des sujets les plus testés du CCNA : vous devez non seulement comprendre la logique, mais aussi écrire des ACLs correctes avec les bons wildcard masks, les placer sur la bonne interface et dans la bonne direction.

### Théorie

#### Qu'est-ce qu'une ACL ?

Une ACL est une liste ordonnée de règles (ACE — Access Control Entries) que le routeur consulte séquentiellement pour chaque paquet. Chaque règle dit soit `permit` (autoriser) soit `deny` (refuser). Le routeur parcourt la liste de haut en bas et s'arrête à la première correspondance.

```
  Paquet arrive sur l'interface
         │
         ▼
  ┌─── ACE 1 ───┐    Match ?
  │ permit 10.x │──── Oui ──→ PERMIT (paquet transmis)
  └──────────────┘
         │ Non
         ▼
  ┌─── ACE 2 ───┐    Match ?
  │ deny 172.x  │──── Oui ──→ DENY (paquet jeté)
  └──────────────┘
         │ Non
         ▼
  ┌─── ACE 3 ───┐    Match ?
  │ permit any  │──── Oui ──→ PERMIT
  └──────────────┘
         │ Non
         ▼
  ┌─ Implicit  ─┐
  │ deny any    │──────────→ DENY (paquet jeté silencieusement)
  └─────────────┘
```

Deux règles fondamentales à ne jamais oublier :
1. **Traitement séquentiel** : la première règle qui correspond est appliquée, les suivantes sont ignorées
2. **Deny implicite** : à la fin de toute ACL, il y a un `deny any` invisible. Si aucune règle ne correspond, le paquet est supprimé

#### ACL Standard vs Extended

| Caractéristique | ACL Standard | ACL Extended |
|----------------|-------------|-------------|
| **Critère de filtrage** | Adresse IP source uniquement | Source, destination, protocole, port |
| **Numéros** | 1–99 et 1300–1999 | 100–199 et 2000–2699 |
| **Placement** | Proche de la **destination** | Proche de la **source** |
| **Granularité** | Grossière (tout ou rien par source) | Fine (filtrage par service) |
| **Syntaxe** | `access-list {1-99} {permit|deny} {source} {wildcard}` | `access-list {100-199} {permit|deny} {proto} {src} {wc} {dst} {wc} [eq port]` |

Pourquoi ce placement ? Une ACL standard ne voit que la source. Si on la place proche de la source, on bloque *tout* le trafic de cette source — même vers des destinations légitimes. En la plaçant proche de la destination, on ne bloque que le flux spécifique qu'on cible.

Une ACL extended, en revanche, peut filtrer par source *et* destination *et* port. On peut donc la placer proche de la source pour bloquer précisément le flux indésirable sans impacter les autres, ce qui économise de la bande passante en évitant au trafic inutile de traverser tout le réseau.

#### Les wildcard masks en détail

Le wildcard mask est le concept qui fait trébucher le plus de candidats au CCNA. Il fonctionne à l'inverse du masque de sous-réseau :

- **Bit 0** dans le wildcard = ce bit **doit correspondre** (on vérifie)
- **Bit 1** dans le wildcard = ce bit est **ignoré** (on ne vérifie pas)

Pour convertir un masque de sous-réseau en wildcard mask, soustrayez chaque octet de 255 :

```
  Masque sous-réseau :   255.255.255.0
  Wildcard mask :        0  . 0 . 0 .255

  Calcul par octet :     255 - 255 = 0
                         255 - 255 = 0
                         255 - 255 = 0
                         255 -   0 = 255
```

Voici les conversions les plus courantes :

| Masque sous-réseau | Préfixe | Wildcard mask | Signification |
|-------------------|---------|---------------|---------------|
| 255.255.255.255 | /32 | 0.0.0.0 | Un seul hôte exact |
| 255.255.255.0 | /24 | 0.0.0.255 | Tout un réseau /24 |
| 255.255.0.0 | /16 | 0.0.255.255 | Tout un réseau /16 |
| 255.0.0.0 | /8 | 0.255.255.255 | Tout un réseau /8 |
| 255.255.255.252 | /30 | 0.0.0.3 | Un lien point-to-point (/30) |
| 255.255.255.240 | /28 | 0.0.0.15 | Un sous-réseau de 16 adresses |
| 255.255.255.128 | /25 | 0.0.0.127 | Un demi-réseau /25 |

**Raccourcis syntaxiques importants :**
- `host 10.1.1.5` équivaut à `10.1.1.5 0.0.0.0` (un seul hôte, wildcard tout à zéro)
- `any` équivaut à `0.0.0.0 255.255.255.255` (n'importe quelle adresse)

#### Wildcard masks non contiguës — attention !

Bien que techniquement possible, un wildcard mask non contigu (comme `0.0.0.254` qui vérifie uniquement le dernier bit de chaque octet) est rarement utilisé et **n'apparaît pas au CCNA**. Concentrez-vous sur les wildcard masks contiguës issus de la conversion directe du masque de sous-réseau.

#### Exercice mental : quel réseau correspond ?

Quand vous voyez `192.168.10.0 0.0.0.255` dans une ACL :
1. Prenez l'adresse : `192.168.10.0`
2. Regardez le wildcard : `0.0.0.255` → les trois premiers octets sont fixes, le dernier varie
3. Conclusion : toutes les adresses de `192.168.10.0` à `192.168.10.255` (le réseau 192.168.10.0/24)

Quand vous voyez `172.16.4.0 0.0.3.255` :
1. Adresse : `172.16.4.0`
2. Wildcard : `0.0.3.255` → les deux premiers octets sont fixes, le troisième varie sur 2 bits (3 = 00000011), le quatrième varie librement
3. Conclusion : adresses de `172.16.4.0` à `172.16.7.255` (le réseau 172.16.4.0/22)

#### ACLs numérotées — Standard

```cisco
! Autoriser le réseau 192.168.1.0/24
R1(config)# access-list 10 permit 192.168.1.0 0.0.0.255
! Autoriser un hôte spécifique
R1(config)# access-list 10 permit host 10.0.0.5
! Deny implicite à la fin — pas besoin de l'écrire
! Mais pour la visibilité dans les logs :
R1(config)# access-list 10 deny any log
```

#### ACLs numérotées — Extended

```cisco
! Autoriser le trafic HTTP du réseau 192.168.1.0/24 vers le serveur web 10.0.0.100
R1(config)# access-list 100 permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 80
! Autoriser HTTPS aussi
R1(config)# access-list 100 permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 443
! Autoriser DNS (UDP et TCP)
R1(config)# access-list 100 permit udp any host 10.0.0.53 eq 53
R1(config)# access-list 100 permit tcp any host 10.0.0.53 eq 53
! Autoriser les réponses ICMP (ping)
R1(config)# access-list 100 permit icmp any any echo-reply
! Deny implicite pour tout le reste
R1(config)# access-list 100 deny ip any any log
```

La syntaxe complète d'une ACE extended :

```
access-list {num} {permit|deny} {protocole} {src} {wildcard-src} {dst} {wildcard-dst} [opérateur port]
```

Opérateurs de port : `eq` (égal), `gt` (supérieur), `lt` (inférieur), `neq` (différent), `range` (plage).

#### ACLs nommées (Named ACLs)

Les ACLs nommées offrent deux avantages majeurs :
1. Un nom descriptif au lieu d'un numéro (meilleure lisibilité)
2. La possibilité de supprimer ou insérer des ACEs individuellement (avec les numéros de séquence)

```cisco
R1(config)# ip access-list standard ALLOW-MGMT
R1(config-std-nacl)# permit 192.168.100.0 0.0.0.255
R1(config-std-nacl)# permit host 10.0.0.5
R1(config-std-nacl)# deny any log
R1(config-std-nacl)# exit

R1(config)# ip access-list extended WEB-FILTER
R1(config-ext-nacl)# permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 80
R1(config-ext-nacl)# permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 443
R1(config-ext-nacl)# deny ip any any log
R1(config-ext-nacl)# exit
```

#### Modification d'une ACL nommée

Pour insérer une règle entre deux ACEs existantes :

```cisco
R1# show access-lists WEB-FILTER
Extended IP access list WEB-FILTER
    10 permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq www
    20 permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 443
    30 deny ip any any log

R1(config)# ip access-list extended WEB-FILTER
R1(config-ext-nacl)# 15 permit tcp 192.168.1.0 0.0.0.255 host 10.0.0.100 eq 8080
R1(config-ext-nacl)# exit
```

Le numéro `15` insère la règle entre les séquences 10 et 20. Cela évite de recréer toute l'ACL.

#### Application d'une ACL sur une interface

Une ACL seule ne fait rien tant qu'elle n'est pas appliquée. L'application se fait sur une interface, dans une direction :

```cisco
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip access-group WEB-FILTER in
R1(config-if)# exit

R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip access-group ALLOW-MGMT in
R1(config-if)# exit
```

**Règles d'application :**
- **in** = le paquet est vérifié *en entrant* sur l'interface (avant le routage)
- **out** = le paquet est vérifié *en sortant* de l'interface (après le routage)
- Maximum **une ACL par interface, par direction, par protocole** (une ACL IPv4 in + une ACL IPv4 out = OK)

```
  Direction "in"                    Direction "out"
                                    
  Paquet →→→ [ACL?] →→→ Routage →→→ [ACL?] →→→ Paquet sort
  entre sur              du                      de
  l'interface            routeur                 l'interface
```

#### ACL sur les lignes VTY

Les ACLs peuvent aussi contrôler l'accès distant aux lignes VTY (SSH/Telnet) :

```cisco
R1(config)# access-list 5 permit 192.168.100.0 0.0.0.255
R1(config)# access-list 5 deny any log
R1(config)# line vty 0 4
R1(config-line)# access-class 5 in
R1(config-line)# exit
```

Notez la commande `access-class` (et non `access-group`) sur les lignes VTY.

### Mise en pratique CLI

Scénario complet : le réseau 192.168.10.0/24 (VLAN employés) doit pouvoir accéder au serveur web 10.0.0.100 (HTTP/HTTPS) et au serveur DNS 10.0.0.53, mais rien d'autre. Le réseau 192.168.20.0/24 (VLAN serveurs) doit être accessible uniquement sur ces ports.

```cisco
R1(config)# ip access-list extended EMPLOYEE-TO-SERVERS
R1(config-ext-nacl)# 10 permit tcp 192.168.10.0 0.0.0.255 host 10.0.0.100 eq 80
R1(config-ext-nacl)# 20 permit tcp 192.168.10.0 0.0.0.255 host 10.0.0.100 eq 443
R1(config-ext-nacl)# 30 permit udp 192.168.10.0 0.0.0.255 host 10.0.0.53 eq 53
R1(config-ext-nacl)# 40 permit icmp 192.168.10.0 0.0.0.255 10.0.0.0 0.0.0.255
R1(config-ext-nacl)# 50 deny ip any any log
R1(config-ext-nacl)# exit

R1(config)# interface GigabitEthernet0/0.10
R1(config-subif)# description VLAN 10 - Employes
R1(config-subif)# ip access-group EMPLOYEE-TO-SERVERS in
R1(config-subif)# exit
```

**Vérification :**

```cisco
R1# show access-lists EMPLOYEE-TO-SERVERS
Extended IP access list EMPLOYEE-TO-SERVERS
    10 permit tcp 192.168.10.0 0.0.0.255 host 10.0.0.100 eq www (287 matches)
    20 permit tcp 192.168.10.0 0.0.0.255 host 10.0.0.100 eq 443 (142 matches)
    30 permit udp 192.168.10.0 0.0.0.255 host 10.0.0.53 eq domain (1053 matches)
    40 permit icmp 192.168.10.0 0.0.0.255 10.0.0.0 0.0.0.255 (38 matches)
    50 deny ip any any log (12 matches)
```

**Interprétation** :
- Les compteurs `matches` confirment que l'ACL est active et que du trafic la traverse
- Le DNS (ligne 30) génère beaucoup de hits — c'est normal, chaque requête web déclenche d'abord une résolution DNS
- La ligne 50 (deny) a 12 matches = 12 paquets bloqués. Le mot-clé `log` enverra un message syslog pour chacun, utile pour l'audit

```cisco
R1# show ip interface GigabitEthernet0/0.10
GigabitEthernet0/0.10 is up, line protocol is up
  ...
  Inbound  access list is EMPLOYEE-TO-SERVERS
  Outgoing access list is not set
  ...
```

**Interprétation** : L'ACL est bien appliquée en direction `inbound` sur la sous-interface Gi0/0.10. Aucune ACL en sortie.

### Point exam

> **Piège courant** : L'oubli du **deny implicite**. Si votre ACL ne contient que des `deny`, elle bloque tout car le deny implicite final bloque aussi tout le reste. Il faut *au moins un* `permit` pour que du trafic passe. Inversement, si vous n'écrivez que des `permit`, le deny implicite bloque tout ce qui n'est pas explicitement autorisé.
>
> **À retenir** :
> - ACL standard → proche de la **destination** | ACL extended → proche de la **source**
> - `access-group` = interface | `access-class` = ligne VTY
> - Le wildcard mask est l'inverse du masque de sous-réseau (255 - chaque octet)
> - Numérotation : 1-99 = standard, 100-199 = extended
> - Maximum 1 ACL par interface, par direction, par protocole

### Exercice 5.6a — ACL Standard

**Contexte** : L'entreprise DataFlow a trois réseaux :
- 192.168.1.0/24 — Réseau Administration
- 192.168.2.0/24 — Réseau Employés
- 192.168.3.0/24 — Réseau Serveurs

Le réseau Employés ne doit PAS pouvoir accéder au réseau Serveurs. L'Administration doit pouvoir accéder partout.

**Consigne** : Écrivez une ACL standard nommée `BLOCK-EMPLOYEES` et appliquez-la sur l'interface appropriée de R1 (l'interface Gi0/2 est connectée au réseau Serveurs).

**Indice** : <details><summary>Voir l'indice</summary>Une ACL standard ne filtre que la source. Placez-la proche de la destination (interface vers les serveurs). N'oubliez pas d'autoriser explicitement le trafic que vous voulez laisser passer, car le deny implicite bloquera tout le reste.</details>

<details>
<summary>Solution</summary>

```cisco
R1(config)# ip access-list standard BLOCK-EMPLOYEES
R1(config-std-nacl)# deny 192.168.2.0 0.0.0.255
R1(config-std-nacl)# permit any
R1(config-std-nacl)# exit
R1(config)# interface GigabitEthernet0/2
R1(config-if)# ip access-group BLOCK-EMPLOYEES out
R1(config-if)# exit
```

**Explication** : L'ACL refuse tout trafic provenant de 192.168.2.0/24 (employés), puis autorise tout le reste avec `permit any` (ce qui inclut le réseau Administration). L'application se fait en `out` sur Gi0/2 (vers les serveurs) car c'est une ACL standard — on la place proche de la destination. Le `permit any` est indispensable pour ne pas bloquer l'Administration via le deny implicite.

</details>

### Exercice 5.6b — ACL Extended avec wildcard masks

**Contexte** : L'entreprise WebCorp a la topologie suivante :

```
  [VLAN 10: 172.16.10.0/24]──┐
                               ├──[R1]──[Internet]
  [VLAN 20: 172.16.20.0/24]──┘    │
                                    │
                              [DMZ: 10.0.1.0/24]
                              - Web: 10.0.1.10
                              - DNS: 10.0.1.53
                              - Mail: 10.0.1.25
```

Politique de sécurité :
- VLAN 10 (développeurs) : HTTP/HTTPS vers le serveur Web, DNS, SSH vers tous les serveurs DMZ
- VLAN 20 (marketing) : HTTP/HTTPS vers le serveur Web, DNS uniquement
- Personne ne doit pouvoir faire de ping vers la DMZ
- Tout autre trafic vers la DMZ est interdit

**Consigne** : Écrivez une ACL extended nommée et appliquez-la sur l'interface appropriée. Justifiez le placement.

**Indice** : <details><summary>Voir l'indice</summary>Une ACL extended peut filtrer source, destination et port. Placez-la proche de la source pour économiser la bande passante. Attention à l'ordre des ACEs : traitez d'abord les cas spécifiques avant les règles générales.</details>

<details>
<summary>Solution</summary>

```cisco
! ACL pour VLAN 10 (développeurs)
R1(config)# ip access-list extended DEV-TO-DMZ
R1(config-ext-nacl)# 10 permit tcp 172.16.10.0 0.0.0.255 host 10.0.1.10 eq 80
R1(config-ext-nacl)# 20 permit tcp 172.16.10.0 0.0.0.255 host 10.0.1.10 eq 443
R1(config-ext-nacl)# 30 permit udp 172.16.10.0 0.0.0.255 host 10.0.1.53 eq 53
R1(config-ext-nacl)# 40 permit tcp 172.16.10.0 0.0.0.255 10.0.1.0 0.0.0.255 eq 22
R1(config-ext-nacl)# 50 deny icmp 172.16.10.0 0.0.0.255 10.0.1.0 0.0.0.255
R1(config-ext-nacl)# 60 deny ip any any log
R1(config-ext-nacl)# exit

! ACL pour VLAN 20 (marketing)
R1(config)# ip access-list extended MKT-TO-DMZ
R1(config-ext-nacl)# 10 permit tcp 172.16.20.0 0.0.0.255 host 10.0.1.10 eq 80
R1(config-ext-nacl)# 20 permit tcp 172.16.20.0 0.0.0.255 host 10.0.1.10 eq 443
R1(config-ext-nacl)# 30 permit udp 172.16.20.0 0.0.0.255 host 10.0.1.53 eq 53
R1(config-ext-nacl)# 40 deny icmp 172.16.20.0 0.0.0.255 10.0.1.0 0.0.0.255
R1(config-ext-nacl)# 50 deny ip any any log
R1(config-ext-nacl)# exit

! Application proche de la source (ACL extended)
R1(config)# interface GigabitEthernet0/0.10
R1(config-subif)# ip access-group DEV-TO-DMZ in
R1(config-subif)# exit
R1(config)# interface GigabitEthernet0/0.20
R1(config-subif)# ip access-group MKT-TO-DMZ in
R1(config-subif)# exit
```

**Explication** :
- Deux ACLs séparées car les droits diffèrent entre VLAN 10 et VLAN 20
- Placement en `in` sur les sous-interfaces source (ACL extended = proche de la source)
- La ligne 40 de DEV-TO-DMZ autorise SSH (port 22) vers *tout* le réseau DMZ (wildcard 0.0.0.255)
- Le deny ICMP explicite n'est pas strictement nécessaire (le deny implicite le bloquerait aussi), mais il documente clairement la politique
- Le `log` sur le deny final aide à l'audit et au troubleshooting

</details>

### Voir aussi

- Topic 1.6 dans Module 1 (subnetting et calcul de masques — base pour les wildcard masks)
- Topic 4.1 dans Module 4 (les ACLs NAT utilisent la même syntaxe wildcard)
- Topic 5.7 dans ce module (DHCP snooping et DAI — sécurité L2 complémentaire aux ACLs L3)

---

## 5.7 — Sécurité Layer 2

> **Exam topic 5.7** : _Configure and verify_ — Layer 2 security features (DHCP snooping, dynamic ARP inspection, and port security)
> **Niveau** : Configure/Verify

### Contexte

Les ACLs protègent au niveau IP (Layer 3), mais de nombreuses attaques se produisent au niveau Ethernet (Layer 2) — là où un switch fait confiance aveuglément à toute trame qui arrive. Un attaquant sur le même VLAN peut usurper des adresses MAC, monter un faux serveur DHCP ou empoisonner la table ARP. Les mécanismes de sécurité L2 du switch sont la parade.

### Théorie

#### Port Security

Port security limite le nombre d'adresses MAC autorisées sur un port de switch. Si un port est configuré pour n'accepter qu'une seule MAC et qu'une deuxième apparaît, le switch réagit.

**Pourquoi c'est utile** : empêche un attaquant de brancher un hub ou un mini-switch pour connecter plusieurs machines, ou de faire du MAC flooding (envoi massif de fausses trames pour saturer la table MAC et forcer le switch à fonctionner en hub).

**Modes d'apprentissage des MAC :**

| Mode | Comportement | Persistance |
|------|-------------|-------------|
| **Static** | MAC configurée manuellement par l'admin | Sauvegardée dans running-config |
| **Dynamic** | MAC apprise automatiquement (par défaut) | Perdue au reboot |
| **Sticky** | MAC apprise automatiquement ET ajoutée à la running-config | Persistante si `copy run start` |

**Actions en cas de violation :**

| Mode | Trafic | Compteur | Syslog | État du port |
|------|--------|----------|--------|-------------|
| **Shutdown** (défaut) | Bloqué | Oui | Oui | err-disabled |
| **Restrict** | Bloqué (MAC non autorisée) | Oui | Oui | Up |
| **Protect** | Bloqué (MAC non autorisée) | Non | Non | Up |

Le mode `shutdown` est le plus sûr — le port passe en `err-disabled` et nécessite une intervention manuelle (`shutdown` puis `no shutdown`) pour être réactivé.

#### DHCP Snooping

DHCP snooping protège contre deux attaques :
- **Rogue DHCP server** : un attaquant branche un serveur DHCP non autorisé qui distribue de fausses adresses (fausse passerelle → man-in-the-middle)
- **DHCP starvation** : un attaquant envoie des milliers de DHCP Discover avec des MAC aléatoires pour épuiser le pool

Le mécanisme repose sur la classification des ports en **trusted** (vers le serveur DHCP légitime) et **untrusted** (tous les autres) :

```
                    ┌──────────────┐
  [Serveur DHCP] ───┤ Port TRUSTED │
                    │              │
  [PC légitime] ───┤ Port untrust │   Switch avec
                    │              │   DHCP Snooping
  [PC légitime] ───┤ Port untrust │
                    │              │
  [Attaquant]   ───┤ Port untrust │
                    └──────────────┘
```

**Comportement :**
- Sur un port **untrusted** : le switch bloque les messages DHCP *serveur* (OFFER, ACK) — seul un vrai serveur peut envoyer ces messages, et il est sur un port trusted
- Sur un port **trusted** : tous les messages DHCP passent
- Le switch construit une **DHCP snooping binding table** qui associe chaque adresse IP à une adresse MAC, un port et un VLAN

Cette binding table est précieuse : elle sert aussi de base à **Dynamic ARP Inspection** (DAI).

#### Dynamic ARP Inspection (DAI)

ARP est un protocole sans authentification — n'importe qui peut envoyer une réponse ARP gratuite (gratuitous ARP) pour associer son adresse MAC à l'adresse IP de la passerelle. C'est l'attaque **ARP spoofing** (ou ARP poisoning).

DAI vérifie chaque paquet ARP reçu sur un port untrusted en le comparant à la **DHCP snooping binding table** :
- Si l'association IP-MAC du paquet ARP correspond à la table → le paquet est transmis
- Sinon → le paquet est supprimé et un log est généré

DAI nécessite que DHCP snooping soit activé au préalable (pour construire la binding table).

### Mise en pratique CLI

#### Configuration de Port Security

```cisco
SW1(config)# interface GigabitEthernet0/1
SW1(config-if)# switchport mode access
SW1(config-if)# switchport port-security
SW1(config-if)# switchport port-security maximum 2
SW1(config-if)# switchport port-security mac-address sticky
SW1(config-if)# switchport port-security violation restrict
SW1(config-if)# exit
```

**Vérification :**

```cisco
SW1# show port-security interface GigabitEthernet0/1
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Restrict
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 2
Total MAC Addresses        : 1
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 1
Last Source Address:Vlan   : 00ab.cd12.3456:10
Security Violation Count   : 0
```

**Interprétation** : Le port est actif (`Secure-up`), une MAC a été apprise en sticky. Le maximum est de 2 — une deuxième MAC est encore acceptée. En cas de violation, le mode `Restrict` bloque le trafic de la MAC non autorisée sans désactiver le port.

#### Configuration de DHCP Snooping

```cisco
! Activer DHCP snooping globalement
SW1(config)# ip dhcp snooping
! Activer sur le VLAN 10
SW1(config)# ip dhcp snooping vlan 10
! Désactiver l'insertion du champ Option 82 (recommandé avec un serveur DHCP externe)
SW1(config)# no ip dhcp snooping information option

! Configurer le port du serveur DHCP comme trusted
SW1(config)# interface GigabitEthernet0/24
SW1(config-if)# ip dhcp snooping trust
SW1(config-if)# exit

! Les ports clients restent untrusted (par défaut)
! Optionnel : limiter le débit DHCP par port (anti-starvation)
SW1(config)# interface range GigabitEthernet0/1-23
SW1(config-if-range)# ip dhcp snooping limit rate 10
SW1(config-if-range)# exit
```

**Vérification :**

```cisco
SW1# show ip dhcp snooping
Switch DHCP snooping is enabled
DHCP snooping is configured on following VLANs:
10
DHCP snooping is operational on following VLANs:
10
Insertion of option 82 is disabled
Interface                  Trusted    Allow number   Rate limit
-----------------------    -------    ------------   ----------
GigabitEthernet0/24        yes        unlimited      unlimited
GigabitEthernet0/1         no         1              10
GigabitEthernet0/2         no         1              10
...
```

```cisco
SW1# show ip dhcp snooping binding
MacAddress          IpAddress       Lease(sec)  Type           VLAN  Interface
------------------  --------------- ----------  -------------- ----  ---------
00:AB:CD:12:34:56   192.168.10.101  86326       dhcp-snooping  10   Gi0/1
00:AB:CD:12:34:78   192.168.10.102  85142       dhcp-snooping  10   Gi0/2
00:AB:CD:12:34:9A   192.168.10.103  84891       dhcp-snooping  10   Gi0/3
```

**Interprétation** : La binding table montre trois associations MAC-IP-VLAN-port apprises dynamiquement. Le port Gi0/24 est trusted (serveur DHCP). Les autres sont limités à 10 paquets DHCP par seconde — un client normal en envoie 4 maximum par cycle (DORA).

#### Configuration de DAI

```cisco
! Activer DAI sur le VLAN 10
SW1(config)# ip arp inspection vlan 10

! Le port trunk ou uplink vers le routeur/serveur doit être trusted
SW1(config)# interface GigabitEthernet0/24
SW1(config-if)# ip arp inspection trust
SW1(config-if)# exit
```

**Vérification :**

```cisco
SW1# show ip arp inspection vlan 10
 Source Mac Validation      : Disabled
 Destination Mac Validation : Disabled
 IP Address Validation      : Disabled

 Vlan  Configuration  Operation  ACL Match          Static ACL
 ----  -------------  ---------  ---------          ----------
   10  Enabled        Active

 Vlan  ACL Logging   DHCP Logging  Probe Logging
 ----  -----------   ------------  -------------
   10  Deny          Deny          Off

SW1# show ip arp inspection statistics vlan 10
 Vlan  Forwarded  Dropped  DHCP Drops  ACL Drops
 ----  ---------  -------  ----------  ---------
   10       1247        3           3          0
```

**Interprétation** : DAI est actif sur le VLAN 10. Trois paquets ARP ont été rejetés car ils ne correspondaient pas à la binding table DHCP snooping — possiblement une tentative d'ARP spoofing ou un poste avec une IP statique non enregistrée.

### Point exam

> **Piège courant** : DHCP snooping doit être activé **avant** DAI. DAI dépend de la binding table construite par DHCP snooping. L'examen peut proposer un scénario où DAI est configuré mais DHCP snooping ne l'est pas — résultat : DAI ne fonctionne pas correctement.
>
> **À retenir** :
> - Port security nécessite que le port soit en mode `access` (pas trunk)
> - Par défaut, tous les ports sont **untrusted** pour DHCP snooping et DAI
> - Un port err-disabled par port security nécessite `shutdown` puis `no shutdown` pour être réactivé
> - `access-class` sur VTY ≠ port security sur un port physique — ce sont deux mécanismes différents

### Exercice 5.7 — Sécurisation d'un switch d'accès

**Contexte** : Le switch SW-Access dessert 20 postes de travail (ports Gi0/1 à Gi0/20) et est connecté au switch de distribution via le port Gi0/24 (trunk). Le serveur DHCP est derrière le switch de distribution.

**Consigne** :
1. Activez port security sur les ports Gi0/1 à Gi0/20 : maximum 1 MAC, mode sticky, violation shutdown
2. Activez DHCP snooping sur le VLAN 10 avec le port Gi0/24 en trusted
3. Limitez le débit DHCP à 5 paquets/seconde sur les ports d'accès
4. Activez DAI sur le VLAN 10 avec le port Gi0/24 en trusted

**Indice** : <details><summary>Voir l'indice</summary>Pour port security, les ports doivent d'abord être en mode access. Pensez à utiliser `interface range` pour configurer les 20 ports en une fois. N'oubliez pas `no ip dhcp snooping information option` si le serveur DHCP est sur un autre switch.</details>

<details>
<summary>Solution</summary>

```cisco
! Port security sur les ports d'accès
SW-Access(config)# interface range GigabitEthernet0/1-20
SW-Access(config-if-range)# switchport mode access
SW-Access(config-if-range)# switchport access vlan 10
SW-Access(config-if-range)# switchport port-security
SW-Access(config-if-range)# switchport port-security maximum 1
SW-Access(config-if-range)# switchport port-security mac-address sticky
SW-Access(config-if-range)# switchport port-security violation shutdown
SW-Access(config-if-range)# exit

! DHCP Snooping
SW-Access(config)# ip dhcp snooping
SW-Access(config)# ip dhcp snooping vlan 10
SW-Access(config)# no ip dhcp snooping information option
SW-Access(config)# interface GigabitEthernet0/24
SW-Access(config-if)# ip dhcp snooping trust
SW-Access(config-if)# exit
SW-Access(config)# interface range GigabitEthernet0/1-20
SW-Access(config-if-range)# ip dhcp snooping limit rate 5
SW-Access(config-if-range)# exit

! DAI
SW-Access(config)# ip arp inspection vlan 10
SW-Access(config)# interface GigabitEthernet0/24
SW-Access(config-if)# ip arp inspection trust
SW-Access(config-if)# exit
```

**Explication** : La combinaison port security + DHCP snooping + DAI forme un trio défensif complet au niveau L2. Port security empêche le MAC flooding et les connexions non autorisées. DHCP snooping bloque les rogue DHCP servers et construit la binding table. DAI utilise cette binding table pour empêcher l'ARP spoofing. Le port Gi0/24 (uplink) est trusted pour les trois mécanismes car le trafic légitime (DHCP replies, ARP du routeur) arrive par là.

</details>

### Voir aussi

- Topic 4.3 et 4.6 dans Module 4 (fonctionnement DHCP — DORA, relay)
- Topic 2.1 dans Module 2 (VLANs — DHCP snooping est activé par VLAN)
- Topic 5.6 dans ce module (ACLs — sécurité L3 complémentaire à la sécurité L2)

---

## 5.8 — AAA : Authentication, Authorization, Accounting

> **Exam topic 5.8** : _Compare_ — Authentication, authorization, and accounting concepts
> **Niveau** : Compare

### Contexte

Avec 5 routeurs et 3 switches, gérer les mots de passe localement reste faisable. Mais quand le réseau grossit à 200 équipements et 50 administrateurs, mettre à jour les mots de passe un par un devient un cauchemar. AAA centralise la gestion des accès — un seul serveur contrôle qui peut se connecter, ce qu'il peut faire, et ce qu'il a fait.

### Théorie

#### Les trois A

| Composant | Question | Fonction | Exemple concret |
|-----------|----------|----------|-----------------|
| **Authentication** | Qui êtes-vous ? | Vérifier l'identité de l'utilisateur | Login/password, certificat, biométrie |
| **Authorization** | Qu'avez-vous le droit de faire ? | Définir les permissions après authentification | Privilège 15 vs lecture seule, commandes autorisées |
| **Accounting** | Qu'avez-vous fait ? | Enregistrer les actions pour audit et facturation | Heure de connexion, commandes exécutées, durée de session |

L'analogie est celle d'un aéroport : au contrôle d'identité, on vérifie votre passeport (**authentication**). Votre carte d'embarquement détermine quelle zone vous pouvez accéder (**authorization**). Les caméras et journaux enregistrent vos déplacements (**accounting**).

#### TACACS+ vs RADIUS

Deux protocoles permettent la communication entre l'équipement réseau (NAS — Network Access Server) et le serveur AAA :

| Caractéristique | TACACS+ | RADIUS |
|----------------|---------|--------|
| **Développé par** | Cisco (propriétaire) | IETF (standard ouvert) |
| **Transport** | TCP port 49 | UDP ports 1645/1646 ou 1812/1813 |
| **Chiffrement** | Paquet entier chiffré | Seulement le mot de passe chiffré |
| **Séparation AAA** | Oui (Authentication, Authorization et Accounting sont séparés) | Non (Authentication et Authorization combinés) |
| **Granularité authorization** | Par commande (ex: autoriser `show` mais pas `configure terminal`) | Par service (ex: accès Shell, accès VPN) |
| **Usage typique** | Administration des équipements réseau (CLI) | Accès réseau utilisateur (Wi-Fi, VPN, 802.1X) |
| **Multiprotocole** | Non (IP uniquement) | Oui (PPP, 802.1X, etc.) |

**Quand choisir lequel ?**
- **TACACS+** pour l'administration des routeurs et switches : la séparation AAA et le contrôle par commande sont essentiels pour les audits de conformité
- **RADIUS** pour l'authentification des utilisateurs réseau : le support multi-protocole est indispensable pour le Wi-Fi (802.1X) et le VPN

```
  ┌──────────────┐          TACACS+ (TCP 49)         ┌───────────────┐
  │ Routeur R1   │──────── (admin CLI) ──────────────│               │
  │              │                                    │  Serveur AAA  │
  │ Switch SW1   │──────── (admin CLI) ──────────────│  (ISE/ACS)    │
  │              │                                    │               │
  │ WLC          │──────── RADIUS (UDP 1812/1813) ───│               │
  │              │          (Wi-Fi users 802.1X)      │               │
  └──────────────┘                                    └───────────────┘
```

#### AAA local vs serveur

| Aspect | AAA Local | AAA Serveur (TACACS+/RADIUS) |
|--------|----------|------------------------------|
| Base de données | Sur chaque équipement (`username ... secret`) | Centralisée sur le serveur AAA |
| Scalabilité | Faible (N équipements × M utilisateurs) | Forte (un seul point de gestion) |
| Fallback | Toujours disponible | Nécessite un fallback local en cas de panne serveur |
| Audit | Limité (syslog local) | Centralisé (accounting détaillé) |
| Coût | Gratuit | Serveur dédié (Cisco ISE, FreeRADIUS) |

En production, on configure généralement le serveur AAA comme méthode primaire et l'authentification locale comme **fallback** en cas d'inaccessibilité du serveur :

```cisco
R1(config)# aaa new-model
R1(config)# aaa authentication login default group tacacs+ local
```

Cette ligne signifie : essayer TACACS+ d'abord ; si le serveur est injoignable, utiliser la base locale.

### Mise en pratique CLI

Configuration AAA avec TACACS+ et fallback local :

```cisco
R1(config)# aaa new-model
R1(config)# tacacs server ISE-SERVER
R1(config-server-tacacs)# address ipv4 10.0.0.50
R1(config-server-tacacs)# key T@c@csK3y!
R1(config-server-tacacs)# exit
R1(config)# aaa authentication login default group tacacs+ local
R1(config)# aaa authorization exec default group tacacs+ local
R1(config)# aaa accounting exec default start-stop group tacacs+
```

**Vérification :**

```cisco
R1# show aaa servers

TACACS+ Server Group: (default)
    Server: ISE-SERVER
        Address: 10.0.0.50/49
        Status: ALIVE
        Authen: request 47, timeouts 0, failover 0, retransmission 0
                Response: accept 42, reject 5, error 0
        Author: request 42, timeouts 0, failover 0, retransmission 0
                Response: accept 42, reject 0, error 0
        Acct:   request 42, timeouts 0, failover 0, retransmission 0
                Response: success 42, error 0
```

**Interprétation** : Le serveur TACACS+ est `ALIVE` et répond. Sur 47 tentatives d'authentification, 42 ont été acceptées et 5 rejetées (probablement des mots de passe incorrects). Zéro timeout = la connectivité est bonne.

### Point exam

> **Piège courant** : L'examen demande souvent "quel protocole AAA chiffre le paquet entier ?". La réponse est **TACACS+**. RADIUS ne chiffre que le mot de passe — le reste du paquet (username, attributs d'authorization) est en clair.
>
> **À retenir** :
> - TACACS+ = **TCP 49**, paquet entier chiffré, AAA **séparés**, contrôle **par commande** → administration réseau
> - RADIUS = **UDP 1812/1813**, mot de passe seul chiffré, Auth+Authz **combinés** → accès utilisateur (Wi-Fi, VPN)
> - `aaa new-model` est obligatoire pour activer AAA sur un équipement Cisco

### Exercice 5.8 — Association AAA et protocoles

**Contexte** : L'entreprise SecureNet déploie un serveur Cisco ISE pour centraliser la gestion des accès.

**Consigne** : Pour chaque scénario, indiquez le protocole recommandé (TACACS+ ou RADIUS) et justifiez.

| Scénario | Protocole | Justification |
|----------|-----------|--------------|
| Les admins réseau se connectent en SSH aux routeurs | | |
| Les employés s'authentifient sur le Wi-Fi WPA2-Enterprise | | |
| On veut journaliser chaque commande tapée par un admin | | |
| Les consultants externes se connectent au VPN AnyConnect | | |
| On veut autoriser uniquement `show` (pas `configure`) pour les juniors | | |

**Indice** : <details><summary>Voir l'indice</summary>TACACS+ excelle pour le contrôle granulaire des administrateurs (par commande). RADIUS est le standard pour l'accès réseau des utilisateurs (Wi-Fi, VPN, 802.1X).</details>

<details>
<summary>Solution</summary>

| Scénario | Protocole | Justification |
|----------|-----------|--------------|
| Admins SSH vers routeurs | **TACACS+** | Contrôle granulaire des commandes, chiffrement total du paquet, séparation AAA |
| Wi-Fi WPA2-Enterprise | **RADIUS** | Seul protocole supporté par le standard 802.1X |
| Journalisation commandes admin | **TACACS+** | Accounting séparé et granulaire (par commande exécutée, pas juste la session) |
| VPN AnyConnect | **RADIUS** | Standard pour l'authentification d'accès réseau, supporte les attributs VPN |
| Autoriser uniquement `show` pour les juniors | **TACACS+** | Authorization par commande = exactement ce qu'il faut pour ce scénario |

</details>

### Voir aussi

- Topic 5.3 dans ce module (mots de passe locaux — le "fallback" quand le serveur AAA est indisponible)
- Topic 2.8 dans Module 2 (TACACS+/RADIUS mentionnés parmi les méthodes de gestion)
- Topic 5.10 dans ce module (WPA2-Enterprise utilise RADIUS pour le 802.1X)

---

## 5.9 — Sécurité Wi-Fi : WPA, WPA2, WPA3

> **Exam topic 5.9** : _Describe_ — Wireless security protocols (WPA, WPA2, and WPA3)
> **Niveau** : Describe

### Contexte

Le Wi-Fi diffuse les données dans les airs — littéralement. Contrairement à un câble Ethernet enfermé dans un faux plancher, un signal radio traverse les murs et peut être capté depuis le parking de l'entreprise. Le chiffrement wireless n'est pas une option : c'est une nécessité absolue.

### Théorie

#### Évolution des protocoles de sécurité Wi-Fi

| Protocole | Année | Chiffrement | Taille clé | Authentification | Statut |
|-----------|-------|-------------|-----------|------------------|--------|
| **WEP** | 1999 | RC4 | 64/128 bits | Clé partagée | Cassé (2004) — **ne jamais utiliser** |
| **WPA** | 2003 | TKIP (RC4 amélioré) | 128 bits | PSK ou 802.1X | Obsolète — vulnérable |
| **WPA2** | 2004 | AES-CCMP | 128 bits | PSK ou 802.1X | Standard actuel |
| **WPA3** | 2018 | AES-GCMP | 128/256 bits | SAE ou 802.1X | Recommandé |

#### WPA2 — Le standard dominant

WPA2 existe en deux modes :

**WPA2-Personal (PSK — Pre-Shared Key)**
- Un mot de passe partagé (8-63 caractères) est configuré sur l'AP et connu de tous les utilisateurs
- Le mot de passe sert à dériver une clé de chiffrement via un échange à 4 étapes (4-way handshake)
- Adapté aux petites structures et au réseau invité
- Faiblesse : si le PSK est compromis, tout le monde est affecté

**WPA2-Enterprise (802.1X)**
- Chaque utilisateur s'authentifie avec ses propres identifiants (login/password, certificat)
- Un serveur RADIUS vérifie l'identité et fournit une clé unique par session
- Adapté aux entreprises (chaque employé a ses identifiants, révocables individuellement)
- Plus complexe à déployer (nécessite un serveur RADIUS comme Cisco ISE)

```
  WPA2-Personal                      WPA2-Enterprise

  [Client] ←──PSK partagé──→ [AP]   [Client] ←──EAP──→ [AP] ←──RADIUS──→ [ISE]
                                                          │
                                             Clé unique par session
```

#### WPA3 — Les améliorations

WPA3 corrige les faiblesses connues de WPA2 :

| Amélioration | WPA2 | WPA3 | Bénéfice |
|-------------|------|------|----------|
| **Échange de clés** | 4-way handshake (PSK) | SAE (Simultaneous Authentication of Equals) | Résiste aux attaques de dictionnaire offline |
| **Forward secrecy** | Non | Oui (Perfect Forward Secrecy) | Même si le PSK est compromis plus tard, le trafic passé reste chiffré |
| **Protection cadres mgmt** | Non (optionnel PMF) | Oui (PMF obligatoire) | Empêche les attaques de deauthentication |
| **Chiffrement ouvert** | Réseau ouvert = pas de chiffrement | OWE (Opportunistic Wireless Encryption) | Même un réseau "ouvert" (café, aéroport) est chiffré |
| **Suite cryptographique Enterprise** | AES-CCMP 128 bits | AES-GCMP 192 bits (mode 192-bit) | Sécurité renforcée pour les organisations sensibles |

**SAE (Simultaneous Authentication of Equals)** remplace le 4-way handshake de WPA2-Personal. Avec WPA2, un attaquant pouvait capturer le handshake et tenter un brute force *offline* (avec un dictionnaire de mots de passe). SAE utilise un échange Diffie-Hellman qui empêche cette attaque — même en capturant l'échange, l'attaquant ne peut pas tester de mots de passe offline.

**PMF (Protected Management Frames)** protège les trames de gestion Wi-Fi (deauthentication, disassociation). Sans PMF, un attaquant peut envoyer de fausses trames de déconnexion pour forcer un client à se réauthentifier — et capturer le handshake au passage.

### Mise en pratique CLI

La configuration Wi-Fi se fait généralement sur le WLC (GUI), mais voici comment vérifier la sécurité d'un SSID :

```cisco
WLC# show wlan summary
Number of WLANs: 3

WLAN ID  WLAN Profile Name       Status    Interface Name
-------  ----------------------  --------  ----------------
1        CORP-WIFI               Enabled   management
2        GUEST-WIFI              Enabled   guest-vlan
3        IOT-DEVICES             Enabled   iot-vlan

WLC# show wlan 1
WLAN Identifier.................. 1
Profile Name..................... CORP-WIFI
Network Name (SSID).............. CORP-WIFI
Status........................... Enabled
...
Security
  802.11 Authentication............ Open System
  FT Support...................... Enabled
  ...
  WPA/WPA2/WPA3 Parameters
    WPA2.......................... Enabled
    WPA3.......................... Enabled
    Auth Key Management
      802.1X...................... Enabled
      PSK......................... Disabled
      SAE......................... Enabled
    Encryption
      AES-CCMP128................. Enabled
      AES-GCMP256................. Enabled
...
```

**Interprétation** : Le SSID `CORP-WIFI` utilise WPA2 et WPA3 simultanément (mode transitoire pour compatibilité). L'authentification est 802.1X (Enterprise) avec SAE activé. Le PSK est désactivé — conforme à une politique d'entreprise. Les deux chiffrements (CCMP pour WPA2, GCMP pour WPA3) sont actifs.

### Point exam

> **Piège courant** : WPA utilise **TKIP** (basé sur RC4), WPA2 utilise **AES-CCMP**, WPA3 utilise **AES-GCMP**. L'examen peut mélanger les associations protocole/chiffrement — ne confondez pas.
>
> **À retenir** :
> - WEP = cassé = jamais. WPA = TKIP = obsolète. WPA2 = AES-CCMP = standard. WPA3 = AES-GCMP + SAE = recommandé
> - PSK = même mot de passe pour tout le monde | 802.1X = identifiants individuels via RADIUS
> - WPA3-Personal utilise **SAE** au lieu du 4-way handshake (anti-dictionnaire offline)
> - WPA3 impose **PMF** (Protected Management Frames) obligatoire

### Exercice 5.9 — Comparaison des protocoles Wi-Fi

**Contexte** : L'école TechAcademy a trois besoins Wi-Fi :
- Réseau administratif (secrétariat, direction) — données sensibles
- Réseau pédagogique (salles de cours) — accès étudiant contrôlé
- Réseau invité (hall d'accueil) — accès Internet libre

**Consigne** : Pour chaque réseau, recommandez le protocole de sécurité Wi-Fi le plus adapté (WPA2-Personal, WPA2-Enterprise, WPA3-Personal, WPA3-Enterprise, ou réseau ouvert avec OWE). Justifiez chaque choix.

**Indice** : <details><summary>Voir l'indice</summary>Considérez la sensibilité des données, le nombre d'utilisateurs, la facilité de gestion (un PSK partagé est-il acceptable pour 500 étudiants ?), et la compatibilité des équipements.</details>

<details>
<summary>Solution</summary>

| Réseau | Protocole recommandé | Justification |
|--------|---------------------|---------------|
| Administratif | **WPA3-Enterprise** (ou WPA2-Enterprise si incompatibilité matérielle) | Données sensibles (dossiers élèves, paie). Chaque membre du personnel a ses identifiants — révocables si quelqu'un quitte l'établissement. AES-GCMP 192 bits pour la confidentialité maximale. |
| Pédagogique | **WPA2-Enterprise** (802.1X) | 500 étudiants — un PSK serait partagé et diffusé en quelques jours. Avec 802.1X, chaque étudiant a son compte (lié au LDAP de l'école), et l'accès est automatiquement révoqué en fin d'année. WPA3 serait idéal mais les appareils étudiants ne le supportent pas tous. |
| Invité | **WPA3-OWE** (ou portail captif sur réseau ouvert) | L'accès doit être simple (pas de mot de passe à communiquer). OWE chiffre le trafic sans demander de mot de passe — invisible pour l'utilisateur. Si les appareils ne supportent pas OWE, un portail captif avec conditions d'utilisation suffit. |

</details>

### Voir aussi

- Topic 5.8 dans ce module (RADIUS — nécessaire pour WPA2/WPA3-Enterprise)
- Topic 2.6 dans Module 2 (architectures wireless et modes AP)
- Topic 5.10 dans ce module (configuration concrète WPA2-PSK via GUI)
- Topic 1.11 dans Module 1 (principes wireless — canaux, SSID, RF, chiffrement)

---

## 5.10 — Configuration WLAN WPA2 PSK via GUI

> **Exam topic 5.10** : _Configure and verify_ — WLAN within the GUI using WPA2 PSK
> **Niveau** : Configure/Verify

### Contexte

Cisco attend des candidats CCNA qu'ils sachent configurer un SSID sur un WLC (Wireless LAN Controller) via l'interface graphique. Cette section décrit les étapes concrètes, écran par écran, pour créer un réseau Wi-Fi WPA2-Personal fonctionnel.

### Théorie

#### Prérequis

Avant de créer un WLAN sur le WLC, vérifiez :
- Le WLC est opérationnel et les APs sont associés
- Les VLANs et interfaces dynamiques sont configurés (un VLAN par SSID)
- Le serveur DHCP est fonctionnel pour le VLAN cible

#### Étapes de configuration sur le WLC GUI

**Étape 1 : Créer le WLAN**
- Menu : **WLANs** → **Create New** → **Go**
- Renseigner :
  - **Profile Name** : `OFFICE-WIFI` (nom interne d'administration)
  - **SSID** : `OFFICE-WIFI` (nom visible par les clients)
  - **ID** : numéro unique (1-512)

**Étape 2 : Paramètres généraux**
- Onglet **General** :
  - **Status** : Enabled
  - **Interface/Interface Group** : sélectionner l'interface VLAN associée (ex: `vlan-office`)
  - **Broadcast SSID** : Enabled (désactiver ne renforce pas réellement la sécurité)

**Étape 3 : Configurer la sécurité**
- Onglet **Security** → sous-onglet **Layer 2** :
  - **Layer 2 Security** : `WPA+WPA2`
  - **WPA2 Policy** : coché
  - **WPA2 Encryption** : `AES`
  - **Auth Key Mgmt** : `PSK`
  - **PSK Format** : `ASCII`
  - **Pre-Shared Key** : entrer le mot de passe (8-63 caractères)

**Étape 4 : Paramètres avancés (optionnels)**
- Onglet **Advanced** :
  - **FlexConnect Local Switching** : activer si les APs sont en mode FlexConnect
  - **Session Timeout** : durée maximale d'une session (1800 sec = 30 min par défaut)
  - **Client Exclusion** : activer pour bloquer temporairement les clients qui échouent l'authentification

**Étape 5 : Appliquer et vérifier**
- Cliquer **Apply**
- Vérifier dans **WLANs** que le nouveau SSID apparaît avec le statut **Enabled**
- Vérifier dans **Monitor** → **Clients** qu'un client parvient à s'associer

#### Représentation des écrans WLC

```
┌─────────────────────────────────────────────────────────┐
│  Cisco WLC — WLANs > Edit 'OFFICE-WIFI'                │
├─────────────────────────────────────────────────────────┤
│  General │ Security │ QoS │ Policy │ Advanced           │
├──────────┴──────────────────────────────────────────────┤
│                                                         │
│  Profile Name:    [OFFICE-WIFI          ]               │
│  SSID:            [OFFICE-WIFI          ]               │
│  Status:          [■ Enabled            ]               │
│  Interface:       [vlan-office     ▼    ]               │
│  Broadcast SSID:  [■ Enabled            ]               │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  Security > Layer 2                                     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Layer 2 Security: [WPA+WPA2       ▼    ]               │
│                                                         │
│  WPA2 Parameters:                                       │
│    ☑ WPA2 Policy                                        │
│    Encryption:     [AES            ▼    ]               │
│                                                         │
│  Auth Key Mgmt:    [PSK            ▼    ]               │
│  PSK Format:       [ASCII          ▼    ]               │
│  Pre-Shared Key:   [••••••••••••••••    ]               │
│                                                         │
│                            [ Apply ]  [ Cancel ]        │
└─────────────────────────────────────────────────────────┘
```

### Mise en pratique CLI

Même si la configuration se fait via GUI, la vérification CLI est indispensable :

```cisco
WLC# show wlan 4

WLAN Identifier.................. 4
Profile Name..................... OFFICE-WIFI
Network Name (SSID).............. OFFICE-WIFI
Status........................... Enabled
MAC Filtering.................... Disabled
Broadcast SSID................... Enabled
...
Interface........................ vlan-office
...
Security
  802.11 Authentication........... Open System
  Static WEP Keys................. Disabled
  Wi-Fi Protected Access (WPA/WPA2)
    WPA (SSN IE).................. Disabled
    WPA2 (RSN IE)................. Enabled
      TKIP Cipher................. Disabled
      AES-CCMP128 Cipher.......... Enabled
  Auth Key Management
    802.1x........................ Disabled
    PSK........................... Enabled
    CCKM.......................... Disabled
...
Number of Active Clients......... 14
```

**Interprétation** :
- WPA2 avec AES-CCMP activé, TKIP désactivé (conforme aux bonnes pratiques)
- Authentification PSK (pas 802.1X) — c'est bien du WPA2-Personal
- 14 clients actifs — le SSID fonctionne
- Le SSID est broadcasté (visible par les clients qui scannent)

### Point exam

> **Piège courant** : L'examen peut montrer une capture d'écran du WLC GUI où WPA et WPA2 sont tous les deux cochés. C'est un mode de compatibilité (transition). Mais si la question demande "quel est le protocole de sécurité le plus fort configuré ?", la réponse est **WPA2** (pas WPA). WPA seul avec TKIP est insuffisant.
>
> **À retenir** :
> - WPA2-PSK nécessite un mot de passe de **8 à 63 caractères** ASCII
> - Le chiffrement doit être **AES** (pas TKIP pour WPA2)
> - Le SSID est associé à une **interface VLAN** sur le WLC
> - Chaque WLAN a un **ID unique** et un **profile name**

### Exercice 5.10 — Configuration WLAN sur captures GUI

**Contexte** : Le WLC de l'hôtel GrandStay doit être configuré avec un SSID invité `GUEST-STAY` en WPA2-PSK avec le mot de passe `Welcome2Hotel!`, associé à l'interface VLAN `guest-vlan`.

**Consigne** : Listez dans l'ordre les paramètres à configurer dans chaque onglet du WLC GUI (General, Security).

**Indice** : <details><summary>Voir l'indice</summary>Suivez les 5 étapes décrites dans la théorie. L'onglet QoS peut rester à `Silver` (best effort) pour un réseau invité.</details>

<details>
<summary>Solution</summary>

**Onglet General :**
- Profile Name : `GUEST-STAY`
- SSID : `GUEST-STAY`
- Status : Enabled
- Interface : `guest-vlan`
- Broadcast SSID : Enabled

**Onglet Security > Layer 2 :**
- Layer 2 Security : `WPA+WPA2`
- WPA2 Policy : coché
- WPA2 Encryption : `AES`
- Auth Key Mgmt : `PSK`
- PSK Format : `ASCII`
- Pre-Shared Key : `Welcome2Hotel!`

**Onglet QoS :**
- Quality of Service : `Silver` (best effort — adapté aux invités)

**Onglet Advanced :**
- Session Timeout : `3600` (1 heure — limite raisonnable pour un invité)
- FlexConnect Local Switching : selon l'architecture de l'hôtel

**Vérification :** se connecter depuis un smartphone au SSID `GUEST-STAY` avec le mot de passe, confirmer l'obtention d'une adresse IP et la connectivité Internet.

</details>

### Voir aussi

- Topic 5.9 dans ce module (théorie WPA/WPA2/WPA3 — pourquoi ces choix)
- Topic 2.9 dans Module 2 (interprétation de la GUI WLC — WLAN creation, QoS profiles)
- Topic 2.7 dans Module 2 (connexions physiques des composants WLAN)

---

## 5.11 — Machine Learning pour la sécurité réseau

> **Exam topic 5.11** : _Describe_ — The use of Machine Learning for network security *(NOUVEAU v1.1)*
> **Niveau** : Describe

### Contexte

Les réseaux modernes génèrent des millions d'événements par jour — logs, alertes, flux de trafic. Aucun humain ne peut tout analyser en temps réel. Le Machine Learning (ML) et l'intelligence artificielle (IA) permettent aux systèmes de sécurité de détecter des schémas anormaux que les règles statiques (ACLs, signatures) ne peuvent pas repérer.

### Théorie

#### Pourquoi le ML en sécurité réseau ?

La sécurité traditionnelle repose sur des **signatures** : des patterns connus d'attaques. Un IPS classique compare le trafic à une base de signatures (comme un antivirus compare les fichiers à une base de virus connus). Le problème : les attaques inédites (zero-day) n'ont pas de signature.

Le ML apporte une approche complémentaire basée sur le **comportement** :
- Il apprend ce qui est "normal" pour un réseau (volumes de trafic, horaires d'activité, protocoles utilisés)
- Il détecte les **anomalies** — des écarts significatifs par rapport à la baseline
- Il peut identifier des menaces inconnues que les signatures ne couvrent pas

L'analogie : un agent de sécurité dans un centre commercial. L'approche par signatures, c'est avoir une liste de visages de voleurs connus. L'approche ML, c'est observer les comportements suspects — quelqu'un qui fait des allers-retours devant les caisses sans rien acheter n'est sur aucune liste, mais son comportement sort de la norme.

#### Applications concrètes du ML en sécurité réseau

| Application | Fonctionnement | Exemple produit Cisco |
|-------------|---------------|----------------------|
| **Détection d'anomalies de trafic** | Le ML établit une baseline du trafic normal et alerte sur les écarts (pic de trafic inhabituel, protocole rare) | Cisco Stealthwatch / Secure Network Analytics |
| **Analyse comportementale des utilisateurs (UEBA)** | Détecte les comportements anormaux d'un utilisateur (connexion à 3h du matin, accès à des ressources inhabituelles) | Cisco ISE avec pxGrid |
| **Analyse de malware** | Classification automatique des fichiers suspects sans signature connue (analyse du comportement en sandbox) | Cisco Secure Malware Analytics (ex-Threat Grid) |
| **Détection de menaces chiffrées (ETA)** | Analyse les métadonnées du trafic chiffré (TLS) pour détecter du malware sans le déchiffrer | Cisco ETA (Encrypted Traffic Analytics) |
| **Sécurité DNS** | Identifie les domaines malveillants (DGA, C2, phishing) en analysant les patterns de requêtes DNS | Cisco Umbrella |

#### Encrypted Traffic Analytics (ETA) — Un exemple concret

Un cas d'usage parlant de ML en réseau : 70% du trafic Internet est aujourd'hui chiffré (HTTPS). Le chiffrement protège la vie privée, mais il empêche aussi les IPS traditionnels d'inspecter le contenu. Les attaquants exploitent cela pour cacher leur trafic malveillant dans du HTTPS.

L'ETA de Cisco analyse le trafic chiffré **sans le déchiffrer** en examinant :
- La taille et le timing des paquets (un C2 beacon a un pattern régulier, différent de la navigation web)
- Les métadonnées TLS (version, cipher suite, extensions)
- Le certificat du serveur (certificats autosignés, durée de vie courte, émetteur inconnu)
- Les séquences de paquets (le "rythme" de la communication)

Le modèle ML est entraîné sur des millions de flux connus (légitimes vs malveillants) et peut classer un nouveau flux avec un taux de précision supérieur à 99%.

#### Types de ML utilisés

| Type | Fonctionnement | Usage en sécurité |
|------|---------------|-------------------|
| **Supervisé** | Apprend à partir d'exemples étiquetés (trafic bon vs trafic mauvais) | Classification de malware, détection de phishing |
| **Non supervisé** | Cherche des patterns sans exemples préalables | Détection d'anomalies, clustering de comportements |
| **Renforcement** | Apprend par essai-erreur et feedback | Réponse automatisée aux incidents (orchestration) |

#### Limites et défis

Le ML n'est pas une solution miracle :
- **Faux positifs** : le ML peut signaler un comportement légitime comme suspect (un administrateur qui travaille tard)
- **Données d'entraînement** : la qualité du modèle dépend de la qualité et de la quantité des données historiques
- **Attaques adversariales** : des attaquants sophistiqués peuvent adapter leur comportement pour rester dans la "norme" détectée par le ML
- **Interprétabilité** : un modèle ML peut détecter une anomalie sans pouvoir expliquer clairement pourquoi (problème de la "boîte noire")
- **Coût computationnel** : l'entraînement et l'inférence nécessitent des ressources significatives

### Mise en pratique CLI

L'ETA (Encrypted Traffic Analytics) s'active sur les routeurs et switches Cisco qui exportent les métadonnées NetFlow vers un collecteur Stealthwatch :

```cisco
R1# show flow monitor ETA-MONITOR cache
  Cache type:                            Normal
  Cache size:                            4096
  Current entries:                       247
  ...
  Flows added:                           18432
  Flows aged:                            18185

R1# show et-analytics
ET-Analytics is ENABLED on the following interfaces:
  GigabitEthernet0/0 (input/output)
  GigabitEthernet0/1 (input/output)

ET-Analytics destination address: 10.0.0.50
ET-Analytics destination port: 2055
Inactive timer: 15
```

**Interprétation** : ETA est actif sur deux interfaces. Les métadonnées de flux sont exportées vers le collecteur à l'adresse 10.0.0.50 (Stealthwatch). 18 432 flux ont été analysés. Le collecteur applique les modèles ML pour classifier chaque flux comme bénin ou potentiellement malveillant.

### Point exam

> **Piège courant** : Le ML complète la sécurité traditionnelle — il ne la remplace pas. L'examen peut proposer "ML remplace les firewalls et ACLs" comme mauvaise réponse. Le ML détecte les anomalies, mais ce sont toujours les mécanismes traditionnels (ACLs, IPS, firewalls) qui bloquent effectivement le trafic malveillant.
>
> **À retenir** :
> - Le ML détecte les **anomalies** et les menaces **inconnues** (zero-day) que les signatures ne couvrent pas
> - L'ETA (Encrypted Traffic Analytics) analyse le trafic chiffré **sans le déchiffrer** — via les métadonnées
> - Le ML nécessite une **baseline** du comportement normal pour détecter les écarts
> - Cisco Stealthwatch (Secure Network Analytics) et Cisco Umbrella sont des produits Cisco qui utilisent le ML

### Exercice 5.11 — Scénarios ML vs traditionnel

**Contexte** : L'équipe SOC de GlobalCorp reçoit les alertes suivantes. Pour chacune, indiquez si la détection est mieux assurée par une approche traditionnelle (signatures/ACLs) ou par le ML.

| Alerte | Approche recommandée | Justification |
|--------|---------------------|---------------|
| Un poste télécharge le malware WannaCry (signature connue) | | |
| Le serveur de paie communique avec une IP en Russie pour la première fois | | |
| Un employé se connecte au VPN à 3h du matin tous les jours depuis une semaine | | |
| Un scan de ports nmap est détecté depuis l'extérieur | | |
| Du trafic HTTPS sortant présente un pattern de beacon régulier toutes les 30 secondes | | |

**Indice** : <details><summary>Voir l'indice</summary>Les menaces connues (signatures existantes) sont mieux gérées par les approches traditionnelles. Les comportements anormaux et les menaces inconnues sont le domaine du ML.</details>

<details>
<summary>Solution</summary>

| Alerte | Approche | Justification |
|--------|----------|---------------|
| WannaCry | **Traditionnelle (IPS/signature)** | Signature connue et largement documentée — l'IPS la détecte instantanément |
| Communication vers IP russe | **ML (anomalie comportementale)** | Pas de signature pour "première communication vers un pays". Le ML détecte l'écart par rapport au comportement normal du serveur |
| VPN à 3h du matin | **ML (UEBA)** | Le pattern de connexion est inhabituel pour cet utilisateur. Pas de règle statique possible car l'accès VPN est légitime en soi |
| Scan nmap | **Traditionnelle (IPS/ACL)** | Les patterns de scan sont bien connus. Un IPS avec signature ou un firewall détecte facilement les séquences de SYN vers des ports différents |
| Beacon HTTPS régulier | **ML (ETA)** | Trafic chiffré — pas d'inspection possible par un IPS classique. L'ETA analyse le timing et la taille des paquets pour identifier le pattern de C2 beacon |

</details>

### Voir aussi

- Topic 5.1 dans ce module (menaces et techniques de mitigation — le ML est une technique de mitigation avancée)
- Topic 1.1.c dans Module 1 (next-gen firewalls et IPS — les plateformes qui intègrent le ML)
- Topic 6.1 dans Module 6 (automatisation réseau — le ML s'inscrit dans la tendance d'automatisation)

---

## Labs Module 5

### Lab 5.1 — ACL Standard et Extended

**Topologie :**

```
                         ┌─────────────────────────┐
                         │                         │
  [PC-Admin]             │         R1               │            [Web-SRV]
  192.168.1.10/24 ───[Gi0/0]                  [Gi0/2]─── 10.0.0.100/24
                         │                         │
  [PC-User]              │                         │            [DNS-SRV]
  192.168.2.10/24 ───[Gi0/1]                      │       ─── 10.0.0.53/24
                         │                         │
                         └─────────────────────────┘

  Gi0/0 = 192.168.1.1/24  (VLAN Admin)
  Gi0/1 = 192.168.2.1/24  (VLAN Users)
  Gi0/2 = 10.0.0.1/24     (VLAN Servers)
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque | Passerelle |
|------------|-----------|-----------|--------|------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — |
| R1 | Gi0/1 | 192.168.2.1 | 255.255.255.0 | — |
| R1 | Gi0/2 | 10.0.0.1 | 255.255.255.0 | — |
| PC-Admin | NIC | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC-User | NIC | 192.168.2.10 | 255.255.255.0 | 192.168.2.1 |
| Web-SRV | NIC | 10.0.0.100 | 255.255.255.0 | 10.0.0.1 |
| DNS-SRV | NIC | 10.0.0.53 | 255.255.255.0 | 10.0.0.1 |

**Objectifs :**
1. Configurer une ACL standard nommée pour restreindre l'accès VTY
2. Configurer une ACL extended nommée pour filtrer le trafic vers les serveurs
3. Vérifier le bon fonctionnement avec `show access-lists` et des tests de connectivité

**Configuration de départ :**

```cisco
! Router R1
hostname R1
no ip domain-lookup
!
interface GigabitEthernet0/0
 description VLAN Admin
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/1
 description VLAN Users
 ip address 192.168.2.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/2
 description VLAN Servers
 ip address 10.0.0.1 255.255.255.0
 no shutdown
!
enable secret LabP@ss2026
username admin privilege 15 secret @dminL@b!
line vty 0 4
 login local
 transport input ssh
```

**Étapes :**

1. **ACL standard — Restreindre l'accès SSH au routeur**
   - Seul le réseau Admin (192.168.1.0/24) peut se connecter en SSH à R1
   - Créer l'ACL : `ip access-list standard VTY-ACCESS`
   - Autoriser : `permit 192.168.1.0 0.0.0.255`
   - Appliquer sur les VTY : `access-class VTY-ACCESS in`
   - Vérification : `show access-lists VTY-ACCESS`
   - Test : depuis PC-Admin, `ssh -l admin 192.168.1.1` → doit réussir
   - Test : depuis PC-User, `ssh -l admin 192.168.2.1` → doit échouer

2. **ACL extended — Filtrer le trafic vers les serveurs**
   - Politique : PC-User peut accéder au Web (HTTP/HTTPS) et au DNS, mais rien d'autre
   - Politique : PC-Admin peut accéder à tout
   - Créer l'ACL : `ip access-list extended USER-TO-SERVERS`
   - Autoriser HTTP : `permit tcp 192.168.2.0 0.0.0.255 host 10.0.0.100 eq 80`
   - Autoriser HTTPS : `permit tcp 192.168.2.0 0.0.0.255 host 10.0.0.100 eq 443`
   - Autoriser DNS : `permit udp 192.168.2.0 0.0.0.255 host 10.0.0.53 eq 53`
   - Autoriser ICMP (pour le troubleshooting) : `permit icmp 192.168.2.0 0.0.0.255 10.0.0.0 0.0.0.255`
   - Bloquer le reste : `deny ip any any log`
   - Appliquer sur Gi0/1 en direction `in`
   - Test depuis PC-User : `ping 10.0.0.100` → doit réussir (ICMP autorisé)
   - Test depuis PC-User : naviguer vers `http://10.0.0.100` → doit réussir
   - Test depuis PC-User : `ssh 10.0.0.100` → doit échouer (SSH non autorisé)

3. **Vérification et interprétation**
   - `show access-lists` → vérifier les compteurs de matches
   - `show ip interface Gi0/1` → vérifier que l'ACL est appliquée en inbound

**Vérification finale :**

```cisco
R1# show access-lists
Standard IP access list VTY-ACCESS
    10 permit 192.168.1.0, wildcard bits 0.0.0.255 (12 matches)
Extended IP access list USER-TO-SERVERS
    10 permit tcp 192.168.2.0 0.0.0.255 host 10.0.0.100 eq www (8 matches)
    20 permit tcp 192.168.2.0 0.0.0.255 host 10.0.0.100 eq 443 (4 matches)
    30 permit udp 192.168.2.0 0.0.0.255 host 10.0.0.53 eq domain (15 matches)
    40 permit icmp 192.168.2.0 0.0.0.255 10.0.0.0 0.0.0.255 (5 matches)
    50 deny ip any any log (3 matches)
```

**Questions de validation :**
1. Pourquoi l'ACL VTY-ACCESS est-elle appliquée avec `access-class` et non `access-group` ?
2. Que se passerait-il si on oubliait la ligne `permit icmp` dans l'ACL USER-TO-SERVERS ?
3. Si l'on déplaçait l'ACL USER-TO-SERVERS sur Gi0/2 en direction `out` au lieu de Gi0/1 `in`, le filtrage fonctionnerait-il de la même façon ?

---

### Lab 5.2 — Port Security et DHCP Snooping

**Topologie :**

```
                    ┌──────────────────────────────────┐
  [PC1]             │           SW1                    │       [DHCP Server]
  (légitime) ──[Gi0/1]                           [Gi0/24]──── 192.168.10.254/24
                    │                                  │
  [PC2]             │                                  │
  (légitime) ──[Gi0/2]                                │
                    │                                  │
  [Attaquant]       │                                  │
  (rogue DHCP) ─[Gi0/3]                               │
                    │                                  │
  [PC4]             │                                  │
  (MAC flood) ──[Gi0/4]                               │
                    └──────────────────────────────────┘

  VLAN 10 — Réseau : 192.168.10.0/24
  DHCP Pool : 192.168.10.100 à 192.168.10.200
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque | Source |
|------------|-----------|-----------|--------|--------|
| SW1 | VLAN 10 | 192.168.10.1 | 255.255.255.0 | Statique |
| DHCP Server | NIC | 192.168.10.254 | 255.255.255.0 | Statique |
| PC1 | NIC | 192.168.10.10x | 255.255.255.0 | DHCP |
| PC2 | NIC | 192.168.10.10x | 255.255.255.0 | DHCP |
| Attaquant | NIC | 192.168.10.250 | 255.255.255.0 | Statique (rogue DHCP) |
| PC4 | NIC | — | — | Outil MAC flooding |

**Objectifs :**
1. Configurer port security pour limiter les adresses MAC
2. Configurer DHCP snooping pour bloquer le rogue DHCP
3. Configurer DAI pour empêcher l'ARP spoofing
4. Tester et vérifier chaque mécanisme

**Étapes :**

1. **Port Security sur tous les ports d'accès**
   - Configurer Gi0/1-4 en mode access, VLAN 10
   - Activer port security : maximum 1 MAC, sticky, violation shutdown
   - Commande : `show port-security`
   - Test : brancher un mini-switch sur Gi0/4 → le port doit passer en err-disabled

2. **DHCP Snooping**
   - Activer globalement et sur VLAN 10
   - Port Gi0/24 en trusted (serveur DHCP légitime)
   - Rate limit 10 sur les ports d'accès
   - Vérification : `show ip dhcp snooping`, `show ip dhcp snooping binding`
   - Test : l'attaquant sur Gi0/3 tente d'envoyer des DHCP Offer → bloqué (port untrusted)

3. **DAI**
   - Activer sur VLAN 10
   - Port Gi0/24 en trusted pour l'ARP inspection
   - Vérification : `show ip arp inspection vlan 10`
   - Test : l'attaquant envoie un gratuitous ARP avec l'IP de la passerelle → bloqué

4. **Récupération d'un port err-disabled**
   - Le port Gi0/4 est en err-disabled après la violation port security
   - Commande : `shutdown` puis `no shutdown` sur Gi0/4
   - Ou configurer la récupération automatique : `errdisable recovery cause psecure-violation`

**Vérification finale :**

```cisco
SW1# show port-security
Secure Port  MaxSecureAddr  CurrentAddr  SecurityViolation  Security Action
-----------  -------------  -----------  -----------------  ---------------
     Gi0/1              1            1                  0         Shutdown
     Gi0/2              1            1                  0         Shutdown
     Gi0/3              1            1                  0         Shutdown
     Gi0/4              1            1                  1         Shutdown

SW1# show ip dhcp snooping binding
MacAddress          IpAddress       Lease(sec)  Type           VLAN  Interface
------------------  --------------- ----------  -------------- ----  ---------
00:AB:CD:11:22:33   192.168.10.101  86400       dhcp-snooping  10   Gi0/1
00:AB:CD:44:55:66   192.168.10.102  86400       dhcp-snooping  10   Gi0/2
```

**Questions de validation :**
1. Pourquoi le port Gi0/24 doit-il être trusted à la fois pour DHCP snooping ET pour DAI ?
2. Si un employé légitime branche un téléphone IP (qui génère une deuxième MAC sur le port), que se passe-t-il avec port security configuré à maximum 1 ?
3. Un poste avec une IP statique (pas obtenue via DHCP) peut-il fonctionner avec DAI activé ? Pourquoi ?

---

### Lab 5.3 — SSH et sécurisation d'accès

**Topologie :**

```
  [PC-Admin] ─────── [SW1] ─────── [R1]
  192.168.100.10/24          192.168.100.1/24
                    VLAN 100 (Management)
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque | Passerelle |
|------------|-----------|-----------|--------|------------|
| R1 | Gi0/0 | 192.168.100.1 | 255.255.255.0 | — |
| SW1 | VLAN 100 | 192.168.100.2 | 255.255.255.0 | 192.168.100.1 |
| PC-Admin | NIC | 192.168.100.10 | 255.255.255.0 | 192.168.100.1 |

**Objectifs :**
1. Sécuriser l'accès console et VTY du routeur R1
2. Configurer SSH v2 et désactiver Telnet
3. Appliquer une ACL pour limiter l'accès SSH au réseau management
4. Configurer une bannière et un mécanisme anti-brute force

**Étapes :**

1. **Sécurisation de base de R1**
   - Configurer hostname, domain-name, enable secret
   - Créer les utilisateurs locaux (admin, operator)
   - Générer la clé RSA 2048 bits
   - Configurer SSH version 2

2. **Sécuriser la console**
   - `login local`, timeout 5 min, `logging synchronous`

3. **Sécuriser les VTY**
   - `login local`, `transport input ssh`, timeout 10 min
   - ACL standard pour restreindre au réseau 192.168.100.0/24

4. **Anti-brute force**
   - `login block-for 120 attempts 3 within 60`
   - `security passwords min-length 10`

5. **Bannière MOTD**
   - Avertissement légal

6. **Vérification**
   - `show ip ssh` → confirmer version 2 et algorithme RSA
   - `show ssh` → voir les sessions actives
   - Tester la connexion SSH depuis PC-Admin
   - Tenter une connexion Telnet → doit échouer

**Vérification finale :**

```cisco
R1# show ip ssh
SSH Enabled - version 2.0
Authentication methods: publickey, keyboard-interactive, password
Authentication Publickey Algorithms: x509v3-ssh-rsa,ssh-rsa
Hostkey Algorithms: x509v3-ssh-rsa,ssh-rsa
Encryption Algorithms: aes128-ctr,aes192-ctr,aes256-ctr
MAC Algorithms: hmac-sha2-256,hmac-sha2-512,hmac-sha1
Authentication timeout: 120 secs; Authentication retries: 3
Minimum expected Diffie Hellman key size: 2048 bits
IOS Keys in SECSH format(ssh-rsa, 2048 bits):
```

**Questions de validation :**
1. Pourquoi la clé RSA doit-elle être d'au moins 768 bits pour SSH v2 ? (2048 bits est la recommandation actuelle)
2. Quelle commande permet de voir qui est actuellement connecté en SSH au routeur ?
3. Si le serveur TACACS+ est injoignable et que `login local` est configuré en fallback, que se passe-t-il lors de la connexion ?

---

## Quiz Module 5 — 15 questions

**Q1.** Quelle est la principale différence entre une menace et une vulnérabilité ? _(Topic 5.1)_

- A) Une menace est interne, une vulnérabilité est externe
- B) Une vulnérabilité est une faiblesse ; une menace est un danger potentiel qui pourrait l'exploiter
- C) Une menace est technique, une vulnérabilité est humaine
- D) Il n'y a pas de différence, ce sont des synonymes

<details>
<summary>Réponse</summary>

**B** — Une vulnérabilité est une faiblesse dans un système (port ouvert, firmware obsolète, mot de passe faible). Une menace est tout événement ou acteur susceptible d'exploiter cette vulnérabilité pour causer un dommage. A est faux car les deux peuvent être internes ou externes. C est faux car les deux peuvent être techniques ou humains. D est évidemment faux.

</details>

---

**Q2.** Quels sont les trois éléments d'un programme de sécurité selon le topic CCNA ? _(Topic 5.2)_

- A) Firewall, IPS, chiffrement
- B) User awareness, training, physical access control
- C) Authentication, authorization, accounting
- D) Confidentialité, intégrité, disponibilité

<details>
<summary>Réponse</summary>

**B** — Les trois éléments d'un security program sont la sensibilisation (user awareness), la formation (training) et le contrôle d'accès physique (physical access control). A décrit des outils techniques, pas un programme. C décrit AAA (topic 5.8). D décrit la triade CIA (topic 5.1).

</details>

---

**Q3.** Un routeur a les deux commandes suivantes dans sa configuration :
```
enable password cisco
enable secret class
```
Quel mot de passe est requis pour accéder au mode enable ? _(Topic 5.3)_

- A) cisco
- B) class
- C) Les deux sont requis (MFA)
- D) Le dernier configuré (cisco si `enable password` est après `enable secret`)

<details>
<summary>Réponse</summary>

**B** — Quand `enable password` et `enable secret` coexistent, `enable secret` **prend toujours le dessus**, quel que soit l'ordre de configuration. Le mot de passe est donc `class`. A est le piège classique. C est faux — ce n'est pas du MFA. D est faux — ce n'est pas le dernier configuré qui gagne, c'est toujours `enable secret`.

</details>

---

**Q4.** Un utilisateur se connecte à un système avec un mot de passe et un code envoyé par SMS sur son téléphone. Combien de facteurs d'authentification sont utilisés ? _(Topic 5.4)_

- A) Un facteur (connaissance)
- B) Deux facteurs (connaissance + possession)
- C) Deux facteurs (connaissance + connaissance)
- D) Trois facteurs (connaissance + possession + inhérence)

<details>
<summary>Réponse</summary>

**B** — Le mot de passe est un facteur de connaissance (ce que vous savez). Le code SMS nécessite la possession du téléphone (ce que vous avez). Ce sont deux catégories différentes, donc MFA à deux facteurs. C est faux car le SMS prouve la possession du téléphone, pas une connaissance. D est faux car il n'y a pas de biométrie.

</details>

---

**Q5.** Quel protocole IPsec fournit le chiffrement des données ? _(Topic 5.5)_

- A) AH (Authentication Header)
- B) ESP (Encapsulating Security Payload)
- C) IKE (Internet Key Exchange)
- D) GRE (Generic Routing Encapsulation)

<details>
<summary>Réponse</summary>

**B** — ESP fournit le chiffrement + l'intégrité + l'authentification. AH ne fournit que l'intégrité et l'authentification — pas de chiffrement. IKE est le protocole de négociation (il ne chiffre pas le trafic utilisateur). GRE est un protocole de tunneling qui n'offre aucune sécurité par lui-même.

</details>

---

**Q6.** Quel est le wildcard mask correspondant au masque de sous-réseau 255.255.255.240 ? _(Topic 5.6)_

- A) 0.0.0.240
- B) 0.0.0.16
- C) 0.0.0.15
- D) 0.0.0.255

<details>
<summary>Réponse</summary>

**C** — Le wildcard mask se calcule en soustrayant chaque octet du masque de 255 : 255-255=0, 255-255=0, 255-255=0, 255-240=15. Le résultat est 0.0.0.15. A est le masque lui-même inversé de façon incorrecte. B est le nombre d'hôtes, pas le wildcard. D correspondrait à un /24.

</details>

---

**Q7.** Où doit-on placer une ACL extended ? _(Topic 5.6)_

- A) Le plus proche possible de la destination
- B) Le plus proche possible de la source
- C) Sur le routeur central (core)
- D) Sur n'importe quelle interface, la position n'a pas d'importance

<details>
<summary>Réponse</summary>

**B** — Une ACL extended peut filtrer par source, destination et port. On la place proche de la source pour bloquer le trafic indésirable le plus tôt possible, économisant ainsi la bande passante. A est la règle pour les ACLs **standard** (qui ne filtrent que la source). C et D sont incorrects.

</details>

---

**Q8.** Quelle commande applique une ACL sur une ligne VTY ? _(Topic 5.6)_

- A) `ip access-group ACL-NAME in`
- B) `ip access-list ACL-NAME in`
- C) `access-class ACL-NAME in`
- D) `access-group ACL-NAME in`

<details>
<summary>Réponse</summary>

**C** — Sur les lignes VTY, on utilise `access-class` (pas `access-group`). `access-group` s'utilise sur les interfaces physiques ou logiques. A est pour les interfaces. B est la commande de création d'une ACL nommée, pas d'application. D n'est pas une commande valide dans ce contexte.

</details>

---

**Q9.** Quel mécanisme de sécurité Layer 2 nécessite que DHCP snooping soit activé au préalable ? _(Topic 5.7)_

- A) Port security
- B) 802.1X
- C) Dynamic ARP Inspection (DAI)
- D) Storm control

<details>
<summary>Réponse</summary>

**C** — DAI utilise la binding table construite par DHCP snooping pour vérifier la correspondance IP-MAC des paquets ARP. Sans DHCP snooping, DAI n'a pas de référence pour ses vérifications. Port security (A) est indépendant. 802.1X (B) utilise RADIUS, pas DHCP snooping. Storm control (D) est un mécanisme de protection contre les tempêtes de broadcast, indépendant.

</details>

---

**Q10.** Quel est le mode de violation par défaut de port security ? _(Topic 5.7)_

- A) Protect
- B) Restrict
- C) Shutdown
- D) Alert

<details>
<summary>Réponse</summary>

**C** — Le mode par défaut est `shutdown` : le port passe en état err-disabled et nécessite une intervention manuelle pour être réactivé. Protect (A) bloque silencieusement sans log ni compteur. Restrict (B) bloque avec log et compteur mais laisse le port actif. Alert (D) n'est pas un mode valide de port security.

</details>

---

**Q11.** Quel protocole AAA chiffre l'intégralité du paquet ? _(Topic 5.8)_

- A) RADIUS
- B) TACACS+
- C) Kerberos
- D) LDAP

<details>
<summary>Réponse</summary>

**B** — TACACS+ chiffre le paquet entier. RADIUS (A) ne chiffre que le mot de passe — le reste du paquet (username, attributs) est en clair. Kerberos (C) et LDAP (D) ne sont pas des protocoles AAA au sens Cisco IOS (TACACS+ et RADIUS sont les deux options pour `aaa authentication`).

</details>

---

**Q12.** Quel protocole de sécurité Wi-Fi utilise SAE (Simultaneous Authentication of Equals) ? _(Topic 5.9)_

- A) WEP
- B) WPA
- C) WPA2
- D) WPA3

<details>
<summary>Réponse</summary>

**D** — SAE est l'une des améliorations majeures de WPA3. Il remplace le 4-way handshake de WPA2-Personal pour résister aux attaques de dictionnaire offline. WEP (A) utilise une clé statique. WPA (B) utilise TKIP. WPA2 (C) utilise le 4-way handshake classique.

</details>

---

**Q13.** Lors de la configuration d'un WLAN en WPA2-PSK sur un WLC, quel chiffrement doit être sélectionné ? _(Topic 5.10)_

- A) WEP 128 bits
- B) TKIP
- C) AES
- D) RC4

<details>
<summary>Réponse</summary>

**C** — WPA2 utilise AES-CCMP comme algorithme de chiffrement. TKIP (B) est l'algorithme de WPA (pas WPA2). WEP (A) et RC4 (D) sont obsolètes et cassés. L'examen insiste sur l'association WPA2 = AES.

</details>

---

**Q14.** Quel est l'avantage principal du Machine Learning par rapport à la détection par signatures en sécurité réseau ? _(Topic 5.11)_

- A) Il est moins cher à déployer
- B) Il peut détecter des menaces inconnues (zero-day) grâce à la détection d'anomalies
- C) Il ne produit jamais de faux positifs
- D) Il remplace complètement les firewalls et les ACLs

<details>
<summary>Réponse</summary>

**B** — Le ML détecte des anomalies comportementales, ce qui lui permet d'identifier des menaces qui n'ont pas de signature connue (zero-day, C2 en trafic chiffré, etc.). A est faux — le ML nécessite des investissements significatifs. C est faux — les faux positifs sont un problème courant du ML. D est faux — le ML complète les mécanismes traditionnels, il ne les remplace pas.

</details>

---

**Q15.** Dans une configuration `aaa authentication login default group tacacs+ local`, que se passe-t-il si le serveur TACACS+ est injoignable ? _(Topic 5.8)_

- A) L'authentification échoue pour tout le monde
- B) Le routeur utilise la base de données locale (username/secret)
- C) Le routeur autorise l'accès sans mot de passe
- D) Le routeur tente RADIUS automatiquement

<details>
<summary>Réponse</summary>

**B** — Le mot-clé `local` après `group tacacs+` est le fallback : si le serveur TACACS+ ne répond pas (timeout), le routeur utilise la base locale (`username ... secret`). A serait vrai si `local` n'était pas spécifié. C est le comportement de la méthode `none` (dangereuse). D est faux — RADIUS n'est utilisé que s'il est explicitement configuré dans la liste de méthodes.

</details>

---

## Récapitulatif Module 5

| Topic | Concept clé | Commande(s) essentielle(s) |
|-------|------------|---------------------------|
| 5.1 | Triade CIA, menaces vs vulnérabilités vs exploits | `show control-plane host open-ports` |
| 5.2 | Awareness, training, physical access control | `exec-timeout`, `logging synchronous` |
| 5.3 | enable secret > enable password, login local | `enable secret`, `username ... secret`, `login local` |
| 5.4 | MFA (3 facteurs), complexité, min-length | `security passwords min-length`, `login block-for` |
| 5.5 | ESP vs AH, IKE Phase 1/2, tunnel vs transport | `show crypto ipsec sa`, `show crypto isakmp sa` |
| 5.6 | ACLs standard/extended, wildcard masks, placement | `access-list`, `ip access-group`, `access-class` |
| 5.7 | Port security, DHCP snooping, DAI (binding table) | `switchport port-security`, `ip dhcp snooping`, `ip arp inspection` |
| 5.8 | TACACS+ (TCP 49, full encrypt) vs RADIUS (UDP 1812/1813) | `aaa new-model`, `aaa authentication login` |
| 5.9 | WPA=TKIP, WPA2=AES-CCMP, WPA3=AES-GCMP+SAE | `show wlan` |
| 5.10 | WLC GUI : profil + SSID + interface + WPA2+AES+PSK | `show wlan {id}` |
| 5.11 | ML détecte anomalies/zero-day, complète les signatures | `show et-analytics` |

**Check-list avant de passer au Module 6 :**
- [ ] Je sais distinguer menace, vulnérabilité et exploit
- [ ] Je sais configurer enable secret, console et VTY avec login local
- [ ] Je connais les trois facteurs MFA et je sais identifier le nombre de facteurs dans un scénario
- [ ] Je sais décrire les composants d'IPsec (ESP, AH, IKE, modes tunnel/transport)
- [ ] Je maîtrise les wildcard masks et je sais les calculer à partir d'un masque de sous-réseau
- [ ] Je sais écrire et appliquer des ACLs standard et extended (numérotées et nommées)
- [ ] Je connais la règle de placement : standard → destination, extended → source
- [ ] Je sais configurer port security, DHCP snooping et DAI
- [ ] Je sais comparer TACACS+ et RADIUS sur les 5 critères clés
- [ ] Je connais les différences entre WPA, WPA2 et WPA3 (chiffrement, authentification)
- [ ] Je sais configurer un WLAN WPA2-PSK via le WLC GUI
- [ ] Je sais décrire le rôle du ML en sécurité réseau (anomalies, ETA, zero-day)
- [ ] J'ai complété les 12 exercices (dont 5.6a et 5.6b)
- [ ] J'ai réalisé les 3 labs
- [ ] J'ai obtenu >70% au quiz
