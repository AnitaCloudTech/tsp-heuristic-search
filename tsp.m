clc;
clear;

% =========================
% DEFINISANJE GRADOVA
% =========================
% Koristimo 5 gradova koje posmatramo u TSP problemu
GRADOVI = {'A','B','C','D','E'};

% INF predstavlja beskonačnost (nepostojanje direktne veze)
INF = inf;

% =========================
% MATRICA UDALJENOSTI
% =========================
% DIST(i,j) predstavlja rastojanje između grada i i j
% Ako je INF -> ne postoji direktna veza
DIST = [ ...
    INF 7   6   10  13;
    7   INF 7   INF 10;
    6   7   INF 8   9;
    10  INF 8   INF 6;
    13  10  9   6   INF];

n = length(GRADOVI);

fprintf('\n============================================================\n');
fprintf('  PROBLEM TRGOVACKOG PUTNIKA (TSP) - 5 gradova\n');
fprintf('============================================================\n\n');

% =========================
% ISPIS MATRICE RASTOJANJA
% =========================
% Ovo radimo da bismo vizuelno proverili graf problema
fprintf('[Matrica rastojanja]\n      ');
for i = 1:n
    fprintf('%6s', GRADOVI{i});
end
fprintf('\n');

for i = 1:n
    fprintf('%4s', GRADOVI{i});
    for j = 1:n
        if isinf(DIST(i,j))
            fprintf('%6s','inf');
        else
            fprintf('%6.0f', DIST(i,j));
        end
    end
    fprintf('\n');
end

% =========================
% BRUTE FORCE (TAČNO REŠENJE)
% =========================
% Ideja: isprobamo sve moguće permutacije gradova
% i biramo onu sa najmanjom ukupnom cenom
[startCost, startRoute] = bruteForceTSP(DIST, 1);

ispisi(startRoute, startCost, 'OPTIMALNO RESENJE (Brute Force)', GRADOVI);

% =========================
% HEURISTIKA 1 - NEAREST NEIGHBOR
% =========================
% Ideja: iz svakog grada idemo u najbliži neposećen grad
[h1_route, h1_cost, h1_steps] = nearestNeighbor(DIST, 1);

ispisi(h1_route, h1_cost, 'H1: Nearest Neighbor (Pohlepna metoda)', GRADOVI);

fprintf('\nDetaljan prikaz koraka H1:\n');
for i = 1:length(h1_steps)
    fprintf('Korak %d: iz grada %s -> izabran grad %s (udaljenost = %.0f)\n', ...
        i, h1_steps(i).from, h1_steps(i).to, h1_steps(i).dist);
end

% =========================
% HEURISTIKA 2 - GREEDY EDGE
% =========================
% Ideja: biramo najkraće ivice, ali pazimo da ne napravimo nevalidan ciklus
% (stepen čvora <= 2 i bez prerano zatvorenog kruga)
[h2_route, h2_cost, h2_steps] = greedyEdge(DIST);

ispisi(h2_route, h2_cost, 'H2: Greedy Edge metoda', GRADOVI);

fprintf('\nDetaljan prikaz koraka H2:\n');
for i = 1:length(h2_steps)
    fprintf('Ivica %s-%s (d=%g): %s\n', ...
        h2_steps(i).a, h2_steps(i).b, h2_steps(i).d, h2_steps(i).status);
end

% =========================
% POREĐENJE REŠENJA
% =========================
fprintf('\n============================================================\n');
fprintf('  POREĐENJE REŠENJA\n');
fprintf('============================================================\n');

fprintf('Optimalno (BF): %s | cena = %.0f\n', printRoute(startRoute, GRADOVI), startCost);
fprintf('H1 NN:          %s | cena = %.0f\n', printRoute(h1_route, GRADOVI), h1_cost);
fprintf('H2 GE:          %s | cena = %.0f\n', printRoute(h2_route, GRADOVI), h2_cost);

% Biramo bolju heuristiku
if h1_cost <= h2_cost
    bestH = 'H1 (Nearest Neighbor)';
    bestCost = h1_cost;
else
    bestH = 'H2 (Greedy Edge)';
    bestCost = h2_cost;
end

fprintf('\nNajbolje heuristicko resenje: %s | cena = %.0f\n', bestH, bestCost);

% Provera koliko smo blizu optimuma
if bestCost == startCost
    fprintf('-> Heuristika je dala OPTIMALNO resenje!\n');
else
    fprintf('-> Odstupanje od optimuma: %.0f (%.2f%%)\n', ...
        bestCost - startCost, (bestCost-startCost)/startCost*100);
end

%% =========================================================
% FUNKCIJE
% =========================================================

% -------------------------
% BRUTE FORCE REŠENJE
% -------------------------
function [bestCost, bestRoute] = bruteForceTSP(DIST, start)

    n = size(DIST,1);
    nodes = 1:n;
    nodes(nodes==start) = [];

    bestCost = inf;
    bestRoute = [];

    % Prolazimo kroz sve moguće permutacije
    permsList = perms(nodes);

    for i = 1:size(permsList,1)
        route = [start permsList(i,:) start];
        cost = calc(route, DIST);

        if cost < bestCost
            bestCost = cost;
            bestRoute = route;
        end
    end
end

% -------------------------
% NEAREST NEIGHBOR
% -------------------------
function [route, cost, steps] = nearestNeighbor(DIST, start)

    n = size(DIST,1);
    visited = false(1,n);

    route = start;
    visited(start) = true;
    current = start;

    steps = struct('from',{},'to',{},'dist',{});

    % Dok ne posetimo sve gradove
    for i = 1:n-1

        best = inf;
        next = -1;

        % tražimo najbliži neposećen grad
        for j = 1:n
            if ~visited(j) && DIST(current,j) < best
                best = DIST(current,j);
                next = j;
            end
        end

        steps(end+1) = struct('from',num2str(current), ...
                               'to',num2str(next), ...
                               'dist',best);

        route(end+1) = next;
        visited(next) = true;
        current = next;
    end

    % vraćamo se u početni grad
    route(end+1) = start;
    cost = calc(route, DIST);
end

% -------------------------
% GREEDY EDGE METODA
% -------------------------
function [route, cost, steps] = greedyEdge(DIST)

    n = size(DIST,1);

    % pravimo listu svih ivica
    edges = [];
    for i = 1:n
        for j = i+1:n
            if ~isinf(DIST(i,j))
                edges = [edges; DIST(i,j) i j];
            end
        end
    end

    % sortiramo po udaljenosti (najkraće prvo)
    edges = sortrows(edges,1);

    degree = zeros(1,n);
    parent = 1:n;

    % Union-Find pomoćne funkcije
    function p = find(x)
        while parent(x) ~= x
            parent(x) = parent(parent(x));
            x = parent(x);
        end
        p = x;
    end

    function union(a,b)
        parent(find(a)) = find(b);
    end

    chosen = [];
    steps = struct('a',{},'b',{},'d',{},'status',{});

    for k = 1:size(edges,1)

        d = edges(k,1);
        a = edges(k,2);
        b = edges(k,3);

        status = "ODBIJENA";

        % proveravamo da li je ivica dozvoljena
        if degree(a) < 2 && degree(b) < 2 && ~(find(a)==find(b) && size(chosen,1)<n-1)

            degree(a) = degree(a) + 1;
            degree(b) = degree(b) + 1;
            union(a,b);

            chosen = [chosen; a b];
            status = "ODABRANA";
        end

        steps(end+1) = struct('a',num2str(a), ...
                               'b',num2str(b), ...
                               'd',d, ...
                               'status',status);

        if size(chosen,1) == n
            break;
        end
    end

    % rekonstrukcija puta iz izabranih ivica
    adj = cell(1,n);
    for i = 1:size(chosen,1)
        adj{chosen(i,1)} = [adj{chosen(i,1)} chosen(i,2)];
        adj{chosen(i,2)} = [adj{chosen(i,2)} chosen(i,1)];
    end

    route = zeros(1,n+1);
    route(1) = 1;

    prev = -1;
    cur = 1;

    for i = 2:n
        neigh = adj{cur};
        next = neigh(neigh ~= prev);

        if isempty(next)
            route = [];
            cost = inf;
            return;
        end

        route(i) = next(1);
        prev = cur;
        cur = next(1);
    end

    route(end) = 1;
    cost = calc(route, DIST);
end

% -------------------------
% FUNKCIJA ZA CENU
% -------------------------
function c = calc(route, DIST)
    c = 0;
    for i = 1:length(route)-1
        c = c + DIST(route(i), route(i+1));
    end
end

% -------------------------
% ISPIS RUTE
% -------------------------
function ispisi(route, cost, titleText, GRADOVI)

    fprintf('\n============================================================\n');
    fprintf('  %s\n', titleText);
    fprintf('============================================================\n');

    fprintf('Ruta: ');
    for i = 1:length(route)
        fprintf('%s', GRADOVI{route(i)});
        if i < length(route)
            fprintf(' -> ');
        end
    end
    fprintf('\n');

    fprintf('Cena: %.0f\n', cost);
end

% -------------------------
% PRETVORBA RUTE U STRING
% -------------------------
function s = printRoute(route, GRADOVI)
    s = "";
    for i = 1:length(route)
        s = s + GRADOVI{route(i)};
        if i < length(route)
            s = s + " -> ";
        end
    end
    s = char(s);
end
%% =========================
% GRAF - TSP PUT
% =========================

figure;
hold on;
grid on;

title('TSP - Grafički prikaz puta');

% koordinate čvorova (ručno raspoređene za lep prikaz)
x = [0 2 4 6 8];
y = [4 8 9 5 1];

% crtanje gradova
for i = 1:length(GRADOVI)
    plot(x(i), y(i), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(x(i)+0.1, y(i)+0.1, GRADOVI{i}, 'FontSize', 12);
end

% funkcija za crtanje rute
plotRoute = @(route, color) ...
    plot(x(route), y(route), color, 'LineWidth', 2);

% OPTIMALNO
plotRoute(startRoute, 'g-');

% H1
plotRoute(h1_route, 'b--');

% H2
plotRoute(h2_route, 'm-.');

legend('Gradovi','Optimalno','H1 NN','H2 Greedy Edge');
hold off;