# tsp-heuristic-search

Ovaj projekat prikazuje rešavanje Problema Trgovačkog Putnika (TSP) na nekompletnom grafu od 5 gradova primenom egzaktnih i heurističkih metoda u okviru predmeta Veštačka inteligencija.

## Implementirani Algoritmi
* **Brute Force (Egzaktna pretraga):** Pronalazi globalni optimum pretragom svih permutacija.
* **H1 (Nearest Neighbor):** Lokalna pohlepna pretraga ($f(n) = h(n)$).
* **H2 (Greedy Edge Insertion):** Globalni pohlepni pristup sa Union-Find strukturom podataka za sprečavanje preuranjenih ciklusa.

## Rezultati
| Algoritam | Ruta | Cena | Odstupanje |
|---|---|---|---|
| Brute Force | A -> B -> E -> D -> C -> A | 37 | 0.0% |
| H1 (Nearest Neighbor) | A -> C -> B -> E -> D -> A | 39 | +5.4% |
| H2 (Greedy Edge) | A -> C -> D -> E -> B -> A | 37 | 0.0% |

## Kako pokrenuti
```bash
python tspsolution.py
```
