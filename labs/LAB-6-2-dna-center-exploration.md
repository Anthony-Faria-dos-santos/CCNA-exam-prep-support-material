# LAB 6.2 — Exploration de Cisco DNA Center : gestion controller-based vs CLI

| Info | Valeur |
|------|--------|
| **Module** | 6 — Automatisation et programmabilite |
| **Topics couverts** | 6.4 (Cisco DNA Center — gestion controller-based) |
| **Difficulte** | Debutant |
| **Duree estimee** | 30 minutes |
| **Outil** | Navigateur web (Cisco DevNet Sandbox DNA Center) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Administrateur                              │
│                    (navigateur web / script)                        │
└──────────────┬──────────────────────────────────┬───────────────────┘
               │                                  │
               │  Northbound APIs                 │  Interface Web
               │  (REST, JSON)                    │  (Dashboard GUI)
               │                                  │
┌──────────────▼──────────────────────────────────▼───────────────────┐
│                                                                     │
│                        CISCO DNA CENTER                             │
│                     (controleur SDN campus)                         │
│                                                                     │
│   ┌──────────┐  ┌──────────┐  ┌───────────┐  ┌──────────────────┐  │
│   │ Assurance │  │ Inventory│  │ Provision │  │ Policy / SWIM    │  │
│   │ (sante)  │  │ (equip.) │  │ (deploy.) │  │ (images IOS)     │  │
│   └──────────┘  └──────────┘  └───────────┘  └──────────────────┘  │
│                                                                     │
└──────────┬──────────────┬────────────────┬──────────────────────────┘
           │              │                │
           │  Southbound  │  Southbound    │  Southbound
           │  (NETCONF)   │  (RESTCONF)    │  (SSH/CLI)
           │              │                │
     ┌─────▼─────┐  ┌────▼──────┐   ┌─────▼─────┐
     │  Switch 1  │  │  Switch 2 │   │ Routeur 1 │
     │  C9300     │  │  C9300    │   │  CSR1000v  │
     └───────────┘  └───────────┘   └───────────┘
```

Ce lab explore Cisco DNA Center, le controleur SDN de Cisco pour les reseaux campus. L'objectif est de comprendre concretement la difference entre gerer un reseau equipement par equipement (approche CLI traditionnelle) et le gerer depuis un point central (approche controller-based). On utilise le sandbox Cisco DevNet, accessible gratuitement depuis un navigateur.

---

## Objectifs

1. Comprendre le role de DNA Center comme controleur SDN pour le campus
2. Identifier les APIs northbound (vers l'administrateur) et southbound (vers les equipements)
3. Explorer le dashboard et l'inventaire des equipements via l'interface web
4. Comparer systematiquement l'approche CLI et l'approche DNA Center pour chaque tache
5. Faire le lien avec les APIs REST etudiees dans le LAB 6.1

---

## Prerequis

- Avoir complete le LAB 6.1 (APIs REST et JSON) — ou au minimum connaitre les concepts REST et JSON
- Un navigateur web moderne (Chrome, Firefox, Edge)
- Un acces Internet (pour atteindre le sandbox Cisco DevNet)
- Connaitre les commandes Cisco de base (`show version`, `show ip interface brief`, `show vlan brief`)

---

## Partie 1 : Introduction a DNA Center

### Etape 1.1 : Qu'est-ce que DNA Center ?

Cisco DNA Center (Digital Network Architecture Center) est une **plateforme de gestion centralisee** pour les reseaux campus. C'est le controleur SDN de Cisco pour les environnements LAN/WLAN d'entreprise.

En termes simples : au lieu de se connecter en SSH sur chaque switch et chaque routeur pour les configurer un par un, DNA Center offre un **point de controle unique** depuis lequel on gere l'ensemble du reseau.

| Concept | Description |
|---------|-------------|
| **Controleur SDN** | DNA Center centralise la gestion, le monitoring et l'automatisation du reseau |
| **Northbound API** | API REST exposee vers l'administrateur (scripts Python, outils tiers, dashboard web). C'est l'interface par laquelle on **commande** le controleur |
| **Southbound API** | Protocoles utilises par DNA Center pour **communiquer avec les equipements** : NETCONF, RESTCONF, SSH/CLI, SNMP |
| **Intent-based** | DNA Center traduit l'**intention** de l'administrateur ("les invites ne doivent pas acceder aux serveurs") en configurations techniques deployees automatiquement |

### Etape 1.2 : Avant DNA Center vs apres DNA Center

Pour bien comprendre l'interet d'un controleur, comparons la meme tache dans les deux approches :

**Scenario : ajouter le VLAN 50 sur 20 switches d'un site**

**Approche CLI traditionnelle :**
1. Ouvrir un terminal SSH vers le switch 1
2. Taper `configure terminal`, `vlan 50`, `name GUESTS`, `exit`
3. Verifier avec `show vlan brief`
4. Fermer la session
5. Repeter les etapes 1-4 pour les 19 autres switches
6. Prier pour ne pas avoir fait de faute de frappe sur l'un d'entre eux

**Approche DNA Center :**
1. Creer un template de configuration contenant les commandes VLAN
2. Selectionner les 20 switches dans l'inventaire
3. Cliquer sur "Deploy" — DNA Center pousse la config sur les 20 switches en parallele
4. Verifier le statut dans le dashboard : vert = succes, rouge = echec avec details

> **La difference fondamentale :** avec le CLI, la charge de travail augmente lineairement avec le nombre d'equipements. Avec DNA Center, la charge reste quasi constante quel que soit le nombre d'equipements. C'est cette scalabilite qui justifie l'investissement dans un controleur.

---

## Partie 2 : Acces au sandbox DNA Center

### Etape 2.1 : Informations de connexion

Cisco met a disposition un sandbox DNA Center "Always-On" via le programme DevNet. Il est accessible 24h/24 sans reservation :

| Information | Valeur |
|-------------|--------|
| **URL** | `https://sandboxdnac.cisco.com` |
| **Username** | `devnetuser` |
| **Password** | `Cisco123!` |
| **Acces** | Lecture seule (vous pouvez explorer mais pas modifier la configuration) |

### Etape 2.2 : Se connecter

1. Ouvrez votre navigateur web
2. Allez a l'adresse `https://sandboxdnac.cisco.com`
3. Votre navigateur affichera probablement un avertissement de certificat SSL — acceptez-le (c'est un environnement de lab)
4. Entrez les identifiants : `devnetuser` / `Cisco123!`
5. Vous arrivez sur le **dashboard** principal de DNA Center

> **Si le sandbox est indisponible :** Le sandbox est partage par des milliers d'utilisateurs et peut etre temporairement en maintenance. Dans ce cas, les descriptions detaillees de chaque section ci-dessous vous permettent de comprendre les concepts sans y acceder directement. Cisco propose aussi d'autres sandboxes sur `https://developer.cisco.com/site/sandbox/` — certains necessitent une reservation.

---

## Partie 3 : Exploration du Dashboard

### Etape 3.1 : La page d'accueil

Une fois connecte, le dashboard de DNA Center affiche une vue globale de la sante du reseau. Voici ce que vous devriez voir :

**Sections principales :**

| Zone du dashboard | Ce qu'elle montre |
|-------------------|-------------------|
| **Network Health** | Pourcentage d'equipements sains (vert), degraded (jaune), critical (rouge). Vue en temps reel |
| **Client Health** | Sante des clients connectes (postes de travail, telephones IP, IoT) |
| **Overall Health** | Score global de sante du reseau, calcule a partir de multiples metriques |
| **Issues** | Alertes et problemes detectes automatiquement. Classes par priorite (P1 a P4) |

### Etape 3.2 : Ce que ca remplace en CLI

Pour obtenir les memes informations **sans** DNA Center, un administrateur devrait :

| Information DNA Center | Equivalent CLI (par equipement) |
|------------------------|--------------------------------|
| Health score d'un switch | `show processes cpu`, `show memory statistics`, `show environment` |
| Etat des interfaces | `show ip interface brief`, `show interfaces status` |
| Clients connectes | `show mac address-table`, `show dot1x all` |
| Alertes / erreurs | `show logging`, `show interfaces` (pour les compteurs d'erreurs) |

Pour un reseau de 50 equipements, cela represente 50 sessions SSH et des dizaines de commandes **show** a taper manuellement. DNA Center consolide tout cela en **un seul ecran**.

> **Point exam :** L'examen CCNA ne vous demandera pas de naviguer dans DNA Center. Mais il vous demandera de comprendre **pourquoi** un controleur centralise est avantageux par rapport a la gestion device-by-device. Le dashboard est l'illustration concrete de cette centralisation.

---

## Partie 4 : Gestion des equipements (Inventory)

### Etape 4.1 : Acceder a l'inventaire

Dans DNA Center, naviguez vers **Provision > Inventory** (ou **Network Devices** selon la version).

L'inventaire affiche la liste de tous les equipements decouverts et geres par DNA Center. Pour chaque equipement, vous voyez :

| Colonne | Description | Equivalent CLI |
|---------|-------------|----------------|
| **Hostname** | Nom de l'equipement | `show running-config \| include hostname` |
| **Management IP** | Adresse IP de gestion | `show ip interface brief` (interface de management) |
| **Platform** | Modele materiel (C9300, ISR4321, etc.) | `show version \| include Model` |
| **Software Version** | Version de l'IOS-XE | `show version \| include Version` |
| **Up Time** | Duree depuis le dernier redemarrage | `show version \| include uptime` |
| **Reachability** | L'equipement est-il joignable depuis DNA Center ? | `ping` depuis la station d'admin |
| **Role** | Role dans le reseau (ACCESS, DISTRIBUTION, CORE, BORDER) | Pas d'equivalent CLI — c'est DNA Center qui determine le role en analysant la topologie |

### Etape 4.2 : Ce que vous devriez voir dans le sandbox

Le sandbox DNA Center contient typiquement ces equipements :

```
┌─────────────────────────────────────────────────────────────┐
│  Hostname              │ IP           │ Platform    │ Role  │
├────────────────────────┼──────────────┼─────────────┼───────┤
│  cat_9k_1.abc.inc      │ 10.10.20.81  │ C9300-24UX  │ ACCESS│
│  cat_9k_2.abc.inc      │ 10.10.20.82  │ C9300-24UX  │ ACCESS│
│  cs3850.abc.inc        │ 10.10.20.80  │ WS-C3850    │ CORE  │
└─────────────────────────────────────────────────────────────┘
```

### Etape 4.3 : Comparaison concrete

**Avec le CLI :** Pour obtenir ce meme tableau, vous devriez :

```
! Sur cat_9k_1 :
SSH admin@10.10.20.81
show version
show ip interface brief
exit

! Sur cat_9k_2 :
SSH admin@10.10.20.82
show version
show ip interface brief
exit

! Sur cs3850 :
SSH admin@10.10.20.80
show version
show ip interface brief
exit
```

Soit 3 connexions SSH, 6 commandes, et un travail manuel de compilation des resultats dans un tableau. Avec 3 equipements, c'est gerable. Avec 300, c'est intenable.

**Avec DNA Center :** Un clic sur "Inventory", et tout est la. En une seule vue.

> **Reflexion :** L'inventaire DNA Center est automatiquement mis a jour. Si un equipement redemarrage ou change de version IOS apres une mise a jour, le dashboard reflete le changement sans intervention. En CLI, il faudrait re-taper `show version` pour le savoir.

---

## Partie 5 : Provisioning et Templates

### Etape 5.1 : Le concept de template

DNA Center permet de creer des **templates de configuration** : des blocs de commandes Cisco IOS/IOS-XE que l'on peut deployer sur un ou plusieurs equipements en un clic.

Un template peut contenir des **variables** qui seront remplacees au moment du deploiement :

```
! Template : "Ajout VLAN"
vlan $VLAN_ID
 name $VLAN_NAME
!
interface range $INTERFACE_RANGE
 switchport mode access
 switchport access vlan $VLAN_ID
 no shutdown
```

Au moment du deploiement, l'administrateur renseigne les valeurs :
- `$VLAN_ID` = 50
- `$VLAN_NAME` = GUESTS
- `$INTERFACE_RANGE` = GigabitEthernet1/0/1-10

DNA Center genere la configuration finale et la pousse sur les equipements selectionnes.

### Etape 5.2 : Avantages par rapport au CLI

| Aspect | CLI (copier-coller) | DNA Center (template) |
|--------|--------------------|-----------------------|
| **Coherence** | Risque de faute de frappe, oubli d'une ligne | Le template est identique pour tous les equipements |
| **Deploiement** | Sequentiel (un device a la fois) | Parallele (tous les devices en meme temps) |
| **Audit** | Aucune trace de qui a fait quoi et quand | Historique complet dans DNA Center |
| **Rollback** | Sauvegardes manuelles (`copy run start`) | DNA Center conserve les versions precedentes |
| **Verification** | `show running-config` manuellement | Compliance check automatise |

### Etape 5.3 : Autres fonctions de provisioning

DNA Center offre aussi :

| Fonction | Description | Benefice |
|----------|-------------|----------|
| **SWIM** (Software Image Management) | Gestion centralisee des images IOS/IOS-XE. Upload, distribution, mise a jour planifiee | Plus besoin de TFTP/SCP device par device |
| **Plug and Play** (PnP) | Un nouvel equipement branche sur le reseau se configure automatiquement via DNA Center | Zero-touch provisioning : le switch sort du carton et se configure seul |
| **Compliance** | Verification automatique que la config de chaque equipement respecte les standards definis | Detection des ecarts de configuration |

> **Point exam :** L'examen CCNA ne vous demandera pas de configurer DNA Center. Mais les concepts de **provisioning centralise**, de **templates** et de **software image management** sont des sujets testables dans le cadre de la comparaison CLI vs controller-based.

---

## Partie 6 : APIs de DNA Center

### Etape 6.1 : DNA Center expose des APIs REST

DNA Center n'est pas seulement une interface graphique. Il expose des **APIs REST northbound** que des scripts et des outils tiers peuvent utiliser. C'est exactement ce qu'on a explore dans le LAB 6.1.

L'API de DNA Center suit les memes principes :

| Composant | Valeur pour DNA Center |
|-----------|----------------------|
| **Base URL** | `https://sandboxdnac.cisco.com` |
| **Authentification** | POST sur `/dna/system/api/v1/auth/token` → retourne un token |
| **Format** | JSON |
| **Verbes HTTP** | GET (lire), POST (creer), PUT (modifier), DELETE (supprimer) |

### Etape 6.2 : Exemple concret — lister les equipements via API

C'est exactement ce qu'on a fait dans le LAB 6.1 avec curl. L'endpoint est :

```
GET /dna/intent/api/v1/network-device
```

La reponse JSON contient les memes informations que le tableau Inventory du dashboard :

```json
{
  "response": [
    {
      "hostname": "cat_9k_1.abc.inc",
      "managementIpAddress": "10.10.20.81",
      "platformId": "C9300-24UX",
      "softwareVersion": "17.9.20220318:182713",
      "role": "ACCESS",
      "reachabilityStatus": "Reachable"
    }
  ]
}
```

### Etape 6.3 : Le lien entre GUI, API et equipements

Voici comment tout s'articule :

```
┌───────────────────────────────────────────────────┐
│                  Administrateur                    │
│                                                   │
│   ┌────────────────┐     ┌─────────────────────┐  │
│   │  Navigateur    │     │  Script Python      │  │
│   │  (Dashboard)   │     │  (curl / requests)  │  │
│   └───────┬────────┘     └──────────┬──────────┘  │
│           │                         │              │
│           │  HTTPS (GUI)            │  REST API    │
│           │                         │  (JSON)      │
└───────────┼─────────────────────────┼──────────────┘
            │                         │
            ▼                         ▼
     ┌──────────────────────────────────────┐
     │           DNA CENTER                 │
     │                                      │
     │   Le dashboard et l'API accedent     │
     │   aux MEMES donnees. Le dashboard    │
     │   utilise lui-meme l'API en interne  │
     └────────────────┬─────────────────────┘
                      │
                      │  Southbound (NETCONF, RESTCONF, SSH)
                      │
               ┌──────▼──────┐
               │ Equipements │
               │   reseau    │
               └─────────────┘
```

> **Point cle :** Le dashboard web de DNA Center **utilise lui-meme l'API REST en interne**. Quand vous cliquez sur "Inventory" dans le navigateur, le dashboard fait un GET sur `/dna/intent/api/v1/network-device` et affiche le resultat sous forme de tableau. La GUI et l'API sont deux facons differentes d'acceder aux memes donnees.

---

## Tableau comparatif final

| Tache | Approche CLI traditionnelle | Approche DNA Center |
|-------|----------------------------|---------------------|
| Voir tous les equipements | SSH sur chaque equipement + `show version` | Dashboard **Inventory** — un clic |
| Deployer un VLAN sur 50 switches | 50 sessions SSH + copier-coller de commandes | 1 template + selection des devices + Deploy |
| Diagnostiquer un probleme reseau | `show commands` manuels sur chaque equipement suspect | **Assurance** — alertes automatiques + analyse de la cause racine |
| Mettre a jour IOS sur 20 switches | TFTP/SCP device par device + reload planifie | **SWIM** — upload image, planification, mise a jour en masse |
| Automatiser via script | Scripts Python avec Paramiko/Netmiko + parsing de texte | **API REST northbound** — donnees structurees en JSON |
| Verifier la coherence des configs | Comparer manuellement les `show running-config` | **Compliance** — verification automatisee par rapport au template |
| Integrer un nouvel equipement | Cablage + console + config manuelle (hostname, IP, VLAN, etc.) | **Plug and Play** — le switch se configure seul en contactant DNA Center |

---

## Verification finale

Cochez chaque critere pour valider la reussite du lab :

- [ ] Vous savez expliquer ce qu'est DNA Center et son role de controleur SDN
- [ ] Vous savez distinguer les APIs northbound (vers l'admin/scripts) et southbound (vers les equipements)
- [ ] Vous savez citer au moins 3 protocoles southbound (NETCONF, RESTCONF, SSH/CLI)
- [ ] Vous comprenez pourquoi un controleur centralise est plus efficace que le CLI pour un grand parc
- [ ] Vous savez comment le dashboard et l'API REST accedent aux memes donnees
- [ ] Vous pouvez comparer CLI vs DNA Center pour au moins 4 taches reseau concretes

---

## Questions de reflexion

### Question 1 — Quel est l'avantage principal de DNA Center pour un reseau de 500 equipements vs CLI ?

<details>
<summary>Voir la reponse</summary>

L'avantage principal est la **scalabilite de la gestion**. Avec le CLI, chaque operation doit etre repetee sur chaque equipement : 500 sessions SSH pour un inventaire, 500 copier-coller pour un changement de configuration, 500 `show version` pour verifier les versions IOS. Le temps et le risque d'erreur augmentent lineairement avec le nombre d'equipements.

Avec DNA Center, la meme operation prend le meme temps, quel que soit le nombre d'equipements :
- Inventaire : 1 clic sur Inventory (ou 1 appel API GET)
- Deploiement VLAN : 1 template deploye en parallele sur les 500 switches
- Mise a jour IOS : 1 image uploadee, 1 planification, deploiement automatique

Au-dela de la scalabilite, DNA Center apporte aussi :
- **Coherence** : tous les equipements recoivent exactement la meme configuration
- **Visibilite** : une vue globale de la sante du reseau au lieu de 500 vues fragmentees
- **Tracabilite** : un historique complet de qui a fait quoi et quand
- **Proactivite** : detection automatique des anomalies, au lieu d'attendre qu'un utilisateur signale un probleme

</details>

### Question 2 — DNA Center utilise des APIs southbound pour communiquer avec les equipements. Lesquelles ?

<details>
<summary>Voir la reponse</summary>

DNA Center utilise principalement trois mecanismes pour communiquer avec les equipements reseau (APIs southbound) :

1. **NETCONF** (Network Configuration Protocol) :
   - Protocole base sur XML, utilise pour la configuration et le monitoring
   - Transport via SSH (port 830)
   - Supporte les transactions (rollback possible si une commande echoue)
   - Privilegie par Cisco pour les equipements recents (IOS-XE 16.x+)

2. **RESTCONF** :
   - Version REST de NETCONF : utilise HTTP/HTTPS au lieu de SSH
   - Donnees en JSON ou XML
   - Plus simple a integrer dans des workflows modernes
   - Fonctionne sur les equipements supportant YANG models

3. **SSH/CLI** :
   - Pour les equipements plus anciens qui ne supportent pas NETCONF/RESTCONF
   - DNA Center se connecte en SSH et envoie les commandes comme un humain le ferait
   - Methode de dernier recours (parsing de texte moins fiable)

4. **SNMP** (Simple Network Management Protocol) :
   - Utilise principalement pour le monitoring (pas pour la configuration)
   - DNA Center collecte des metriques via SNMP (CPU, memoire, trafic interfaces)

> **Point exam :** NETCONF et RESTCONF sont les reponses attendues quand on parle d'APIs southbound de DNA Center. SSH/CLI et SNMP sont aussi utilises mais ne sont pas des "APIs" au sens strict — ce sont des protocoles de gestion traditionnels.

</details>

### Question 3 — Pourquoi Cisco pousse-t-il vers les solutions controller-based ?

<details>
<summary>Voir la reponse</summary>

Cisco pousse vers les solutions controller-based pour trois raisons principales :

**1. Complexite croissante des reseaux :**
Les reseaux modernes comptent des centaines, voire des milliers d'equipements. Le cloud, l'IoT, le BYOD et le teletravail multiplient les points d'acces et les politiques de securite. Gerer tout cela equipement par equipement est devenu physiquement impossible avec des equipes de taille raisonnable.

**2. Securite et conformite :**
Un controleur permet d'appliquer des politiques de securite de maniere **uniforme** sur l'ensemble du reseau. Sans controleur, un switch mal configure (oubli d'un ACL, port laisse ouvert) peut rester des mois sans que personne ne le remarque. DNA Center detecte automatiquement les ecarts de configuration.

**3. Agilite operationnelle :**
Les entreprises ont besoin de reagir vite : deployer un nouveau service en heures (pas en semaines), isoler une menace en secondes (pas en minutes). L'automatisation via un controleur le permet. Le CLI ne le permet pas a cette echelle.

Il y a aussi une raison commerciale evidente : DNA Center est un produit Cisco avec des licences recurrentes. Mais l'argument technique est reel — et c'est ce que l'examen CCNA attend comme reponse.

</details>

### Question 4 — Un reseau de 3 switches a-t-il besoin de DNA Center ?

<details>
<summary>Voir la reponse</summary>

Non, probablement pas. Et c'est important de savoir le dire.

DNA Center est concu pour les reseaux de taille moyenne a grande (50+ equipements). Pour 3 switches :

**Contre DNA Center :**
- Le cout est disproportionne : DNA Center necessite un serveur dedie (appliance physique ou VM puissante) et des licences annuelles
- La complexite ajoutee : installer, configurer et maintenir DNA Center est un projet en soi
- Le benefice est marginal : gerer 3 switches en CLI prend quelques minutes, la centralisation n'apporte pas de gain significatif

**Pour DNA Center (meme avec 3 switches) :**
- Si ces 3 switches font partie d'un reseau qui va grandir rapidement
- Si les exigences de securite et de conformite imposent un outil de verification automatisee
- Si l'equipe souhaite experimenter et se former sur les outils modernes

**Reponse pragmatique :** Pour un petit reseau, la gestion CLI reste parfaitement adequate. L'investissement dans un controleur se justifie quand le nombre d'equipements ou la complexite des politiques depasse ce qu'une equipe peut gerer manuellement de maniere fiable.

> **Analogie :** C'est comme un tableur Excel vs un ERP. Pour 10 lignes de comptabilite, Excel suffit largement. Pour 10 000 lignes avec de la facturation, de la paie et des stocks, un ERP devient necessaire. Le CLI est le "Excel" du reseau, DNA Center est le "ERP".

</details>

---

## Point exam

Ce qu'il faut absolument retenir pour le CCNA 200-301 concernant DNA Center et la gestion controller-based :

| Sujet | Ce qui est teste |
|-------|-----------------|
| **DNA Center** | Savoir que c'est le controleur SDN de Cisco pour les reseaux campus |
| **Northbound API** | API REST (JSON) exposee vers l'administrateur et les outils d'automatisation |
| **Southbound API** | NETCONF, RESTCONF, SSH/CLI — protocoles entre le controleur et les equipements |
| **CLI vs Controller** | Savoir comparer les deux approches : avantages et inconvenients de chacune |
| **Overlay / Underlay / Fabric** | L'underlay est le reseau physique (cables, routage IP). L'overlay est le reseau virtuel cree par-dessus (tunnels VXLAN). La fabric est l'ensemble underlay + overlay gere par DNA Center (SD-Access) |
| **Intent-based networking** | DNA Center traduit l'intention de l'administrateur en configurations deployees automatiquement |
| **SWIM** | Software Image Management — gestion centralisee des mises a jour IOS |

> **Vocabulaire a connaitre :**
>
> | Terme | Definition |
> |-------|-----------|
> | **Underlay** | Infrastructure reseau physique : les cables, les switches, les routeurs, le routage IP classique (OSPF/IS-IS). C'est le reseau "reel" |
> | **Overlay** | Reseau virtuel construit par-dessus l'underlay via des tunnels (VXLAN). Permet de creer des segments logiques independants de la topologie physique |
> | **Fabric** | L'ensemble underlay + overlay, orchestre par DNA Center. Dans le contexte Cisco, on parle de **SD-Access** (Software-Defined Access) |
> | **Control plane node** | Equipement qui gere la base de donnees de localisation des endpoints dans la fabric (protocol LISP) |
> | **Edge node** | Switch qui connecte les endpoints (PCs, telephones, serveurs) a la fabric |
> | **Border node** | Equipement qui connecte la fabric au reste du reseau (WAN, Internet, datacenter) |
>
> Au CCNA, on ne vous demandera pas de configurer une fabric SD-Access. Mais vous devez connaitre les termes et comprendre l'architecture a haut niveau.
