# LAB 5.2 — Port Security, DHCP Snooping et Dynamic ARP Inspection

| Info | Valeur |
|------|--------|
| **Module** | 5 — Security Fundamentals |
| **Topics couverts** | 5.7 — Describe the need for Layer 2 security (DHCP snooping, DAI, port security) |
| **Difficulté** | Intermédiaire |
| **Durée estimée** | 40 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                    ┌────────────┐
                    │     R1     │
                    │ DHCP Server│
                    │ 192.168.1.1│
                    └─────┬──────┘
                          │ Gi0/0
                          │
                          │ Gi0/1 (Trunk)
                   ┌──────┴──────┐
                   │    SW1      │
                   │  (Switch)   │
                   └┬───┬───┬───┬┘
                    │   │   │   │
                 Fa0/1 Fa0/2 Fa0/3 Fa0/4
                    │   │   │   │
                  PC1  PC2  PC3  PC4
                 DHCP DHCP DHCP  Attaquant
                                192.168.1.50
                                (statique)

                    192.168.1.0/24
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle | Mode |
|----------|-----------|------------|--------|------------|------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — | Serveur DHCP + Gateway |
| SW1 | VLAN 1 | 192.168.1.2 | 255.255.255.0 | 192.168.1.1 | Management |
| PC1 | NIC (Fa0/1) | DHCP | — | DHCP | Légitime |
| PC2 | NIC (Fa0/2) | DHCP | — | DHCP | Légitime |
| PC3 | NIC (Fa0/3) | DHCP | — | DHCP | Légitime |
| PC4 | NIC (Fa0/4) | 192.168.1.50 | 255.255.255.0 | 192.168.1.1 | Attaquant simulé |

**Pool DHCP :** 192.168.1.100 — 192.168.1.200 (passerelle 192.168.1.1, DNS 8.8.8.8)

---

## Objectifs

1. Configurer un serveur DHCP sur R1 et vérifier le fonctionnement normal
2. Configurer Port Security avec apprentissage sticky et les trois modes de violation
3. Simuler une violation de port security et observer les différentes réactions
4. Configurer DHCP Snooping pour protéger contre les faux serveurs DHCP
5. Configurer Dynamic ARP Inspection (DAI) pour prévenir l'ARP spoofing
6. Vérifier l'ensemble avec les commandes `show` appropriées

---

## Prérequis

- Configuration de base d'un switch Cisco (hostname, VLAN)
- Compréhension du protocole DHCP (DORA : Discover, Offer, Request, Ack)
- Compréhension du protocole ARP
- Notions de sécurité réseau couche 2 (MAC flooding, rogue DHCP, ARP spoofing)

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
 description Lien vers SW1
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
line console 0
 logging synchronous
exit

interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1

end
write memory
```

### PC4 — Configuration manuelle

Configurez **PC4** avec une adresse IP statique :
- IP : 192.168.1.50
- Masque : 255.255.255.0
- Passerelle : 192.168.1.1

Les PCs 1 à 3 restent en mode DHCP pour l'instant (ils ne recevront leur adresse qu'après la configuration du serveur DHCP).

---

## Partie 1 : Configuration DHCP sur R1 et fonctionnement normal

Avant de sécuriser quoi que ce soit, on met en place le service DHCP sur R1 et on vérifie que les PCs reçoivent bien leur adresse automatiquement.

### Étape 1.1 — Configurer le pool DHCP sur R1

Sur **R1** :

```
configure terminal

ip dhcp excluded-address 192.168.1.1 192.168.1.99

ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8
 lease 1
exit
```

Décortiquons :
- `ip dhcp excluded-address 192.168.1.1 192.168.1.99` : on exclut les adresses .1 à .99 du pool pour éviter les conflits avec les équipements à IP statique (R1, SW1, et potentiellement d'autres).
- `network` : le réseau à servir.
- `default-router` : la passerelle par défaut que les clients recevront.
- `dns-server` : le serveur DNS communiqué aux clients.
- `lease 1` : durée du bail en jours.

### Étape 1.2 — Renouveler les adresses DHCP sur les PCs

Sur **PC1**, **PC2** et **PC3**, allez dans Desktop > IP Configuration, cochez "DHCP" et attendez que l'adresse soit attribuée.

Vous pouvez aussi utiliser le Command Prompt :

```
ipconfig /renew
```

### Étape 1.3 — Vérifier les baux DHCP sur R1

Sur **R1** :

```
show ip dhcp binding
```

**Output attendu :**

```
R1#show ip dhcp binding
IP address       Client-ID/              Lease expiration        Type
                 Hardware address
192.168.1.100    0001.4234.A1B2           Apr 05 2026 10:30 AM   Automatic
192.168.1.101    0001.4234.C3D4           Apr 05 2026 10:30 AM   Automatic
192.168.1.102    0001.4234.E5F6           Apr 05 2026 10:31 AM   Automatic
```

### Étape 1.4 — Vérifier la connectivité

Depuis **PC1** :

```
ping 192.168.1.1
```

**Résultat attendu :** le ping réussit. Le DHCP fonctionne correctement, les PCs ont leur adresse, passerelle et DNS.

---

## Partie 2 : Port Security — Configuration sticky et modes de violation

Le Port Security est la première ligne de défense au niveau couche 2. Il limite le nombre d'adresses MAC autorisées sur un port du switch et définit quoi faire en cas de violation.

### Rappel théorique : les 3 modes de violation

| Mode | Trafic | Compteur | Log/SNMP | Port |
|------|--------|----------|----------|------|
| **shutdown** | Bloqué | Oui | Oui | Passe en err-disabled |
| **restrict** | Bloqué (MAC non autorisée) | Oui | Oui | Reste up |
| **protect** | Bloqué silencieusement | Non | Non | Reste up |

> **Point exam :** la différence entre `restrict` et `protect` est subtile mais importante. Les deux bloquent les trames de l'adresse MAC non autorisée, mais `restrict` incrémente le compteur de violations et génère des logs, tandis que `protect` bloque silencieusement sans aucune trace. En production, `shutdown` est le mode le plus courant car il force une intervention humaine.

### Étape 2.1 — Configurer Port Security sur Fa0/1 (mode shutdown)

Sur **SW1** :

```
configure terminal

interface FastEthernet0/1
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown
exit
```

Décortiquons :
- `switchport mode access` : **obligatoire** avant d'activer le port-security. Le port-security ne fonctionne pas sur les ports en mode dynamic (auto/desirable).
- `switchport port-security` : active la fonctionnalité.
- `maximum 1` : un seul MAC autorisé sur ce port.
- `mac-address sticky` : le switch apprend automatiquement la première adresse MAC qu'il voit et la "colle" dans la running-config. Pas besoin de la taper manuellement.
- `violation shutdown` : si une deuxième MAC est détectée, le port passe en err-disabled (éteint).

### Étape 2.2 — Configurer Port Security sur Fa0/2 (mode restrict)

```
interface FastEthernet0/2
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation restrict
exit
```

### Étape 2.3 — Configurer Port Security sur Fa0/3 (mode protect)

```
interface FastEthernet0/3
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation protect
exit
```

### Étape 2.4 — Configurer Fa0/4 en mode access (pour l'attaquant)

```
interface FastEthernet0/4
 switchport mode access
exit
```

On ne met pas de port-security sur Fa0/4 pour l'instant (on l'ajoutera plus tard si besoin).

### Étape 2.5 — Générer du trafic pour apprendre les MACs

Depuis chaque PC (PC1, PC2, PC3), lancez un ping vers R1 pour que le switch apprenne les adresses MAC :

```
ping 192.168.1.1
```

### Étape 2.6 — Vérifier les adresses MAC apprises

Sur **SW1** :

```
show port-security
```

**Output attendu :**

```
SW1#show port-security
Secure Port  MaxSecureAddr  CurrentAddr  SecurityViolation  Security Action
-----------  -------------  -----------  -----------------  ---------------
      Fa0/1              1            1                  0         Shutdown
      Fa0/2              1            1                  0         Restrict
      Fa0/3              1            1                  0         Protect
-----------  -------------  -----------  -----------------  ---------------
Total Addresses in System (excluding one mac per port)     : 0
Max Addresses limit in System (excluding one mac per port) : 1024
```

Pour voir les MAC apprises en détail :

```
show port-security address
```

**Output attendu :**

```
SW1#show port-security address
               Secure Mac Address Table
---------------------------------------------------------------------------
Vlan    Mac Address       Type                Ports   Remaining Age (mins)
----    -----------       ----                -----   --------------------
   1    0001.4234.A1B2    SecureSticky        Fa0/1        -
   1    0001.4234.C3D4    SecureSticky        Fa0/2        -
   1    0001.4234.E5F6    SecureSticky        Fa0/3        -
---------------------------------------------------------------------------
Total Addresses in System (excluding one mac per port)     : 0
Max Addresses limit in System (excluding one mac per port) : 1024
```

Le type `SecureSticky` confirme que les adresses ont été apprises automatiquement et sauvegardées dans la configuration.

### Étape 2.7 — Vérifier dans la running-config

```
show running-config interface FastEthernet0/1
```

**Output attendu :**

```
SW1#show running-config interface FastEthernet0/1
Building configuration...

Current configuration : 227 bytes
!
interface FastEthernet0/1
 switchport mode access
 switchport port-security
 switchport port-security mac-address sticky
 switchport port-security mac-address sticky 0001.4234.A1B2
!
end
```

> **C'est l'avantage du sticky :** la MAC est écrite directement dans la configuration. Après un `write memory`, elle survivra à un redémarrage du switch. Sans sticky, il faudrait soit configurer la MAC manuellement, soit la réapprendre à chaque boot.

---

## Partie 3 : Simuler une violation de Port Security

### Étape 3.1 — Simuler une violation sur Fa0/1 (mode shutdown)

Pour simuler une violation, on peut changer l'adresse MAC de PC1 dans Packet Tracer :

1. Cliquez sur **PC1** > Config > FastEthernet0 > changez l'adresse MAC (par exemple : `00AA.BB11.2233`)
2. Lancez un ping depuis PC1 :

```
ping 192.168.1.1
```

**Résultat attendu :** le port Fa0/1 passe en **err-disabled**. Le lien est coupé. Plus aucun trafic ne passe.

Sur **SW1** :

```
show port-security interface FastEthernet0/1
```

**Output attendu :**

```
SW1#show port-security interface FastEthernet0/1
Port Security              : Enabled
Port Status                : Secure-shutdown
Violation Mode             : Shutdown
Aging Time                 : 0 mins
Aging Type                 : Absolute
SecureStatic Address Aging : Disabled
Maximum MAC Addresses      : 1
Total MAC Addresses        : 1
Configured MAC Addresses   : 0
Sticky MAC Addresses       : 1
Last Source Address:Vlan   : 00AA.BB11.2233:1
Security Violation Count   : 1
```

Le statut `Secure-shutdown` confirme que le port est en err-disabled.

Vérifiez l'état de l'interface :

```
show interfaces FastEthernet0/1 status
```

**Output attendu :**

```
Port      Name       Status       Vlan       Duplex  Speed Type
Fa0/1                err-disabled 1          auto    auto  10/100BaseTX
```

### Étape 3.2 — Restaurer le port après une violation shutdown

Pour récupérer un port en err-disabled, il faut le shut/no shut manuellement (après avoir corrigé le problème) :

1. Remettez d'abord la MAC d'origine sur PC1 (revenez à la MAC originale dans les paramètres de PC1)
2. Sur **SW1** :

```
configure terminal
interface FastEthernet0/1
 shutdown
 no shutdown
exit
```

> **Point exam :** un port en err-disabled ne se rétablit **jamais** automatiquement par défaut. Il faut une intervention manuelle (shutdown puis no shutdown). On peut activer la récupération automatique avec `errdisable recovery cause psecure-violation` et `errdisable recovery interval 300` (300 secondes), mais ce n'est pas la pratique recommandée en production.

### Étape 3.3 — Observer le comportement en mode restrict (Fa0/2)

Changez la MAC de PC2 de la même manière et lancez un ping. Le port reste **up**, mais les trames de la nouvelle MAC sont bloquées et le compteur de violations s'incrémente.

```
show port-security interface FastEthernet0/2
```

**Output attendu :**

```
SW1#show port-security interface FastEthernet0/2
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Restrict
...
Security Violation Count   : 3
```

Le port est toujours `Secure-up`, mais les violations sont comptabilisées.

### Étape 3.4 — Observer le comportement en mode protect (Fa0/3)

Même manipulation sur PC3. Le port reste **up**, les trames sont bloquées silencieusement, mais le compteur de violations reste a **0**.

```
show port-security interface FastEthernet0/3
```

**Output attendu :**

```
SW1#show port-security interface FastEthernet0/3
Port Security              : Enabled
Port Status                : Secure-up
Violation Mode             : Protect
...
Security Violation Count   : 0
```

> **Attention piège exam :** en mode `protect`, le trafic est bien bloqué mais aucune notification n'est générée. C'est problématique en production car on ne sait pas qu'une attaque a lieu. C'est pourquoi `shutdown` est le mode le plus utilisé.

### Étape 3.5 — Remettre les MACs d'origine

Restaurez les adresses MAC originales sur tous les PCs avant de passer à la suite. Faites un `shutdown` / `no shutdown` sur les ports si nécessaire.

---

## Partie 4 : DHCP Snooping — Protection contre les faux serveurs DHCP

Le DHCP Snooping protège contre les attaques de type "rogue DHCP server" : un attaquant connecte un faux serveur DHCP au réseau pour distribuer de fausses passerelles ou de faux DNS, interceptant ainsi le trafic des victimes (attaque man-in-the-middle).

### Rappel théorique

Le DHCP Snooping classe les ports en deux catégories :
- **Trusted (fiable)** : port autorisé à envoyer des messages DHCP server (Offer, Ack). Typiquement le port vers le vrai serveur DHCP.
- **Untrusted (non fiable)** : port qui ne peut envoyer que des messages DHCP client (Discover, Request). Tout message server provenant d'un port untrusted est bloqué.

### Étape 4.1 — Activer DHCP Snooping sur SW1

Sur **SW1** :

```
configure terminal

ip dhcp snooping
ip dhcp snooping vlan 1
no ip dhcp snooping information option
```

> **Pourquoi `no ip dhcp snooping information option` ?** Par défaut, quand le DHCP snooping est activé, le switch ajoute l'option 82 (relay agent information) aux paquets DHCP. Si le serveur DHCP (ici R1) ne supporte pas l'option 82, il rejette les requêtes. En désactivant cette option, on évite ce problème dans un environnement de lab simple.

### Étape 4.2 — Configurer le port trusted

Le port Gi0/1 vers R1 (le vrai serveur DHCP) doit être trusted :

```
interface GigabitEthernet0/1
 ip dhcp snooping trust
exit
```

> **Tous les autres ports sont untrusted par défaut.** On n'a pas besoin de configurer explicitement `no ip dhcp snooping trust` sur les ports access — c'est le comportement par défaut.

### Étape 4.3 — Vérifier la configuration DHCP Snooping

```
show ip dhcp snooping
```

**Output attendu :**

```
SW1#show ip dhcp snooping
Switch DHCP snooping is enabled
DHCP snooping is configured on following VLANs:
1
Insertion of option 82 is disabled
Interface                  Trusted     Rate limit (pps)
-----------------------    -------     ----------------
GigabitEthernet0/1         yes         unlimited
FastEthernet0/1            no          unlimited
FastEthernet0/2            no          unlimited
FastEthernet0/3            no          unlimited
FastEthernet0/4            no          unlimited
```

### Étape 4.4 — Renouveler les adresses DHCP des PCs

Comme le DHCP snooping vient d'être activé, les PCs doivent refaire un cycle DHCP pour que le switch enregistre leurs bindings :

Sur **PC1**, **PC2** et **PC3** :

```
ipconfig /release
ipconfig /renew
```

### Étape 4.5 — Vérifier la table de binding DHCP Snooping

```
show ip dhcp snooping binding
```

**Output attendu :**

```
SW1#show ip dhcp snooping binding
MacAddress          IpAddress        Lease(sec)  Type           VLAN  Interface
------------------  ---------------  ----------  -------------  ----  -----------------
00:01:42:34:A1:B2   192.168.1.100    86400       dhcp-snooping  1     FastEthernet0/1
00:01:42:34:C3:D4   192.168.1.101    86400       dhcp-snooping  1     FastEthernet0/2
00:01:42:34:E5:F6   192.168.1.102    86400       dhcp-snooping  1     FastEthernet0/3
```

Cette table associe chaque adresse MAC à son IP, son VLAN et son port physique. C'est cette table qui servira de base à DAI (Dynamic ARP Inspection) dans la partie suivante.

### Étape 4.6 — Simuler un rogue DHCP server sur PC4

PC4 est connecté sur Fa0/4 (untrusted). Si un attaquant lançait un serveur DHCP sur PC4, les messages DHCP Offer envoyés depuis ce port seraient automatiquement bloqués par le switch.

> **Note Packet Tracer :** Il est difficile de simuler un vrai serveur DHCP rogue dans Packet Tracer. L'idée est de comprendre le mécanisme : tout message DHCP de type server (Offer ou Ack) arrivant sur un port untrusted est supprimé. Vous pouvez observer ce comportement en regardant les compteurs de rejet dans les logs du switch.

Pour vérifier que le snooping bloque bien les messages non autorisés :

```
show ip dhcp snooping statistics
```

> **Dans un réseau réel**, cette protection est critique. Sans DHCP snooping, un attaquant peut distribuer de fausses passerelles et intercepter tout le trafic du réseau (man-in-the-middle).

---

## Partie 5 : Dynamic ARP Inspection (DAI)

DAI protège contre les attaques d'ARP spoofing (empoisonnement du cache ARP). Un attaquant envoie de fausses réponses ARP pour associer son adresse MAC à l'IP de la passerelle, et intercepte ainsi le trafic.

DAI s'appuie sur la table de binding DHCP Snooping pour valider les paquets ARP : si un paquet ARP contient une association MAC-IP qui n'est pas dans la table DHCP snooping, il est bloqué.

### Étape 5.1 — Activer DAI sur le VLAN 1

Sur **SW1** :

```
configure terminal
ip arp inspection vlan 1
```

### Étape 5.2 — Configurer le port trusted pour DAI

Le port vers R1 doit aussi être trusted pour DAI, sinon les ARP de R1 (qui a une IP statique et n'est pas dans la table DHCP snooping) seraient bloqués :

```
interface GigabitEthernet0/1
 ip arp inspection trust
exit
```

### Étape 5.3 — Comprendre pourquoi PC4 sera bloqué

PC4 a une IP statique (192.168.1.50) et n'a pas obtenu son adresse via DHCP. Son association MAC-IP n'apparaît donc **pas** dans la table DHCP snooping. Quand PC4 enverra un paquet ARP, DAI le comparera à la table de binding, ne trouvera aucune correspondance, et **bloquera** le paquet.

Depuis **PC4** :

```
ping 192.168.1.1
```

**Résultat attendu :** le ping **échoue**. Les paquets ARP de PC4 sont rejetés par DAI car son IP statique n'a pas de binding DHCP correspondant.

> **Question naturelle :** "Et si j'ai des équipements légitimes avec des IP statiques ?" Dans ce cas, on crée des ARP ACLs (Access Control Lists pour ARP) qui autorisent explicitement ces associations MAC-IP. Mais cela sort du cadre de ce lab.

### Étape 5.4 — Vérifier DAI

```
show ip arp inspection
```

**Output attendu :**

```
SW1#show ip arp inspection

Source Mac Validation      : Disabled
Destination Mac Validation : Disabled
IP Address Validation      : Disabled

 Vlan     Configuration    Operation   ACL Match          Static ACL
 ----     -------------    ---------   ---------          ----------
    1     Enabled          Active

 Vlan     ACL Logging      DHCP Logging      Probe Logging
 ----     -----------      ------------      -------------
    1     Deny             Deny              Off

 Vlan      Forwarded        Dropped     DHCP Drops      ACL Drops
 ----      ---------        -------     ----------      ---------
    1              8              3              3              0
```

La colonne `Dropped` montre les paquets ARP qui ont été rejetés (ceux de PC4).

Pour voir les détails des paquets ARP :

```
show ip arp inspection statistics
```

---

## Partie 6 : Vérification complète et récapitulatif

### Étape 6.1 — Commandes de vérification Port Security

| Commande | Ce qu'elle montre |
|----------|-------------------|
| `show port-security` | Résumé de tous les ports sécurisés (max, current, violations) |
| `show port-security interface Fa0/1` | Détails d'un port spécifique (mode, status, MACs, violations) |
| `show port-security address` | Table des adresses MAC sécurisées (type, port, VLAN) |

### Étape 6.2 — Commandes de vérification DHCP Snooping

| Commande | Ce qu'elle montre |
|----------|-------------------|
| `show ip dhcp snooping` | Configuration globale (VLANs, ports trusted/untrusted) |
| `show ip dhcp snooping binding` | Table de binding (MAC ↔ IP ↔ Port ↔ VLAN) |
| `show ip dhcp snooping statistics` | Compteurs de paquets traités/rejetés |

### Étape 6.3 — Commandes de vérification DAI

| Commande | Ce qu'elle montre |
|----------|-------------------|
| `show ip arp inspection` | Configuration et compteurs par VLAN |
| `show ip arp inspection statistics` | Statistiques détaillées (forwarded/dropped) |
| `show ip arp inspection interfaces` | État trust/untrust de chaque interface |

### Étape 6.4 — Récapitulatif des trois protections couche 2

| Mécanisme | Protège contre | S'appuie sur |
|-----------|---------------|--------------|
| **Port Security** | MAC flooding, accès physique non autorisé | Table CAM (adresses MAC) |
| **DHCP Snooping** | Rogue DHCP server, DHCP starvation | Ports trusted/untrusted |
| **DAI** | ARP spoofing (man-in-the-middle) | Table DHCP Snooping binding |

> **Point exam :** ces trois mécanismes fonctionnent en cascade. Le DHCP snooping construit une table de binding que DAI utilise pour valider les ARP. C'est pour cela qu'il faut **toujours activer DHCP snooping avant DAI**.

---

## Vérification finale

Cochez chaque critère pour valider la réussite du lab :

- [ ] Le serveur DHCP sur R1 distribue correctement les adresses aux PCs 1 à 3
- [ ] Port Security est actif avec sticky sur les ports Fa0/1 à Fa0/3
- [ ] Chaque port a un mode de violation différent (shutdown, restrict, protect)
- [ ] Une violation sur Fa0/1 met le port en err-disabled
- [ ] Une violation sur Fa0/2 bloque le trafic mais incrémente le compteur
- [ ] Une violation sur Fa0/3 bloque le trafic sans incrémenter le compteur
- [ ] DHCP Snooping est actif sur le VLAN 1 avec Gi0/1 comme port trusted
- [ ] La table de binding DHCP snooping contient les 3 PCs légitimes
- [ ] DAI est actif sur le VLAN 1 et bloque les ARP de PC4 (IP statique sans binding)
- [ ] Vous savez expliquer la différence entre les 3 modes de violation port-security

---

## Questions de réflexion

### Question 1 — Pourquoi le port-security ne fonctionne-t-il pas sur un port en mode `dynamic auto` ou `dynamic desirable` ?

<details>
<summary>Voir la réponse</summary>

Un port en mode dynamique peut négocier un trunk. Sur un trunk, plusieurs adresses MAC sont attendues (une par VLAN, potentiellement des centaines). Le port-security, qui limite le nombre de MAC autorisées, est incompatible avec cette nature dynamique. IOS exige que le port soit en mode `access` (ou `trunk` statique) avant d'activer le port-security, pour que la politique de sécurité soit prévisible et cohérente.

</details>

### Question 2 — Un PC légitime est déplacé d'un port à un autre sur le même switch. Que se passe-t-il avec le port-security en mode sticky ?

<details>
<summary>Voir la réponse</summary>

Deux problèmes surviennent simultanément :

1. **L'ancien port** conserve la MAC sticky dans sa config. Si un autre équipement est branché sur ce port avec une MAC différente, il sera bloqué.

2. **Le nouveau port** ne connaît pas la MAC du PC déplacé. Si ce port a aussi du sticky, il tentera d'apprendre la nouvelle MAC. Si une autre MAC est déjà sticky sur ce port, le PC sera bloqué.

Solution : sur l'ancien port, supprimer manuellement la MAC sticky (`no switchport port-security mac-address sticky xxxx.xxxx.xxxx`) et faire un `shutdown` / `no shutdown`. C'est le prix de la sécurité : tout déplacement physique nécessite une intervention administrative.

</details>

### Question 3 — Si on active DHCP Snooping mais qu'on oublie de configurer le port vers le vrai serveur DHCP en trusted, que se passe-t-il ?

<details>
<summary>Voir la réponse</summary>

Le vrai serveur DHCP sera traité comme un rogue DHCP. Ses messages DHCP Offer et Ack seront bloqués par le switch. Aucun PC ne pourra obtenir d'adresse IP via DHCP. Le réseau sera paralysé pour tous les clients DHCP. C'est une erreur de configuration fréquente qui peut provoquer une panne réseau majeure. La première chose à vérifier quand le DHCP ne fonctionne plus après avoir activé le snooping, c'est le port trusted.

</details>

### Question 4 — Pourquoi DAI ne peut-il pas fonctionner sans DHCP Snooping ?

<details>
<summary>Voir la réponse</summary>

DAI a besoin d'une base de référence pour savoir quelle association MAC-IP est légitime. Cette base de référence est la table de binding construite par DHCP Snooping. Quand un paquet ARP arrive, DAI regarde dans cette table : "est-ce que cette MAC est bien associée à cette IP ?". Sans la table, DAI n'aurait aucun moyen de distinguer un ARP légitime d'un ARP forgé.

Pour les équipements à IP statique (qui ne sont pas dans la table DHCP snooping), on peut créer des ARP ACLs manuelles, mais cela nécessite une configuration supplémentaire.

</details>

### Question 5 — En production, quel mode de violation port-security recommanderiez-vous et pourquoi ?

<details>
<summary>Voir la réponse</summary>

Le mode **shutdown** est recommandé en production pour plusieurs raisons :

1. **Visibilité :** le port passe en err-disabled, ce qui est immédiatement visible dans `show interfaces status`. Impossible de passer à côté.

2. **Action corrective :** l'intervention manuelle obligatoire (shutdown/no shutdown) force l'administrateur à investiguer la cause de la violation avant de restaurer le service.

3. **Sécurité :** le trafic est totalement coupé, il n'y a aucune fuite possible.

Le mode `restrict` peut être utile en phase de diagnostic (on veut voir les violations sans couper le service), et le mode `protect` est rarement utilisé car il bloque sans laisser de trace, rendant le dépannage très difficile.

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
 description Lien vers SW1
exit

! --- Serveur DHCP ---
ip dhcp excluded-address 192.168.1.1 192.168.1.99

ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 8.8.8.8
 lease 1
exit

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

! --- Trunk vers R1 ---
interface GigabitEthernet0/1
 switchport mode trunk
exit

! --- Port Security Fa0/1 : shutdown ---
interface FastEthernet0/1
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown
exit

! --- Port Security Fa0/2 : restrict ---
interface FastEthernet0/2
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation restrict
exit

! --- Port Security Fa0/3 : protect ---
interface FastEthernet0/3
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation protect
exit

! --- Port attaquant ---
interface FastEthernet0/4
 switchport mode access
exit

! --- DHCP Snooping ---
ip dhcp snooping
ip dhcp snooping vlan 1
no ip dhcp snooping information option

interface GigabitEthernet0/1
 ip dhcp snooping trust
exit

! --- Dynamic ARP Inspection ---
ip arp inspection vlan 1

interface GigabitEthernet0/1
 ip arp inspection trust
exit

end
write memory
```

</details>
