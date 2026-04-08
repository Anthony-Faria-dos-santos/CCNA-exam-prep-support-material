# Module 4 — IP Services

> **Domain** : 4 — IP Services | **Poids examen** : 10%
> **Durée estimée** : 1 semaine | **Prérequis** : Modules 1 à 3
> **Topics couverts** : 4.1 à 4.9

## Objectif du module

À l'issue de ce module, vous serez capable de :
- Configurer et vérifier le NAT statique, le NAT par pool et le PAT (overload)
- Configurer et vérifier NTP en mode client et serveur
- Expliquer le rôle de DHCP et DNS dans un réseau d'entreprise
- Expliquer la fonction de SNMP pour la supervision réseau
- Décrire les fonctionnalités syslog, incluant les facilities et les niveaux de sévérité
- Configurer et vérifier un client DHCP et un relais DHCP
- Expliquer les mécanismes QoS per-hop (classification, marking, queuing, policing, shaping)
- Configurer l'accès distant sécurisé via SSH
- Décrire les capacités de TFTP et FTP pour la gestion des fichiers réseau

---

## 4.1 — NAT statique et pools

> **Exam topic 4.1** : *Configure and verify* — inside source NAT using static and pools
> **Niveau** : Configure/Verify

### Contexte

Quand votre entreprise possède un réseau de 500 postes utilisant des adresses privées (10.x.x.x), comment ces machines accèdent-elles à Internet ? Elles ne peuvent pas envoyer des paquets avec une adresse source privée — les routeurs Internet les jetteraient immédiatement. C'est là qu'intervient le NAT (Network Address Translation) : il traduit les adresses privées en adresses publiques routables avant que les paquets ne quittent le réseau.

### Théorie

Le NAT a été conçu dans les années 1990 pour répondre à l'épuisement des adresses IPv4. Plutôt que d'attribuer une adresse publique à chaque appareil, on utilise des adresses privées en interne (RFC 1918) et le routeur NAT les traduit à la frontière du réseau.

#### Terminologie NAT

Quatre termes reviennent systématiquement dans la documentation Cisco et à l'examen :

| Terme | Définition | Exemple |
|-------|-----------|---------|
| **Inside local** | Adresse IP de l'hôte interne vue depuis l'intérieur | 10.1.1.50 (le PC) |
| **Inside global** | Adresse IP de l'hôte interne vue depuis l'extérieur | 203.0.113.10 (après traduction) |
| **Outside local** | Adresse IP de l'hôte externe vue depuis l'intérieur | 8.8.8.8 (serveur DNS Google) |
| **Outside global** | Adresse IP de l'hôte externe vue depuis l'extérieur | 8.8.8.8 (identique en général) |

Pour retenir : pensez au point de vue. "Inside" = votre réseau. "Local" = vu depuis l'intérieur. "Global" = vu depuis l'extérieur. La plupart du temps, seule l'adresse **inside** change — c'est pourquoi on parle d'**inside source NAT**.

#### Schéma : Flux NAT à travers un routeur

```
          Réseau interne                    Réseau externe (Internet)
         (inside)                           (outside)

  [PC1] 10.1.1.50 ──┐
                     │    ┌──────────────┐
  [PC2] 10.1.1.51 ──┼────┤   R1 (NAT)   ├──── 203.0.113.0/24 ──── [Internet]
                     │    │              │
  [PC3] 10.1.1.52 ──┘    │ Inside  Out  │
                          │ Gi0/0  Gi0/1 │
                          └──────────────┘
                          10.1.1.1    203.0.113.1

  ── Paquet sortant ──
  Avant NAT : src=10.1.1.50     dst=8.8.8.8
  Après NAT : src=203.0.113.10  dst=8.8.8.8

  ── Paquet retour ──
  Avant NAT : src=8.8.8.8  dst=203.0.113.10
  Après NAT : src=8.8.8.8  dst=10.1.1.50
```

#### Les trois types de NAT

**1. NAT statique (Static NAT)**

Un mapping permanent un-pour-un entre une adresse inside local et une adresse inside global. Utilisé principalement pour les serveurs internes qui doivent être joignables depuis l'extérieur (serveur web, serveur mail).

Caractéristiques :
- Mapping permanent — reste dans la table même sans trafic
- Bidirectionnel — permet l'initiation de connexions depuis l'extérieur
- Consomme une adresse publique par serveur

**2. NAT dynamique (Dynamic NAT avec pool)**

Un pool d'adresses publiques est partagé entre les hôtes internes sur la base du premier arrivé, premier servi. Quand un hôte initie une connexion, il obtient une adresse du pool. Quand la connexion se termine (ou expire), l'adresse retourne dans le pool.

Caractéristiques :
- Mapping temporaire — créé à la demande
- Unidirectionnel — seules les connexions initiées depuis l'intérieur fonctionnent
- Si le pool est épuisé, les nouvelles connexions sont refusées

**3. PAT (Port Address Translation) — aussi appelé NAT overload**

Tous les hôtes internes partagent **une seule** adresse publique (souvent l'adresse de l'interface outside du routeur). La distinction entre les flux se fait grâce aux numéros de port source. C'est le mécanisme le plus courant — c'est ce que fait votre box Internet à la maison.

Caractéristiques :
- Des milliers d'hôtes peuvent partager une seule adresse publique
- Utilise les ports TCP/UDP pour différencier les flux (jusqu'à ~65 000 translations)
- Unidirectionnel par défaut

| Critère | NAT statique | NAT dynamique (pool) | PAT (overload) |
|---------|-------------|---------------------|----------------|
| Mapping | 1:1 permanent | 1:1 temporaire | N:1 (port-based) |
| Direction | Bidirectionnel | Inside → Outside | Inside → Outside |
| Adresses publiques | 1 par hôte | Pool partagé | 1 pour tous |
| Cas d'usage | Serveurs publics | Groupes d'utilisateurs | Accès Internet général |
| Connexion entrante | Oui | Non | Non (sauf port forwarding) |

### Mise en pratique CLI

#### Configuration NAT statique

```cisco
! Sur R1 — mapper le serveur web interne 10.1.1.100 vers 203.0.113.10
R1(config)# ip nat inside source static 10.1.1.100 203.0.113.10
!
! Désigner les interfaces inside et outside
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip nat inside
R1(config-if)# exit
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip nat outside
R1(config-if)# exit
```

#### Configuration NAT dynamique avec pool

```cisco
! Définir le pool d'adresses publiques
R1(config)# ip nat pool POOL-PUBLIC 203.0.113.10 203.0.113.20 netmask 255.255.255.0
!
! Définir quels hôtes internes ont le droit d'utiliser le NAT (ACL)
R1(config)# access-list 1 permit 10.1.1.0 0.0.0.255
!
! Lier l'ACL au pool
R1(config)# ip nat inside source list 1 pool POOL-PUBLIC
!
! Interfaces (si pas déjà configurées)
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip nat inside
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip nat outside
```

#### Configuration PAT (overload)

```cisco
! Méthode 1 : PAT avec l'adresse de l'interface outside
R1(config)# access-list 1 permit 10.1.1.0 0.0.0.255
R1(config)# ip nat inside source list 1 interface GigabitEthernet0/1 overload

! Méthode 2 : PAT avec un pool (overload sur le pool)
R1(config)# ip nat pool PAT-POOL 203.0.113.10 203.0.113.10 netmask 255.255.255.0
R1(config)# ip nat inside source list 1 pool PAT-POOL overload
```

Le mot-clé **overload** est ce qui fait toute la différence entre le NAT dynamique classique et le PAT.

#### Vérification

```cisco
R1# show ip nat translations
Pro  Inside global      Inside local       Outside local      Outside global
tcp  203.0.113.1:1024   10.1.1.50:45320    8.8.8.8:443        8.8.8.8:443
tcp  203.0.113.1:1025   10.1.1.51:52100    142.250.74.46:80   142.250.74.46:80
---  203.0.113.10       10.1.1.100         ---                ---
```

**Interprétation** :
- Les deux premières lignes sont des translations PAT (notez les numéros de port et le protocole `tcp`). L'adresse 203.0.113.1 est partagée — seuls les ports diffèrent.
- La troisième ligne est un mapping NAT statique (pas de port, pas de protocole, marqué `---`). Il est permanent et apparaît même sans trafic actif.

```cisco
R1# show ip nat statistics
Total active translations: 3 (1 static, 2 dynamic; 2 extended)
Peak translations: 47, occurred 01:23:45 ago
Outside interfaces:
  GigabitEthernet0/1
Inside interfaces:
  GigabitEthernet0/0
Hits: 15234  Misses: 12
CEF Translated packets: 15234, CEF Punted packets: 0
Expired translations: 44
Dynamic mappings:
-- Inside Source
[Id: 1] access-list 1 interface GigabitEthernet0/1 refcount 2
```

**Interprétation** :
- **Hits** : nombre de paquets ayant trouvé une translation existante
- **Misses** : paquets ayant nécessité la création d'une nouvelle translation
- **refcount** : nombre de translations actives utilisant cette règle dynamique

Pour effacer les translations dynamiques (utile en troubleshooting) :
```cisco
R1# clear ip nat translation *
```

> Cette commande ne supprime pas les translations statiques — elles sont permanentes.

### Point exam

> **Piège courant** : Oublier de configurer `ip nat inside` ou `ip nat outside` sur les interfaces. Sans ces commandes, le NAT ne fonctionne tout simplement pas, même si la règle de translation est correcte. C'est la première chose à vérifier en cas de problème.
>
> **À retenir** : Le mot-clé **overload** distingue le PAT du NAT dynamique classique. Sans `overload`, chaque hôte interne consomme une adresse du pool entière. Avec `overload`, des milliers d'hôtes partagent une seule adresse grâce aux ports.
>
> **Attention** : À l'examen, les termes inside local / inside global / outside local / outside global sont souvent testés avec des scénarios où il faut identifier quelle adresse correspond à quel terme. Retenez le tableau des 4 termes.

### Exercice 4.1 — NAT statique + PAT

**Contexte** : L'entreprise NetCorp a un réseau interne 172.16.0.0/16. Le FAI a attribué le bloc 198.51.100.0/28 (14 adresses utilisables). Le serveur web interne (172.16.1.100) doit être accessible depuis Internet sur l'adresse 198.51.100.10. Tous les autres postes doivent accéder à Internet via PAT sur l'adresse de l'interface outside (198.51.100.1).

**Consigne** : Écrivez la configuration complète du routeur NAT-GW (interfaces Gi0/0 inside, Gi0/1 outside).

**Indice** : <details><summary>Voir l'indice</summary>Vous avez besoin de deux règles NAT : une statique pour le serveur web et une dynamique avec overload pour le reste. L'ACL doit matcher le réseau 172.16.0.0/16.</details>

<details>
<summary>Solution</summary>

```cisco
NAT-GW(config)# interface GigabitEthernet0/0
NAT-GW(config-if)# ip address 172.16.0.1 255.255.0.0
NAT-GW(config-if)# ip nat inside
NAT-GW(config-if)# no shutdown
NAT-GW(config-if)# exit
!
NAT-GW(config)# interface GigabitEthernet0/1
NAT-GW(config-if)# ip address 198.51.100.1 255.255.255.240
NAT-GW(config-if)# ip nat outside
NAT-GW(config-if)# no shutdown
NAT-GW(config-if)# exit
!
! NAT statique pour le serveur web
NAT-GW(config)# ip nat inside source static 172.16.1.100 198.51.100.10
!
! PAT pour tous les autres hôtes
NAT-GW(config)# access-list 1 permit 172.16.0.0 0.0.255.255
NAT-GW(config)# ip nat inside source list 1 interface GigabitEthernet0/1 overload
```

**Explication** : Le NAT statique donne au serveur web une adresse publique fixe et permanente, permettant les connexions entrantes. Le PAT (overload sur l'interface) permet à tous les autres hôtes du réseau 172.16.0.0/16 de partager l'adresse 198.51.100.1 pour accéder à Internet. Le wildcard mask `0.0.255.255` correspond au /16.

</details>

### Voir aussi

- Topic 1.7 dans Module 1 (adressage IPv4 privé — RFC 1918, la raison d'être du NAT)
- Topic 3.3.a dans Module 3 (route par défaut — le routeur NAT a besoin d'une default route vers le FAI)
- Topic 5.6 dans Module 5 (ACLs — les ACLs utilisées par le NAT suivent la même syntaxe)

---

## 4.2 — NTP (client et serveur)

> **Exam topic 4.2** : *Configure and verify* — NTP operating in a client and server mode
> **Niveau** : Configure/Verify

### Contexte

Imaginez qu'un incident de sécurité se produit à 14h32. Vous consultez les logs du routeur — il affiche 14h28. Le switch indique 15h45. Le pare-feu montre 14h31. Reconstituer la chronologie de l'attaque devient un casse-tête. Le protocole NTP (Network Time Protocol) résout ce problème en synchronisant toutes les horloges réseau sur une référence commune, avec une précision à la milliseconde.

### Théorie

NTP est un protocole de la couche application (UDP port 123) conçu en 1985 par David Mills. Il utilise un modèle hiérarchique organisé en **strates** (stratum) :

```
           ┌─────────────────┐
           │  Stratum 0      │  Horloge atomique, GPS
           │  (référence)    │  Non accessible directement par NTP
           └────────┬────────┘
                    │
           ┌────────┴────────┐
           │  Stratum 1      │  Serveurs NTP connectés directement
           │  (serveur root) │  à une horloge Stratum 0
           └────────┬────────┘
                    │
           ┌────────┴────────┐
           │  Stratum 2      │  Serveurs synchronisés sur Stratum 1
           │  (serveur)      │  (ex: pool.ntp.org)
           └────────┬────────┘
                    │
           ┌────────┴────────┐
           │  Stratum 3      │  Vos routeurs et switches
           │  (client)       │  synchronisés sur Stratum 2
           └─────────────────┘

  Plus le stratum est bas, plus la source est fiable.
  Maximum : Stratum 15. Stratum 16 = non synchronisé.
```

Chaque niveau ajoute un stratum. Un serveur Stratum 2 synchronisé sur un Stratum 1 transmet le temps avec un stratum de 3 à ses clients. Au-delà de Stratum 15, l'horloge est considérée comme non fiable.

#### Pourquoi NTP est critique en entreprise

- **Corrélation des logs** : sans horloge synchronisée, l'investigation d'incidents est compromise
- **Certificats TLS/SSL** : un certificat est valide dans un intervalle de temps — une horloge décalée peut rejeter des certificats valides ou accepter des certificats expirés
- **Authentification Kerberos** : tolère un décalage maximal de 5 minutes entre client et serveur
- **Protocoles de routage** : OSPF utilise des timestamps dans certains messages

### Mise en pratique CLI

#### Configurer un routeur comme client NTP

```cisco
! Pointer vers un serveur NTP (ici, un serveur interne 10.1.1.254)
R1(config)# ntp server 10.1.1.254

! Optionnel : définir un second serveur pour la redondance
R1(config)# ntp server 10.1.1.253

! Optionnel : définir le fuseau horaire
R1(config)# clock timezone CET 1
R1(config)# clock summer-time CEST recurring
```

#### Configurer un routeur comme serveur NTP (master)

```cisco
! Déclarer ce routeur comme source NTP locale (stratum 4)
R1(config)# ntp master 4

! Les autres équipements pourront se synchroniser sur R1
```

> Un routeur configuré avec `ntp master` génère son propre temps. Utilisez cette commande uniquement dans un lab ou dans un réseau isolé sans accès à un serveur NTP externe.

#### Vérification

```cisco
R1# show ntp status
Clock is synchronized, stratum 5, reference is 10.1.1.254
nominal freq is 250.0000 Hz, actual freq is 249.9998 Hz, precision is 2**18
ntp uptime is 864000 (1/100 of seconds), resolution is 4000
reference time is E4A1B2C3.4D5E6F70 (14:32:15.302 CET Fri Apr 4 2026)
clock offset is 0.5234 msec, root delay is 12.45 msec
root dispersion is 25.67 msec, peer dispersion is 1.23 msec
loopfilter state is 'CTRL' (Normal Controlled Loop),
drift is 0.000008 s/s
```

**Interprétation** :
- **Clock is synchronized** : la synchronisation a réussi (peut prendre plusieurs minutes après configuration)
- **stratum 5** : ce routeur est Stratum 5 (son serveur est Stratum 4)
- **reference is 10.1.1.254** : le serveur NTP utilisé
- **clock offset is 0.5234 msec** : décalage résiduel avec le serveur — excellent (< 1 ms)

```cisco
R1# show ntp associations
  address         ref clock       st   when   poll reach  delay  offset   disp
*~10.1.1.254      10.1.1.1         4     32     64   377  12.4    0.52    1.23
+~10.1.1.253      10.1.1.1         4     45     64   377  15.2    1.10    2.45
 * sys.peer, # selected, + candidate, - outlyer, x falseticker, ~ configured
```

**Interprétation** :
- **\*** (astérisque) : serveur actuellement sélectionné comme source (sys.peer)
- **+** : candidat acceptable comme source de secours
- **reach** : registre octal des 8 dernières tentatives — `377` (octal) = 11111111 (binaire) = 8/8 tentatives réussies
- **poll** : intervalle de polling en secondes (64 s ici)

### Point exam

> **Piège courant** : Confondre `ntp server` (client qui se synchronise sur un serveur externe) et `ntp master` (le routeur devient lui-même source de temps). À l'examen, un scénario peut demander de configurer R1 en tant que **serveur** pour le LAN — il faut alors utiliser `ntp master` sur R1, puis `ntp server <IP-de-R1>` sur les clients.
>
> **À retenir** : Le stratum du client est toujours **stratum du serveur + 1**. Si votre serveur est Stratum 3, votre routeur sera Stratum 4.
>
> **Attention** : NTP utilise **UDP port 123**. La synchronisation initiale peut prendre de 5 à 15 minutes — ne paniquez pas si `show ntp status` affiche "Clock is unsynchronized" juste après la configuration.

### Exercice 4.2 — Synchronisation NTP

**Contexte** : Le réseau de l'entreprise MédiaPlus dispose d'un serveur NTP central (SRV-NTP, 10.10.10.254, stratum 2). Le routeur R1 doit se synchroniser sur ce serveur. Les switches SW1 et SW2 doivent à leur tour se synchroniser sur R1.

**Consigne** : Écrivez les commandes nécessaires sur R1, SW1 et SW2.

**Indice** : <details><summary>Voir l'indice</summary>R1 est à la fois client (de SRV-NTP) et serveur (pour SW1/SW2). Pas besoin de `ntp master` si R1 relaie simplement l'heure reçue d'un serveur externe.</details>

<details>
<summary>Solution</summary>

```cisco
! Sur R1 — client du serveur NTP
R1(config)# ntp server 10.10.10.254

! Sur SW1 — client de R1
SW1(config)# ntp server 10.10.10.1
! (10.10.10.1 = adresse de management de R1)

! Sur SW2 — client de R1
SW2(config)# ntp server 10.10.10.1
```

**Explication** : R1 n'a pas besoin d'être configuré comme `ntp master` — dès qu'il est synchronisé via `ntp server`, il peut servir de référence NTP aux autres équipements. R1 sera Stratum 3 (2+1), et SW1/SW2 seront Stratum 4 (3+1). Un routeur Cisco qui reçoit `ntp server` agit automatiquement comme serveur NTP pour les équipements qui le pointent.

</details>

### Voir aussi

- Topic 4.5 dans ce module (Syslog — la synchronisation NTP est indispensable pour que les timestamps des logs soient cohérents)
- Topic 2.8 dans Module 2 (accès de management — NTP fait partie des services de gestion réseau)

---

## 4.3 — DHCP et DNS : rôles dans le réseau

> **Exam topic 4.3** : *Explain* — the role of DHCP and DNS within the network
> **Niveau** : Explain

### Contexte

Sans DHCP, chaque poste d'un réseau de 500 machines devrait être configuré manuellement : adresse IP, masque, passerelle, serveur DNS. Une seule faute de frappe et c'est le conflit d'adresses. Sans DNS, pour consulter un site web, il faudrait taper `142.250.74.46` au lieu de `google.com`. Ces deux protocoles sont invisibles pour l'utilisateur final mais absolument fondamentaux dans tout réseau, du plus petit au plus grand.

### Théorie

#### DHCP — Dynamic Host Configuration Protocol

DHCP fonctionne sur le modèle client-serveur et utilise les ports UDP 67 (serveur) et UDP 68 (client). Son rôle est d'attribuer automatiquement une configuration IP complète aux clients du réseau.

##### Le processus DORA

L'attribution d'une adresse suit quatre étapes, résumées par l'acronyme **DORA** :

```
  Client                                              Serveur DHCP
    │                                                      │
    │  1. DISCOVER (broadcast)                             │
    │  src: 0.0.0.0  dst: 255.255.255.255                 │
    │ ─────────────────────────────────────────────────► │
    │                                                      │
    │  2. OFFER (unicast ou broadcast)                     │
    │  "Je te propose 10.1.1.50/24"                        │
    │ ◄───────────────────────────────────────────────── │
    │                                                      │
    │  3. REQUEST (broadcast)                              │
    │  "J'accepte l'offre de 10.1.1.50"                    │
    │ ─────────────────────────────────────────────────► │
    │                                                      │
    │  4. ACKNOWLEDGE (unicast ou broadcast)               │
    │  "Confirmé. Bail = 24h"                              │
    │ ◄───────────────────────────────────────────────── │
    │                                                      │
```

Pourquoi le REQUEST est-il en **broadcast** alors que le client connaît déjà le serveur ? Parce que s'il y a plusieurs serveurs DHCP, le REQUEST informe les autres serveurs que leur offre a été refusée — ils peuvent ainsi libérer l'adresse qu'ils avaient réservée.

##### Informations fournies par DHCP

| Paramètre | Obligatoire | Exemple |
|-----------|-------------|---------|
| Adresse IP | Oui | 10.1.1.50 |
| Masque de sous-réseau | Oui | 255.255.255.0 |
| Passerelle par défaut | Optionnel (mais toujours configuré) | 10.1.1.1 |
| Serveur(s) DNS | Optionnel (mais quasi toujours configuré) | 10.1.1.254, 8.8.8.8 |
| Durée du bail (lease time) | Oui | 86400 secondes (24h) |
| Nom de domaine | Optionnel | corp.netcorp.local |

##### Le bail DHCP (lease)

Le client ne possède pas l'adresse — il la loue. À 50% du bail, il tente un renouvellement (DHCP Request unicast au serveur). Si pas de réponse, il réessaie à 87,5%. Si le bail expire sans renouvellement, le client perd son adresse et relance le processus DORA.

#### DNS — Domain Name System

DNS est le service de résolution de noms du réseau. Il traduit les noms de domaine lisibles par l'humain (comme `www.cisco.com`) en adresses IP compréhensibles par les machines (comme `72.163.4.185`). Il fonctionne sur UDP port 53 (requêtes standard) et TCP port 53 (transferts de zone et réponses volumineuses).

##### Hiérarchie DNS

```
                        . (root)
                       / | \
                    com  net  fr     ← TLD (Top-Level Domain)
                   /       \    \
               cisco     example  gouv
              /                      \
           www                       impots
     72.163.4.185                 ???.???.???.???
```

La résolution est **récursive** du point de vue du client : il envoie une requête au serveur DNS local, qui se charge de remonter la hiérarchie si nécessaire (root → TLD → authoritative). Le client ne voit qu'une seule question et une seule réponse.

##### Types d'enregistrements DNS courants

| Type | Rôle | Exemple |
|------|------|---------|
| **A** | Nom → adresse IPv4 | www.cisco.com → 72.163.4.185 |
| **AAAA** | Nom → adresse IPv6 | www.cisco.com → 2001:420:1101:1::185 |
| **CNAME** | Alias vers un autre nom | mail.corp.com → outlook.office365.com |
| **MX** | Serveur de messagerie | corp.com → mail.corp.com (priorité 10) |
| **PTR** | Adresse IP → nom (reverse DNS) | 72.163.4.185 → www.cisco.com |

##### DNS dans un réseau d'entreprise

Dans un réseau Cisco typique, le serveur DNS interne résout les noms locaux (serveurs, imprimantes) et transfère les requêtes pour les domaines externes vers un DNS public (8.8.8.8, 1.1.1.1). Les clients reçoivent l'adresse du DNS via DHCP.

### Mise en pratique CLI

#### Vérifier la configuration DNS sur un routeur

```cisco
R1# show ip dns view
DNS View default parameters:
Logging is off
DNS Resolver settings:
  Domain lookup state: enabled
  Default domain name: corp.netcorp.local
  DNS server address(es):
    10.1.1.254
    8.8.8.8
```

#### Tester la résolution DNS depuis un routeur

```cisco
R1# ping www.cisco.com
Translating "www.cisco.com"...domain server (10.1.1.254) [OK]
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 72.163.4.185, timeout is 2 seconds:
!!!!!
Success rate is 100 percent (5/5), round-trip min/avg/max = 28/32/40 ms
```

#### Configurer un routeur comme serveur DNS (pour un lab)

```cisco
R1(config)# ip dns server
R1(config)# ip host SRV-WEB 10.1.1.100
R1(config)# ip name-server 8.8.8.8
```

#### Vérification DHCP côté client (PC Windows)

```
C:\> ipconfig /all
   DHCP Enabled. . . . . . . . . . . : Yes
   IPv4 Address. . . . . . . . . . . : 10.1.1.50
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 10.1.1.1
   DHCP Server . . . . . . . . . . . : 10.1.1.254
   DNS Servers . . . . . . . . . . . : 10.1.1.254
                                        8.8.8.8
   Lease Obtained. . . . . . . . . . : vendredi 4 avril 2026 08:00:12
   Lease Expires . . . . . . . . . . : samedi 5 avril 2026 08:00:12
```

### Point exam

> **Piège courant** : Confondre les ports DHCP. Le **serveur** écoute sur le port **67**, le **client** utilise le port **68**. Moyen mnémotechnique : 67 < 68, et le serveur vient en premier dans une relation client-serveur.
>
> **À retenir** : DHCP utilise **UDP** (pas TCP). Le DISCOVER et le REQUEST sont des **broadcasts** (destination 255.255.255.255). DNS utilise **UDP port 53** pour les requêtes normales et **TCP port 53** pour les transferts de zone ou les réponses dépassant 512 octets.
>
> **Attention** : Le processus DORA est un classique de l'examen. Connaissez l'ordre exact (Discover → Offer → Request → Acknowledge) et le fait que DISCOVER et REQUEST sont en broadcast.

### Exercice 4.3 — Flux DHCP et résolution DNS

**Contexte** : Un PC vient d'être branché sur le réseau VLAN 10 de l'entreprise TechnoVert. Le VLAN 10 a pour réseau 10.10.10.0/24, passerelle 10.10.10.1, serveur DHCP 10.10.10.254.

**Consigne** : Décrivez dans l'ordre chronologique les 6 premières étapes réseau (couche par couche) quand l'utilisateur ouvre son navigateur et tape `www.technovert.fr` après avoir branché le câble Ethernet.

**Indice** : <details><summary>Voir l'indice</summary>D'abord DHCP (le PC n'a pas d'adresse), puis DNS (il ne connaît pas l'IP du site), puis HTTP.</details>

<details>
<summary>Solution</summary>

1. **DHCP Discover** : Le PC envoie un broadcast UDP (src 0.0.0.0:68, dst 255.255.255.255:67) pour trouver un serveur DHCP
2. **DHCP Offer** : Le serveur 10.10.10.254 propose l'adresse 10.10.10.50/24 avec passerelle 10.10.10.1 et DNS 10.10.10.254
3. **DHCP Request** : Le PC accepte l'offre (broadcast)
4. **DHCP Acknowledge** : Le serveur confirme — le PC a maintenant une configuration IP complète
5. **DNS Query** : Le PC envoie une requête DNS (UDP port 53) au serveur 10.10.10.254 pour résoudre `www.technovert.fr`
6. **DNS Reply** : Le serveur DNS répond avec l'adresse IP (ex: 185.12.34.56)
7. *(Bonus)* **TCP SYN** : Le PC initie une connexion HTTP/HTTPS vers 185.12.34.56 sur le port 80/443

**Explication** : Sans DHCP, le PC n'a ni adresse IP, ni passerelle, ni DNS. DHCP doit donc se produire en premier. Ensuite, le navigateur a besoin de l'adresse IP du site, ce qui déclenche la résolution DNS. Enfin seulement, la connexion TCP/HTTP peut s'établir.

</details>

### Voir aussi

- Topic 1.5 dans Module 1 (TCP vs UDP — DHCP et DNS utilisent UDP)
- Topic 4.6 dans ce module (configuration DHCP client et relay — la mise en pratique CLI de DHCP)
- Topic 2.6 dans Module 2 (wireless — les clients Wi-Fi utilisent aussi DHCP pour obtenir leur configuration)

---

## 4.4 — SNMP

> **Exam topic 4.4** : *Explain* — the function of SNMP in network operations
> **Niveau** : Explain

### Contexte

Vous gérez un réseau de 200 équipements répartis sur 5 sites. Comment savoir en temps réel si un lien est saturé, si un switch chauffe, si la mémoire d'un routeur atteint sa limite ? Vous n'allez pas vous connecter en SSH à chaque équipement toutes les 5 minutes. SNMP (Simple Network Management Protocol) centralise la collecte de ces métriques, et peut même vous alerter instantanément quand un problème survient.

### Théorie

SNMP est un protocole de la couche application qui permet la supervision et la gestion des équipements réseau. Il repose sur trois composants principaux :

#### Architecture SNMP

```
  ┌─────────────────────────────────────┐
  │        NMS (Network Management      │
  │           Station)                  │
  │  Ex: SolarWinds, Nagios, Zabbix,   │
  │      PRTG, LibreNMS                 │
  │                                     │
  │  Rôle: collecte, stocke, affiche   │
  │  les données des agents SNMP       │
  └──────────────┬──────────────────────┘
                 │
         ┌───────┴────────┐  UDP 161 (queries)
         │                │  UDP 162 (traps)
         ▼                ▼
  ┌──────────┐     ┌──────────┐
  │ Agent    │     │ Agent    │
  │ (R1)     │     │ (SW1)    │    Agents = logiciel SNMP
  │          │     │          │    sur chaque équipement géré
  │ MIB      │     │ MIB      │
  └──────────┘     └──────────┘
```

| Composant | Rôle | Détail |
|-----------|------|--------|
| **NMS** (Network Management Station) | Supervise | Interroge les agents, reçoit les alertes, stocke les données |
| **Agent** | Répond | Logiciel embarqué sur le routeur/switch, expose les données de la MIB |
| **MIB** (Management Information Base) | Stocke | Base de données hiérarchique contenant les variables supervisables (OIDs) |

#### Les opérations SNMP

| Opération | Direction | Description |
|-----------|-----------|-------------|
| **GET** | NMS → Agent | Lire la valeur d'une variable spécifique |
| **GET-NEXT** | NMS → Agent | Lire la variable suivante dans la MIB (parcours séquentiel) |
| **GET-BULK** | NMS → Agent | Lire plusieurs variables en une seule requête (SNMPv2c+) |
| **SET** | NMS → Agent | Modifier la valeur d'une variable (ex: désactiver une interface) |
| **TRAP** | Agent → NMS | Notification asynchrone d'un événement (ex: interface down) |
| **INFORM** | Agent → NMS | Comme TRAP, mais avec accusé de réception (SNMPv2c+) |

La différence fondamentale entre **TRAP** et **INFORM** : un trap est "fire and forget" — l'agent l'envoie et ne sait jamais si le NMS l'a reçu. Un inform attend une confirmation ; si le NMS ne répond pas, l'agent retransmet.

#### Versions SNMP

| Critère | SNMPv1 | SNMPv2c | SNMPv3 |
|---------|--------|---------|--------|
| Authentification | Community string (texte clair) | Community string (texte clair) | Username + password (MD5/SHA) |
| Chiffrement | Non | Non | Oui (DES, AES) |
| Sécurité | Faible | Faible | Forte |
| GET-BULK | Non | Oui | Oui |
| INFORM | Non | Oui | Oui |
| Usage recommandé | Obsolète | Labs uniquement | Production |

Les community strings agissent comme des mots de passe en texte clair :
- **RO (read-only)** : permet uniquement la lecture (GET, GET-NEXT, GET-BULK). Par défaut : `public`
- **RW (read-write)** : permet la lecture ET l'écriture (SET). Par défaut : `private`

> En production, changez **toujours** les community strings par défaut. C'est l'équivalent de laisser le mot de passe `admin` sur un routeur.

#### La MIB — Organisation en arbre

La MIB organise les variables en arbre hiérarchique. Chaque variable est identifiée par un **OID** (Object Identifier) numérique :

```
  iso(1).org(3).dod(6).internet(1).mgmt(2).mib-2(1)
                                                 │
                           ┌─────────────────────┼──────────┐
                        system(1)            interfaces(2)  ip(4)
                           │                     │
                    sysDescr(1)            ifNumber(1)
                    sysUpTime(3)           ifTable(2)
                    sysName(5)                │
                    sysLocation(6)        ifEntry(1)
                                              │
                                         ifDescr(2)
                                         ifOperStatus(8)
                                         ifInOctets(10)
```

L'OID de `sysName` est `1.3.6.1.2.1.1.5` — long mais structuré.

### Mise en pratique CLI

#### Configurer SNMPv2c sur un routeur

```cisco
! Community read-only pour la supervision
R1(config)# snmp-server community MONITOR-2026 ro

! Community read-write pour la gestion (usage restreint)
R1(config)# snmp-server community CONFIG-SEC rw

! Définir les informations système
R1(config)# snmp-server location "Salle serveur, Bâtiment A, Paris"
R1(config)# snmp-server contact "noc@netcorp.com"

! Configurer les traps vers le NMS (10.1.1.200)
R1(config)# snmp-server host 10.1.1.200 version 2c MONITOR-2026
R1(config)# snmp-server enable traps snmp linkdown linkup
R1(config)# snmp-server enable traps config
```

#### Vérification

```cisco
R1# show snmp
Chassis: FTX1234A5BC
37521 SNMP packets input
    0 Bad SNMP version errors
    0 Unknown community name
    0 Illegal operation for community name supplied
    0 Encoding errors
    35200 Number of requested variables
    0 Number of altered variables
    2321 Get-request PDUs
    0 Get-next PDUs
    0 Set-request PDUs
    0 Input queue drops
37500 SNMP packets output
    0 Too big errors
    0 No such name errors
    0 Bad values errors
    0 General errors
    35200 Response PDUs
    2300 Trap PDUs
```

**Interprétation** :
- **2321 Get-request PDUs** : le NMS a interrogé le routeur 2 321 fois
- **2300 Trap PDUs** : le routeur a envoyé 2 300 notifications au NMS
- **0 Unknown community name** : aucune requête avec un mauvais community string (si ce compteur augmente, quelqu'un essaie de deviner votre community)

### Point exam

> **Piège courant** : Confondre les ports SNMP. Le NMS envoie ses requêtes (GET/SET) vers le port **UDP 161** de l'agent. Les traps et informs sont envoyés par l'agent vers le port **UDP 162** du NMS.
>
> **À retenir** : SNMPv3 est la seule version qui offre authentification ET chiffrement. SNMPv1 et v2c transmettent les community strings en texte clair — elles sont vulnérables au sniffing. L'examen peut demander « quelle version SNMP fournit le chiffrement ? » — la réponse est toujours **v3**.
>
> **Attention** : Un **TRAP** n'est pas fiable (pas d'acquittement). Un **INFORM** est fiable (acquittement obligatoire). Cette distinction est un classique de l'examen.

### Exercice 4.4 — Interpréter un scénario SNMP

**Contexte** : L'administrateur de BioTech Corp constate que le NMS ne reçoit plus les alertes de changement de configuration du routeur R-CORE, alors que le polling (GET) fonctionne normalement.

**Consigne** : Identifiez trois causes possibles de ce problème et la commande de vérification correspondante pour chacune.

**Indice** : <details><summary>Voir l'indice</summary>Le polling fonctionne, donc la connectivité et la community RO sont correctes. Le problème concerne spécifiquement les traps. Pensez à la configuration des traps, à la destination, et aux ACLs.</details>

<details>
<summary>Solution</summary>

| Cause possible | Commande de vérification |
|---------------|--------------------------|
| 1. Les traps de config ne sont pas activés | `show running-config \| include snmp-server enable traps` — vérifier que `snmp-server enable traps config` est présent |
| 2. Le serveur de destination des traps est mal configuré | `show snmp host` — vérifier que l'IP du NMS est correcte et la community correspond |
| 3. Une ACL bloque le trafic UDP 162 entre R-CORE et le NMS | `show access-lists` sur les interfaces traversées + `show snmp` pour voir si le compteur de Trap PDUs augmente (si oui, le routeur envoie mais les traps sont bloquées en route) |

**Explication** : Le fait que le GET fonctionne prouve que l'agent SNMP tourne et que la community RO est correcte. Les traps sont un mécanisme séparé qui nécessite sa propre configuration (destination + type de traps activés). C'est une source d'erreur classique.

</details>

### Voir aussi

- Topic 4.5 dans ce module (Syslog — autre mécanisme de notification, souvent complémentaire de SNMP)
- Topic 2.8 dans Module 2 (accès de management — SNMP fait partie des outils de gestion)
- Topic 6.2 dans Module 6 (réseaux traditionnels vs controller-based — SNMP est l'outil classique de supervision en réseau traditionnel)

---

## 4.5 — Syslog : facilities et niveaux de sévérité

> **Exam topic 4.5** : *Describe* — the use of syslog features including facilities and levels
> **Niveau** : Describe

### Contexte

Quand un routeur redémarre de façon inattendue à 3h du matin, la première question est : « que s'est-il passé juste avant ? ». Les messages syslog sont le journal de bord du réseau — chaque événement significatif y est consigné, des simples changements d'état d'interface aux erreurs critiques. Bien comprendre comment lire et organiser ces messages est indispensable pour le dépannage.

### Théorie

Syslog est un standard (RFC 5424) qui permet aux équipements réseau d'envoyer des messages de journal à un collecteur centralisé. Chaque message syslog contient trois informations essentielles :

1. **Facility** : la source du message (quel composant l'a généré)
2. **Severity** (niveau de sévérité) : la gravité du message
3. **Message** : le contenu descriptif de l'événement

#### Les 8 niveaux de sévérité

C'est le tableau le plus important de cette section — il faut le connaître par coeur pour l'examen :

| Niveau | Mot-clé | Description | Exemple |
|--------|---------|-------------|---------|
| **0** | **Emergency** | Système inutilisable | Crash du système |
| **1** | **Alert** | Action immédiate nécessaire | Température critique |
| **2** | **Critical** | Condition critique | Erreur mémoire |
| **3** | **Error** | Condition d'erreur | Erreur d'interface |
| **4** | **Warning** | Avertissement | Seuil de mémoire atteint |
| **5** | **Notification** | Normal mais significatif | Interface up/down |
| **6** | **Informational** | Message informatif | Transaction de configuration |
| **7** | **Debugging** | Message de débogage | Output de `debug` |

**Moyen mnémotechnique** : **E**very **A**wesome **C**isco **E**ngineer **W**ill **N**eed **I**ce cream **D**aily
(Emergency, Alert, Critical, Error, Warning, Notification, Informational, Debugging)

> Plus le numéro est **bas**, plus c'est **grave**. Quand on configure un niveau, **tous les niveaux de gravité inférieure ou égale** sont inclus. Configurer le niveau 4 (Warning) capture aussi les niveaux 0 à 3.

#### Anatomy d'un message syslog

```
*Apr  4 14:32:15.302: %LINEPROTO-5-UPDOWN: Line protocol on Interface
  GigabitEthernet0/1, changed state to down
  │                    │         │ │
  │                    │         │ └── Description de l'événement
  │                    │         └──── Mnémonique (nom de l'événement)
  │                    └──────────── Sévérité (5 = Notification)
  └───────────────────────────────── Facility (LINEPROTO)
```

#### Destinations des messages syslog

Les messages syslog peuvent être envoyés vers plusieurs destinations simultanément :

| Destination | Commande | Persistance | Usage |
|-------------|----------|-------------|-------|
| **Console** | `logging console <niveau>` | Non (affiché en temps réel) | Débogage interactif |
| **Terminal (VTY)** | `terminal monitor` | Non (session en cours) | Débogage à distance |
| **Buffer** | `logging buffered <taille> <niveau>` | Perdu au reboot | Consultation locale (`show logging`) |
| **Serveur syslog** | `logging host <IP>` | Oui (stocké sur le serveur) | Centralisation, archivage, conformité |

#### Facilities courantes sur Cisco IOS

| Facility | Source |
|----------|--------|
| `%LINEPROTO` | Protocole de ligne (état des interfaces) |
| `%LINK` | Couche physique des interfaces |
| `%OSPF` | Protocole OSPF |
| `%SYS` | Système général |
| `%SEC` | Sécurité (login, ACLs) |
| `%DHCPD` | Serveur DHCP |
| `%NTP` | Protocole NTP |
| `%CDP` | Cisco Discovery Protocol |

### Mise en pratique CLI

#### Configurer syslog sur un routeur

```cisco
! Envoyer les logs vers un serveur syslog externe
R1(config)# logging host 10.1.1.200

! Définir le niveau de sévérité pour le serveur (informational = 0 à 6)
R1(config)# logging trap informational

! Configurer le buffer local (64 Ko, niveau debugging)
R1(config)# logging buffered 65536 debugging

! Activer les timestamps (indispensable pour la corrélation)
R1(config)# service timestamps log datetime msec localtime

! Limiter les messages console au niveau Warning (éviter le flood)
R1(config)# logging console warnings
```

#### Vérification

```cisco
R1# show logging
Syslog logging: enabled (0 messages dropped, 0 messages rate-limited,
                0 flushes, 0 overflows, 15234 messages logged)
        Logging to: console (warning)
        Logging to: monitor (debugging)
        Logging to: buffer (65536 bytes, debugging)
        Logging to: host 10.1.1.200 (informational)

Log Buffer (65536 bytes):

*Apr  4 14:32:15.302: %LINEPROTO-5-UPDOWN: Line protocol on Interface
  GigabitEthernet0/1, changed state to down
*Apr  4 14:32:17.105: %LINK-3-UPDOWN: Interface GigabitEthernet0/1,
  changed state to down
*Apr  4 14:35:42.891: %LINEPROTO-5-UPDOWN: Line protocol on Interface
  GigabitEthernet0/1, changed state to up
*Apr  4 14:35:43.002: %LINK-3-UPDOWN: Interface GigabitEthernet0/1,
  changed state to up
*Apr  4 15:01:12.456: %SYS-5-CONFIG_I: Configured from console by
  admin on vty0 (10.1.1.50)
```

**Interprétation** :
- Le message `%LINK-3-UPDOWN` est de sévérité **3** (Error) — la couche physique a changé d'état
- Le message `%LINEPROTO-5-UPDOWN` est de sévérité **5** (Notification) — le protocole de ligne suit
- Le message `%SYS-5-CONFIG_I` informe qu'un administrateur a modifié la configuration depuis le terminal VTY0
- La différence entre `%LINK` et `%LINEPROTO` : LINK = couche physique (câble), LINEPROTO = couche 2 (encapsulation). On voit d'abord LINK down, puis LINEPROTO down

### Point exam

> **Piège courant** : L'examen demande souvent « quel niveau de logging configurer pour capturer les messages de niveau Warning ET plus graves ? ». La réponse est **4** (ou `warnings`). Configurer le niveau 4 inclut automatiquement les niveaux 0, 1, 2 et 3. Beaucoup de candidats sélectionnent le niveau 3 (errors), oubliant que warning est le niveau 4.
>
> **À retenir** : Les 8 niveaux de sévérité (0-7) et leur mnémonique. Le niveau 0 est le plus grave, le niveau 7 le moins grave. La commande `service timestamps log datetime msec` est essentielle pour la corrélation des logs — sans elle, les messages n'ont pas de timestamp exploitable.
>
> **Attention** : Syslog utilise **UDP port 514** par défaut. Comme UDP est non fiable, des messages peuvent être perdus — c'est pourquoi le buffer local est un complément utile.

### Exercice 4.5 — Classer des messages syslog

**Contexte** : Voici 6 messages syslog provenant d'un routeur.

**Consigne** : Classez-les du plus grave au moins grave, identifiez le niveau de sévérité de chacun, et déterminez lesquels seraient capturés avec `logging trap errors`.

```
A: %OSPF-4-FLOOD_WAR: Process 1 re-originates LSA ID 10.0.0.0, ...
B: %LINEPROTO-5-UPDOWN: Line protocol on Interface Gi0/0, changed state to up
C: %SYS-2-MALLOCFAIL: Memory allocation of 65536 bytes failed
D: %DUAL-7-PKTRECV: Received packet from 10.1.1.2
E: %SYS-0-CPUHOG: Task ran for 10024 msec
F: %SEC-6-IPACCESSLOGP: list 101 denied tcp 10.1.1.50 → 10.1.1.100
```

**Indice** : <details><summary>Voir l'indice</summary>Le chiffre après le premier tiret dans le code (ex: %SYS-**2**-MALLOCFAIL) est le niveau de sévérité. `logging trap errors` = niveau 3 = capture 0, 1, 2 et 3.</details>

<details>
<summary>Solution</summary>

| Rang | Message | Facility | Sévérité | Nom du niveau |
|------|---------|----------|----------|---------------|
| 1 | E | SYS | **0** | Emergency |
| 2 | C | SYS | **2** | Critical |
| 3 | A | OSPF | **4** | Warning |
| 4 | B | LINEPROTO | **5** | Notification |
| 5 | F | SEC | **6** | Informational |
| 6 | D | DUAL | **7** | Debugging |

Avec `logging trap errors` (niveau 3), seuls les messages de niveaux **0, 1, 2 et 3** sont capturés. Dans notre liste : **E** (niveau 0) et **C** (niveau 2). Le message A (niveau 4 = Warning) n'est PAS capturé par le niveau errors.

</details>

### Voir aussi

- Topic 4.2 dans ce module (NTP — les timestamps syslog n'ont de valeur que si l'horloge est synchronisée)
- Topic 4.4 dans ce module (SNMP — SNMP et syslog sont complémentaires : SNMP pour les métriques, syslog pour les événements)
- Topic 5.1 dans Module 5 (concepts de sécurité — les logs syslog sont un outil de détection des menaces)

---

## 4.6 — DHCP client et relay

> **Exam topic 4.6** : *Configure and verify* — DHCP client and relay
> **Niveau** : Configure/Verify

### Contexte

La section 4.3 a expliqué le fonctionnement théorique de DHCP. Passons maintenant à la pratique. Deux scénarios reviennent constamment en entreprise : configurer une interface routeur pour qu'elle obtienne son adresse par DHCP (typique pour l'interface WAN vers le FAI), et configurer un **relay DHCP** pour que les clients d'un VLAN distant puissent atteindre un serveur DHCP situé dans un autre sous-réseau.

### Théorie

#### Le problème du broadcast DHCP

Le message DHCP Discover est un **broadcast** de couche 3 (destination 255.255.255.255). Or, les routeurs ne transfèrent pas les broadcasts — c'est leur comportement par défaut et c'est une bonne chose pour éviter les tempêtes de broadcast. Le problème : si le serveur DHCP n'est pas dans le même sous-réseau que le client, le Discover n'arrivera jamais au serveur.

```
  VLAN 10 (10.10.10.0/24)              VLAN 20 (10.10.20.0/24)
  ┌──────┐  ┌──────┐                   ┌─────────────┐
  │ PC1  │  │ PC2  │                   │ SRV-DHCP    │
  │ ???  │  │ ???  │                   │ 10.10.20.100│
  └──┬───┘  └──┬───┘                   └──────┬──────┘
     │         │                               │
  ───┴─────────┴───────┐          ┌────────────┴──────
                       │          │
                  ┌────┴──────────┴────┐
                  │     R1 (relay)     │
                  │  Gi0/0: 10.10.10.1│
                  │  Gi0/1: 10.10.20.1│
                  └────────────────────┘

  Sans relay : DHCP Discover (broadcast) s'arrête à R1 → PC1 n'obtient PAS d'adresse
  Avec relay : R1 convertit le broadcast en unicast vers 10.10.20.100 → ça marche !
```

#### DHCP Relay (ip helper-address)

La commande `ip helper-address` sur l'interface du routeur côté client résout ce problème. Quand le routeur reçoit un broadcast DHCP sur cette interface, il le convertit en **unicast** dirigé vers le serveur DHCP spécifié.

Ce que fait concrètement `ip helper-address` :
1. Intercepte le broadcast DHCP reçu sur l'interface
2. Insère l'adresse de l'interface réceptrice dans le champ **GIADDR** (Gateway IP Address) du paquet DHCP
3. Envoie le paquet en unicast au serveur DHCP spécifié
4. Le serveur DHCP utilise le GIADDR pour déterminer quel pool d'adresses utiliser
5. Le serveur envoie la réponse au routeur (GIADDR), qui la retransmet au client

> `ip helper-address` ne redirige pas seulement DHCP — par défaut, elle redirige 8 services UDP : DHCP (67, 68), TFTP (69), DNS (53), TACACS (49), NetBIOS (137, 138), et Time (37).

#### Configurer un routeur comme serveur DHCP

Un routeur Cisco IOS peut agir comme serveur DHCP pour les petits réseaux (agences, télétravail) :

```cisco
! Créer un pool DHCP pour le VLAN 10
R1(config)# ip dhcp pool VLAN10-POOL
R1(dhcp-config)# network 10.10.10.0 255.255.255.0
R1(dhcp-config)# default-router 10.10.10.1
R1(dhcp-config)# dns-server 10.10.20.100 8.8.8.8
R1(dhcp-config)# domain-name netcorp.local
R1(dhcp-config)# lease 0 12 0
! lease = 0 jours, 12 heures, 0 minutes
R1(dhcp-config)# exit
!
! Exclure les adresses réservées (routeur, serveurs, imprimantes)
R1(config)# ip dhcp excluded-address 10.10.10.1 10.10.10.20
```

L'exclusion est déclarée **en dehors** du pool — c'est une erreur fréquente de la mettre à l'intérieur.

### Mise en pratique CLI

#### Configurer une interface routeur comme client DHCP

```cisco
! L'interface obtient son adresse du FAI via DHCP
R1(config)# interface GigabitEthernet0/1
R1(config-if)# ip address dhcp
R1(config-if)# no shutdown
```

#### Configurer le DHCP Relay

```cisco
! Sur l'interface côté clients (VLAN 10)
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip helper-address 10.10.20.100
```

C'est aussi simple que ça — une seule ligne de configuration. Mais c'est cette ligne qui fait la différence entre « DHCP fonctionne » et « les PC n'obtiennent pas d'adresse ».

#### Vérification du serveur DHCP

```cisco
R1# show ip dhcp binding
Bindings from all pools not associated with VRF:
IP address          Client-ID/              Lease expiration        Type
                    Hardware address/
                    User name
10.10.10.21         0100.1a2b.3c4d.50       Apr 05 2026 02:15 AM   Automatic
10.10.10.22         0100.1a2b.3c4d.60       Apr 05 2026 02:18 AM   Automatic
10.10.10.23         0100.1a2b.3c4d.70       Apr 05 2026 02:20 AM   Automatic
```

**Interprétation** :
- Trois clients ont reçu des adresses du pool (10.10.10.21 à .23 — les .1 à .20 sont exclues)
- Le **Client-ID** correspond à l'adresse MAC du client (préfixée de `01` pour Ethernet)
- Le bail expire dans ~12h (conformément à `lease 0 12 0`)

```cisco
R1# show ip dhcp pool
Pool VLAN10-POOL :
 Utilization mark (high/low)    : 100 / 0
 Subnet size (first/next)       : 0 / 0
 Total addresses                : 254
 Leased addresses               : 3
 Pending event                  : none
 1 subnet is currently in the pool :
 Current index        IP address range                    Leased addresses
 10.10.10.24          10.10.10.1   - 10.10.10.254         3
```

```cisco
R1# show ip dhcp server statistics
Memory usage         25165
Address pools        1
Database agents      0
Automatic bindings   3
Manual bindings      0
Expired bindings     0
Malformed messages   0
Secure arp entries   0

Message              Received
BOOTREQUEST          0
DHCPDISCOVER         3
DHCPREQUEST          3
DHCPDECLINE          0
DHCPRELEASE          0
DHCPINFORM           0

Message              Sent
BOOTREPLY            0
DHCPOFFER            3
DHCPACK              3
DHCPNAK              0
```

**Interprétation** : On voit clairement le processus DORA — 3 DISCOVER reçus, 3 OFFER envoyés, 3 REQUEST reçus, 3 ACK envoyés. Chaque colonne correspond à une étape du processus pour 3 clients.

### Point exam

> **Piège courant** : Oublier que `ip dhcp excluded-address` est une commande **globale** (mode config), pas une commande du pool DHCP. Si vous la tapez dans le mode `dhcp-config`, le routeur l'accepte comme nom de pool... et l'exclusion ne fonctionne pas.
>
> **À retenir** : `ip helper-address` se configure sur l'interface **côté client** (pas côté serveur). Elle pointe vers l'adresse IP du serveur DHCP. Le routeur utilise le champ GIADDR pour indiquer au serveur quel sous-réseau dessert — c'est ainsi que le serveur choisit le bon pool.
>
> **Attention** : `ip address dhcp` sur une interface routeur = le routeur est **client** DHCP. Ne confondez pas avec la configuration du **serveur** DHCP (commande `ip dhcp pool`).

### Exercice 4.6 — Relay DHCP inter-VLAN

**Contexte** : L'entreprise DataFlow a 3 VLANs sur le site principal :
- VLAN 10 (Users) : 10.10.10.0/24, passerelle 10.10.10.1 sur R1 Gi0/0.10
- VLAN 20 (VoIP) : 10.10.20.0/24, passerelle 10.10.20.1 sur R1 Gi0/0.20
- VLAN 30 (Servers) : 10.10.30.0/24, serveur DHCP à 10.10.30.50

**Consigne** : Configurez le relay DHCP pour que les VLANs 10 et 20 obtiennent leurs adresses du serveur DHCP centralisé dans le VLAN 30.

**Indice** : <details><summary>Voir l'indice</summary>Avec un routeur-on-a-stick, les sous-interfaces sont les "interfaces côté client". Le helper-address doit être configuré sur chaque sous-interface qui a besoin du relay.</details>

<details>
<summary>Solution</summary>

```cisco
R1(config)# interface GigabitEthernet0/0.10
R1(config-subif)# ip helper-address 10.10.30.50
R1(config-subif)# exit
!
R1(config)# interface GigabitEthernet0/0.20
R1(config-subif)# ip helper-address 10.10.30.50
R1(config-subif)# exit
```

**Explication** : Chaque sous-interface qui dessert un VLAN nécessitant DHCP doit avoir son propre `ip helper-address`. Quand un PC du VLAN 10 envoie un DHCP Discover en broadcast, R1 le reçoit sur Gi0/0.10, insère 10.10.10.1 comme GIADDR, et l'envoie en unicast à 10.10.30.50. Le serveur DHCP voit le GIADDR 10.10.10.1 et sait qu'il doit attribuer une adresse du pool 10.10.10.0/24. Même logique pour le VLAN 20 avec le GIADDR 10.10.20.1.

</details>

### Voir aussi

- Topic 4.3 dans ce module (rôle de DHCP — théorie DORA, baux, paramètres distribués)
- Topic 2.1.c dans Module 2 (inter-VLAN connectivity — le relay DHCP fonctionne souvent sur des sous-interfaces router-on-a-stick)
- Topic 5.7 dans Module 5 (DHCP snooping — mécanisme de sécurité Layer 2 qui protège contre les serveurs DHCP malveillants)

---

## 4.7 — QoS : classification, marking, queuing, policing et shaping

> **Exam topic 4.7** : *Explain* — the forwarding per-hop behavior (PHB) for QoS, such as classification, marking, queuing, congestion, policing, and shaping
> **Niveau** : Explain

### Contexte

Sur un réseau d'entreprise, un appel VoIP en cours et un téléchargement de 2 Go se disputent la même bande passante. Sans QoS, le téléchargement noie la voix — la conversation devient hachée, les mots se perdent. La QoS (Quality of Service) permet de dire au réseau : « la voix passe en priorité, le téléchargement attend ». C'est un arbitre de trafic qui garantit que les applications critiques obtiennent les ressources dont elles ont besoin.

### Théorie

Le terme **PHB** (Per-Hop Behavior) signifie que chaque équipement réseau (chaque « saut ») prend ses propres décisions de traitement du trafic. Il n'y a pas de réservation de bout en bout comme dans ATM — chaque routeur applique ses politiques QoS localement.

#### Les mécanismes QoS — vue d'ensemble

La QoS se décompose en plusieurs mécanismes qui s'enchaînent dans l'ordre suivant :

```
  Paquet entrant                                            Paquet sortant
       │                                                         ▲
       ▼                                                         │
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌────┴─────────┐
  │ CLASSIFICA-  │──►│   MARKING    │──►│   QUEUING     │──►│  SCHEDULING  │
  │ TION         │   │ (marquage)   │   │ (mise en file)│   │  (envoi)     │
  │              │   │              │   │               │   │              │
  │ "Qui es-tu?" │   │ "Je te       │   │ "File         │   │ "File        │
  │              │   │  tampon"     │   │  prioritaire  │   │  prioritaire │
  │              │   │              │   │  ou standard" │   │  d'abord"    │
  └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘
                                              │
                                    ┌─────────┴─────────┐
                                    ▼                   ▼
                              ┌──────────┐        ┌──────────┐
                              │ POLICING │        │ SHAPING  │
                              │ (limite  │        │ (lissage │
                              │  dure)   │        │  doux)   │
                              └──────────┘        └──────────┘
```

#### 1. Classification

La classification identifie le type de trafic. Elle examine les paquets selon différents critères :

| Critère | Couche | Exemple |
|---------|--------|---------|
| Adresse IP source/destination | 3 | ACL : `permit 10.1.1.0 0.0.0.255` |
| Port TCP/UDP | 4 | Port 5060 (SIP), ports 16384-32767 (RTP) |
| Valeur DSCP | 3 | EF (Expedited Forwarding) = 46 |
| Valeur CoS (802.1Q) | 2 | CoS 5 pour la voix |
| NBAR (reconnaissance d'application) | 7 | YouTube, Teams, Zoom |

#### 2. Marking (marquage)

Une fois classifié, le paquet est « tamponné » pour que les équipements suivants sachent comment le traiter sans refaire la classification. Deux champs sont utilisés :

**Au niveau Layer 2 (trame 802.1Q)** — **CoS** (Class of Service) :
- 3 bits dans le tag VLAN 802.1Q → valeurs 0 à 7
- Perdu dès que la trame quitte le domaine VLAN (pas routé)

**Au niveau Layer 3 (paquet IP)** — **DSCP** (Differentiated Services Code Point) :
- 6 bits dans l'en-tête IP (champ ToS) → valeurs 0 à 63
- Préservé de bout en bout tant que les routeurs ne le modifient pas

| Classe de trafic | DSCP | Décimal | CoS | Usage |
|------------------|------|---------|-----|-------|
| Voice (EF) | 101110 | **46** | 5 | Voix RTP |
| Video (AF41) | 100010 | **34** | 4 | Vidéoconférence |
| Critical Data (AF31) | 011010 | **26** | 3 | Applications métier |
| Transactional (AF21) | 010010 | **18** | 2 | Transactions bases de données |
| Best Effort (BE) | 000000 | **0** | 0 | Trafic par défaut |

Le marquage DSCP utilise le modèle **AF** (Assured Forwarding) avec la notation AFxy, où :
- x = classe (1-4, 4 étant la plus prioritaire)
- y = probabilité de drop en cas de congestion (1=faible, 2=moyenne, 3=haute)

Et le marquage **EF** (Expedited Forwarding) pour la voix — priorité maximale, latence minimale.

#### 3. Queuing (mise en file d'attente)

Quand l'interface de sortie est congestionnée, les paquets sont placés dans des files d'attente selon leur marquage. Cisco utilise principalement **CBWFQ** (Class-Based Weighted Fair Queuing) :

- Chaque classe de trafic a sa propre file
- Chaque file dispose d'une bande passante minimum garantie
- Une file **prioritaire** (LLQ — Low Latency Queue) est réservée à la voix et à la vidéo temps réel

#### 4. Congestion avoidance

Quand une file approche de sa capacité maximale, le mécanisme **WRED** (Weighted Random Early Detection) commence à rejeter aléatoirement des paquets **avant** que la file soit pleine. Les paquets avec une probabilité de drop élevée (AF13 > AF12 > AF11) sont rejetés en premier.

Sans WRED, quand la file est pleine, tous les nouveaux paquets sont rejetés indistinctement (tail drop) — ce qui provoque la synchronisation TCP et une chute brutale du débit.

#### 5. Policing vs Shaping

Ces deux mécanismes contrôlent le débit, mais de manière très différente :

| Critère | Policing | Shaping |
|---------|----------|---------|
| Action si dépassement | **Rejette** (drop) ou re-marque | **Retarde** (buffer) |
| Latence ajoutée | Non | Oui (mise en buffer) |
| Direction | Entrée ou sortie | Sortie uniquement |
| Effet sur le débit | Coupure nette | Lissage progressif |
| Analogie | Radar routier : excès de vitesse = amende | Feu de circulation : régule le flux |
| Usage typique | FAI limitant le débit d'un client | Adapter le débit sortant à la capacité du lien distant |

```
  Policing (entrée ou sortie)          Shaping (sortie uniquement)
  Débit ▲                              Débit ▲
        │    ╱╲                               │
        │   ╱  ╲  ╱╲                          │  ┌──────────────────────┐
  Seuil │──╱────╲╱──╲──── drop               │  │  débit lissé         │
        │ ╱          ╲                        │  └──────────────────────┘
        │╱                                    │╱
        └──────────────► temps                └──────────────────► temps
        Les pics au-dessus du seuil           Les pics sont bufferisés et
        sont coupés (paquets jetés)           étalés dans le temps
```

### Mise en pratique CLI

#### Vérifier le marquage QoS (class-map et policy-map)

```cisco
R1# show policy-map interface GigabitEthernet0/0
 GigabitEthernet0/0

  Service-policy output: WAN-QOS-POLICY

    Class-map: VOICE (match-all)
      234521 packets, 18761680 bytes
      5 minute offered rate 256000 bps, drop rate 0 bps
      Match: dscp ef
      Queueing
        queue limit 64 packets
        (queue depth/total drops/no-buffer drops) 0/0/0
        (pkts output/bytes output) 234521/18761680
      Priority: 512 kbps, burst bytes 12800, b/w exceed drops: 0

    Class-map: CRITICAL-DATA (match-all)
      1523400 packets, 912040000 bytes
      5 minute offered rate 4096000 bps, drop rate 0 bps
      Match: dscp af31
      Queueing
        queue limit 128 packets
        (queue depth/total drops/no-buffer drops) 0/0/0
        (pkts output/bytes output) 1523400/912040000
      Bandwidth: 2048 kbps

    Class-map: class-default (match-any)
      5234000 packets, 6280800000 bytes
      5 minute offered rate 25600000 bps, drop rate 12800 bps
      Match: any
      Queueing
        queue limit 256 packets
        (queue depth/total drops/no-buffer drops) 45/12340/0
```

**Interprétation** :
- La classe **VOICE** (DSCP EF) a une file prioritaire de 512 kbps avec **0 drops** — la voix n'a jamais été dégradée
- La classe **CRITICAL-DATA** (DSCP AF31) a une bande passante garantie de 2 048 kbps
- La classe **class-default** (tout le reste) montre 12 340 drops — du trafic best-effort a été rejeté pendant les périodes de congestion

### Point exam

> **Piège courant** : Confondre policing et shaping. **Policing** = drop (rejette les paquets excédentaires, pas de latence ajoutée). **Shaping** = delay (retarde les paquets dans un buffer, ajoute de la latence). L'examen pose souvent la question sous forme de scénario : « un FAI limite le débit d'un client » → policing. « Un routeur doit adapter son débit sortant au lien WAN » → shaping.
>
> **À retenir** : DSCP EF (46) = voix. DSCP est dans l'en-tête **IP** (Layer 3), CoS est dans le tag **802.1Q** (Layer 2). Le CoS disparaît quand le paquet est routé hors du VLAN. Le DSCP traverse les routeurs.
>
> **Attention** : L'examen teste le concept PHB — chaque routeur prend ses décisions indépendamment. Il n'y a pas de signalisation de bout en bout. C'est pourquoi le marquage est essentiel : il porte l'information de classe dans chaque paquet.

### Exercice 4.7 — Associer les mécanismes QoS

**Contexte** : L'entreprise VocalNet déploie la téléphonie IP sur son réseau WAN.

**Consigne** : Pour chaque scénario ci-dessous, identifiez le mécanisme QoS principal :

1. Le téléphone IP marque ses paquets voix avec DSCP EF
2. Le routeur WAN place les paquets voix dans une file séparée avec latence garantie < 150 ms
3. Le routeur identifie le trafic YouTube et le classe comme « non-critique »
4. Le FAI rejette les paquets du client au-delà de 100 Mbps
5. Le routeur d'agence lisse son débit sortant à 10 Mbps pour correspondre au lien WAN
6. Quand la file best-effort approche de la saturation, certains paquets AF13 sont rejetés avant les AF11

**Indice** : <details><summary>Voir l'indice</summary>Les 6 mécanismes sont : classification, marking, queuing (LLQ), policing, shaping, congestion avoidance (WRED).</details>

<details>
<summary>Solution</summary>

| Scénario | Mécanisme |
|----------|-----------|
| 1. Téléphone marque DSCP EF | **Marking** (le téléphone applique le marquage DSCP) |
| 2. File séparée à faible latence | **Queuing / LLQ** (Low Latency Queue — file prioritaire) |
| 3. Identifier le trafic YouTube | **Classification** (NBAR identifie l'application) |
| 4. FAI rejette au-delà de 100 Mbps | **Policing** (drop des paquets excédentaires) |
| 5. Lisser le débit à 10 Mbps | **Shaping** (bufferiser et étaler dans le temps) |
| 6. Drop sélectif avant saturation | **Congestion avoidance / WRED** (drop aléatoire préventif basé sur la probabilité de drop AF) |

</details>

### Voir aussi

- Topic 1.5 dans Module 1 (TCP vs UDP — la QoS traite différemment TCP et UDP : TCP réagit à la perte, UDP non)
- Topic 2.9 dans Module 2 (configuration WLAN GUI — les profils QoS font partie de la configuration wireless)
- Topic 3.4 dans Module 3 (OSPF — le coût OSPF et la QoS sont des concepts distincts : OSPF choisit le chemin, QoS traite le trafic sur ce chemin)

---

## 4.8 — Accès distant sécurisé via SSH

> **Exam topic 4.8** : *Configure* — network devices for remote access using SSH
> **Niveau** : Configure

### Contexte

Se connecter à un routeur via Telnet, c'est comme envoyer un mot de passe sur une carte postale — n'importe qui sur le chemin peut le lire. SSH (Secure Shell) chiffre intégralement la session d'administration : authentification, commandes, outputs. C'est le standard absolu pour l'accès distant aux équipements réseau. Aucun réseau d'entreprise sérieux n'utilise Telnet en 2026.

### Théorie

SSH fonctionne en couche application sur TCP port 22. Il existe en deux versions :
- **SSHv1** : obsolète, vulnérable à plusieurs attaques — ne jamais l'utiliser
- **SSHv2** : version courante, chiffrement robuste (AES), authentification par clé ou mot de passe

#### Prérequis pour configurer SSH sur un équipement Cisco

SSH nécessite quatre éléments sur l'équipement :

| Prérequis | Commande | Pourquoi |
|-----------|----------|---------|
| Hostname (pas "Router") | `hostname R1` | Le hostname fait partie du nom de la clé RSA |
| Nom de domaine | `ip domain-name corp.local` | Le domaine + hostname = nom de la clé |
| Clé RSA (≥ 2048 bits) | `crypto key generate rsa modulus 2048` | Chiffrement asymétrique pour l'échange de clés |
| Utilisateur local | `username admin secret P@ss2026!` | Authentification (sauf si TACACS+/RADIUS) |

> Sans hostname et nom de domaine, la commande `crypto key generate rsa` échoue avec l'erreur `% Please define a domain-name first`. C'est la source d'erreur numéro 1 en lab.

#### SSH vs Telnet

| Critère | Telnet | SSH |
|---------|--------|-----|
| Port | TCP 23 | TCP 22 |
| Chiffrement | **Aucun** (texte clair) | AES-128/256, 3DES |
| Authentification | Mot de passe en clair | Clé RSA + mot de passe chiffré |
| Sécurité | Vulnérable au sniffing | Résistant au sniffing |
| Usage | Lab isolé uniquement | Production |
| Overhead | Minimal | Léger (chiffrement) |

### Mise en pratique CLI

#### Configuration complète de SSH

```cisco
! Étape 1 : Hostname et domaine
R1(config)# hostname R1
R1(config)# ip domain-name netcorp.local

! Étape 2 : Générer la clé RSA
R1(config)# crypto key generate rsa modulus 2048
The name for the keys will be: R1.netcorp.local
% The key modulus size is 2048 bits
% Generating 2048 bit RSA keys, keys will be non-exportable...
[OK] (elapsed time was 2 seconds)

! Étape 3 : Forcer SSHv2
R1(config)# ip ssh version 2

! Étape 4 : Créer un utilisateur local
R1(config)# username admin privilege 15 secret Cisco$ecure2026

! Étape 5 : Configurer les lignes VTY
R1(config)# line vty 0 4
R1(config-line)# transport input ssh
R1(config-line)# login local
R1(config-line)# exec-timeout 10 0
R1(config-line)# exit

! Optionnel : tuning SSH
R1(config)# ip ssh time-out 60
R1(config)# ip ssh authentication-retries 3
```

**Détail des commandes VTY** :
- `transport input ssh` : autorise **uniquement** SSH (bloque Telnet). Pour les deux : `transport input ssh telnet` (déconseillé en production)
- `login local` : utilise la base d'utilisateurs locale pour l'authentification
- `exec-timeout 10 0` : déconnexion automatique après 10 minutes d'inactivité

#### Vérification

```cisco
R1# show ip ssh
SSH Enabled - version 2.0
Authentication methods: publickey, keyboard-interactive, password
Authentication timeout: 60 secs; Authentication retries: 3
Minimum expected Diffie Hellman key size : 2048 bits
IOS Keys in SECSH format(ssh-rsa, base64 encoded):
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB...
```

```cisco
R1# show ssh
Connection Version Mode Encryption  Hmac         State          Username
0          2.0     IN   aes256-ctr  hmac-sha2-256 Session started admin
0          2.0     OUT  aes256-ctr  hmac-sha2-256 Session started admin
```

**Interprétation** :
- **Version 2.0** : SSHv2 est actif (sécurisé)
- **aes256-ctr** : chiffrement AES 256 bits en mode counter
- **hmac-sha2-256** : intégrité vérifiée par HMAC SHA-256
- Un administrateur "admin" est actuellement connecté

#### Se connecter en SSH depuis un autre routeur

```cisco
R2# ssh -l admin 10.1.1.1
Password: ********
R1#
```

### Point exam

> **Piège courant** : Oublier l'une des étapes préalables (hostname, domain-name, crypto key). L'examen donne souvent un scénario où SSH « ne fonctionne pas » et vous devez identifier l'étape manquante. La clé RSA ne peut pas être générée sans hostname et domaine.
>
> **À retenir** : SSH = **TCP port 22**. Telnet = **TCP port 23**. La commande `transport input ssh` sur les lignes VTY bloque Telnet. Le modulus RSA doit être **au minimum 768 bits** pour SSHv2, mais Cisco recommande **2048 bits**. Avec `login local`, le routeur consulte la base d'utilisateurs locale — avec `login`, il demande le mot de passe de la ligne VTY (moins sécurisé).
>
> **Attention** : `ip ssh version 2` force SSHv2. Sans cette commande, le routeur peut négocier SSHv1 avec un client ancien — ce qui est une faille de sécurité.

### Exercice 4.8 — Sécuriser l'accès à un routeur

**Contexte** : Le routeur R-EDGE de la société SecureNet est accessible via Telnet (port 23) depuis n'importe quel réseau. Le hostname est toujours "Router". Aucune clé RSA n'a été générée. L'accès utilise le mot de passe de ligne VTY "cisco123".

**Consigne** : Écrivez la configuration complète pour migrer de Telnet vers SSH uniquement. Créez l'utilisateur "netadmin" avec le mot de passe "S3cur3!Net" et le niveau de privilège 15.

**Indice** : <details><summary>Voir l'indice</summary>N'oubliez pas les prérequis : hostname, domain-name, crypto key. Puis la configuration des lignes VTY.</details>

<details>
<summary>Solution</summary>

```cisco
Router(config)# hostname R-EDGE
R-EDGE(config)# ip domain-name securenet.local
R-EDGE(config)# crypto key generate rsa modulus 2048
R-EDGE(config)# ip ssh version 2
R-EDGE(config)# username netadmin privilege 15 secret S3cur3!Net
R-EDGE(config)# line vty 0 4
R-EDGE(config-line)# transport input ssh
R-EDGE(config-line)# login local
R-EDGE(config-line)# exec-timeout 10 0
R-EDGE(config-line)# exit
!
! Optionnel mais recommandé : sécuriser les tentatives
R-EDGE(config)# ip ssh time-out 60
R-EDGE(config)# ip ssh authentication-retries 3
```

**Explication** : La migration de Telnet vers SSH se fait en 6 étapes : hostname, domaine, clé RSA, version SSH, utilisateur local, configuration VTY. Le `transport input ssh` bloque définitivement Telnet. Le `login local` remplace le mot de passe partagé par une authentification individuelle (chaque administrateur a son propre compte).

</details>

### Voir aussi

- Topic 2.8 dans Module 2 (connexions d'accès de management — SSH, Telnet, console, HTTPS)
- Topic 5.3 dans Module 5 (contrôle d'accès par mots de passe — `enable secret`, `username secret`, politique de mots de passe)
- Topic 5.4 dans Module 5 (politique de mots de passe — complexité, MFA, alternatives)

---

## 4.9 — TFTP et FTP dans le réseau

> **Exam topic 4.9** : *Describe* — the capabilities and functions of TFTP/FTP in the network
> **Niveau** : Describe

### Contexte

Un routeur qui plante et perd sa configuration, un switch qui a besoin d'une mise à jour IOS, un administrateur qui veut sauvegarder les configs de 50 équipements avant une maintenance — tous ces scénarios nécessitent un protocole de transfert de fichiers. TFTP et FTP sont les deux protocoles historiques utilisés dans les réseaux pour ces opérations.

### Théorie

#### TFTP — Trivial File Transfer Protocol

TFTP est volontairement minimaliste. Créé à l'époque où les équipements réseau avaient très peu de mémoire, il fait le strict nécessaire : transférer un fichier, point final.

| Caractéristique | Détail |
|----------------|--------|
| Transport | **UDP port 69** |
| Authentification | **Aucune** |
| Navigation dans les répertoires | **Non** (il faut connaître le nom exact du fichier) |
| Taille des blocs | 512 octets par défaut |
| Fiabilité | Acquittement bloc par bloc (stop-and-wait) |
| Chiffrement | **Aucun** |
| Usage typique | Boot réseau (PXE), sauvegarde/restauration IOS, transfert de configs |

TFTP est comme un guichet automatique sans écran de menu : vous devez savoir exactement ce que vous voulez. Pas de liste de fichiers, pas de mot de passe, pas de répertoire. Juste : « donne-moi ce fichier » ou « prends ce fichier ».

#### FTP — File Transfer Protocol

FTP est bien plus complet mais aussi plus lourd. Il offre une véritable gestion de fichiers.

| Caractéristique | Détail |
|----------------|--------|
| Transport | **TCP port 21** (contrôle) + **TCP port 20** (données) |
| Authentification | Username + password (texte clair) |
| Navigation répertoires | **Oui** (ls, cd, pwd…) |
| Taille des blocs | Variable, négociée |
| Fiabilité | TCP garantit la livraison |
| Chiffrement | **Aucun** (FTP standard) — SFTP/FTPS existent mais hors scope CCNA |
| Usage typique | Transferts volumineux (images IOS), gestion centralisée de fichiers |

#### Comparaison TFTP vs FTP

| Critère | TFTP | FTP |
|---------|------|-----|
| Protocole transport | **UDP** (port 69) | **TCP** (ports 20, 21) |
| Authentification | Non | Oui (user + password) |
| Lister les fichiers | Non | Oui |
| Vitesse | Lent (blocs 512 octets, stop-and-wait) | Rapide (TCP windowing, blocs variables) |
| Complexité | Très simple | Plus complexe (2 connexions) |
| Sécurité | Aucune | Faible (credentials en clair) |
| Mémoire requise | Minimale | Plus importante |
| Cas d'usage réseau | Boot PXE, petits fichiers, configs | Images IOS volumineuses, transferts réguliers |

#### Opérations courantes en réseau

Les deux protocoles servent principalement à :

1. **Sauvegarder la configuration** : copier running-config vers un serveur TFTP/FTP
2. **Restaurer la configuration** : copier une config depuis un serveur vers le routeur
3. **Mettre à jour l'IOS** : copier une nouvelle image IOS vers la flash du routeur
4. **Sauvegarder l'IOS** : copier l'image IOS vers un serveur (backup avant upgrade)

### Mise en pratique CLI

#### Sauvegarder la config sur un serveur TFTP

```cisco
R1# copy running-config tftp:
Address or name of remote host []? 10.1.1.200
Destination filename [r1-confg]? R1-backup-20260404.cfg
!!
1524 bytes copied in 0.456 secs (3342 bytes/sec)
```

#### Restaurer une config depuis TFTP

```cisco
R1# copy tftp: running-config
Address or name of remote host []? 10.1.1.200
Source filename []? R1-backup-20260404.cfg
Destination filename [running-config]?
Accessing tftp://10.1.1.200/R1-backup-20260404.cfg...
Loading R1-backup-20260404.cfg from 10.1.1.200 (via GigabitEthernet0/0): !
[OK - 1524 bytes]
1524 bytes copied in 0.234 secs (6513 bytes/sec)
```

#### Mettre à jour l'IOS via FTP

```cisco
! Configurer les credentials FTP
R1(config)# ip ftp username admin
R1(config)# ip ftp password FtpS3cure!
R1(config)# exit
!
! Copier l'image IOS depuis le serveur FTP
R1# copy ftp: flash:
Address or name of remote host []? 10.1.1.200
Source filename []? isr4300-universalk9.17.09.04a.SPA.bin
Destination filename [isr4300-universalk9.17.09.04a.SPA.bin]?
Accessing ftp://10.1.1.200/isr4300-universalk9.17.09.04a.SPA.bin...
Loading isr4300-universalk9.17.09.04a.SPA.bin
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
[OK - 523456789 bytes]
523456789 bytes copied in 312.5 secs (1675061 bytes/sec)
```

#### Vérifier les fichiers en flash

```cisco
R1# show flash:
-#- --length-- -----date/time------ path
1    523456789 Apr 04 2026 15:20:30 isr4300-universalk9.17.09.04a.SPA.bin
2    234567890 Jan 15 2026 10:00:00 isr4300-universalk9.17.06.05.SPA.bin

1056321536 bytes total (298396857 bytes free)
```

### Point exam

> **Piège courant** : Confondre les ports. TFTP = **UDP 69**. FTP = **TCP 21** (contrôle) + **TCP 20** (données). TFTP utilise UDP mais implémente sa propre fiabilité par acquittement de chaque bloc — ce n'est pas « non fiable », c'est fiable mais lent.
>
> **À retenir** : TFTP n'a **aucune authentification** — n'importe qui sur le réseau peut récupérer un fichier s'il en connaît le nom. FTP a une authentification mais les credentials passent en **clair**. Ni l'un ni l'autre n'est sécurisé. Pour la sécurité, on utilise SCP (Secure Copy, basé sur SSH).
>
> **Attention** : La commande `copy` de Cisco est très flexible : `copy running-config tftp:`, `copy flash: tftp:`, `copy tftp: flash:`. L'examen peut demander quelle commande utiliser pour sauvegarder ou restaurer — la syntaxe est toujours `copy <source> <destination>`.

### Exercice 4.9 — TFTP vs FTP pour une migration IOS

**Contexte** : L'administratrice de LogiTrans doit mettre à jour l'IOS de 15 routeurs pendant une fenêtre de maintenance de 2 heures. La nouvelle image fait 550 Mo. Le serveur de fichiers est à 10.1.1.200. Le réseau de management est un lien 100 Mbps dédié.

**Consigne** : Quel protocole recommanderiez-vous (TFTP ou FTP) et pourquoi ? Estimez le temps de transfert pour un routeur avec chaque protocole (TFTP : débit effectif ~500 Ko/s en stop-and-wait, FTP : débit effectif ~10 Mo/s sur un lien 100 Mbps).

**Indice** : <details><summary>Voir l'indice</summary>Calculez le temps total pour 15 routeurs avec chaque protocole. 550 Mo ÷ débit = temps par routeur. Multipliez par 15.</details>

<details>
<summary>Solution</summary>

| Protocole | Débit effectif | Temps par routeur | Temps total (15 routeurs) |
|-----------|---------------|-------------------|---------------------------|
| TFTP | ~500 Ko/s | 550 000 Ko ÷ 500 = **1 100 s ≈ 18 min** | 18 × 15 = **270 min ≈ 4h30** |
| FTP | ~10 Mo/s | 550 Mo ÷ 10 = **55 s ≈ 1 min** | 1 × 15 = **15 min** |

**Recommandation** : **FTP** sans hésitation. Avec TFTP, la migration prendrait 4h30 et dépasserait largement la fenêtre de 2 heures. Avec FTP, 15 minutes suffisent, laissant amplement le temps pour les vérifications post-upgrade. La différence de débit s'explique par le mécanisme stop-and-wait de TFTP (acquittement de chaque bloc de 512 octets) vs le windowing TCP de FTP.

</details>

### Voir aussi

- Topic 4.8 dans ce module (SSH — SCP, basé sur SSH, est l'alternative sécurisée à TFTP/FTP)
- Topic 2.8 dans Module 2 (accès de management — TFTP/FTP font partie de l'écosystème de gestion)
- Topic 1.5 dans Module 1 (TCP vs UDP — TFTP sur UDP, FTP sur TCP, illustration concrète des différences)

---

## Labs Module 4

### Lab 4.1 — NAT/PAT

**Topologie :**

```
                        "Internet" (simulé)
                        ┌─────────────┐
                        │  SRV-EXT    │
                        │ 8.8.8.100   │
                        └──────┬──────┘
                               │ Gi0/0
                        ┌──────┴──────┐
                        │   ISP-R     │
                        │ 8.8.8.1     │    Nuage "Internet"
                        │ 203.0.113.1 │
                        └──────┬──────┘
                               │ Gi0/1
          ─────────────────────┤ 203.0.113.0/30
                               │ Gi0/1 (.2)
                        ┌──────┴──────┐
                        │   R1-NAT    │    Routeur NAT gateway
                        │ Gi0/0: .1   │
                        └──────┬──────┘
                               │ 10.1.1.0/24
                   ┌───────────┼───────────┐
                   │           │           │
            ┌──────┴──┐  ┌────┴────┐  ┌───┴──────┐
            │  PC1    │  │  PC2    │  │ SRV-WEB  │
            │ .50     │  │ .51     │  │ .100     │
            └─────────┘  └─────────┘  └──────────┘
```

**Tableau d'adressage :**

| Équipement | Interface | Adresse IP | Masque | Passerelle |
|------------|-----------|-----------|--------|------------|
| R1-NAT | Gi0/0 | 10.1.1.1 | 255.255.255.0 | — |
| R1-NAT | Gi0/1 | 203.0.113.2 | 255.255.255.252 | 203.0.113.1 |
| ISP-R | Gi0/1 | 203.0.113.1 | 255.255.255.252 | — |
| ISP-R | Gi0/0 | 8.8.8.1 | 255.255.255.0 | — |
| PC1 | NIC | 10.1.1.50 | 255.255.255.0 | 10.1.1.1 |
| PC2 | NIC | 10.1.1.51 | 255.255.255.0 | 10.1.1.1 |
| SRV-WEB | NIC | 10.1.1.100 | 255.255.255.0 | 10.1.1.1 |
| SRV-EXT | NIC | 8.8.8.100 | 255.255.255.0 | 8.8.8.1 |

**Objectifs :**
1. Configurer le NAT statique pour rendre SRV-WEB accessible depuis Internet
2. Configurer le PAT (overload) pour que PC1 et PC2 accèdent à Internet
3. Vérifier les translations NAT

**Configuration de départ :**
```cisco
! Router R1-NAT
hostname R1-NAT
no ip domain-lookup
!
interface GigabitEthernet0/0
 description LAN interne
 ip address 10.1.1.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/1
 description Vers ISP
 ip address 203.0.113.2 255.255.255.252
 no shutdown
!
ip route 0.0.0.0 0.0.0.0 203.0.113.1

! Router ISP-R (pré-configuré)
hostname ISP-R
interface GigabitEthernet0/0
 ip address 8.8.8.1 255.255.255.0
 no shutdown
interface GigabitEthernet0/1
 ip address 203.0.113.1 255.255.255.252
 no shutdown
! Route retour pour le NAT statique
ip route 203.0.113.10 255.255.255.255 203.0.113.2
```

**Étapes :**

1. **Désigner les interfaces NAT**
   - Sur R1-NAT, configurez Gi0/0 comme `ip nat inside` et Gi0/1 comme `ip nat outside`
   - Vérification : `show ip nat statistics` — les interfaces doivent apparaître

2. **Configurer le NAT statique pour SRV-WEB**
   - Commande : `ip nat inside source static 10.1.1.100 203.0.113.10`
   - Vérification : `show ip nat translations` — la translation statique doit apparaître immédiatement

3. **Configurer le PAT pour les PCs**
   - Créez l'ACL : `access-list 10 permit 10.1.1.0 0.0.0.255`
   - Configurez le PAT : `ip nat inside source list 10 interface GigabitEthernet0/1 overload`

4. **Tester le NAT statique**
   - Depuis SRV-EXT, pingez 203.0.113.10 → le ping doit réussir (traduit vers 10.1.1.100)
   - Sur R1-NAT : `show ip nat translations` — une translation dynamique doit apparaître

5. **Tester le PAT**
   - Depuis PC1, pingez 8.8.8.100 → le ping doit réussir
   - Depuis PC2, faites de même
   - Sur R1-NAT : `show ip nat translations` — les deux PCs partagent l'adresse 203.0.113.2 avec des ports différents

**Vérification finale :**
```cisco
R1-NAT# show ip nat translations
Pro  Inside global      Inside local       Outside local      Outside global
---  203.0.113.10       10.1.1.100         ---                ---
icmp 203.0.113.2:1024   10.1.1.50:1        8.8.8.100:1        8.8.8.100:1
icmp 203.0.113.2:1025   10.1.1.51:1        8.8.8.100:1        8.8.8.100:1

R1-NAT# show ip nat statistics
Total active translations: 3 (1 static, 2 dynamic; 2 extended)
Outside interfaces:
  GigabitEthernet0/1
Inside interfaces:
  GigabitEthernet0/0
Hits: 24  Misses: 2
```

**Questions de validation :**
1. Pourquoi le NAT statique apparaît-il dans la table même sans trafic, alors que les translations PAT n'apparaissent qu'après un ping ?
2. Si l'ACL 10 utilisait `permit 10.1.1.50 0.0.0.0` au lieu de `permit 10.1.1.0 0.0.0.255`, que se passerait-il pour PC2 ?

---

### Lab 4.2 — DHCP, NTP et Syslog

**Topologie :**

```
                    ┌──────────────┐
                    │  SRV-MGMT    │  NTP Stratum 2
                    │ 10.1.30.100  │  + Syslog server
                    └──────┬───────┘
                           │
  VLAN 30 (Servers)        │
  ─────────────────────────┤
                           │ Gi0/0.30 (.1)
                    ┌──────┴──────┐
                    │     R1      │
                    │ DHCP relay  │
                    │ NTP client  │
                    └──────┬──────┘
                           │ Gi0/0 (trunk)
                    ┌──────┴──────┐
                    │    SW1      │
                    └──┬──────┬───┘
                       │      │
  VLAN 10 (Users)      │      │  VLAN 20 (VoIP)
  ─────────────────────┤      ├─────────────────
         │             │      │         │
    ┌────┴───┐   ┌─────┴┐  ┌─┴────┐ ┌──┴─────┐
    │  PC1   │   │ PC2  │  │ IP-P1│ │ IP-P2  │
    │  DHCP  │   │ DHCP │  │ DHCP │ │ DHCP   │
    └────────┘   └──────┘  └──────┘ └────────┘
```

**Tableau d'adressage :**

| Équipement | Interface/VLAN | Adresse IP | Masque | Méthode |
|------------|---------------|-----------|--------|---------|
| R1 | Gi0/0.10 | 10.1.10.1 | 255.255.255.0 | Statique |
| R1 | Gi0/0.20 | 10.1.20.1 | 255.255.255.0 | Statique |
| R1 | Gi0/0.30 | 10.1.30.1 | 255.255.255.0 | Statique |
| SRV-MGMT | NIC (VLAN 30) | 10.1.30.100 | 255.255.255.0 | Statique |
| PC1 | NIC (VLAN 10) | DHCP | — | DHCP |
| PC2 | NIC (VLAN 10) | DHCP | — | DHCP |
| IP-P1 | NIC (VLAN 20) | DHCP | — | DHCP |
| IP-P2 | NIC (VLAN 20) | DHCP | — | DHCP |

**Objectifs :**
1. Configurer R1 comme serveur DHCP pour les VLANs 10 et 20
2. Configurer le relay DHCP sur les sous-interfaces
3. Synchroniser R1 et SW1 avec le serveur NTP
4. Centraliser les logs sur le serveur syslog

**Configuration de départ :**
```cisco
! Router R1 (sous-interfaces et VLANs pré-configurés)
hostname R1
no ip domain-lookup
!
interface GigabitEthernet0/0
 no shutdown
!
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 10.1.10.1 255.255.255.0
!
interface GigabitEthernet0/0.20
 encapsulation dot1Q 20
 ip address 10.1.20.1 255.255.255.0
!
interface GigabitEthernet0/0.30
 encapsulation dot1Q 30
 ip address 10.1.30.1 255.255.255.0

! Switch SW1 (VLANs et ports pré-configurés)
hostname SW1
interface GigabitEthernet0/1
 switchport mode trunk
interface range FastEthernet0/1-10
 switchport mode access
 switchport access vlan 10
interface range FastEthernet0/11-20
 switchport mode access
 switchport access vlan 20
interface Vlan10
 ip address 10.1.10.2 255.255.255.0
 no shutdown
```

**Étapes :**

1. **Configurer les pools DHCP sur R1**
   ```cisco
   R1(config)# ip dhcp excluded-address 10.1.10.1 10.1.10.10
   R1(config)# ip dhcp excluded-address 10.1.20.1 10.1.20.10
   !
   R1(config)# ip dhcp pool VLAN10-USERS
   R1(dhcp-config)# network 10.1.10.0 255.255.255.0
   R1(dhcp-config)# default-router 10.1.10.1
   R1(dhcp-config)# dns-server 10.1.30.100 8.8.8.8
   R1(dhcp-config)# lease 1
   R1(dhcp-config)# exit
   !
   R1(config)# ip dhcp pool VLAN20-VOIP
   R1(dhcp-config)# network 10.1.20.0 255.255.255.0
   R1(dhcp-config)# default-router 10.1.20.1
   R1(dhcp-config)# dns-server 10.1.30.100
   R1(dhcp-config)# lease 0 8 0
   R1(dhcp-config)# exit
   ```

2. **Configurer le relay DHCP (si le serveur DHCP est externe)**
   - Note : dans ce lab, R1 est le serveur DHCP, donc le relay n'est nécessaire que si on déplace le serveur DHCP sur SRV-MGMT. Pour la pratique :
   ```cisco
   R1(config)# interface GigabitEthernet0/0.10
   R1(config-subif)# ip helper-address 10.1.30.100
   R1(config)# interface GigabitEthernet0/0.20
   R1(config-subif)# ip helper-address 10.1.30.100
   ```

3. **Configurer NTP**
   ```cisco
   ! R1 se synchronise sur SRV-MGMT
   R1(config)# ntp server 10.1.30.100
   !
   ! SW1 se synchronise sur R1
   SW1(config)# ntp server 10.1.10.1
   ```
   - Vérification : `show ntp status` (attendre quelques minutes pour la synchronisation)
   - Vérification : `show ntp associations`

4. **Configurer Syslog**
   ```cisco
   ! Sur R1
   R1(config)# logging host 10.1.30.100
   R1(config)# logging trap informational
   R1(config)# logging buffered 65536 debugging
   R1(config)# service timestamps log datetime msec localtime
   !
   ! Sur SW1
   SW1(config)# logging host 10.1.30.100
   SW1(config)# logging trap informational
   SW1(config)# service timestamps log datetime msec localtime
   ```

5. **Tester le DHCP**
   - Sur PC1, relâchez et renouvelez l'adresse : `ipconfig /release` puis `ipconfig /renew`
   - Vérifiez : `ipconfig /all` — l'adresse doit être dans le range 10.1.10.11-254
   - Sur R1 : `show ip dhcp binding`

**Vérification finale :**
```cisco
R1# show ip dhcp binding
IP address          Client-ID/              Lease expiration        Type
                    Hardware address
10.1.10.11          0100.aaaa.bbbb.01       Apr 05 2026 14:15 AM   Automatic
10.1.10.12          0100.aaaa.bbbb.02       Apr 05 2026 14:18 AM   Automatic
10.1.20.11          0100.cccc.dddd.01       Apr 04 2026 22:20 PM   Automatic
10.1.20.12          0100.cccc.dddd.02       Apr 04 2026 22:22 PM   Automatic

R1# show ntp status
Clock is synchronized, stratum 3, reference is 10.1.30.100

R1# show logging | include Syslog
Logging to 10.1.30.100  (informational)
```

**Questions de validation :**
1. Pourquoi le bail du VLAN 20 (VoIP) est-il plus court que celui du VLAN 10 (Users) ?
2. Si `show ntp status` affiche "Clock is unsynchronized" après 1 minute, est-ce un problème ? Pourquoi ?

---

## Quiz Module 4 — 15 questions

**Q1.** Quelle commande configure le PAT (NAT overload) en utilisant l'adresse de l'interface outside ? _(Topic 4.1)_

- A) `ip nat inside source list 1 pool MYPOOL`
- B) `ip nat inside source list 1 interface Gi0/1 overload`
- C) `ip nat outside source list 1 interface Gi0/1`
- D) `ip nat inside source static 10.1.1.1 203.0.113.1`

<details>
<summary>Réponse</summary>

**B** — La commande `ip nat inside source list 1 interface Gi0/1 overload` active le PAT en utilisant l'adresse de l'interface Gi0/1. Le mot-clé `overload` est essentiel — sans lui (option A), c'est du NAT dynamique classique avec un pool (et un mapping 1:1). L'option C utilise "outside source" qui traduit l'adresse source des paquets venant de l'extérieur. L'option D est du NAT statique (1:1 permanent).

</details>

---

**Q2.** Un routeur NAT a la translation suivante dans sa table :
```
Pro  Inside global      Inside local       Outside local      Outside global
tcp  203.0.113.1:2048   10.1.1.50:49152    142.250.74.46:443  142.250.74.46:443
```
Quelle est l'adresse vue par le serveur web 142.250.74.46 comme source du paquet ? _(Topic 4.1)_

- A) 10.1.1.50
- B) 203.0.113.1
- C) 142.250.74.46
- D) 10.1.1.1

<details>
<summary>Réponse</summary>

**B** — Le serveur web voit l'adresse **Inside Global** (203.0.113.1) car c'est l'adresse traduite visible depuis l'extérieur. L'adresse Inside Local (10.1.1.50) est l'adresse réelle du PC sur le réseau interne — elle n'est jamais visible depuis Internet grâce au NAT. L'option C est l'adresse du serveur lui-même, pas la source. L'option D n'apparaît nulle part dans cette translation.

</details>

---

**Q3.** Un switch affiche `Clock is synchronized, stratum 5`. Quel est le stratum de son serveur NTP ? _(Topic 4.2)_

- A) 3
- B) 4
- C) 5
- D) 6

<details>
<summary>Réponse</summary>

**B** — Le stratum d'un client NTP est toujours **stratum du serveur + 1**. Si le switch est Stratum 5, son serveur est Stratum **4**. L'option A (3) donnerait un client Stratum 4. L'option C (5) est le stratum du switch lui-même, pas de son serveur. L'option D (6) est impossible — ce serait le stratum d'un client synchronisé sur CE switch.

</details>

---

**Q4.** Dans le processus DHCP, quel message est envoyé en premier par le client ? _(Topic 4.3)_

- A) DHCP Request
- B) DHCP Offer
- C) DHCP Discover
- D) DHCP Acknowledge

<details>
<summary>Réponse</summary>

**C** — Le processus DORA commence par **Discover**. Le client, qui n'a pas encore d'adresse IP, envoie un broadcast DHCP Discover (src 0.0.0.0, dst 255.255.255.255) pour trouver un serveur DHCP. L'Offer (B) est la réponse du serveur. Le Request (A) est la troisième étape. L'Acknowledge (D) est la quatrième et dernière étape.

</details>

---

**Q5.** Quelle version de SNMP offre à la fois l'authentification et le chiffrement ? _(Topic 4.4)_

- A) SNMPv1
- B) SNMPv2c
- C) SNMPv3
- D) SNMPv2c et SNMPv3

<details>
<summary>Réponse</summary>

**C** — Seul **SNMPv3** offre les deux. SNMPv1 et SNMPv2c utilisent des community strings transmises en texte clair — elles n'offrent ni authentification forte ni chiffrement. L'option D est incorrecte car SNMPv2c n'a pas de chiffrement. SNMPv3 utilise MD5 ou SHA pour l'authentification et DES ou AES pour le chiffrement.

</details>

---

**Q6.** Un message syslog affiche `%OSPF-4-FLOOD_WAR`. Quel est son niveau de sévérité ? _(Topic 4.5)_

- A) Error
- B) Warning
- C) Notification
- D) Informational

<details>
<summary>Réponse</summary>

**B** — Le chiffre **4** dans `%OSPF-4-FLOOD_WAR` indique le niveau de sévérité **Warning** (niveau 4). Le chiffre est toujours entre les deux premiers tirets du code. Error est le niveau 3. Notification est le niveau 5. Informational est le niveau 6. Moyen mnémotechnique : 0-Emergency, 1-Alert, 2-Critical, 3-Error, **4-Warning**, 5-Notification, 6-Informational, 7-Debugging.

</details>

---

**Q7.** Quelle commande configure un relay DHCP sur une interface routeur ? _(Topic 4.6)_

- A) `ip dhcp relay 10.1.1.254`
- B) `ip helper-address 10.1.1.254`
- C) `ip dhcp server 10.1.1.254`
- D) `ip forward-protocol dhcp 10.1.1.254`

<details>
<summary>Réponse</summary>

**B** — La commande `ip helper-address` configurée sur l'interface côté client convertit les broadcasts DHCP en unicast vers le serveur spécifié. L'option A n'existe pas en syntaxe IOS. L'option C n'est pas la commande correcte. L'option D modifie les protocoles relayés par helper-address mais ne configure pas le relay lui-même. La commande helper-address se configure en mode interface.

</details>

---

**Q8.** Quelle est la différence fondamentale entre policing et shaping en QoS ? _(Topic 4.7)_

- A) Le policing est utilisé en sortie, le shaping en entrée
- B) Le policing rejette le trafic excédentaire, le shaping le retarde
- C) Le policing utilise TCP, le shaping utilise UDP
- D) Le policing s'applique au Layer 2, le shaping au Layer 3

<details>
<summary>Réponse</summary>

**B** — Le **policing** rejette (drop) les paquets qui dépassent le débit configuré, tandis que le **shaping** les met en buffer et les envoie progressivement (delay). L'option A est inversée en partie : le policing peut s'appliquer en entrée ET en sortie, le shaping uniquement en sortie. Les options C et D n'ont aucun rapport avec le fonctionnement de ces mécanismes.

</details>

---

**Q9.** Quels sont les trois prérequis pour générer une clé RSA nécessaire à SSH sur un routeur Cisco ? _(Topic 4.8)_

- A) Hostname, enable password, NTP configuré
- B) Hostname, domain-name, username local
- C) Domain-name, enable secret, logging configuré
- D) Hostname, domain-name, ip ssh version 2

<details>
<summary>Réponse</summary>

**B** — Pour générer une clé RSA avec `crypto key generate rsa`, il faut un **hostname** (pas "Router") et un **domain-name** configuré. Le **username local** est ensuite nécessaire pour l'authentification SSH (avec `login local`). L'option A mentionne enable password (pas requis pour RSA) et NTP (utile mais pas prérequis). L'option C omet le hostname. L'option D mentionne `ip ssh version 2` qui ne peut être configuré qu'APRÈS la génération de la clé.

</details>

---

**Q10.** Quel protocole de transfert de fichiers n'offre AUCUNE authentification ? _(Topic 4.9)_

- A) FTP
- B) SFTP
- C) TFTP
- D) SCP

<details>
<summary>Réponse</summary>

**C** — **TFTP** (Trivial File Transfer Protocol) n'a aucun mécanisme d'authentification. N'importe qui connaissant le nom du fichier peut le récupérer. FTP (A) a une authentification par username/password (en clair). SFTP (B) et SCP (D) utilisent SSH pour l'authentification et le chiffrement — ils sont les plus sécurisés.

</details>

---

**Q11.** Avec `logging trap warnings` configuré, quels niveaux de sévérité sont envoyés au serveur syslog ? _(Topic 4.5)_

- A) Uniquement le niveau 4 (Warning)
- B) Niveaux 4 à 7 (Warning à Debugging)
- C) Niveaux 0 à 4 (Emergency à Warning)
- D) Niveaux 0 à 3 (Emergency à Error)

<details>
<summary>Réponse</summary>

**C** — Configurer un niveau de sévérité inclut **ce niveau et tous les niveaux plus graves** (numéro inférieur). `logging trap warnings` (niveau 4) capture les niveaux 0 (Emergency), 1 (Alert), 2 (Critical), 3 (Error) et 4 (Warning). Les niveaux 5, 6 et 7 sont exclus. L'option B est l'inverse de la logique correcte. L'option D omet le niveau 4 lui-même.

</details>

---

**Q12.** Un réseau utilise le routeur R1 comme serveur DHCP. Les commandes suivantes ont été configurées :
```
ip dhcp excluded-address 10.1.1.1 10.1.1.10
ip dhcp pool LAN
 network 10.1.1.0 255.255.255.0
 default-router 10.1.1.1
```
Quelle sera la première adresse attribuée à un client ? _(Topic 4.6)_

- A) 10.1.1.1
- B) 10.1.1.2
- C) 10.1.1.10
- D) 10.1.1.11

<details>
<summary>Réponse</summary>

**D** — La commande `ip dhcp excluded-address 10.1.1.1 10.1.1.10` exclut les adresses .1 à .10 de la distribution DHCP. La première adresse disponible dans le pool est donc **10.1.1.11**. L'option A (.1) est le routeur lui-même (exclu). L'option B (.2) est dans la plage d'exclusion. L'option C (.10) est la dernière adresse de la plage d'exclusion.

</details>

---

**Q13.** Quel port est utilisé par un agent SNMP pour recevoir les requêtes GET du NMS ? _(Topic 4.4)_

- A) UDP 161
- B) UDP 162
- C) TCP 161
- D) TCP 162

<details>
<summary>Réponse</summary>

**A** — L'agent SNMP écoute sur **UDP port 161** pour les requêtes du NMS (GET, GET-NEXT, SET). Le port **UDP 162** (option B) est utilisé par le NMS pour recevoir les traps/informs envoyés par les agents. SNMP utilise **UDP**, pas TCP — les options C et D sont donc incorrectes.

</details>

---

**Q14.** Pourquoi le message DHCP Request (étape 3 de DORA) est-il envoyé en broadcast ? _(Topic 4.3)_

- A) Parce que le client n'a pas encore d'adresse IP
- B) Pour informer les autres serveurs DHCP que leur offre a été refusée
- C) Parce que le serveur DHCP ne peut recevoir que des broadcasts
- D) Pour demander une extension du bail

<details>
<summary>Réponse</summary>

**B** — Le Request est envoyé en broadcast pour **informer tous les serveurs DHCP** du réseau. S'il y a plusieurs serveurs qui ont chacun envoyé une Offer, le broadcast Request leur permet de savoir quelle offre a été acceptée et de libérer les adresses qu'ils avaient réservées. L'option A est un fait vrai mais pas la raison du broadcast (un unicast fonctionnerait techniquement). L'option C est fausse. L'option D décrit un renouvellement, qui est unicast.

</details>

---

**Q15.** Un administrateur tape `copy running-config tftp:` sur un routeur. Quel est l'effet de cette commande ? _(Topic 4.9)_

- A) Restaure la configuration depuis un serveur TFTP
- B) Sauvegarde la configuration en cours sur un serveur TFTP
- C) Copie l'image IOS vers un serveur TFTP
- D) Synchronise la startup-config avec un serveur TFTP

<details>
<summary>Réponse</summary>

**B** — La syntaxe `copy <source> <destination>` copie de gauche à droite. `running-config` est la source (la configuration active en mémoire), `tftp:` est la destination. Cette commande **sauvegarde** la configuration courante sur le serveur TFTP. L'option A serait `copy tftp: running-config`. L'option C serait `copy flash: tftp:`. L'option D n'est pas une opération standard.

</details>

---

## Récapitulatif Module 4

| Topic | Concept clé | Commande(s) essentielles |
|-------|------------|--------------------------|
| 4.1 | NAT statique (1:1), dynamique (pool), PAT (overload) | `ip nat inside source static`, `ip nat inside source list ... overload`, `show ip nat translations` |
| 4.2 | NTP synchronise les horloges — hiérarchie stratum | `ntp server`, `ntp master`, `show ntp status`, `show ntp associations` |
| 4.3 | DHCP = attribution auto IP (DORA), DNS = résolution de noms | `ipconfig /all`, `show ip dns view` |
| 4.4 | SNMP = supervision centralisée (NMS, agents, MIB, traps) | `snmp-server community`, `snmp-server host`, `show snmp` |
| 4.5 | Syslog = journal d'événements, 8 niveaux (0=grave, 7=debug) | `logging host`, `logging trap`, `show logging` |
| 4.6 | DHCP client (ip address dhcp), relay (ip helper-address) | `ip address dhcp`, `ip helper-address`, `show ip dhcp binding` |
| 4.7 | QoS PHB : classification → marking → queuing → scheduling | `show policy-map interface` |
| 4.8 | SSH : hostname + domain + RSA + VTY = accès chiffré | `crypto key generate rsa`, `transport input ssh`, `show ip ssh` |
| 4.9 | TFTP (UDP 69, simple) vs FTP (TCP 20/21, complet) | `copy running-config tftp:`, `copy ftp: flash:` |

**Check-list avant de passer au Module 5 :**
- [ ] Je sais configurer NAT statique, NAT dynamique avec pool, et PAT (overload)
- [ ] Je sais identifier les 4 types d'adresses NAT (inside local/global, outside local/global)
- [ ] Je sais configurer NTP en mode client et serveur, et interpréter `show ntp status`
- [ ] Je sais expliquer le processus DORA et le rôle de DNS
- [ ] Je sais expliquer SNMP (versions, composants, opérations GET/SET/TRAP/INFORM)
- [ ] Je connais les 8 niveaux de sévérité syslog et peux les classer
- [ ] Je sais configurer un pool DHCP, le relay (`ip helper-address`), et un client DHCP
- [ ] Je sais distinguer policing (drop) de shaping (delay) et expliquer le marquage DSCP/CoS
- [ ] Je sais configurer SSH de bout en bout (hostname, domain, RSA, VTY)
- [ ] Je sais comparer TFTP et FTP et utiliser `copy` pour les sauvegardes
- [ ] J'ai complété les 9 exercices
- [ ] J'ai réalisé les 2 labs (NAT/PAT + DHCP/NTP/Syslog)
- [ ] J'ai obtenu >70% au quiz (11/15 minimum)
