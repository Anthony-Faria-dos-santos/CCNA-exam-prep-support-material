# LAB 5.1 — ACL standard et extended : filtrage du trafic réseau

| Info | Valeur |
|------|--------|
| **Module** | 5 — Security Fundamentals |
| **Topics couverts** | 5.6 — Configure and verify access control lists |
| **Difficulté** | Intermédiaire |
| **Durée estimée** | 45 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
        LAN1                                              LAN2
   10.0.1.0/24                                       10.0.2.0/24
                                                    
  ┌────────┐                                       ┌────────────┐
  │  PC1   │                                       │  SRV-WEB   │
  │ .10    │                                       │  .100      │
  └───┬────┘                                       └─────┬──────┘
      │                                                  │
  ┌───┴────┐                                       ┌─────┴──────┐
  │  PC2   │                                       │  SRV-DNS   │
  │ .11    │                                       │  .200      │
  └───┬────┘                                       └─────┬──────┘
      │                                                  │
      │           Se0/0/0            Se0/0/0              │
      │ Gi0/0  ┌────────┐  .1  .2  ┌────────┐  Gi0/0    │
      ├────────┤   R1   ├──────────┤   R2   ├────────────┤
      │  .1    └────────┘          └────────┘  .1        │
      │         10.0.12.0/30                             │
      │                                            ┌─────┴──────┐
      │                                            │    PC3     │
      │                                            │    .10     │
      │                                            └────────────┘
```

---

## Tableau d'adressage

| Appareil | Interface | Adresse IP | Masque | Passerelle |
|----------|-----------|------------|--------|------------|
| R1 | Gi0/0 | 10.0.1.1 | 255.255.255.0 | — |
| R1 | Se0/0/0 | 10.0.12.1 | 255.255.255.252 | — |
| R2 | Se0/0/0 | 10.0.12.2 | 255.255.255.252 | — |
| R2 | Gi0/0 | 10.0.2.1 | 255.255.255.0 | — |
| PC1 | NIC | 10.0.1.10 | 255.255.255.0 | 10.0.1.1 |
| PC2 | NIC | 10.0.1.11 | 255.255.255.0 | 10.0.1.1 |
| SRV-WEB | NIC | 10.0.2.100 | 255.255.255.0 | 10.0.2.1 |
| SRV-DNS | NIC | 10.0.2.200 | 255.255.255.0 | 10.0.2.1 |
| PC3 | NIC | 10.0.2.10 | 255.255.255.0 | 10.0.2.1 |

---

## Objectifs

1. Mettre en place l'adressage IP et vérifier la connectivité complète sans aucune ACL
2. Configurer une ACL standard numérotée pour bloquer un hôte spécifique
3. Configurer une ACL standard nommée pour autoriser un hôte et bloquer un réseau entier
4. Configurer une ACL extended nommée pour filtrer par protocole et port
5. Vérifier et analyser les ACL avec les commandes `show` et comprendre les compteurs

---

## Prérequis

- Adressage IPv4 et sous-réseaux (masques, notation CIDR)
- Configuration de base d'un routeur Cisco (hostname, interfaces)
- Routage statique
- Compréhension du modèle TCP/IP (protocoles TCP, UDP, ICMP, numéros de ports)

---

## Configuration de départ

Copiez-collez ces configurations **avant de commencer le lab**. Elles mettent en place le hostname, le routage statique et désactivent la résolution DNS.

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
 ip address 10.0.1.1 255.255.255.0
 no shutdown
 description LAN1
exit

interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 clock rate 128000
 no shutdown
 description Lien vers R2
exit

ip route 10.0.2.0 255.255.255.0 10.0.12.2

end
write memory
```

### R2 — Configuration initiale

```
enable
configure terminal
hostname R2
no ip domain-lookup
line console 0
 logging synchronous
exit

interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
 description Lien vers R1
exit

interface GigabitEthernet0/0
 ip address 10.0.2.1 255.255.255.0
 no shutdown
 description LAN2
exit

ip route 10.0.1.0 255.255.255.0 10.0.12.1

end
write memory
```

### PCs et serveurs

Configurez manuellement via l'interface graphique de Packet Tracer :

- **PC1** : IP 10.0.1.10/24, passerelle 10.0.1.1
- **PC2** : IP 10.0.1.11/24, passerelle 10.0.1.1
- **SRV-WEB** : IP 10.0.2.100/24, passerelle 10.0.2.1 — activer le service **HTTP** (port 80) et **HTTPS** (port 443)
- **SRV-DNS** : IP 10.0.2.200/24, passerelle 10.0.2.1 — activer le service **DNS** (ajouter un enregistrement A : `www.lab.local` → `10.0.2.100`)
- **PC3** : IP 10.0.2.10/24, passerelle 10.0.2.1

---

## Partie 1 : Configuration de base et vérification de connectivité sans ACL

Avant de mettre en place la moindre ACL, on vérifie que tout le monde communique correctement. Une ACL mal placée sur un réseau qui ne fonctionne pas est un cauchemar à dépanner : on ne saurait pas si le problème vient du routage ou du filtrage.

### Étape 1.1 — Vérifier les interfaces de R1

Sur **R1** :

```
show ip interface brief
```

**Output attendu :**

```
R1#show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     10.0.1.1        YES manual up                    up
Serial0/0/0            10.0.12.1       YES manual up                    up
```

### Étape 1.2 — Vérifier les interfaces de R2

Sur **R2** :

```
show ip interface brief
```

**Output attendu :**

```
R2#show ip interface brief
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     10.0.2.1        YES manual up                    up
Serial0/0/0            10.0.12.2       YES manual up                    up
```

### Étape 1.3 — Vérifier les routes statiques

Sur **R1** :

```
show ip route static
```

**Output attendu :**

```
R1#show ip route static
      10.0.0.0/8 is variably subnetted, 4 subnets, 3 masks
S        10.0.2.0/24 [1/0] via 10.0.12.2
```

### Étape 1.4 — Tester la connectivité de bout en bout

Depuis **PC1**, pingez chaque destination :

```
ping 10.0.1.1
ping 10.0.12.2
ping 10.0.2.100
ping 10.0.2.200
ping 10.0.2.10
```

Depuis **PC2**, testez aussi :

```
ping 10.0.2.100
```

**Tous les pings doivent réussir.** Si un ping échoue, corrigez le routage ou l'adressage avant de continuer.

> **Bonne pratique :** Toujours établir un "baseline" de connectivité avant d'appliquer des ACL. Cela permet de distinguer un problème de filtrage d'un problème de routage.

### Étape 1.5 — Tester l'accès web

Depuis **PC1**, ouvrez le navigateur web (onglet Desktop > Web Browser) et tapez :

```
http://10.0.2.100
```

La page par défaut du serveur web doit s'afficher. Cela confirme que le service HTTP fonctionne.

---

## Partie 2 : ACL standard numérotée — Bloquer un hôte spécifique

On veut empêcher **PC2 (10.0.1.11)** d'accéder au réseau LAN2, tout en laissant PC1 et les autres hôtes communiquer normalement.

### Rappel théorique : les ACL standard

Une ACL standard filtre **uniquement sur l'adresse IP source**. Elle ne peut pas distinguer les protocoles ou les ports. Les ACL standard numérotées utilisent les numéros **1 à 99** (et 1300-1999 en plage étendue).

> **Règle de placement — Point exam :** une ACL standard doit être placée **le plus près possible de la destination**. Pourquoi ? Parce qu'elle ne filtre que la source, si on la place trop près de la source, on risque de bloquer le trafic vers des destinations qui ne devraient pas être affectées.

### Étape 2.1 — Créer l'ACL standard numérotée sur R2

Sur **R2** :

```
configure terminal

access-list 10 deny host 10.0.1.11
access-list 10 permit any
```

Décortiquons ces deux lignes :

- `access-list 10` : on crée (ou ajoute à) l'ACL numéro 10
- `deny host 10.0.1.11` : interdire tout trafic dont la source est exactement 10.0.1.11. Le mot-clé `host` équivaut au wildcard mask `0.0.0.0` (correspondance exacte)
- `permit any` : autoriser tout le reste. **Cette ligne est indispensable** car à la fin de toute ACL, il y a un `deny any` implicite (invisible). Sans le `permit any`, tout serait bloqué.

### Étape 2.2 — Appliquer l'ACL sur l'interface

Toujours sur **R2** :

```
interface GigabitEthernet0/0
 ip access-group 10 out
exit
```

> **Pourquoi `out` sur Gi0/0 de R2 ?** Le trafic de PC2 arrive sur R2 par Se0/0/0 (interface d'entrée) et sort par Gi0/0 (interface de sortie vers LAN2). En appliquant l'ACL en sortie (`out`) sur Gi0/0, on filtre le trafic juste avant qu'il n'atteigne le réseau de destination. C'est le placement "le plus près de la destination" recommandé pour les ACL standard.

### Étape 2.3 — Vérifier le filtrage

Depuis **PC2** :

```
ping 10.0.2.100
```

**Résultat attendu :** le ping **échoue** (Request timed out).

Depuis **PC1** :

```
ping 10.0.2.100
```

**Résultat attendu :** le ping **réussit** (Reply from 10.0.2.100).

### Étape 2.4 — Examiner l'ACL

Sur **R2** :

```
show access-lists
```

**Output attendu :**

```
R2#show access-lists
Standard IP access list 10
    10 deny host 10.0.1.11 (4 match(es))
    20 permit any (5 match(es))
```

Les numéros 10 et 20 sont les numéros de séquence attribués automatiquement par IOS. Les compteurs `match(es)` indiquent combien de paquets ont correspondu à chaque entrée.

Vérifiez aussi dans quelle direction l'ACL est appliquée :

```
show ip interface GigabitEthernet0/0
```

Cherchez les lignes `Outgoing access list` et `Inbound access list` dans la sortie.

**Output attendu (extrait pertinent) :**

```
  Outgoing access list is 10
  Inbound access list is not set
```

### Étape 2.5 — Nettoyer avant la partie suivante

Retirons l'ACL pour repartir de zéro :

```
configure terminal
interface GigabitEthernet0/0
 no ip access-group 10 out
exit
no access-list 10
end
```

> **Ordre important :** on retire d'abord l'ACL de l'interface (`no ip access-group`), puis on supprime l'ACL elle-même (`no access-list`). Si on supprime l'ACL en premier, pendant un bref instant l'interface référence une ACL vide qui bloquerait tout le trafic (rappel : deny implicite).

Vérifiez que le nettoyage est effectif :

```
show access-lists
```

La sortie doit être vide.

---

## Partie 3 : ACL standard nommée — Bloquer un réseau avec exception

Cette fois, on veut bloquer **tout le réseau 10.0.1.0/24** de l'accès à LAN2, **sauf PC1 (10.0.1.10)** qui doit pouvoir continuer à communiquer.

### Rappel théorique : ACL nommée vs numérotée

Les ACL nommées offrent plusieurs avantages :
- Un nom descriptif plutôt qu'un numéro (plus lisible)
- On peut supprimer ou insérer des entrées individuelles sans tout supprimer
- La syntaxe permet un mode de sous-configuration dédié

### Étape 3.1 — Créer l'ACL standard nommée sur R2

Sur **R2** :

```
configure terminal

ip access-list standard BLOCK-LAN1
 permit host 10.0.1.10
 deny 10.0.1.0 0.0.0.255
 permit any
exit
```

> **L'ordre des entrées est crucial.** L'IOS parcourt les ACL de haut en bas et s'arrête à la première correspondance. Si on inversait les deux premières lignes (deny 10.0.1.0/24 avant permit PC1), PC1 correspondrait au `deny` et serait bloqué avant même d'atteindre le `permit`. L'ACL est un "first match wins".

Décortiquons :
- `permit host 10.0.1.10` : on autorise explicitement PC1 en premier (exception à la règle de blocage)
- `deny 10.0.1.0 0.0.0.255` : on bloque tout le réseau 10.0.1.0/24. Le wildcard `0.0.0.255` signifie "les 3 premiers octets doivent correspondre, le dernier est libre"
- `permit any` : on autorise tout le reste (trafic local de LAN2, etc.)

### Étape 3.2 — Appliquer l'ACL

Sur **R2** :

```
interface GigabitEthernet0/0
 ip access-group BLOCK-LAN1 out
exit
```

Même logique de placement que précédemment : ACL standard, on la met le plus près de la destination.

### Étape 3.3 — Vérifier le filtrage

Depuis **PC1** :

```
ping 10.0.2.100
```

**Résultat attendu :** le ping **réussit** (PC1 est explicitement autorisé).

Depuis **PC2** :

```
ping 10.0.2.100
```

**Résultat attendu :** le ping **échoue** (PC2 fait partie de 10.0.1.0/24 et n'est pas dans l'exception).

### Étape 3.4 — Examiner l'ACL nommée

Sur **R2** :

```
show access-lists
```

**Output attendu :**

```
R2#show access-lists
Standard IP access list BLOCK-LAN1
    10 permit host 10.0.1.10 (5 match(es))
    20 deny 10.0.1.0 0.0.0.255 (4 match(es))
    30 permit any (8 match(es))
```

### Étape 3.5 — Modifier une ACL nommée (avantage des nommées)

Imaginons qu'on veuille aussi autoriser PC2. Avec une ACL nommée, on peut insérer une ligne sans tout supprimer :

```
configure terminal
ip access-list standard BLOCK-LAN1
 15 permit host 10.0.1.11
exit
```

Le numéro de séquence `15` place cette entrée entre la ligne 10 (permit PC1) et la ligne 20 (deny le réseau).

Vérifiez :

```
show access-lists
```

**Output attendu :**

```
R2#show access-lists
Standard IP access list BLOCK-LAN1
    10 permit host 10.0.1.10
    15 permit host 10.0.1.11
    20 deny 10.0.1.0 0.0.0.255
    30 permit any
```

> **C'est un des avantages majeurs des ACL nommées.** Avec une ACL numérotée, il aurait fallu la supprimer entièrement et la recréer.

### Étape 3.6 — Nettoyer avant la partie suivante

```
configure terminal
interface GigabitEthernet0/0
 no ip access-group BLOCK-LAN1 out
exit
no ip access-list standard BLOCK-LAN1
end
```

---

## Partie 4 : ACL extended nommée — Filtrage par protocole et port

Les ACL extended sont bien plus puissantes que les ACL standard : elles peuvent filtrer sur l'adresse source, l'adresse de destination, le protocole (TCP, UDP, ICMP...) et les numéros de port. C'est ce qu'on utilise dans le monde réel pour des politiques de sécurité granulaires.

On veut appliquer cette politique :
- **PC1 et PC2** peuvent accéder au web (HTTP port 80 et HTTPS port 443) sur SRV-WEB uniquement
- **PC1 et PC2** peuvent faire des requêtes DNS (UDP port 53) vers SRV-DNS
- **Tout autre trafic** depuis LAN1 est bloqué (pas de ping, pas de Telnet, rien d'autre)

> **Règle de placement — Point exam :** une ACL extended doit être placée **le plus près possible de la source**. Pourquoi ? Parce qu'elle peut filtrer finement (source, destination, protocole, port), on bloque le trafic indésirable avant qu'il ne traverse inutilement le réseau. Cela économise de la bande passante.

### Étape 4.1 — Créer l'ACL extended nommée sur R1

Sur **R1** (le plus près de la source, LAN1) :

```
configure terminal

ip access-list extended WEB-ONLY
 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 80
 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 443
 permit udp 10.0.1.0 0.0.0.255 host 10.0.2.200 eq 53
 deny ip 10.0.1.0 0.0.0.255 10.0.2.0 0.0.0.255
 permit ip any any
exit
```

Décortiquons chaque ligne :

- `permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 80` : autoriser tout hôte du réseau 10.0.1.0/24 à envoyer du trafic TCP vers 10.0.2.100 (SRV-WEB) sur le port 80 (HTTP). Le `eq` signifie "equal to" (port de destination exact).

- `permit tcp ... eq 443` : même chose pour HTTPS.

- `permit udp ... host 10.0.2.200 eq 53` : autoriser les requêtes DNS (UDP port 53) vers SRV-DNS.

- `deny ip 10.0.1.0 0.0.0.255 10.0.2.0 0.0.0.255` : bloquer tout autre trafic IP de LAN1 vers LAN2. Cela inclut ICMP (ping), Telnet, SSH, etc. Le mot-clé `ip` couvre tous les protocoles.

- `permit ip any any` : autoriser tout le reste. Sans cette ligne, le `deny any` implicite bloquerait aussi le trafic de gestion, le routage, etc. Cette ligne est importante pour ne pas casser la connectivité globale du routeur.

### Étape 4.2 — Appliquer l'ACL sur l'interface

Sur **R1** :

```
interface GigabitEthernet0/0
 ip access-group WEB-ONLY in
exit
```

> **Pourquoi `in` sur Gi0/0 de R1 ?** Le trafic de LAN1 entre dans le routeur R1 par Gi0/0. En appliquant l'ACL en entrée (`in`), on filtre le trafic dès qu'il entre dans R1, avant même que le routeur ne le traite. C'est le placement "le plus près de la source" recommandé pour les ACL extended.

### Étape 4.3 — Vérifier le filtrage HTTP/HTTPS

Depuis **PC1**, ouvrez le navigateur web et tapez :

```
http://10.0.2.100
```

**Résultat attendu :** la page web s'affiche correctement. Le trafic TCP port 80 est autorisé.

### Étape 4.4 — Vérifier le blocage du ping

Depuis **PC1** :

```
ping 10.0.2.100
```

**Résultat attendu :** le ping **échoue** (Request timed out). Le protocole ICMP n'est pas dans les `permit`, donc il tombe dans le `deny ip` vers LAN2.

### Étape 4.5 — Vérifier le DNS

Depuis **PC1**, configurez le serveur DNS comme 10.0.2.200 dans les paramètres réseau (Desktop > IP Configuration > DNS Server : 10.0.2.200).

Utilisez ensuite la commande dans le Command Prompt :

```
nslookup www.lab.local
```

**Résultat attendu :**

```
Server: 10.0.2.200
Address: 10.0.2.200

Name: www.lab.local
Address: 10.0.2.100
```

La résolution DNS fonctionne car UDP port 53 est autorisé.

### Étape 4.6 — Vérifier que le trafic local de LAN2 n'est pas affecté

Depuis **PC3** :

```
ping 10.0.2.100
ping 10.0.2.200
```

**Résultat attendu :** les deux pings **réussissent**. Le trafic interne à LAN2 n'entre pas par Gi0/0 de R1, il reste local sur le réseau de R2 et n'est pas concerné par l'ACL.

---

## Partie 5 : Vérification et analyse des compteurs

### Étape 5.1 — Examiner l'ACL extended avec ses compteurs

Sur **R1** :

```
show access-lists
```

**Output attendu :**

```
R1#show access-lists
Extended IP access list WEB-ONLY
    10 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq www (12 match(es))
    20 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 443
    30 permit udp 10.0.1.0 0.0.0.255 host 10.0.2.200 eq domain (2 match(es))
    40 deny ip 10.0.1.0 0.0.0.255 10.0.2.0 0.0.0.255 (4 match(es))
    50 permit ip any any (22 match(es))
```

> **Remarquez** que IOS remplace automatiquement le port 80 par `www` et le port 53 par `domain` dans l'affichage. Ce sont les noms de service standards. L'examen CCNA peut utiliser les deux formes.

### Étape 5.2 — Vérifier l'application sur l'interface

Sur **R1** :

```
show ip interface GigabitEthernet0/0
```

**Output attendu (extrait pertinent) :**

```
  Inbound access list is WEB-ONLY
  Outgoing access list is not set
```

### Étape 5.3 — Remettre à zéro les compteurs

Pour recommencer une analyse propre :

```
clear access-list counters
```

Puis lancez un test spécifique et revérifiez les compteurs pour confirmer quelle règle est matchée.

### Étape 5.4 — Récapitulatif des types d'ACL

| Caractéristique | ACL standard | ACL extended |
|----------------|--------------|--------------|
| **Filtre sur** | Adresse source uniquement | Source, destination, protocole, port |
| **Numéros** | 1-99, 1300-1999 | 100-199, 2000-2699 |
| **Placement** | Près de la destination | Près de la source |
| **Granularité** | Faible | Élevée |
| **Wildcard mask** | Oui | Oui |
| **Deny implicite** | Oui (fin de toute ACL) | Oui (fin de toute ACL) |

### Étape 5.5 — Rappel sur les wildcard masks

Les wildcard masks sont l'inverse des masques de sous-réseau. Voici les plus courants :

| Besoin | Wildcard mask | Signification |
|--------|---------------|---------------|
| Un seul hôte | `0.0.0.0` (ou mot-clé `host`) | Correspondance exacte des 32 bits |
| Un réseau /24 | `0.0.0.255` | Les 3 premiers octets correspondent, le dernier est libre |
| Un réseau /16 | `0.0.255.255` | Les 2 premiers octets correspondent |
| Tout | `255.255.255.255` (ou mot-clé `any`) | Aucune vérification, tout correspond |
| Un réseau /30 | `0.0.0.3` | Les 30 premiers bits correspondent |

> **Astuce de calcul :** wildcard = 255.255.255.255 - masque de sous-réseau. Exemple : 255.255.255.255 - 255.255.255.0 = 0.0.0.255.

---

## Vérification finale

Cochez chaque critère pour valider la réussite du lab :

- [ ] Sans ACL, tous les PCs peuvent pinger toutes les destinations (baseline)
- [ ] L'ACL standard numérotée bloque PC2 vers LAN2 mais autorise PC1
- [ ] L'ACL standard nommée bloque tout LAN1 sauf PC1
- [ ] L'ACL extended autorise HTTP/HTTPS vers SRV-WEB et DNS vers SRV-DNS depuis LAN1
- [ ] L'ACL extended bloque le ping de LAN1 vers LAN2
- [ ] Le trafic local de LAN2 (PC3 vers les serveurs) n'est pas affecté par l'ACL extended
- [ ] Vous savez lire les compteurs dans `show access-lists`
- [ ] Vous savez identifier la direction (in/out) d'une ACL sur une interface avec `show ip interface`
- [ ] Vous savez expliquer pourquoi les ACL standard vont près de la destination et les extended près de la source

---

## Questions de réflexion

### Question 1 — Pourquoi faut-il toujours ajouter `permit any` (ou `permit ip any any`) à la fin d'une ACL ?

<details>
<summary>Voir la réponse</summary>

Parce que toute ACL se termine par un `deny any` implicite (invisible dans la configuration). Si on ne met pas de `permit` explicite à la fin, tout le trafic qui ne correspond à aucune entrée de l'ACL sera automatiquement bloqué. Cela inclut le trafic légitime qu'on n'a pas pensé à autoriser. Par exemple, sans le `permit ip any any` dans l'ACL WEB-ONLY, le trafic de routage, le trafic de gestion du routeur, et le trafic provenant de LAN2 vers LAN1 seraient tous bloqués.

</details>

### Question 2 — Que se passerait-il si on plaçait l'ACL extended WEB-ONLY sur R2 (Gi0/0 in) au lieu de R1 (Gi0/0 in) ?

<details>
<summary>Voir la réponse</summary>

Fonctionnellement, le filtrage marcherait de la même manière : le trafic non autorisé de LAN1 serait tout de même bloqué. Cependant, ce serait un gaspillage de ressources réseau. Le trafic interdit traverserait tout le lien série R1-R2 avant d'être rejeté par R2. En plaçant l'ACL sur R1 (près de la source), on empêche ce trafic de consommer inutilement la bande passante du lien WAN. C'est pourquoi la bonne pratique est de placer les ACL extended le plus près possible de la source.

</details>

### Question 3 — Vous avez configuré une ACL standard sur R2 pour bloquer 10.0.1.11, mais même PC1 (10.0.1.10) ne peut plus pinger LAN2. Quelle est l'erreur la plus probable ?

<details>
<summary>Voir la réponse</summary>

L'erreur la plus probable est l'oubli du `permit any` à la fin de l'ACL. Si l'ACL contient uniquement `deny host 10.0.1.11` sans `permit any`, le `deny any` implicite bloque tout le trafic, y compris celui de PC1. La solution est d'ajouter `access-list 10 permit any` après la ligne deny.

Autre possibilité : l'ACL est appliquée dans la mauvaise direction ou sur la mauvaise interface, ce qui bloquerait le trafic de retour ou le trafic local de LAN2.

</details>

### Question 4 — Dans l'ACL extended WEB-ONLY, pourquoi utilise-t-on `deny ip` et pas `deny tcp` dans la ligne de blocage ?

<details>
<summary>Voir la réponse</summary>

Le mot-clé `ip` dans une ACL Cisco signifie "tout protocole IP", ce qui englobe TCP, UDP, ICMP, et tout autre protocole de couche 4. Si on avait utilisé `deny tcp`, on aurait bloqué uniquement le trafic TCP non autorisé, mais le trafic UDP (autre que DNS), ICMP (ping), et tout autre protocole aurait encore pu passer vers LAN2. En utilisant `deny ip`, on s'assure que le blocage est total pour tout trafic de LAN1 vers LAN2 qui n'a pas été explicitement autorisé par les lignes précédentes.

</details>

### Question 5 — Un collègue vous dit : "Les ACL standard et extended font la même chose, les extended sont juste plus longues à écrire." Que lui répondez-vous ?

<details>
<summary>Voir la réponse</summary>

C'est faux. Les ACL standard ne filtrent que sur l'adresse source, ce qui est très limité. Elles ne peuvent pas distinguer le type de trafic : elles bloquent tout ou rien pour une source donnée. Les ACL extended, en revanche, filtrent sur la source, la destination, le protocole et les ports. Cela permet des politiques de sécurité granulaires comme "autoriser PC1 à accéder au web mais pas au SSH sur le même serveur".

De plus, le placement diffère : les ACL standard vont près de la destination (car elles bloqueraient trop de trafic si placées près de la source), tandis que les extended vont près de la source (pour économiser la bande passante). Ce sont deux outils complémentaires avec des cas d'usage différents.

</details>

---

## Solution complète

<details>
<summary>Voir la solution complète de R1 (avec ACL extended)</summary>

```
enable
configure terminal

hostname R1
no ip domain-lookup

! --- Interfaces ---
interface GigabitEthernet0/0
 ip address 10.0.1.1 255.255.255.0
 no shutdown
 description LAN1
exit

interface Serial0/0/0
 ip address 10.0.12.1 255.255.255.252
 clock rate 128000
 no shutdown
 description Lien vers R2
exit

! --- Routage statique ---
ip route 10.0.2.0 255.255.255.0 10.0.12.2

! --- ACL extended : politique de filtrage granulaire ---
ip access-list extended WEB-ONLY
 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 80
 permit tcp 10.0.1.0 0.0.0.255 host 10.0.2.100 eq 443
 permit udp 10.0.1.0 0.0.0.255 host 10.0.2.200 eq 53
 deny ip 10.0.1.0 0.0.0.255 10.0.2.0 0.0.0.255
 permit ip any any
exit

! --- Application sur l'interface source ---
interface GigabitEthernet0/0
 ip access-group WEB-ONLY in
exit

end
write memory
```

</details>

<details>
<summary>Voir la solution complète de R2 (avec ACL standard nommée)</summary>

```
enable
configure terminal

hostname R2
no ip domain-lookup

! --- Interfaces ---
interface Serial0/0/0
 ip address 10.0.12.2 255.255.255.252
 no shutdown
 description Lien vers R1
exit

interface GigabitEthernet0/0
 ip address 10.0.2.1 255.255.255.0
 no shutdown
 description LAN2
exit

! --- Routage statique ---
ip route 10.0.1.0 255.255.255.0 10.0.12.1

! --- ACL standard nommée : bloquer LAN1 sauf PC1 ---
ip access-list standard BLOCK-LAN1
 permit host 10.0.1.10
 deny 10.0.1.0 0.0.0.255
 permit any
exit

! --- Application sur l'interface destination ---
interface GigabitEthernet0/0
 ip access-group BLOCK-LAN1 out
exit

end
write memory
```

</details>

> **Note :** dans un déploiement réel, on ne mettrait pas les deux ACL (standard sur R2 et extended sur R1) en même temps. Ce lab les présente séparément à des fins pédagogiques. En production, une ACL extended sur R1 suffirait pour couvrir tous les besoins de filtrage.
