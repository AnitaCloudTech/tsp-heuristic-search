import itertools

GRADOVI = ['A', 'B', 'C', 'D', 'E']

INF = float('inf')
DIST = {
    'A': {'A': INF, 'B': 7,   'C': 6,   'D': 10,  'E': 13},
    'B': {'A': 7,   'B': INF, 'C': 7,   'D': INF, 'E': 10},
    'C': {'A': 6,   'B': 7,   'C': INF, 'D': 8,   'E': 9},
    'D': {'A': 10,  'B': INF, 'C': 8,   'D': INF, 'E': 6},
    'E': {'A': 13,   'B': 10,  'C': 9,  'D': 6,   'E': INF},
}

def cena_rute(ruta):
    ukupno = 0
    for i in range(len(ruta) - 1):
        d = DIST[ruta[i]][ruta[i+1]]
        if d == INF:
            return INF
        ukupno += d
    return ukupno

def ispisi_rutu(naziv, ruta, cena):
    print(f"\n{'='*50}")
    print(f"  {naziv}")
    print(f"{'='*50}")
    print(f"  Ruta : {' -> '.join(ruta)}")
    print(f"  Cena : {cena}")
    print(f"{'='*50}")

def brute_force(start='A'):
    ostali = [g for g in GRADOVI if g != start]
    optimalna_ruta = None
    minimalna_cena = INF
    for perm in itertools.permutations(ostali):
        ruta = [start] + list(perm) + [start]
        c = cena_rute(ruta)
        if c < minimalna_cena:
            minimalna_cena = c
            optimalna_ruta = ruta
    return optimalna_ruta, minimalna_cena

def heuristika_nearest_neighbor(start='A'):
    poseceni = set([start])
    ruta = [start]
    trenutni = start
    koraci = []
    while len(poseceni) < len(GRADOVI):
        najbliži = None
        min_dist = INF
        kandidati = {}
        for grad in GRADOVI:
            if grad not in poseceni:
                d = DIST[trenutni][grad]
                kandidati[grad] = d
                if d < min_dist:
                    min_dist = d
                    najbliži = grad
        koraci.append({
            'iz': trenutni,
            'kandidati': kandidati,
            'izabran': najbliži,
            'h_vrednost': min_dist
        })
        poseceni.add(najbliži)
        ruta.append(najbliži)
        trenutni = najbliži
    ruta.append(start)
    return ruta, cena_rute(ruta), koraci

def heuristika_greedy_edge(start='A'):
    ivice = []
    for a in GRADOVI:
        for b in GRADOVI:
            if a < b and DIST[a][b] != INF:
                ivice.append((DIST[a][b], a, b))
    ivice.sort()
    stepen = {g: 0 for g in GRADOVI}
    adj = {g: [] for g in GRADOVI}
    parent = {g: g for g in GRADOVI}
    odabrane_ivice = []

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(x, y):
        parent[find(x)] = find(y)

    koraci = []
    for d, a, b in ivice:
        if stepen[a] >= 2:
            razlog = f"Čvor {a} već ima stepen 2"
        elif stepen[b] >= 2:
            razlog = f"Čvor {b} već ima stepen 2"
        elif find(a) == find(b) and len(odabrane_ivice) < len(GRADOVI) - 1:
            razlog = "Formira preuranjeni krug"
        else:
            adj[a].append(b)
            adj[b].append(a)
            stepen[a] += 1
            stepen[b] += 1
            union(a, b)
            odabrane_ivice.append((d, a, b))
            razlog = "ODABRANA"
        koraci.append({'ivica': (a, b), 'dist': d, 'status': razlog})
        if len(odabrane_ivice) == len(GRADOVI):
            break

    ruta = [start]
    prev = None
    cur = start
    for _ in range(len(GRADOVI) - 1):
        sledeci = next((x for x in adj[cur] if x != prev), None)
        if sledeci is None:
            return None, INF, koraci
        ruta.append(sledeci)
        prev = cur
        cur = sledeci
    ruta.append(start)
    return ruta, cena_rute(ruta), koraci

if __name__ == "__main__":
    print("\n" + "="*60)
    print("  PROBLEM TRGOVAČKOG PUTNIKA - TSP (5 gradova)")
    print("  Veštačka inteligencija, 2025/2026")
    print("="*60)

    print("\n[GRAF - Matrica rastojanja]")
    print(f"{'':>4}", end="")
    for g in GRADOVI:
        print(f"{g:>6}", end="")
    print()
    for a in GRADOVI:
        print(f"{a:>4}", end="")
        for b in GRADOVI:
            d = DIST[a][b]
            print(f"{'inf' if d==INF else d:>6}", end="")
        print()

    opt_ruta, opt_cena = brute_force()
    ispisi_rutu("OPTIMALNO REŠENJE (Brute Force)", opt_ruta, opt_cena)

    h1_ruta, h1_cena, h1_koraci = heuristika_nearest_neighbor()
    ispisi_rutu("H1: Nearest Neighbor (Pohlepna pretraga)", h1_ruta, h1_cena)
    print("\n  Detalji izvršavanja H1:")
    for i, k in enumerate(h1_koraci):
        print(f"  Korak {i+1}: Iz {k['iz']} -> kandidati: {k['kandidati']}")
        print(f"           Izabran: {k['izabran']} (h={k['h_vrednost']})")

    h2_ruta, h2_cena, h2_koraci = heuristika_greedy_edge()
    ispisi_rutu("H2: Greedy Edge Insertion (Pohlepno umetanje ivica)", h2_ruta, h2_cena)
    print("\n  Detalji izvršavanja H2:")
    for k in h2_koraci:
        print(f"  Ivica {k['ivica'][0]}-{k['ivica'][1]} (d={k['dist']}): {k['status']}")

    print("\n" + "="*60)
    print("  POREĐENJE REZULTATA")
    print("="*60)
    print(f"  Optimalno (BF): {' -> '.join(opt_ruta):30s}  cena = {opt_cena}")
    print(f"  H1 (NN):        {' -> '.join(h1_ruta):30s}  cena = {h1_cena}")
    print(f"  H2 (GE):        {' -> '.join(h2_ruta) if h2_ruta else 'N/A':30s}  cena = {h2_cena}")

    bolja_h = "H1" if h1_cena <= h2_cena else "H2"
    bolja_cena = min(h1_cena, h2_cena)
    print(f"\n  Bolje heurističko rešenje: {bolja_h} sa cenom {bolja_cena}")
    if bolja_cena == opt_cena:
        print(f"  -> {bolja_h} pronalazi OPTIMALNO rešenje!")
    else:
        razlika = bolja_cena - opt_cena
        print(f"  -> {bolja_h} odstupa od optimuma za {razlika} ({razlika/opt_cena*100:.1f}%)")
    print()
