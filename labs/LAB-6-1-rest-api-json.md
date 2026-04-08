# LAB 6.1 — APIs REST, verbes HTTP et format JSON

| Info | Valeur |
|------|--------|
| **Module** | 6 — Automatisation et programmabilite |
| **Topics couverts** | 6.5 (APIs REST), 6.7 (JSON et format de donnees) |
| **Difficulte** | Debutant |
| **Duree estimee** | 30 minutes |
| **Outil** | Navigateur web + curl (ou Postman) |

---

## Architecture conceptuelle

```
┌──────────────────────────────────────────────────────────────┐
│                      Client REST                             │
│               (navigateur, curl, script Python)              │
└──────────────┬───────────────────────────────┬───────────────┘
               │                               │
               │   Requete HTTP                │   Reponse HTTP
               │   (GET, POST, PUT, DELETE)    │   (JSON + code status)
               │                               │
               ▼                               │
┌──────────────────────────────────────────────────────────────┐
│                    Serveur API REST                           │
│              (controleur SDN, DNA Center, etc.)              │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│   /api/v1/network-device       → liste des equipements      │
│   /api/v1/network-device/{id}  → un equipement specifique   │
│   /api/v1/interface            → liste des interfaces       │
│   /api/v1/host                 → liste des hotes            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Ce lab ne necessite pas Packet Tracer. Il utilise un navigateur web et l'outil curl (ou Postman) pour explorer les concepts fondamentaux des APIs REST dans un contexte reseau. L'objectif est de comprendre comment les equipements modernes sont geres via des APIs, en complement (ou en remplacement) du CLI traditionnel.

---

## Objectifs

1. Comprendre les principes fondamentaux de l'architecture REST
2. Associer les verbes HTTP aux operations CRUD
3. Interpreter les codes de reponse HTTP
4. Lire et manipuler des donnees au format JSON
5. Effectuer une requete API reelle vers un sandbox Cisco DevNet
6. Comparer l'approche CLI traditionnelle avec l'approche API

---

## Prerequis

- Savoir ouvrir un terminal (PowerShell, CMD, ou terminal Linux/Mac)
- Connaitre le concept basique de client/serveur (un client demande, un serveur repond)
- Avoir curl installe (present par defaut sur Windows 10+, macOS et Linux)
- Optionnel : avoir Postman installe (gratuit, interface graphique plus visuelle)

---

## Partie 1 : Comprendre REST et CRUD

### Etape 1.1 : Les principes REST

REST (REpresentational State Transfer) n'est pas un protocole, c'est un **style d'architecture** defini en 2000 par Roy Fielding. Une API est dite "RESTful" quand elle respecte ces principes :

| Principe | Signification | Exemple concret |
|----------|---------------|-----------------|
| **Client-Server** | Le client et le serveur sont independants. Le client n'a pas besoin de connaitre l'implementation du serveur | Votre script Python (client) interroge DNA Center (serveur) sans connaitre sa base de donnees interne |
| **Stateless** | Chaque requete contient **toutes** les informations necessaires. Le serveur ne garde aucun souvenir des requetes precedentes | Chaque appel API inclut le token d'authentification. Le serveur ne "se souvient" pas que vous vous etes authentifie avant |
| **Uniform Interface** | Les ressources sont identifiees par des URLs standardisees et manipulees via les verbes HTTP | `/api/v1/network-device` identifie toujours la collection d'equipements, quel que soit le client |
| **Cacheable** | Les reponses indiquent si elles peuvent etre mises en cache | Un GET sur la liste des equipements peut etre cache pendant 60 secondes |

> **Pourquoi c'est important pour le reseau ?** Avant REST, chaque constructeur avait son propre protocole de gestion (SNMP, CLI proprietaire, interfaces web non standardisees). Avec REST, un meme script Python peut gerer un switch Cisco, un routeur Juniper et un pare-feu Palo Alto : il suffit de changer l'URL de base.

### Etape 1.2 : CRUD et les verbes HTTP

CRUD est un acronyme qui designe les quatre operations fondamentales sur les donnees. Chaque operation correspond a un verbe HTTP :

| Operation CRUD | Verbe HTTP | Description | Exemple reseau |
|----------------|-----------|-------------|----------------|
| **C**reate | `POST` | Creer une nouvelle ressource | Ajouter un VLAN sur un switch |
| **R**ead | `GET` | Lire / recuperer une ressource | Lister tous les equipements du reseau |
| **U**pdate | `PUT` / `PATCH` | Modifier une ressource existante | Modifier le hostname d'un routeur |
| **D**elete | `DELETE` | Supprimer une ressource | Supprimer un VLAN |

> **Point exam CCNA :** La correspondance CRUD ↔ verbes HTTP est un classique de l'examen. Retenez-la par coeur. L'examen teste aussi la difference entre PUT (remplacement complet de la ressource) et PATCH (modification partielle), mais en pratique au CCNA on vous demandera surtout la correspondance de base.

### Etape 1.3 : Les codes de reponse HTTP

Chaque reponse HTTP inclut un code numerique a trois chiffres qui indique le resultat de la requete. Les voici regroupes par famille :

| Famille | Signification | Codes frequents |
|---------|---------------|-----------------|
| **2xx** | Succes | `200 OK` — requete reussie |
| | | `201 Created` — ressource creee avec succes (reponse a un POST) |
| | | `204 No Content` — succes mais pas de contenu a retourner (souvent apres un DELETE) |
| **3xx** | Redirection | `301 Moved Permanently` — la ressource a change d'URL |
| **4xx** | Erreur client | `400 Bad Request` — requete mal formee (JSON invalide, parametre manquant) |
| | | `401 Unauthorized` — authentification requise ou token invalide |
| | | `403 Forbidden` — authentifie mais droits insuffisants |
| | | `404 Not Found` — la ressource demandee n'existe pas |
| **5xx** | Erreur serveur | `500 Internal Server Error` — le serveur a rencontre un probleme |

> **Astuce :** Retenez la logique des familles. 2xx = tout va bien, 4xx = c'est votre faute (mauvaise URL, pas d'authentification), 5xx = c'est la faute du serveur. A l'examen, on vous demandera d'interpreter un code de reponse dans un scenario.

---

## Partie 2 : Anatomie d'une requete/reponse REST

### Etape 2.1 : Structure d'une URL d'API

Une URL d'API REST se decompose comme suit :

```
https://sandboxdnac.cisco.com/dna/intent/api/v1/network-device?limit=5
└──────────────────────────┘ └─────────────────────────────┘ └───────┘
        Base URL                       Endpoint                Parametres
                                                              de requete
```

| Composant | Role | Exemple |
|-----------|------|---------|
| **Base URL** | Adresse du serveur API | `https://sandboxdnac.cisco.com` |
| **Endpoint** | Chemin vers la ressource | `/dna/intent/api/v1/network-device` |
| **Parametres** | Filtres, pagination, options | `?limit=5&offset=0` |

### Etape 2.2 : Les headers HTTP importants

Les headers sont des metadonnees envoyees avec la requete ou la reponse. Voici les plus courants en contexte API :

| Header | Direction | Role | Exemple |
|--------|-----------|------|---------|
| `Content-Type` | Requete et reponse | Indique le format des donnees | `application/json` |
| `Authorization` | Requete | Transmet le token d'authentification | `Bearer eyJhbG...` |
| `Accept` | Requete | Format de reponse souhaite | `application/json` |

### Etape 2.3 : Exemples avec un equipement reseau

Imaginons une API de gestion reseau. Voici comment les quatre operations CRUD se traduisent en requetes HTTP concretes :

**Lister tous les equipements (Read) :**

```
GET /api/v1/network-device HTTP/1.1
Host: controller.lab.local
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Accept: application/json
```

Reponse : `200 OK` + liste JSON des equipements.

**Ajouter un equipement (Create) :**

```
POST /api/v1/network-device HTTP/1.1
Host: controller.lab.local
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "ipAddress": "10.10.20.5",
  "snmpVersion": "v2c",
  "snmpROCommunity": "readonly",
  "type": "NETWORK_DEVICE"
}
```

Reponse : `201 Created` + details de l'equipement ajoute.

**Modifier un equipement (Update) :**

```
PUT /api/v1/network-device/abc-123-def
Host: controller.lab.local
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json

{
  "hostname": "SW-CORE-01-UPDATED",
  "managementIpAddress": "10.10.20.1",
  "role": "DISTRIBUTION"
}
```

Reponse : `200 OK` + equipement modifie.

**Supprimer un equipement (Delete) :**

```
DELETE /api/v1/network-device/abc-123-def
Host: controller.lab.local
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

Reponse : `204 No Content` (supprime, rien a retourner).

> **Remarque :** Notez que POST agit sur la collection (`/network-device`) tandis que PUT et DELETE agissent sur une ressource specifique identifiee par son ID (`/network-device/abc-123-def`). C'est un pattern fondamental de REST.

---

## Partie 3 : Manipuler du JSON

### Etape 3.1 : Qu'est-ce que JSON ?

JSON (JavaScript Object Notation) est le format standard d'echange de donnees pour les APIs REST modernes. Il est lisible par les humains et facile a parser par les machines.

Les deux structures de base :

| Structure | Syntaxe | Description |
|-----------|---------|-------------|
| **Objet** | `{ }` | Collection de paires cle:valeur. L'equivalent d'un dictionnaire |
| **Tableau** | `[ ]` | Liste ordonnee de valeurs. L'equivalent d'une liste |

Les types de donnees possibles :

| Type | Exemple | Notes |
|------|---------|-------|
| String (chaine) | `"SW-CORE-01"` | Toujours entre guillemets doubles |
| Number (nombre) | `42`, `3.14` | Pas de guillemets |
| Boolean | `true`, `false` | Pas de guillemets, en minuscules |
| Null | `null` | Absence de valeur, en minuscules |
| Object | `{"key": "value"}` | Imbrication possible |
| Array | `[1, 2, 3]` | Peut contenir n'importe quel type |

### Etape 3.2 : Exemple concret — donnees d'un equipement reseau

Voici un exemple realiste de reponse JSON representant un switch :

```json
{
  "hostname": "SW-CORE-01",
  "managementIpAddress": "10.10.20.1",
  "platformId": "C9300-48T",
  "softwareVersion": "17.3.1",
  "role": "ACCESS",
  "upTime": "45 days, 12:30:15",
  "reachabilityStatus": "Reachable",
  "interfaces": [
    {
      "name": "GigabitEthernet1/0/1",
      "status": "up",
      "vlan": 10
    },
    {
      "name": "GigabitEthernet1/0/2",
      "status": "down",
      "vlan": 20
    }
  ]
}
```

### Etape 3.3 : Exercices d'extraction

A partir du JSON ci-dessus, repondez aux questions suivantes :

**Exercice 1 :** Quel est le hostname de l'equipement ?

<details>
<summary>Voir la reponse</summary>

`SW-CORE-01` — c'est la valeur associee a la cle `"hostname"`. Le type est **string** (chaine de caracteres, entre guillemets).

</details>

**Exercice 2 :** Combien d'interfaces sont listees et quel est le statut de la deuxieme ?

<details>
<summary>Voir la reponse</summary>

Il y a **2 interfaces** (le tableau `"interfaces"` contient 2 objets). La deuxieme interface (`GigabitEthernet1/0/2`) a le statut `"down"` et appartient au VLAN `20`.

</details>

**Exercice 3 :** Quel est le type de la valeur `10` dans `"vlan": 10` ?

<details>
<summary>Voir la reponse</summary>

C'est un **number** (nombre). On le reconnait parce qu'il n'y a pas de guillemets autour. Si c'etait `"10"` (avec guillemets), ce serait un string.

</details>

**Exercice 4 :** Reecrivez le JSON pour indiquer que l'equipement est injoignable et que l'interface GigabitEthernet1/0/1 est dans le VLAN 30.

<details>
<summary>Voir la reponse</summary>

Il suffit de modifier deux valeurs :

```json
{
  "hostname": "SW-CORE-01",
  "managementIpAddress": "10.10.20.1",
  "platformId": "C9300-48T",
  "softwareVersion": "17.3.1",
  "role": "ACCESS",
  "upTime": "45 days, 12:30:15",
  "reachabilityStatus": "Unreachable",
  "interfaces": [
    {
      "name": "GigabitEthernet1/0/1",
      "status": "up",
      "vlan": 30
    },
    {
      "name": "GigabitEthernet1/0/2",
      "status": "down",
      "vlan": 20
    }
  ]
}
```

Les modifications : `"reachabilityStatus"` passe de `"Reachable"` a `"Unreachable"`, et `"vlan"` de `10` a `30` pour la premiere interface.

</details>

### Etape 3.4 : Erreurs JSON courantes

Attention a ces pieges frequents (et testables a l'examen) :

```json
// ERREUR 1 : guillemets simples (invalide en JSON)
{'hostname': 'SW-01'}

// CORRECT :
{"hostname": "SW-01"}
```

```json
// ERREUR 2 : virgule apres le dernier element (trailing comma)
{
  "hostname": "SW-01",
  "ip": "10.10.20.1",
}

// CORRECT :
{
  "hostname": "SW-01",
  "ip": "10.10.20.1"
}
```

```json
// ERREUR 3 : cles sans guillemets (invalide en JSON, valide en JavaScript)
{hostname: "SW-01"}

// CORRECT :
{"hostname": "SW-01"}
```

> **Point exam :** L'examen CCNA peut vous montrer un extrait JSON et vous demander d'identifier l'erreur. Les trois erreurs ci-dessus sont les plus frequentes.

---

## Partie 4 : Exercice pratique avec curl

### Etape 4.1 : Le sandbox Cisco DevNet

Cisco met a disposition des sandboxes (environnements de test) gratuits via DevNet. Le sandbox DNA Center "Always-On" est accessible sans reservation :

| Information | Valeur |
|-------------|--------|
| **URL** | `https://sandboxdnac.cisco.com` |
| **Username** | `devnetuser` |
| **Password** | `Cisco123!` |

> **Attention :** Ce sandbox est partage par des milliers d'utilisateurs dans le monde. Il peut etre temporairement indisponible ou lent. C'est normal. Si le sandbox est inaccessible, utilisez les exemples statiques fournis dans l'etape 4.4.

### Etape 4.2 : Obtenir un token d'authentification

Avant de pouvoir interroger l'API DNA Center, il faut s'authentifier. DNA Center utilise un systeme de token : on envoie ses identifiants une premiere fois, et on recoit un token temporaire a reutiliser pour les requetes suivantes.

Ouvrez un terminal et tapez :

```bash
curl -s -k -X POST "https://sandboxdnac.cisco.com/dna/system/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -u "devnetuser:Cisco123!" | python -m json.tool
```

Decomposons cette commande :

| Element | Role |
|---------|------|
| `curl` | Outil en ligne de commande pour faire des requetes HTTP |
| `-s` | Mode silencieux (pas de barre de progression) |
| `-k` | Accepter les certificats SSL auto-signes (necessaire pour le sandbox) |
| `-X POST` | Utiliser le verbe HTTP POST |
| `-H "Content-Type: application/json"` | Header indiquant le format JSON |
| `-u "devnetuser:Cisco123!"` | Authentification Basic (username:password) |
| `python -m json.tool` | Formater la reponse JSON pour la lisibilite |

**Reponse attendue :**

```json
{
    "Token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2M..."
}
```

Copiez ce token, vous en aurez besoin pour les requetes suivantes. Stockez-le dans une variable pour simplifier :

```bash
TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2M..."
```

### Etape 4.3 : Lister les equipements reseau

Maintenant, utilisez le token pour interroger l'API :

```bash
curl -s -k "https://sandboxdnac.cisco.com/dna/intent/api/v1/network-device" \
  -H "X-Auth-Token: $TOKEN" \
  -H "Accept: application/json" | python -m json.tool
```

Cette requete effectue un **GET** sur l'endpoint `/dna/intent/api/v1/network-device`, ce qui correspond a l'operation **Read** (CRUD). On recupere la liste de tous les equipements geres par DNA Center.

### Etape 4.4 : Interpreter la reponse

Voici un extrait typique de la reponse (simplifie pour la clarte) :

```json
{
  "response": [
    {
      "hostname": "cat_9k_1.abc.inc",
      "managementIpAddress": "10.10.20.81",
      "platformId": "C9300-24UX",
      "softwareVersion": "17.9.20220318:182713",
      "type": "Cisco Catalyst 9300 Switch",
      "role": "ACCESS",
      "upTime": "67 days, 4:52:31.00",
      "reachabilityStatus": "Reachable",
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "series": "Cisco Catalyst 9300 Series Switches",
      "lastUpdateTime": 1712234567890,
      "macAddress": "00:1A:2B:3C:4D:5E"
    },
    {
      "hostname": "cat_9k_2.abc.inc",
      "managementIpAddress": "10.10.20.82",
      "platformId": "C9300-24UX",
      "softwareVersion": "17.9.20220318:182713",
      "type": "Cisco Catalyst 9300 Switch",
      "role": "ACCESS",
      "upTime": "67 days, 4:50:12.00",
      "reachabilityStatus": "Reachable",
      "id": "f6e5d4c3-b2a1-0987-6543-210fedcba987",
      "series": "Cisco Catalyst 9300 Series Switches",
      "lastUpdateTime": 1712234567891,
      "macAddress": "00:1A:2B:3C:4D:5F"
    },
    {
      "hostname": "cs3850.abc.inc",
      "managementIpAddress": "10.10.20.80",
      "platformId": "WS-C3850-48U-E",
      "softwareVersion": "16.12.4",
      "type": "Cisco Catalyst38xx stack-able ethernet switch",
      "role": "CORE",
      "upTime": "120 days, 8:15:33.00",
      "reachabilityStatus": "Reachable",
      "id": "11223344-5566-7788-99aa-bbccddeeff00",
      "series": "Cisco Catalyst 3850 Series Ethernet Stackable Switch",
      "lastUpdateTime": 1712234567892,
      "macAddress": "00:2A:3B:4C:5D:6E"
    }
  ],
  "version": "1.0"
}
```

**Analysons cette reponse :**

- La structure globale est un **objet** (accolades `{}`) avec deux cles : `"response"` et `"version"`
- `"response"` contient un **tableau** (crochets `[]`) de 3 objets, chacun representant un equipement
- Chaque equipement a des proprietes comme `hostname`, `managementIpAddress`, `platformId`, etc.
- Toutes les valeurs textuelles sont des **strings**, `lastUpdateTime` est un **number** (timestamp Unix en millisecondes)

> **Comparaison mentale :** Pour obtenir ces memes informations en CLI traditionnel, il faudrait se connecter en SSH a chacun des 3 equipements et taper `show version` + `show ip interface brief` sur chacun. L'API vous donne tout en une seule requete.

---

## Partie 5 : Comparer CLI vs API

### Etape 5.1 : Tableau comparatif

| Critere | CLI traditionnel | API REST |
|---------|-----------------|----------|
| **Scalabilite** | 1 session SSH par equipement. 100 equipements = 100 connexions manuelles | 1 requete peut retourner la liste des 100 equipements |
| **Automatisation** | Possible mais complexe (scripts expect, Paramiko). Le parsing de texte brut est fragile | Natif. Les donnees sont structurees en JSON, directement exploitables par un programme |
| **Format de sortie** | Texte brut non structure, different selon la version d'IOS | JSON structure, standardise, predictible |
| **Courbe d'apprentissage** | Faible pour les taches simples (show, configure) | Plus elevee initialement (HTTP, JSON, authentification) |
| **Idempotence** | Non garantie. Relancer un script CLI peut creer des doublons | PUT est idempotent par conception. Relancer la meme requete donne le meme resultat |
| **Gestion des erreurs** | Parser le texte de sortie pour detecter les erreurs | Codes HTTP standardises (200, 404, 500...) |
| **Temps reel** | Il faut interroger chaque equipement | Le controleur centralise les donnees |

### Etape 5.2 : Quand utiliser quoi ?

**Privilegier le CLI quand :**
- Vous diagnostiquez un probleme sur un seul equipement
- Vous faites une modification ponctuelle rapide
- L'equipement n'est pas gere par un controleur
- Vous etes en situation d'urgence sans acces au controleur

**Privilegier l'API quand :**
- Vous gerez un parc de plus de 10 equipements
- Vous devez appliquer la meme configuration sur plusieurs devices
- Vous avez besoin de donnees structurees pour un rapport ou un tableau de bord
- Vous automatisez des taches repetitives (provisionning, inventaire, audit)

> **Realite du terrain :** Dans les reseaux modernes, les deux approches coexistent. Un ingenieur reseau utilise le CLI pour le debug en direct et l'API (via un controleur comme DNA Center) pour les operations en masse et le monitoring. L'examen CCNA attend que vous compreniez les avantages de chaque approche.

---

## Verification finale

Cochez chaque critere pour valider la reussite du lab :

- [ ] Vous savez associer chaque verbe HTTP a son operation CRUD (POST=Create, GET=Read, PUT/PATCH=Update, DELETE=Delete)
- [ ] Vous savez interpreter les codes de reponse HTTP par famille (2xx succes, 4xx erreur client, 5xx erreur serveur)
- [ ] Vous savez lire un document JSON et identifier les types de donnees (string, number, boolean, null, object, array)
- [ ] Vous savez reperer les erreurs de syntaxe JSON courantes (guillemets simples, trailing comma, cles sans guillemets)
- [ ] Vous comprenez la structure d'une URL d'API (base URL + endpoint + parametres)
- [ ] Vous avez effectue (ou compris) une requete curl vers une API REST
- [ ] Vous pouvez expliquer la difference entre une approche CLI et une approche API pour gerer un parc reseau

---

## Questions de reflexion

### Question 1 — Pourquoi JSON est-il prefere a XML pour les APIs REST modernes ?

<details>
<summary>Voir la reponse</summary>

JSON est prefere a XML pour plusieurs raisons :

1. **Legerete :** JSON est beaucoup plus compact. Comparez :
   - JSON : `{"hostname": "SW-01"}` (23 caracteres)
   - XML : `<hostname>SW-01</hostname>` (33 caracteres)
   Pour des reponses contenant des centaines d'equipements, la difference de volume est significative.

2. **Lisibilite :** JSON est plus intuitif a lire pour un humain. Moins de balises, moins de bruit visuel.

3. **Parsing natif :** JSON est directement exploitable en JavaScript (d'ou son nom) et facilement parsable dans tous les langages modernes (Python `json.loads()`, etc.). XML necessite un parseur dedie plus complexe.

4. **Compatibilite web :** Les navigateurs et les frameworks web modernes travaillent nativement en JSON. XML necessite une transformation supplementaire.

Cela dit, XML reste utilise dans certains protocoles reseau comme NETCONF (qui transporte ses donnees en XML). Au CCNA, retenez que REST + JSON est le standard moderne, tandis que NETCONF + XML est aussi utilise dans l'automatisation reseau.

</details>

### Question 2 — Quelle est la difference entre PUT et PATCH ?

<details>
<summary>Voir la reponse</summary>

Les deux servent a modifier une ressource existante, mais de maniere differente :

- **PUT** remplace **integralement** la ressource. Vous devez envoyer **tous** les champs, meme ceux qui ne changent pas. Si vous oubliez un champ, il sera supprime ou remis a sa valeur par defaut.

- **PATCH** effectue une modification **partielle**. Vous n'envoyez que les champs a modifier. Les champs non mentionnes restent inchanges.

Exemple concret :

Un equipement a ces proprietes : `hostname`, `ip`, `role`, `version`.

Avec **PUT** pour changer seulement le hostname, vous devez envoyer :
```json
{"hostname": "SW-NEW", "ip": "10.10.20.1", "role": "ACCESS", "version": "17.3.1"}
```

Avec **PATCH** pour la meme modification :
```json
{"hostname": "SW-NEW"}
```

En pratique, PATCH est plus economique en bande passante et moins risque (pas de suppression accidentelle de champs). Mais PUT garantit que l'etat final est exactement ce que vous avez envoye.

Au CCNA, l'essentiel est de savoir que les deux correspondent a l'operation **Update** du CRUD.

</details>

### Question 3 — Un GET retourne un code 401 — que signifie-t-il et comment corriger ?

<details>
<summary>Voir la reponse</summary>

Le code **401 Unauthorized** signifie que la requete n'est pas authentifiee ou que le token d'authentification est invalide/expire.

Causes possibles :
1. **Token manquant** : vous avez oublie le header `Authorization` ou `X-Auth-Token` dans la requete
2. **Token expire** : les tokens ont une duree de vie limitee (souvent 1 heure). Il faut en obtenir un nouveau via l'endpoint d'authentification
3. **Credentials incorrects** : le username ou le password utilise pour obtenir le token est faux
4. **Token mal copie** : une erreur de copier-coller (espace en trop, caractere manquant)

Pour corriger :
1. Verifiez que le header d'authentification est present dans votre requete
2. Obtenez un nouveau token via un POST sur l'endpoint d'authentification
3. Verifiez les credentials (username/password)

Ne confondez pas avec **403 Forbidden** : un 403 signifie que vous etes bien authentifie mais que votre compte n'a pas les **permissions** necessaires pour cette action. Un 401 est un probleme d'**identite**, un 403 est un probleme de **droits**.

</details>

### Question 4 — Comment une API REST permet-elle de configurer 100 switches en meme temps, alors que le CLI ne le permet pas ?

<details>
<summary>Voir la reponse</summary>

Avec le CLI, vous devez ouvrir une session SSH vers chaque switch individuellement, taper les commandes, verifier le resultat et passer au suivant. C'est un processus **sequentiel** et **manuel**. Pour 100 switches, c'est des heures de travail et un risque d'erreur eleve (oubli d'un switch, faute de frappe, inconsistance).

Avec une API REST et un controleur comme DNA Center, le processus est fondamentalement different :

1. **Le controleur connait deja tous les equipements** : il a decouvert les 100 switches et maintient un inventaire centralise.

2. **Un seul appel API cree un template** : vous envoyez un POST avec la configuration souhaitee (par exemple : "ajouter VLAN 50 sur tous les switches du site Paris").

3. **Le controleur deploie en parallele** : il se charge de pousser la configuration sur les 100 switches simultanement via ses APIs southbound (NETCONF, RESTCONF, ou CLI via SSH).

4. **Le controleur verifie le resultat** : il confirme que chaque switch a bien applique la configuration et signale les echecs.

Un script Python peut aussi faire la meme chose sans controleur : une boucle `for` qui itere sur 100 adresses IP et envoie la meme requete API a chacune. Meme sequentiellement, c'est beaucoup plus rapide et fiable qu'un humain.

C'est l'un des arguments les plus forts en faveur de l'approche controller-based que Cisco pousse dans le CCNA.

</details>

---

## Point exam

Ce qu'il faut absolument retenir pour le CCNA 200-301 concernant les APIs REST et JSON :

| Sujet | Ce qui est teste |
|-------|-----------------|
| **CRUD ↔ HTTP** | Savoir associer Create=POST, Read=GET, Update=PUT/PATCH, Delete=DELETE |
| **Codes HTTP** | Connaitre les familles (2xx, 4xx, 5xx) et les codes les plus courants (200, 201, 400, 401, 403, 404, 500) |
| **Principes REST** | Stateless, client-server, uniform interface |
| **JSON** | Reconnaitre un objet `{}`, un tableau `[]`, les types de donnees. Reperer les erreurs de syntaxe |
| **CLI vs API** | Avantages et inconvenients de chaque approche. Quand utiliser quoi |
| **Authentification** | Comprendre le concept de token (obtenu via POST, reutilise dans les requetes suivantes) |

> **Conseil pratique :** L'examen CCNA ne vous demandera pas d'ecrire du code ou de taper des commandes curl. Il vous montrera un extrait JSON ou une requete HTTP et vous demandera d'interpreter ce que vous voyez. Focalisez-vous sur la **comprehension** plutot que sur la memorisation de syntaxe.
