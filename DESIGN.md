# Document de conception

> Document vivant : on le complète au fur et à mesure.

## Vision

Un MMORPG **agréable entre amis** (10 à 50 joueurs sur un même serveur), dans l'esprit
d'**Albion Online** (économie entre joueurs, l'équipement définit les compétences, combat en
temps réel) et de **Dofus** (univers 2D isométrique, métiers, ambiance), avec une
**timeline originale**.

## Piliers

1. **Jouer ensemble** : tout est plus fun en groupe, rien n'oblige à jouer seul ou
   à « farmer » des heures.
2. **Ce que tu portes, c'est ce que tu es** : pas de classe fixe, les armes et armures
   donnent les compétences (comme Albion).
3. **Une économie faite par les joueurs** : récolte, métiers, artisanat, échanges.
4. **Un monde qui a une histoire** : la timeline (à définir, voir plus bas).

## Choix techniques

| Sujet | Choix | Pourquoi |
|---|---|---|
| Moteur | Godot 4.3+ (GDScript) | Gratuit, exporte PC + Android + iOS, isométrique natif |
| Rendu | GL Compatibility | Fonctionne sur le plus de téléphones possible |
| Vue | 2D isométrique, tuiles 64×32 | Style Dofus |
| Réseau (prévu) | Serveur Godot sans affichage, autoritaire | Même code client/serveur, anti-triche |
| Contrôles | Clavier, clic/toucher pour se déplacer, D-pad virtuel optionnel | PC et mobile |

## Feuille de route

- [x] **Étape 1a** : carte isométrique, déplacement clavier / clic / toucher, D-pad mobile, options
- [ ] **Étape 1b** : un monstre, une arme avec des compétences, des points de vie
- [ ] **Étape 2** : multijoueur (serveur autoritaire, plusieurs joueurs sur la même carte)
- [ ] **Étape 3** : récolte, fabrication, inventaire sauvegardé, l'équipement donne les compétences
- [ ] **Étape 4** : plusieurs zones, la timeline, les guildes, un marché

## Timeline (à choisir)

- **A. Les Échos** : le monde évolue par ères ; les actions des joueurs décident de l'ère suivante.
- **B. Fracture** : chaque zone est figée à une époque différente, avec des portails entre elles.
- **C. Les Héritiers** : on joue la génération suivante et on découvre le passé à l'envers.
