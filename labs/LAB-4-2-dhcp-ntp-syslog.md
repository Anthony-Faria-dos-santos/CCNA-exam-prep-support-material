# LAB 4.2 — DHCP, relais DHCP, NTP et Syslog

| Info | Valeur |
|------|--------|
| **Module** | 4 — IP Services |
| **Topics couverts** | 4.2 (DHCP), 4.3 (DHCP relay), 4.5 (NTP), 4.6 (Syslog) |
| **Difficulté** | Intermédiaire |
| **Durée estimée** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                                    192.168.2.0/24
                                   ┌──────────┐
                                   │   PC4    │
                                   │  (DHCP)  │
                                   └────┬─────┘
                                        │
                                   ┌────┴─────┐
                                   │   SW2    │
                                   └────┬─────┘
                                        │
                                        │ Gi0/1
                                        │ 192.168.2.1/24
                              ┌─────────┴─────────┐
                              │        R1          │
                              │  (Serveur DHCP)    │
                              │  (Client NTP)      │
                              └─────────┬──────────┘
                                        │ Gi0/0
                                        │ 192.168.1.1/24
                                        │
                              ┌─────────┴──────────┐
                              │       SW1           │
                              │   (Client NTP)      │
                              └──┬─────┬──────┬─────┘
                                 │     │      │
                                PC1   PC2    PC3         NTP-SYSLOG-SRV
                              (DHCP) (DHCP) (DHCP)      192.168.1.100
                                                         (IP statique)
                           192.168.1.0/24
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle | Source |
|----------|-----------|------------|--------|------------|--------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — | Statique |
| R1 | Gi0/1 | 192.168.2.1 | 255.255.255.0 | — | Statique |
| SW1 | VLAN 1 | DHCP ou 192.168.1.2 | 255.255.255.0 | 192.168.1.1 | Statique |
| SW2 | VLAN 1 | 192.168.2.2 | 255.255.255.0 | 192.168.2.1 | Statique |
| NTP-SYSLOG-SRV | NIC | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | Statique |
| PC1 | NIC | DHCP (192.168.1.50-.99) | 255.255.255.0 | 192.168.1.1 | DHCP |
| PC2 | NIC | DHCP (192.168.1.50-.99) | 255.255.255.0 | 192.168.1.1 | DHCP |
| PC3 | NIC | DHCP (192.168.1.50-.99) | 255.255.255.0 | 192.168.1.1 | DHCP |
| PC4 | NIC | DHCP (192.168.2.50-.99) | 255.255.255.0 | 192.168.2.1 | DHCP |

**Pool DHCP LAN-POOL :** 192.168.1.50 — 192.168.1.99 (réseau 1)
**Pool DHCP LAN2-POOL :** 192.168.2.50 — 192.168.2.99 (réseau 2)
**Exclusions :** .1 — .49 (infrastructure) et .100 — .110 (serveurs) sur chaque réseau

---

## Objectifs

1. Configurer un serveur DHCP sur R1 avec les bonnes exclusions et options
2. Vérifier que les PCs obtiennent une adresse IP via DHCP
3. Configurer un relais DHCP pour un second réseau derrière R1
4. Configurer la synchronisation NTP entre le serveur, R1 et SW1
5. Configurer l'envoi des logs Syslog de R1 vers le serveur centralisé
6. Vérifier le fonctionnement global de tous les services

---

## Prérequis

- Configuration de base d'un routeur et d'un switch Cisco
- Compréhension du principe client/serveur
- Notions de base sur les broadcasts et le fonctionnement de DHCP (DORA)
- Savoir configurer une adresse IP statique sur un PC dans Packet Tracer

---

## Configuration de départ

Copiez-collez ces configurations **avant de commencer le lab**.

### R1 — Configuration initiale

```
enable
configure terminal
hostname R1
no ip domain-lookup
line console 0
 logging synchronous
exit

interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 description LAN principal
exit

interface GigabitEthernet0/1
 ip address 192.168.2.1 255.255.255.0
 no shutdown
 description LAN secondaire
exit
```

### SW1 — Configuration initiale

```
enable
configure terminal
hostname SW1
no ip domain-lookup
line console 0
 logging synchronous
exit

interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1
```

### SW2 — Configuration initiale

```
enable
configure terminal
hostname SW2
no ip domain-lookup
line console 0
 logging synchronous
exit

interface vlan 1
 ip address 192.168.2.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.2.1
```

### NTP-SYSLOG-SRV

Dans Packet Tracer, placez un **Server** et configurez-le manuellement :
- **IP** : 192.168.1.100 / 255.255.255.0 / Passerelle : 192.168.1.1
- **Onglet Services > NTP** : activez le service NTP (Authentication = Off pour simplifier)
- **Onglet Services > Syslog** : activez le service Syslog

---

## Partie 1 : Configuration du serveur DHCP sur R1

DHCP (Dynamic Host Configuration Protocol) automatise l'attribution des adresses IP. Au lieu de configurer chaque PC manuellement, les hôtes envoient un broadcast DHCP Discover et le serveur leur attribue une adresse avec tous les paramètres réseau (masque, passerelle, DNS).

### Étape 1.1 — Définir les exclusions d'adresses

Les exclusions indiquent au serveur DHCP de ne **jamais** distribuer ces adresses. On exclut les adresses déjà utilisées par l'infrastructure (routeur, switch, serveurs) :

Sur **R1** :

```
configure terminal

ip dhcp excluded-address 192.168.1.1 192.168.1.49
ip dhcp excluded-address 192.168.1.100 192.168.1.110
```

> **Pourquoi exclure ?** Sans exclusion, le serveur DHCP pourrait attribuer l'adresse 192.168.1.1 (celle du routeur) ou 192.168.1.100 (celle du serveur NTP/Syslog) à un PC. Cela provoquerait un conflit d'adresses IP et des dysfonctionnements réseau. En entreprise, on réserve généralement les premières adresses pour l'infrastructure et un bloc pour les serveurs.

### Étape 1.2 — Créer le pool DHCP

```
ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8
 domain-name lab.local
 lease 2
exit
```

Décortiquons chaque ligne :

| Commande | Rôle | Option DHCP |
|----------|------|-------------|
| `network` | Définit le réseau et le masque à distribuer | — |
| `default-router` | Passerelle par défaut envoyée aux clients | Option 3 |
| `dns-server` | Serveur DNS envoyé aux clients | Option 6 |
| `domain-name` | Suffixe DNS envoyé aux clients | Option 15 |
| `lease 2` | Durée du bail = 2 jours (format : jours [heures] [minutes]) | — |

> **Concept clé — le bail (lease) :** quand un PC reçoit une adresse DHCP, il ne la "possède" pas pour toujours. Le bail définit la durée pendant laquelle l'adresse est réservée. À 50% du bail, le client tente de renouveler (DHCP Request unicast). À 87,5%, il retente en broadcast. Si le bail expire, le client perd son adresse et doit recommencer le processus DORA.

### Étape 1.3 — Vérifier la configuration du pool

```
show ip dhcp pool
```

**Output attendu :**

```
R1#show ip dhcp pool

Pool LAN-POOL :
 Utilization mark (high/low)    : 100 / 0
 Subnet size (first/next)       : 0 / 0
 Total addresses                : 254
 Leased addresses               : 0
 Pending event                  : none
 1 subnet is currently in the pool :
 Current index        IP address range                    Leased addresses
 192.168.1.50         192.168.1.1      - 192.168.1.254    0
```

---

## Partie 2 : Configuration des PCs en DHCP et vérification

### Étape 2.1 — Configurer les PCs en DHCP

Sur chaque PC (PC1, PC2, PC3) dans Packet Tracer :
1. Allez dans l'onglet **Desktop > IP Configuration**
2. Sélectionnez **DHCP**
3. Attendez que le PC obtienne une adresse

Le PC devrait afficher une adresse dans la plage 192.168.1.50 — 192.168.1.99 avec :
- Masque : 255.255.255.0
- Passerelle : 192.168.1.1
- DNS : 8.8.8.8

### Étape 2.2 — Vérifier les baux DHCP sur R1

```
show ip dhcp binding
```

**Output attendu :**

```
R1#show ip dhcp binding
Bindings from all pools not associated with VRF:
IP address          Client-ID/              Lease expiration        Type
                    Hardware address/
                    User name
192.168.1.50        0060.3E45.A1B2           Apr 06 2026 10:30 AM   Automatic
192.168.1.51        0060.3E45.C3D4           Apr 06 2026 10:30 AM   Automatic
192.168.1.52        0060.3E45.E5F6           Apr 06 2026 10:31 AM   Automatic
```

Chaque PC a reçu une adresse unique, avec une date d'expiration du bail à J+2.

### Étape 2.3 — Vérifier depuis un PC (ligne de commande)

Sur **PC1**, ouvrez le **Command Prompt** et tapez :

```
ipconfig /all
```

**Output attendu :**

```
FastEthernet0 Connection:(default port)

   Connection-specific DNS Suffix..: lab.local
   Physical Address................: 0060.3E45.A1B2
   Link-local IPv6 Address.........: FE80::260:3EFF:FE45:A1B2
   IPv6 Address....................: ::
   IPv4 Address....................: 192.168.1.50
   Subnet Mask.....................: 255.255.255.0
   Default Gateway.................: 192.168.1.1
   DHCP Servers....................: 192.168.1.1
   DHCPv6 IAID.....................:
   DHCPv6 Client DUID..............:
   DNS Servers.....................: 8.8.8.8
```

Tous les paramètres configurés dans le pool sont bien distribués.

### Étape 2.4 — Tester un renouvellement

Sur PC1 :

```
ipconfig /release
ipconfig /renew
```

Le PC libère son bail puis en obtient un nouveau. Il peut recevoir la même adresse ou une différente.

### Étape 2.5 — Vérifier la connectivité

Depuis PC1, pingez le serveur NTP/Syslog :

```
ping 192.168.1.100
```

**Output attendu :** 4 réponses, 0% de perte.

---

## Partie 3 : Relais DHCP (ip helper-address)

Voici un problème classique : PC4 est sur le réseau 192.168.2.0/24, mais le serveur DHCP est R1 sur le réseau 192.168.1.0/24. Or, DHCP utilise des **broadcasts**, et les broadcasts ne traversent pas les routeurs. Comment PC4 peut-il obtenir une adresse ?

La réponse : le **relais DHCP** (`ip helper-address`). Le routeur intercepte les broadcasts DHCP sur une interface et les retransmet en **unicast** vers le serveur DHCP.

### Étape 3.1 — Créer le second pool DHCP

Sur **R1** :

```
configure terminal

ip dhcp excluded-address 192.168.2.1 192.168.2.49
ip dhcp excluded-address 192.168.2.100 192.168.2.110

ip dhcp pool LAN2-POOL
 network 192.168.2.0 255.255.255.0
 default-router 192.168.2.1
 dns-server 8.8.8.8
 domain-name lab.local
 lease 2
exit
```

### Étape 3.2 — Configurer le relais DHCP

Ici, le serveur DHCP est R1 lui-même. Comme l'interface Gi0/1 de R1 est directement connectée au réseau 192.168.2.0/24, R1 sait déjà traiter les requêtes DHCP qui arrivent sur cette interface : il matche le réseau du pool LAN2-POOL (network 192.168.2.0).

Cependant, pour illustrer le concept de relais DHCP tel qu'il est testé à l'examen, configurons quand même le `ip helper-address`. Imaginons que le serveur DHCP soit sur 192.168.1.1 et que nous configurons le relais sur l'interface du réseau distant :

```
interface GigabitEthernet0/1
 ip helper-address 192.168.1.1
exit
```

> **Comment fonctionne `ip helper-address` :**
> 1. PC4 envoie un broadcast DHCP Discover (255.255.255.255)
> 2. R1 reçoit ce broadcast sur Gi0/1
> 3. Grâce à `ip helper-address`, R1 transforme le broadcast en unicast vers 192.168.1.1
> 4. R1 (en tant que serveur DHCP) traite la requête, voit qu'elle vient de l'interface 192.168.2.0/24, et attribue une adresse du pool LAN2-POOL
> 5. La réponse DHCP Offer est renvoyée vers PC4
>
> **Point exam :** `ip helper-address` se configure sur l'interface **du côté du client**, pas du côté du serveur. C'est l'erreur la plus fréquente. Dans un vrai réseau, si le serveur DHCP est sur un autre sous-réseau, c'est indispensable.

### Étape 3.3 — Configurer PC4 en DHCP

Sur **PC4** dans Packet Tracer :
1. Onglet **Desktop > IP Configuration**
2. Sélectionnez **DHCP**

PC4 devrait obtenir une adresse dans la plage 192.168.2.50 — 192.168.2.99.

### Étape 3.4 — Vérifier

Sur **R1** :

```
show ip dhcp binding
```

**Output attendu :**

```
R1#show ip dhcp binding
Bindings from all pools not associated with VRF:
IP address          Client-ID/              Lease expiration        Type
                    Hardware address/
                    User name
192.168.1.50        0060.3E45.A1B2           Apr 06 2026 10:30 AM   Automatic
192.168.1.51        0060.3E45.C3D4           Apr 06 2026 10:30 AM   Automatic
192.168.1.52        0060.3E45.E5F6           Apr 06 2026 10:31 AM   Automatic
192.168.2.50        0060.3E45.7890           Apr 06 2026 10:35 AM   Automatic
```

PC4 a bien obtenu une adresse du pool LAN2-POOL.

Vérifiez aussi les statistiques des deux pools :

```
show ip dhcp pool
```

Depuis **PC4**, pingez le serveur NTP/Syslog sur le réseau 1 :

```
ping 192.168.1.100
```

Le ping doit réussir puisque R1 route entre les deux réseaux.

> **Astuce exam :** `ip helper-address` ne transmet pas uniquement DHCP. Par défaut, il relaye 8 protocoles basés sur UDP : TFTP (69), DNS (53), Time (37), NetBIOS (137, 138), BOOTP/DHCP (67, 68), et TACACS (49). À l'examen, on vous demande principalement DHCP.

---

## Partie 4 : Configuration NTP

NTP (Network Time Protocol) synchronise les horloges de tous les équipements réseau. C'est essentiel pour la corrélation des logs, les certificats numériques, et les protocoles d'authentification. Sans NTP, chaque appareil a une horloge indépendante qui dérive, rendant le diagnostic d'incidents quasi impossible.

### Étape 4.1 — Vérifier l'horloge actuelle de R1

```
show clock
```

**Output attendu (avant NTP) :**

```
R1#show clock
*00:12:34.567 UTC Mon Mar 1 1993
```

L'horloge est complètement fausse : les routeurs Cisco démarrent avec une date par défaut (souvent en 1993). C'est exactement le problème que NTP résout.

### Étape 4.2 — Configurer le serveur NTP dans Packet Tracer

Sur le **NTP-SYSLOG-SRV** dans Packet Tracer :
1. Onglet **Services > NTP**
2. Vérifiez que le service est **ON**
3. Notez la date et l'heure affichées (le serveur Packet Tracer simule un stratum 1)

### Étape 4.3 — Configurer R1 comme client NTP

Sur **R1** :

```
configure terminal
ntp server 192.168.1.100
```

C'est tout. Une seule commande. R1 va automatiquement contacter le serveur NTP et synchroniser son horloge.

### Étape 4.4 — Configurer SW1 comme client NTP

On peut configurer SW1 pour se synchroniser soit directement avec le serveur, soit avec R1 (qui agit alors comme relais NTP). Configurons-le directement sur le serveur :

Sur **SW1** :

```
configure terminal
ntp server 192.168.1.100
```

### Étape 4.5 — Configurer le fuseau horaire (optionnel mais recommandé)

Sur **R1** :

```
clock timezone CET 1
clock summer-time CEST recurring
```

Sur **SW1** :

```
clock timezone CET 1
clock summer-time CEST recurring
```

### Étape 4.6 — Vérifier la synchronisation NTP

Attendez environ 30 secondes à 1 minute dans Packet Tracer, puis vérifiez.

Sur **R1** :

```
show ntp status
```

**Output attendu :**

```
R1#show ntp status
Clock is synchronized, stratum 2, reference is 192.168.1.100
nominal freq is 250.0000 Hz, actual freq is 250.0000 Hz, precision is 2**24
reference time is E5A1B2C3.4D5E6F70 (10:30:00.302 CET Sat Apr 4 2026)
clock offset is 0.00 msec, root delay is 1.00 msec
root dispersion is 10.20 msec, peer dispersion is 0.12 msec
loopfilter state is 'CTRL' (Normal Controlled Loop),
drift compensation is 0.000000000 s/s
system poll interval is 64, last update was 32 secs ago.
```

Points importants dans cette sortie :
- **Clock is synchronized** : la synchronisation est réussie
- **stratum 2** : R1 est à stratum 2 car son serveur (NTP-SYSLOG-SRV) est stratum 1. Chaque "saut" ajoute un niveau de stratum

> **Concept exam — Stratum NTP :**
>
> | Stratum | Description |
> |---------|-------------|
> | 0 | Source de temps de référence (horloge atomique, GPS) — non joignable directement par NTP |
> | 1 | Serveur directement connecté à une source stratum 0 |
> | 2 | Synchronisé avec un serveur stratum 1 |
> | ... | Chaque niveau ajoute 1 |
> | 15 | Dernier stratum valide |
> | 16 | Non synchronisé (inutilisable) |
>
> Plus le stratum est bas, plus l'horloge est précise et fiable.

Vérifiez aussi les associations NTP :

```
show ntp associations
```

**Output attendu :**

```
R1#show ntp associations
  address         ref clock       st   when   poll reach  delay  offset   disp
*~192.168.1.100   .GPS.            1     32     64   377  1.000   0.000  0.120
 * sys.peer, # selected, + candidate, - outlyer, x falseticker, ~ configured
```

Le symbole `*` devant l'adresse indique que c'est le peer actif (serveur utilisé pour la synchronisation).

Enfin, vérifiez l'horloge :

```
show clock
```

**Output attendu (après NTP) :**

```
R1#show clock
11:30:45.123 CET Sat Apr 4 2026
```

L'horloge affiche maintenant la date et l'heure correctes.

---

## Partie 5 : Configuration Syslog

Syslog est le protocole standard pour la journalisation centralisée. Au lieu de consulter les logs sur chaque équipement individuellement, on les envoie tous vers un serveur central. C'est indispensable pour la sécurité, la conformité et le diagnostic.

### Étape 5.1 — Les 8 niveaux Syslog (à connaître par coeur)

Avant de configurer, il faut comprendre les niveaux de sévérité. Plus le numéro est bas, plus le message est critique :

| Niveau | Nom | Mot-clé IOS | Description | Mnémonique |
|--------|-----|-------------|-------------|------------|
| 0 | Emergency | emergencies | Système inutilisable | **E**very |
| 1 | Alert | alerts | Action immédiate nécessaire | **A**wesome |
| 2 | Critical | critical | Condition critique | **C**isco |
| 3 | Error | errors | Condition d'erreur | **E**ngineer |
| 4 | Warning | warnings | Condition d'avertissement | **W**ill |
| 5 | Notification | notifications | Normal mais significatif | **N**eed |
| 6 | Informational | informational | Message d'information | **I**ce |
| 7 | Debug | debugging | Message de débogage | **D**aily |

> **Astuce mémotechnique :** "**E**very **A**wesome **C**isco **E**ngineer **W**ill **N**eed **I**ce **D**aily" (Emergency, Alert, Critical, Error, Warning, Notification, Informational, Debug).
>
> **Point exam :** quand on configure `logging trap 6` (informational), le routeur envoie tous les messages de niveau 0 à 6. Le niveau configuré inclut **tous les niveaux inférieurs** (= plus critiques). Le niveau 7 (debug) est exclu car trop verbeux pour un serveur central.

### Étape 5.2 — Activer les timestamps dans les logs

Sans timestamps, les messages de log ne montrent que le type d'événement mais pas quand il s'est produit, ce qui rend le diagnostic très difficile.

Sur **R1** :

```
configure terminal
service timestamps log datetime msec
service timestamps debug datetime msec
```

> **Pourquoi `datetime msec` ?** L'option `datetime` ajoute la date et l'heure complètes (au lieu d'un simple uptime). L'option `msec` ajoute les millisecondes, utile pour corréler des événements qui se produisent presque simultanément.

### Étape 5.3 — Configurer l'envoi des logs vers le serveur Syslog

```
logging host 192.168.1.100
logging trap informational
```

Décortiquons :
- `logging host 192.168.1.100` : envoie les logs via UDP port 514 vers le serveur Syslog
- `logging trap informational` : filtre les messages envoyés au serveur : seulement les niveaux 0 à 6 (on exclut le debug, trop verbeux)

### Étape 5.4 — Configurer le logging sur la console et le buffer

```
logging console warnings
logging buffered 16384 informational
```

- `logging console warnings` : la console n'affiche que les messages de niveau 0 à 4 (pour éviter de noyer l'administrateur)
- `logging buffered 16384 informational` : stocke les messages de niveau 0 à 6 dans un buffer local de 16 Ko (utile quand on n'a pas accès au serveur)

### Étape 5.5 — Ajouter le numéro de séquence aux logs (optionnel)

```
service sequence-numbers
```

Cela ajoute un numéro incrémental à chaque message, ce qui permet de repérer les messages manquants.

### Étape 5.6 — Générer du trafic pour tester Syslog

Pour générer des messages de log, on peut éteindre puis rallumer une interface :

```
interface GigabitEthernet0/1
 shutdown
```

Attendez quelques secondes, puis :

```
 no shutdown
exit
```

**Messages attendus sur la console de R1 :**

```
000003: *Apr  4 11:35:12.345: %LINK-5-CHANGED: Interface GigabitEthernet0/1, changed state to administratively down
000004: *Apr  4 11:35:13.345: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
000005: *Apr  4 11:35:22.456: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to up
000006: *Apr  4 11:35:23.456: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
```

Décortiquons le format d'un message Syslog Cisco :

```
000003: *Apr  4 11:35:12.345: %LINK-5-CHANGED: Interface GigabitEthernet0/1...
│       │                      │    │ │
│       │                      │    │ └── Mnémonique (nom de l'événement)
│       │                      │    └──── Niveau de sévérité (5 = Notification)
│       │                      └───────── Facility (catégorie du message)
│       └──────────────────────────────── Timestamp (grâce à service timestamps)
└──────────────────────────────────────── Numéro de séquence (grâce à service sequence-numbers)
```

### Étape 5.7 — Vérifier les logs sur le serveur

Sur **NTP-SYSLOG-SRV** dans Packet Tracer :
1. Onglet **Services > Syslog**
2. Les messages envoyés par R1 devraient apparaître dans la liste

### Étape 5.8 — Vérifier le buffer local

Sur **R1** :

```
show logging
```

**Output attendu :**

```
R1#show logging
Syslog logging: enabled (0 messages dropped, 0 messages rate-limited,
                0 flushes, 0 overruns, xml disabled, filtering disabled)

No Active Message Discriminator.

No Inactive Message Discriminator.

    Console logging: level warnings, 2 messages logged, xml disabled,
                     filtering disabled
    Monitor logging: level debugging, 0 messages logged, xml disabled,
                     filtering disabled
    Buffer logging:  level informational, 6 messages logged, xml disabled,
                     filtering disabled
    Logging Exception size (4096 bytes)
    Count and timestamp logging messages: disabled
    Persistent logging: disabled

    Trap logging: level informational, 6 message lines logged
        Logging to 192.168.1.100  (udp port 514, audit disabled,
              link up),
              6 message lines logged,
              0 message lines rate-limited,
              0 message lines dropped-by-MD,
              xml disabled, sequence number disabled
              filtering disabled

Log Buffer (16384 bytes):

000001: *Apr  4 11:30:01.234: %SYS-5-CONFIG_I: Configured from console by console
000002: *Apr  4 11:32:15.567: %SYS-5-CONFIG_I: Configured from console by console
000003: *Apr  4 11:35:12.345: %LINK-5-CHANGED: Interface GigabitEthernet0/1, changed state to administratively down
000004: *Apr  4 11:35:13.345: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to down
000005: *Apr  4 11:35:22.456: %LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to up
000006: *Apr  4 11:35:23.456: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/1, changed state to up
```

---

## Partie 6 : Vérification globale

### Étape 6.1 — Tableau récapitulatif des commandes de vérification

| Service | Commande | Ce qu'elle vérifie |
|---------|----------|-------------------|
| DHCP | `show ip dhcp pool` | Configuration des pools, adresses disponibles |
| DHCP | `show ip dhcp binding` | Baux actifs (qui a quelle adresse) |
| DHCP | `show ip dhcp server statistics` | Compteurs DORA (Discover, Offer, Request, Ack) |
| DHCP relay | `show ip interface Gi0/1` | Vérifie que `helper-address` est configuré |
| NTP | `show ntp status` | État de synchronisation, stratum |
| NTP | `show ntp associations` | Serveurs NTP configurés et leur état |
| NTP | `show clock` | Heure actuelle du routeur |
| Syslog | `show logging` | Configuration des destinations et niveaux, buffer |

### Étape 6.2 — Vérification DHCP relay

```
show ip interface GigabitEthernet0/1
```

Cherchez la ligne "Helper address" dans la sortie :

```
  Helper address is 192.168.1.1
```

### Étape 6.3 — Vérification des statistiques DHCP

```
show ip dhcp server statistics
```

**Output attendu :**

```
R1#show ip dhcp server statistics
Memory usage         25308
Address pools        2
Database agents      0
Automatic bindings   4
Manual bindings      0
Expired bindings     0
Malformed messages   0
Secure arp entries   0

Message              Received
BOOTREQUEST          0
DHCPDISCOVER         4
DHCPREQUEST          4
DHCPINFORM           0
DHCPRELEASE          0
DHCPDECLINE          0

Message              Sent
BOOTREPLY            0
DHCPOFFER            4
DHCPACK              4
DHCPNAK              0
```

Les compteurs montrent le processus DORA complet : 4 Discover reçus, 4 Offer envoyés, 4 Request reçus, 4 ACK envoyés (un par PC).

---

## Vérification finale

Cochez chaque critère pour valider la réussite du lab :

- [ ] Les trois PCs du LAN 1 ont obtenu une adresse DHCP dans la plage 192.168.1.50-.99
- [ ] PC4 sur le LAN 2 a obtenu une adresse DHCP dans la plage 192.168.2.50-.99
- [ ] `show ip dhcp binding` affiche 4 baux actifs (3 sur LAN-POOL, 1 sur LAN2-POOL)
- [ ] Les PCs ont reçu la passerelle (192.168.1.1 ou 192.168.2.1), le DNS (8.8.8.8) et le domaine (lab.local)
- [ ] `show ntp status` sur R1 indique "Clock is synchronized" avec stratum 2
- [ ] `show clock` sur R1 affiche la date et l'heure correctes
- [ ] `show logging` sur R1 montre l'envoi vers 192.168.1.100, niveau trap = informational
- [ ] Les messages de log apparaissent sur le serveur Syslog dans Packet Tracer
- [ ] Vous savez réciter les 8 niveaux Syslog dans l'ordre

---

## Questions de réflexion

### Question 1 — Pourquoi faut-il configurer `ip helper-address` sur l'interface côté client et non côté serveur ?

<details>
<summary>Voir la réponse</summary>

Parce que le broadcast DHCP Discover envoyé par le client arrive sur l'interface du routeur connectée au même réseau que le client. C'est sur cette interface que le routeur doit intercepter le broadcast et le convertir en unicast vers le serveur DHCP. Si on le mettait côté serveur, le broadcast n'atteindrait jamais le routeur (les broadcasts ne traversent pas les routeurs) et la commande serait inutile.

Retenez : `ip helper-address` = "intercepter les broadcasts qui arrivent sur CETTE interface et les envoyer en unicast vers le serveur DHCP".

</details>

### Question 2 — Un PC obtient l'adresse 192.168.1.1 via DHCP et provoque un conflit d'adresses. Quelle est la cause et comment la corriger ?

<details>
<summary>Voir la réponse</summary>

La cause est l'absence ou la mauvaise configuration des exclusions DHCP. L'adresse 192.168.1.1 (celle du routeur) n'a pas été exclue du pool avec `ip dhcp excluded-address`.

Correction :
```
ip dhcp excluded-address 192.168.1.1 192.168.1.49
clear ip dhcp binding *
```

La commande `clear ip dhcp binding *` force la libération de tous les baux, obligeant les clients à renouveler et obtenir une adresse dans la plage autorisée. Alternativement, on peut cibler un seul bail avec `clear ip dhcp binding 192.168.1.1`.

</details>

### Question 3 — R1 affiche `show ntp status` avec "Clock is unsynchronized, stratum 16". Quelles sont les causes possibles ?

<details>
<summary>Voir la réponse</summary>

Stratum 16 signifie "non synchronisé". Causes possibles :

1. **Le serveur NTP est injoignable** : vérifiez avec `ping 192.168.1.100`. Si le ping échoue, c'est un problème de connectivité réseau (interface down, mauvaise adresse IP, etc.).

2. **La commande `ntp server` est mal configurée** : vérifiez avec `show running-config | include ntp`. L'adresse doit correspondre exactement au serveur.

3. **Le service NTP n'est pas activé sur le serveur** : dans Packet Tracer, vérifiez que NTP est bien sur "ON" dans l'onglet Services du serveur.

4. **Pas assez de temps écoulé** : NTP peut prendre jusqu'à 5 minutes pour se synchroniser initialement. Attendez et revérifiez.

5. **Le serveur NTP lui-même n'est pas synchronisé** : un serveur NTP dont le stratum est 16 ne peut pas synchroniser ses clients.

</details>

### Question 4 — Quelle est la différence entre `logging console`, `logging monitor`, `logging buffered` et `logging trap` ?

<details>
<summary>Voir la réponse</summary>

Ces quatre commandes contrôlent vers quelle destination les logs sont envoyés, et à quel niveau de sévérité :

| Commande | Destination | Notes |
|----------|-------------|-------|
| `logging console` | Port console physique | Visible uniquement si connecté par câble console. Peut ralentir le routeur si trop verbeux |
| `logging monitor` | Sessions VTY (Telnet/SSH) | Nécessite aussi `terminal monitor` dans la session |
| `logging buffered` | Mémoire RAM locale | Consultable avec `show logging`. Taille configurable en octets |
| `logging trap` | Serveur Syslog externe (via `logging host`) | Envoi en UDP port 514. Le plus important pour la centralisation |

Chaque destination peut avoir un niveau de sévérité différent. Exemple : on peut mettre `logging console warnings` (niveaux 0-4 seulement sur la console) et `logging trap informational` (niveaux 0-6 vers le serveur Syslog).

</details>

### Question 5 — Pourquoi est-il critique d'avoir NTP configuré avant de configurer Syslog ?

<details>
<summary>Voir la réponse</summary>

Sans NTP, les timestamps dans les logs sont incorrects (le routeur démarre avec une horloge en 1993). Quand vous enquêtez sur un incident de sécurité, vous avez besoin de savoir exactement **quand** chaque événement s'est produit pour reconstituer la chronologie. Si chaque équipement a une horloge différente, il est impossible de corréler les logs entre un routeur, un switch et un pare-feu.

Par exemple, si un routeur indique une intrusion à 10:30 mais que le switch indique l'événement réseau correspondant à 02:15 (parce que son horloge n'était pas synchronisée), l'investigation devient un cauchemar.

C'est pour cela que la bonne pratique est : **d'abord NTP, ensuite Syslog**. Les timestamps n'ont de valeur que s'ils sont précis et cohérents sur tous les équipements.

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

! --- Interfaces ---
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
 description LAN principal
exit

interface GigabitEthernet0/1
 ip address 192.168.2.1 255.255.255.0
 ip helper-address 192.168.1.1
 no shutdown
 description LAN secondaire
exit

! --- DHCP Exclusions ---
ip dhcp excluded-address 192.168.1.1 192.168.1.49
ip dhcp excluded-address 192.168.1.100 192.168.1.110
ip dhcp excluded-address 192.168.2.1 192.168.2.49
ip dhcp excluded-address 192.168.2.100 192.168.2.110

! --- Pool DHCP LAN 1 ---
ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8
 domain-name lab.local
 lease 2
exit

! --- Pool DHCP LAN 2 ---
ip dhcp pool LAN2-POOL
 network 192.168.2.0 255.255.255.0
 default-router 192.168.2.1
 dns-server 8.8.8.8
 domain-name lab.local
 lease 2
exit

! --- NTP ---
ntp server 192.168.1.100
clock timezone CET 1
clock summer-time CEST recurring

! --- Syslog ---
service timestamps log datetime msec
service timestamps debug datetime msec
service sequence-numbers
logging host 192.168.1.100
logging trap informational
logging console warnings
logging buffered 16384 informational

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

interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1

! --- NTP ---
ntp server 192.168.1.100
clock timezone CET 1
clock summer-time CEST recurring

end
write memory
```

</details>

<details>
<summary>Voir la solution complète de SW2</summary>

```
enable
configure terminal

hostname SW2
no ip domain-lookup

interface vlan 1
 ip address 192.168.2.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.2.1

end
write memory
```

</details>
