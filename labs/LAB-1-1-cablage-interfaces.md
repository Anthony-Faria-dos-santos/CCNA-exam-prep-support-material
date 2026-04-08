# LAB 1.1 — Cablage, interfaces et connectivite de base

| Info | Detail |
|------|--------|
| **Module** | 1 — Fondamentaux reseau |
| **Topics couverts** | 1.3 (Interfaces physiques), 1.4 (Types de cables), 1.6 (Adressage IPv4 de base), 1.10 (Verification de la connectivite) |
| **Difficulte** | Debutant |
| **Duree estimee** | 30 minutes |
| **Outil** | Cisco Packet Tracer 8.x |

---

## Topologie

```
                    Cable console (bleu)
                    ┌──────────────────┐
                    │                  │
               ┌────┴────┐       ┌────┴────┐
               │   PC    │       │         │
               │ (admin) │       │   R1    │
               └─────────┘       │ 2911    │
                                 └────┬────┘
                                      │ Gi0/0
                                      │ Cable droit
                                      │
                                 ┌────┴────┐
                                 │   SW1   │
                                 │ 2960    │
                                 ├─────────┤
                              Fa0/1     Fa0/2
                               │           │
                          Cable droit  Cable droit
                               │           │
                          ┌────┴────┐ ┌────┴────┐
                          │  PC1    │ │  PC2    │
                          └─────────┘ └─────────┘
```

---

## Tableau d'adressage

| Equipement | Interface | Adresse IP | Masque | Passerelle par defaut |
|------------|-----------|------------|--------|----------------------|
| R1 | Gi0/0 | 192.168.1.1 | 255.255.255.0 | — |
| SW1 | VLAN 1 | 192.168.1.2 | 255.255.255.0 | 192.168.1.1 |
| PC1 | FastEthernet0 | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| PC2 | FastEthernet0 | 192.168.1.11 | 255.255.255.0 | 192.168.1.1 |

---

## Objectifs

1. Identifier les differents types de cables reseau (console, droit, croise) et savoir quand les utiliser
2. Cabler correctement une topologie avec un routeur, un switch et deux PCs
3. Configurer les adresses IP sur toutes les interfaces
4. Verifier la connectivite de bout en bout avec `ping`
5. Diagnostiquer des erreurs courantes d'interface (duplex/speed mismatch)

---

## Prerequis

- Savoir naviguer dans l'interface de Packet Tracer (glisser des equipements, connecter des cables)
- Connaitre la notation CIDR de base (/24 = 255.255.255.0)
- Comprendre qu'une adresse IP identifie un equipement sur le reseau

---

## Configuration de depart

Aucune configuration initiale n'est necessaire. Tous les equipements partent de leur configuration d'usine. Le lab se construit entierement de zero.

**Equipements a placer dans Packet Tracer :**
- 1x Routeur Cisco 2911
- 1x Switch Cisco 2960
- 2x PC generiques

---

## Partie 1 — Identification du cablage

### Etape 1.1 : Comprendre les trois types de cables

Avant de cabler quoi que ce soit, il faut connaitre les regles.

**Cable console (bleu clair dans Packet Tracer) :**
- Sert a administrer un equipement reseau (routeur, switch) depuis un PC
- Se branche du port RS-232 (ou USB) du PC vers le port Console du routeur/switch
- Ne transporte PAS de donnees reseau, uniquement des commandes de gestion

**Cable droit (straight-through) :**
- Connecte des equipements de types **differents** : PC vers switch, routeur vers switch
- C'est le cable le plus courant en reseau

**Cable croise (crossover) :**
- Connecte des equipements de **meme type** : switch vers switch, PC vers PC, routeur vers routeur
- En theorie necessaire aussi pour routeur vers PC (deux hotes)

> **Point exam CCNA :** Les switches modernes disposent de la fonctionnalite **auto-MDIX** qui detecte automatiquement le type de cable et s'adapte. En pratique, le type de cable importe donc moins. Cependant, l'examen CCNA 200-301 teste toujours la theorie classique (droit vs croise). Retenez les regles traditionnelles.

### Etape 1.2 : Cabler la topologie

Dans Packet Tracer, realisez les connexions suivantes :

| Connexion | Type de cable | Port source | Port destination |
|-----------|--------------|-------------|-----------------|
| PC admin vers R1 | Console (bleu) | RS-232 | Console |
| R1 vers SW1 | Droit (noir) | Gi0/0 | Gi0/1 |
| PC1 vers SW1 | Droit (noir) | FastEthernet0 | Fa0/1 |
| PC2 vers SW1 | Droit (noir) | FastEthernet0 | Fa0/2 |

**Comment faire dans Packet Tracer :**

1. Cliquez sur l'icone cable (eclair) en bas a gauche
2. Selectionnez le type de cable voulu
3. Cliquez sur le premier equipement, choisissez l'interface
4. Cliquez sur le second equipement, choisissez l'interface

Les voyants sur le schema doivent passer au **vert** au bout de quelques secondes (sauf le lien R1 vers SW1 qui restera rouge/orange tant que l'interface du routeur n'est pas activee — c'est normal).

### Etape 1.3 : Acceder au routeur par le cable console

1. Cliquez sur le PC admin
2. Allez dans l'onglet **Desktop** puis **Terminal**
3. Laissez les parametres par defaut (9600 baud, 8 bits, None, 1, None)
4. Cliquez sur **OK**

Vous devriez voir le prompt du routeur :

```
Router>
```

C'est la preuve que le cable console fonctionne. Vous etes en mode **utilisateur** (le `>` l'indique).

---

## Partie 2 — Configuration des adresses IP

### Etape 2.1 : Configurer le routeur R1

Depuis le terminal du PC admin (connecte en console), entrez les commandes suivantes :

```
Router> enable
Router# configure terminal
Router(config)# hostname R1
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 192.168.1.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit
R1(config)# exit
R1#
```

**Pourquoi `no shutdown` ?** Sur un routeur Cisco, toutes les interfaces sont desactivees par defaut (etat `administratively down`). La commande `no shutdown` active l'interface. C'est une difference majeure avec les switches ou les ports sont actifs par defaut.

Apres `no shutdown`, vous devriez voir apparaitre :

```
%LINK-5-CHANGED: Interface GigabitEthernet0/0, changed state to up
%LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
```

Le voyant du lien R1-SW1 doit maintenant passer au **vert**.

### Etape 2.2 : Configurer l'interface de gestion du switch SW1

Cliquez sur SW1, allez dans l'onglet **CLI** :

```
Switch> enable
Switch# configure terminal
Switch(config)# hostname SW1
SW1(config)# interface vlan 1
SW1(config-if)# ip address 192.168.1.2 255.255.255.0
SW1(config-if)# no shutdown
SW1(config-if)# exit
SW1(config)# ip default-gateway 192.168.1.1
SW1(config)# exit
SW1#
```

**Pourquoi configurer VLAN 1 et pas un port physique ?** Un switch de couche 2 ne route pas le trafic IP. On lui attribue une adresse IP uniquement pour pouvoir l'administrer a distance (SSH, Telnet). Cette adresse se configure sur une interface virtuelle : le VLAN de gestion (par defaut VLAN 1).

### Etape 2.3 : Configurer les PCs

Pour chaque PC, cliquez dessus puis allez dans **Desktop > IP Configuration** :

**PC1 :**
| Champ | Valeur |
|-------|--------|
| IPv4 Address | 192.168.1.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.1.1 |

**PC2 :**
| Champ | Valeur |
|-------|--------|
| IPv4 Address | 192.168.1.11 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.1.1 |

---

## Partie 3 — Verification de la connectivite

### Etape 3.1 : Verifier les interfaces du routeur

Depuis le terminal du routeur R1 :

```
R1# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.1.1     YES manual up                    up
GigabitEthernet0/1     unassigned      YES unset  administratively down down
GigabitEthernet0/2     unassigned      YES unset  administratively down down
Vlan1                  unassigned      YES unset  administratively down down
```

Verifiez que Gi0/0 affiche **up/up**. Les deux colonnes `Status` et `Protocol` doivent etre a `up`.

- Si `Status` = `administratively down` : vous avez oublie `no shutdown`
- Si `Status` = `up` mais `Protocol` = `down` : probleme physique (cable mal connecte)

### Etape 3.2 : Verifier les interfaces du switch

Depuis le CLI de SW1 :

```
SW1# show ip interface brief
```

**Output attendu :**

```
Interface              IP-Address      OK? Method Status                Protocol
FastEthernet0/1        unassigned      YES unset  up                    up
FastEthernet0/2        unassigned      YES unset  up                    up
...
GigabitEthernet0/1     unassigned      YES unset  up                    up
...
Vlan1                  192.168.1.2     YES manual up                    up
```

Les ports connectes (Fa0/1, Fa0/2, Gi0/1) doivent etre `up/up`. L'interface VLAN 1 doit montrer l'adresse IP configuree.

Verifiez aussi l'etat detaille des ports :

```
SW1# show interfaces status
```

**Output attendu :**

```
Port      Name   Status       Vlan    Duplex  Speed Type
Fa0/1            connected    1       a-full  a-100 10/100BaseTX
Fa0/2            connected    1       a-full  a-100 10/100BaseTX
...
Gi0/1            connected    1       a-full  a-1000 10/100/1000BaseTX
```

Le statut `connected` confirme que le cable est bien branche et que l'interface est active.

### Etape 3.3 : Tester la connectivite par ping

Depuis **PC1** (Desktop > Command Prompt) :

```
C:\> ping 192.168.1.1
```

**Output attendu :**

```
Pinging 192.168.1.1 with 32 bytes of data:

Reply from 192.168.1.1: bytes=32 time<1ms TTL=255
Reply from 192.168.1.1: bytes=32 time<1ms TTL=255
Reply from 192.168.1.1: bytes=32 time<1ms TTL=255
Reply from 192.168.1.1: bytes=32 time<1ms TTL=255

Ping statistics for 192.168.1.1:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

> **Note :** Le premier ping peut echouer (`Request timed out` ou `Destination host unreachable`). C'est normal : le switch doit d'abord apprendre l'adresse MAC via ARP. Relancez le ping si necessaire.

Effectuez maintenant les tests suivants depuis PC1 :

| Destination | Commande | Resultat attendu |
|-------------|----------|-----------------|
| Routeur R1 | `ping 192.168.1.1` | Succes (4/4) |
| Switch SW1 | `ping 192.168.1.2` | Succes (4/4) |
| PC2 | `ping 192.168.1.11` | Succes (4/4) |
| PC1 lui-meme | `ping 192.168.1.10` | Succes (4/4) |

Verifiez aussi la configuration IP des PCs :

```
C:\> ipconfig
```

**Output attendu (PC1) :**

```
FastEthernet0 Connection:(default port)

   Connection-specific DNS Suffix..:
   Link-local IPv6 Address.........: FE80::xxx:xxxx:xxxx:xxxx
   IPv6 Address....................: ::
   IPv4 Address....................: 192.168.1.10
   Subnet Mask.....................: 255.255.255.0
   Default Gateway.................: 192.168.1.1
```

### Etape 3.4 : Tester depuis le routeur

Depuis R1, testez la connectivite vers les PCs :

```
R1# ping 192.168.1.10
```

**Output attendu :**

```
Type escape sequence to abort.
Sending 5, 100-byte ICMP Echos to 192.168.1.10, timeout is 2 seconds:
.!!!!
Success rate is 80 percent (4/5), round-trip min/avg/max = 0/0/0 ms
```

Le premier `.` (echec) est cause par la resolution ARP. Un taux de 80% au premier ping est normal sur Cisco. Les pings suivants donneront 100%.

---

## Partie 4 — Diagnostic d'erreurs d'interface

### Etape 4.1 : Creer un mismatch duplex/speed

Cette etape simule un probleme courant en production. On va forcer des parametres incompatibles sur un port du switch.

Depuis SW1 :

```
SW1# configure terminal
SW1(config)# interface FastEthernet0/1
SW1(config-if)# duplex half
SW1(config-if)# speed 10
SW1(config-if)# exit
SW1(config)# exit
SW1#
```

On force le port Fa0/1 en half-duplex a 10 Mbps, alors que PC1 est en auto-negociation.

### Etape 4.2 : Observer les symptomes

Verifiez l'etat de l'interface :

```
SW1# show interfaces FastEthernet0/1
```

Cherchez ces lignes dans l'output :

```
  Half-duplex, 10Mb/s, media type is 10/100BaseTX
  ...
  0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored
  0 late collision, 0 deferred
```

Le port fonctionne toujours mais en mode degrade. En situation reelle, un mismatch duplex provoque des **late collisions** et des performances tres degradees (lenteur, paquets perdus).

Verifiez aussi :

```
SW1# show interfaces status
```

**Output attendu :**

```
Port      Name   Status       Vlan    Duplex  Speed Type
Fa0/1            connected    1       half    10    10/100BaseTX
Fa0/2            connected    1       a-full  a-100 10/100BaseTX
```

Remarquez la difference : Fa0/1 montre `half` et `10` (valeurs forcees), tandis que Fa0/2 montre `a-full` et `a-100` (le prefixe `a-` signifie "auto-negocie").

### Etape 4.3 : Corriger le probleme

Remettez l'interface en auto-negociation :

```
SW1# configure terminal
SW1(config)# interface FastEthernet0/1
SW1(config-if)# duplex auto
SW1(config-if)# speed auto
SW1(config-if)# exit
SW1(config)# exit
SW1#
```

Verifiez la correction :

```
SW1# show interfaces status
```

Fa0/1 devrait maintenant afficher `a-full` et `a-100` a nouveau.

> **Point exam CCNA :** Un mismatch duplex est une cause classique de problemes de performance reseau. Si un cote est en `full-duplex` et l'autre en `half-duplex`, le cote half-duplex detectera des collisions alors que le cote full-duplex ne s'y attend pas. Le resultat : late collisions, retransmissions, et debit effectif tres reduit. La bonne pratique est de laisser les deux cotes en **auto** ou de forcer les **memes parametres** des deux cotes.

---

## Verification finale

Avant de considerer ce lab comme termine, verifiez chaque critere :

- [ ] Le cable console connecte le PC admin au port Console de R1
- [ ] Les cables droits connectent R1 a SW1, et les PCs a SW1
- [ ] R1 Gi0/0 est configure avec 192.168.1.1/24 et l'interface est `up/up`
- [ ] SW1 VLAN 1 est configure avec 192.168.1.2/24 et une passerelle par defaut
- [ ] PC1 a l'adresse 192.168.1.10/24 avec la passerelle 192.168.1.1
- [ ] PC2 a l'adresse 192.168.1.11/24 avec la passerelle 192.168.1.1
- [ ] `ping` de PC1 vers R1 (192.168.1.1) : succes
- [ ] `ping` de PC1 vers PC2 (192.168.1.11) : succes
- [ ] `ping` de PC2 vers SW1 (192.168.1.2) : succes
- [ ] Les interfaces du switch sont en `auto/auto` (duplex/speed)

---

## Questions de reflexion

**Q1 : Pourquoi un routeur necessite `no shutdown` sur ses interfaces mais pas un switch ?**

<details>
<summary>Reponse</summary>

C'est une decision de design Cisco. Les routeurs ont leurs interfaces desactivees par defaut pour des raisons de securite : un routeur connecte generalement des reseaux differents et on veut que l'administrateur active deliberement chaque interface apres l'avoir configuree. Les switches, eux, sont des equipements "plug and play" de couche 2 : leurs ports sont actifs par defaut pour permettre une mise en service rapide.

</details>

**Q2 : Que se passe-t-il si vous utilisez un cable croise au lieu d'un cable droit entre PC1 et SW1 ?**

<details>
<summary>Reponse</summary>

Dans Packet Tracer, si auto-MDIX est actif sur le switch (cas des modeles recents comme le 2960), la connexion fonctionnera quand meme. Le switch detecte automatiquement le croisement et s'adapte. En revanche, sur un equipement ancien sans auto-MDIX, le lien ne s'etablirait pas (voyant rouge). Pour l'examen CCNA, retenez la regle classique : cable droit entre equipements de types differents.

</details>

**Q3 : Vous configurez tout correctement mais le ping de PC1 vers R1 echoue. Quel est votre processus de diagnostic ?**

<details>
<summary>Reponse</summary>

Procedure methodique du bas vers le haut (modele OSI) :

1. **Couche 1 (Physique)** : Verifier les voyants dans Packet Tracer. Sont-ils verts ? Le cable est-il du bon type et branche aux bonnes interfaces ?
2. **Couche 2 (Liaison)** : `show interfaces status` sur SW1. Le port est-il `connected` ? Y a-t-il un mismatch duplex/speed ?
3. **Couche 3 (Reseau)** : `show ip interface brief` sur R1. L'interface est-elle `up/up` ? L'adresse IP est-elle correcte ? Verifier `ipconfig` sur PC1 pour confirmer IP, masque et passerelle.
4. **Test progressif** : Pinger d'abord 192.168.1.10 depuis PC1 (loopback local), puis 192.168.1.2 (switch), puis 192.168.1.1 (routeur). Le premier echec indique ou se situe le probleme.

</details>

**Q4 : Pourquoi le switch a-t-il besoin d'une passerelle par defaut alors qu'il ne route pas le trafic ?**

<details>
<summary>Reponse</summary>

La passerelle par defaut sur un switch n'est utilisee que pour le **trafic de gestion** genere par le switch lui-meme (reponses Telnet/SSH, requetes NTP, envoi de logs Syslog, etc.). Elle n'a aucun effet sur le trafic des utilisateurs qui traverse le switch. Sans passerelle, le switch ne pourrait communiquer qu'avec les equipements de son propre sous-reseau.

</details>

**Q5 : Un collegue vous dit "le ping fonctionne localement mais pas vers un autre reseau". Quel equipement verifiez-vous en priorite ?**

<details>
<summary>Reponse</summary>

Le routeur, qui est la passerelle par defaut. Verifiez :
1. Que l'interface du routeur sur le LAN local est `up/up` avec la bonne adresse IP
2. Que les PCs ont la bonne passerelle par defaut configuree
3. Que le routeur a une route vers le reseau de destination (`show ip route`)

Dans ce lab, il n'y a qu'un seul reseau, donc ce scenario ne s'applique pas directement. Mais c'est une question classique de l'examen.

</details>

---

## Solution complete

<details>
<summary>Cliquez pour afficher la solution</summary>

### R1 — Configuration complete

```
enable
configure terminal
hostname R1
interface GigabitEthernet0/0
 ip address 192.168.1.1 255.255.255.0
 no shutdown
exit
exit
```

### SW1 — Configuration complete

```
enable
configure terminal
hostname SW1
interface vlan 1
 ip address 192.168.1.2 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.1.1
exit
```

### PC1 — Configuration IP

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 192.168.1.10 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.1.1 |

### PC2 — Configuration IP

| Parametre | Valeur |
|-----------|--------|
| IPv4 Address | 192.168.1.11 |
| Subnet Mask | 255.255.255.0 |
| Default Gateway | 192.168.1.1 |

### Cablage

| Connexion | Cable | Interface source | Interface destination |
|-----------|-------|-----------------|---------------------|
| PC admin - R1 | Console | RS-232 | Console |
| R1 - SW1 | Droit | Gi0/0 | Gi0/1 |
| PC1 - SW1 | Droit | FastEthernet0 | Fa0/1 |
| PC2 - SW1 | Droit | FastEthernet0 | Fa0/2 |

### Tests de verification

Depuis PC1 :
```
ping 192.168.1.1
ping 192.168.1.2
ping 192.168.1.11
ipconfig
```

Depuis R1 :
```
show ip interface brief
ping 192.168.1.10
ping 192.168.1.11
```

Depuis SW1 :
```
show ip interface brief
show interfaces status
ping 192.168.1.1
```

</details>
