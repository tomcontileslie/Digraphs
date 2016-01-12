#############################################################################
##
#W  attr.gi
#Y  Copyright (C) 2014                                   James D. Mitchell
##
##  Licensing information can be found in the README file of this package.
##
#############################################################################
##

BindGlobal("DIGRAPHS_OrbitNumbers",
function(G, v, n)
  local orbits, out, i, j;

  orbits := DigraphOrbits(G, Difference([1 .. n], [v]), n).orbits;

  out := [1 .. n];
  out[v] := 1;

  for i in [1 .. Length(orbits)] do
    for j in orbits[i] do
      out[j] := i + 1;
    od;
  od;

  return rec(orbitNumbers := out,
             representatives := Concatenation([v], List(orbits, Representative)));
end);

InstallMethod(DigraphGroup, "for a digraph",
[IsDigraph], AutomorphismGroup);

# this is arranged like this in case we want to change the method in future,
# and also to allow its use **before** the creation of a digraph (such as when
# the group is given as an argument to the constructor.

InstallMethod(DigraphOrbits, "for a group with known generators and a list",
[IsGroup and HasGeneratorsOfGroup, IsList, IsPosInt],
function(G, domain, nr_vertices)
  local blist, sch, nr, orbs, gens, genstoapply, o, l, i, j, k;

  #TODO add checks, list should be a list of pos ints closed under the action of
  # G.
  blist := BlistList([1 .. nr_vertices], []);
  sch   := EmptyPlist(Length(domain));
  nr    := Length(domain);
  orbs  := [];
  gens  := GeneratorsOfGroup(G);
  genstoapply := [1 .. Length(gens)];

  for i in domain do
    if not blist[i] then
      o        := [i];
      blist[i] := true;
      Add(orbs, o);
      sch[i] := -Length(orbs);
      for j in o do
        for k in genstoapply do
          l := j ^ gens[k];
          if not blist[l] then
            blist[l] := true;
            Add(o, l);
            sch[l] := k;
          fi;
        od;
      od;
    fi;
  od;
  return rec(orbits := orbs, schreier := sch);
end);

InstallMethod(DigraphStabilizers, "for a group and a list",
[IsGroup, IsList], # list of orbit reps
function(G, orbit_reps);
  return List(orbit_reps, i -> Stabilizer(G, i));
end);

InstallMethod(DigraphOrbits, "for a digraph",
[IsDigraph],
function(digraph)
  local record;

  record := DigraphOrbits(DigraphGroup(digraph),
                          DigraphVertices(digraph),
                          DigraphNrVertices(digraph));
  SetDigraphSchreierVector(digraph, record.schreier);
  return record.orbits;
end);

InstallMethod(DigraphSchreierVector, "for a digraph",
[IsDigraph],
function(digraph)
  local record;

  record := DigraphOrbits(DigraphGroup(digraph),
                          DigraphVertices(digraph),
                          DigraphNrVertices(digraph));
  SetDigraphOrbits(digraph, record.orbits);
  return record.schreier;
end);

InstallMethod(DigraphOrbitReps, "for a digraph",
[IsDigraph],
function(digraph)
  return List(DigraphOrbits(digraph), x -> x[1]);
end);

InstallMethod(DigraphStabilizer, "for a digraph and a vertex",
[IsDigraph, IsPosInt],
function(digraph, rep)
  local pos, stabs;

  pos := -1 * DigraphSchreierVector(digraph)[rep];
  if pos < 0 then
    ErrorMayQuit("Digraphs: DigraphStabilizer: usage,\n");
  fi;
  stabs := DigraphStabilizers(digraph);
  if not IsBound(DigraphStabilizers(digraph)[pos]) then
    stabs[pos] := Stabilizer(DigraphGroup(digraph),
                             DigraphOrbitReps(digraph)[pos]);
  fi;
  return DigraphStabilizers(digraph)[pos];
end);

InstallMethod(DigraphStabilizers, "for a digraph",
[IsDigraph],
function(digraph);
  return [];
end);

InstallMethod(AsTransformation, "for a digraph",
[IsDigraph],
function(digraph)
  if not IsFunctionalDigraph(digraph) then
    return fail;
  fi;
  return Transformation(Concatenation(OutNeighbours(digraph)));
end);

InstallMethod(ReducedDigraph, "for a digraph",
[IsDigraph],
function(digraph)
  local old, adj, len, map, labels, i, sinkmap, sinklen, x, pos, gr;

  if IsConnectedDigraph(digraph) then
    return digraph;
  fi;

  old := OutNeighbours(digraph);

  # Extract all the non-empty lists of out-neighbours
  adj := [];
  len := 0;
  map := [];
  labels := [];
  for i in DigraphVertices(digraph) do
    if not IsEmpty(old[i]) then
      len := len + 1;
      adj[len] := ShallowCopy(old[i]);
      map[len] := i;
      labels[len] := DigraphVertexLabel(digraph, i);
    fi;
  od;

  # Renumber the contents
  sinkmap := [];
  sinklen := 0;
  for x in adj do
    for i in [1 .. Length(x)] do
      pos := PositionSet(map, x[i]);
      if pos = fail then
        # x[i] has no out-neighbours
        pos := Position(sinkmap, x[i]);
        if pos = fail then
          # x[i] has not yet been encountered
          sinklen := sinklen + 1;
          sinkmap[sinklen] := x[i];
          pos := sinklen + len;
          adj[pos] := EmptyPlist(0);
          labels[pos] := DigraphVertexLabel(digraph, x[i]);
        else
          pos := pos + len;
        fi;
      fi;
      x[i] := pos;
    od;
  od;

  # Return the reduced graph, with labels preserved
  gr := DigraphNC(adj);
  SetDigraphVertexLabels(gr, labels);
  return gr;
end);

InstallMethod(DigraphDual, "for a digraph",
[IsDigraph],
function(digraph)
  local verts, old, new, gr, i;

  if IsMultiDigraph(digraph) then
    ErrorMayQuit("Digraphs: DigraphDual: usage,\n",
                 "the argument <graph> must not have multiple edges,");
  fi;

  verts := DigraphVertices(digraph);
  old := OutNeighbours(digraph);
  new := [];

  for i in verts do
    new[i] := DifferenceLists(verts, old[i]);
  od;
  gr := DigraphNC(new);
  SetDigraphVertexLabels(gr, DigraphVertexLabels(digraph));
  return gr;
end);

#

InstallMethod(DigraphNrVertices, "for a digraph",
[IsDigraph],
function(graph)
  return graph!.nrvertices;
end);

#

InstallMethod(DigraphNrEdges, "for a digraph",
[IsDigraph], DIGRAPH_NREDGES);

#

InstallMethod(DigraphEdges, "for a digraph",
[IsDigraph],
function(graph)
  local out, adj, nr, i, j;

  out := EmptyPlist(DigraphNrEdges(graph));
  adj := OutNeighbours(graph);
  nr := 0;

  for i in DigraphVertices(graph) do
    for j in adj[i] do
      nr := nr + 1;
      out[nr] := [i, j];
    od;
  od;
  return out;
end);

# attributes for digraphs . . .

InstallMethod(AsGraph, "for a digraph", [IsDigraph], Graph);

#

InstallMethod(DigraphVertices, "for a digraph",
[IsDigraph],
function(digraph)
  return [1 .. DigraphNrVertices(digraph)];
end);

InstallMethod(DigraphRange, "for a digraph",
[IsDigraph],
function(digraph)
  DIGRAPH_SOURCE_RANGE(digraph);
  SetDigraphSource(digraph, digraph!.source);
  return digraph!.range;
end);

InstallMethod(DigraphSource, "for a digraph",
[IsDigraph],
function(digraph)
  DIGRAPH_SOURCE_RANGE(digraph);
  SetDigraphRange(digraph, digraph!.range);
  return digraph!.source;
end);

#

InstallMethod(OutNeighbours, "for a digraph",
[IsDigraph],
function(digraph)
  local out;
  if IsBound(digraph!.adj) then
    return digraph!.adj;
  fi;
  out := DIGRAPH_OUT_NBS(DigraphNrVertices(digraph),
                         DigraphSource(digraph),
                         DigraphRange(digraph));
  digraph!.adj := out;
  return out;
end);

#

InstallMethod(InNeighbours, "for a digraph",
[IsDigraph],
function(digraph)
  return DIGRAPH_IN_OUT_NBS(OutNeighbours(digraph));
end);

#

InstallMethod(AdjacencyMatrix, "for a digraph",
[IsDigraph], ADJACENCY_MATRIX);

#

InstallMethod(DigraphShortestDistances, "for a digraph",
[IsDigraph], DIGRAPH_SHORTEST_DIST);

# returns the vertices (i.e. numbers) of <digraph> ordered so that there are no
# edges from <out[j]> to <out[i]> for all <i> greater than <j>.

InstallMethod(DigraphTopologicalSort, "for a digraph",
[IsDigraph], function(graph)
  return DIGRAPH_TOPO_SORT(OutNeighbours(graph));
end);

#

InstallMethod(DigraphStronglyConnectedComponents, "for a digraph",
[IsDigraph],
function(digraph)
  local verts;

  if HasIsAcyclicDigraph(digraph) and IsAcyclicDigraph(digraph) then
    verts := DigraphVertices(digraph);
    return rec(comps := List(verts, x -> [x]), id := verts * 1);

  elif HasIsStronglyConnectedDigraph(digraph)
      and IsStronglyConnectedDigraph(digraph) then
    verts := DigraphVertices(digraph);
    return rec(comps := [verts * 1], id := verts * 0 + 1);
  fi;

  return GABOW_SCC(OutNeighbours(digraph));
end);

#

InstallMethod(DigraphConnectedComponents, "for a digraph",
[IsDigraph],
DIGRAPH_CONNECTED_COMPONENTS);

#

InstallMethod(OutDegrees, "for a digraph",
[IsDigraph],
function(digraph)
  local adj, degs, i;

  adj := OutNeighbours(digraph);
  degs := EmptyPlist(DigraphNrVertices(digraph));
  for i in DigraphVertices(digraph) do
    degs[i] := Length(adj[i]);
  od;
  return degs;
end);

#

InstallMethod(InDegrees, "for a digraph with in neighbours",
[IsDigraph and HasInNeighbours],
function(digraph)
  local inn, degs, i;

  inn := InNeighbours(digraph);
  degs := EmptyPlist(DigraphNrVertices(digraph));
  for i in DigraphVertices(digraph) do
    degs[i] := Length(inn[i]);
  od;
  return degs;
end);

#

InstallMethod(InDegrees, "for a digraph",
[IsDigraph],
function(digraph)
  local adj, degs, x, i;

  adj := OutNeighbours(digraph);
  degs := [1 .. DigraphNrVertices(digraph)] * 0;
  for x in adj do
    for i in x do
      degs[i] := degs[i] + 1;
    od;
  od;
  return degs;
end);

#

InstallMethod(OutDegreeSequence, "for a digraph",
[IsDigraph],
function(digraph)
  local out;

  out := ShallowCopy(OutDegrees(digraph));
  Sort(out,
       function(a, b)
         return b < a;
       end);
  return out;
end);

#

InstallMethod(OutDegreeSequence, "for a digraph",
[IsDigraph and HasDigraphGroup],
function(digraph)
  local out, adj, orbs, orb;

  out := [];
  adj := OutNeighbours(digraph);
  orbs := DigraphOrbits(digraph);
  for orb in orbs do
    Append(out, [1 .. Length(orb)] * 0 + Length(adj[orb[1]]));
  od; 
  return out;
end);

#

InstallMethod(OutDegreeSet, "for a digraph",
[IsDigraph],
function(digraph)
  local out;

  out := ShallowCopy(OutDegrees(digraph));
  return Set(out);
end);

#

InstallMethod(InDegreeSequence, "for a digraph",
[IsDigraph],
function(digraph)
  local out;

  out := ShallowCopy(InDegrees(digraph));
  Sort(out,
       function(a, b)
         return b < a;
       end);
  return out;
end);

#

InstallMethod(InDegreeSequence, "for a digraph",
[IsDigraph and HasDigraphGroup and HasInNeighbours],
function(digraph)
  local out, adj, orbs, orb;

  out := [];
  adj := InNeighbours(digraph);
  orbs := DigraphOrbits(digraph);
  for orb in orbs do
    Append(out, [1 .. Length(orb)] * 0 + Length(adj[orb[1]]));
  od; 
  return out;
end);

#

InstallMethod(InDegreeSet, "for a digraph",
[IsDigraph],
function(digraph)
  local out;

  out := ShallowCopy(InDegrees(digraph));
  return Set(out);
end);

#

InstallMethod(DigraphSources, "for a digraph with in-degrees",
[IsDigraph and HasInDegrees], 3,
function(digraph)
  local degs;

  degs := InDegrees(digraph);
  return Filtered(DigraphVertices(digraph), x -> degs[x] = 0);
end);

InstallMethod(DigraphSources, "for a digraph with in-neighbours",
[IsDigraph and HasInNeighbours],
function(digraph)
  local inn, sources, count, i;

  inn := InNeighbours(digraph);
  sources := EmptyPlist(DigraphNrVertices(digraph));
  count := 0;
  for i in DigraphVertices(digraph) do
    if IsEmpty(inn[i]) then
      count := count + 1;
      sources[count] := i;
    fi;
  od;
  ShrinkAllocationPlist(sources);
  return sources;
end);

InstallMethod(DigraphSources, "for a digraph",
[IsDigraph],
function(digraph)
  local verts, out, seen, v, i;

  verts := DigraphVertices(digraph);
  out := OutNeighbours(digraph);
  seen := BlistList(verts, []);
  for v in out do
    for i in v do
      seen[i] := true;
    od;
  od;
  return Filtered(verts, x -> not seen[x]);
end);

#

InstallMethod(DigraphSinks, "for a digraph with out-degrees",
[IsDigraph and HasOutDegrees],
function(digraph)
  local degs;

  degs := OutDegrees(digraph);
  return Filtered(DigraphVertices(digraph), x -> degs[x] = 0);
end);

InstallMethod(DigraphSinks, "for a digraph",
[IsDigraph],
function(digraph)
  local out, sinks, count, i;

  out   := OutNeighbours(digraph);
  sinks := [];
  count := 0;
  for i in DigraphVertices(digraph) do
    if IsEmpty(out[i]) then
      count := count + 1;
      sinks[count] := i;
    fi;
  od;
  return sinks;
end);

#

InstallMethod(DigraphPeriod, "for a digraph",
[IsDigraph],
function(digraph)
  local comps, out, deg, nrvisited, period, current, stack, len, depth,
  olddepth, i;

  if HasIsAcyclicDigraph(digraph) and IsAcyclicDigraph(digraph) then
    return 0;
  fi;

  comps := DigraphStronglyConnectedComponents(digraph)!.comps;
  out := OutNeighbours(digraph);
  deg := OutDegrees(digraph);

  nrvisited := [1 .. Length(DigraphVertices(digraph))] * 0;
  period := 0;

  for i in [1 .. Length(comps)] do
    stack := [comps[i][1]];
    len := 1;
    depth := EmptyPlist(Length(DigraphVertices(digraph)));
    depth[comps[i][1]] := 1;
    while len <> 0 do
      current := stack[len];
      if nrvisited[current] = deg[current] then
        len := len - 1;
      else
        nrvisited[current] := nrvisited[current] + 1;
        len := len + 1;
        stack[len] := out[current][nrvisited[current]];
        olddepth := depth[current];
        if IsBound(depth[stack[len]]) then
          period := GcdInt(period, depth[stack[len]] - olddepth - 1);
          if period = 1 then
            return period;
          fi;
        else
          depth[stack[len]] := olddepth + 1;
        fi;
      fi;
    od;
  od;

  if period = 0 then
    SetIsAcyclicDigraph(digraph, true);
  fi;

  return period;
end);

#

InstallMethod(DigraphDiameter, "for a digraph",
[IsDigraph],
function(digraph)
  local outer_reps, out_nbs, diameter, girth, v, orbs, i, orbnum, reps, next, laynum, localGirth, layers, nprev, nhere, nnext, lnum, x, y;

  if DigraphNrVertices(digraph) = 0 then
    return - 1;
  elif not IsStronglyConnectedDigraph(digraph) then
    return - 1;
  fi;

  #TODO improve this, really check if the complexity is better with the group
  #or without, or if the group is not known, but the number of vertices makes
  #the usual algorithm impossible.
  #if not (HasDigraphGroup(digraph) and Size(DigraphGroup(digraph)) > 1) then
  #  return DIGRAPH_DIAMETER(digraph);
  #fi;

  outer_reps := DigraphOrbitReps(digraph);
  out_nbs    := OutNeighbours(digraph);
  diameter   := 0;
  girth      := 0;

  for i in [1 .. Length(outer_reps)] do
    v := outer_reps[i];
    orbs := DIGRAPHS_OrbitNumbers(DigraphStabilizer(digraph, v),
                                  v,
                                  DigraphNrVertices(digraph));

    i               := 1;
    orbnum          := orbs.orbitNumbers;
    reps            := orbs.representatives;
    next            := [orbnum[v]];
    laynum          := [1 .. Length(reps)] * 0;
    laynum[next[1]] := 1;
    localGirth      := -1;
    layers          := [next];

    while Length(next) > 0 do
      next := [];
      for x in layers[i] do
        nprev := 0;
        nhere := 0;
        nnext := 0;
        for y in out_nbs[reps[x]] do
          lnum := laynum[orbnum[y]];
          if i > 1 and lnum = i - 1 then
            nprev := nprev + 1;
          elif lnum = i then
            nhere := nhere + 1;
          elif lnum = i + 1 then
            nnext := nnext + 1;
          elif lnum = 0 then
            AddSet(next, orbnum[y]);
            nnext := nnext + 1;
            laynum[orbnum[y]] := i + 1;
          fi;
        od;
        if (localGirth = -1 or localGirth = 2 * i - 1) and nprev > 1 then
          localGirth := 2 * (i - 1);
        fi;
        if localGirth = -1 and nhere > 0 then
          localGirth := 2 * i - 1;
        fi;
      od;
      if Length(next) > 0 then
        i := i + 1;
        layers[i] := next;
      fi;
    od;

    if Length(layers) - 1 > diameter then
      diameter := Length(layers) - 1;
    fi;
    if localGirth > girth then 
      girth := localGirth;
    fi;
  od;
  SetDigraphGirth(digraph, girth);
  return diameter;
end);

#

InstallMethod(DigraphSymmetricClosure, "for a digraph",
[IsDigraph],
function(digraph)
  local n, verts, mat, new, x, gr, i, j, k;

  n := DigraphNrVertices(digraph);
  if not (HasIsSymmetricDigraph(digraph) and IsSymmetricDigraph(digraph))
      and n > 1 then
    verts := [1 .. n]; # We don't want DigraphVertices as that's immutable
    mat := List(verts, x -> verts * 0);
    new := OutNeighboursCopy(digraph);
    for i in verts do
      for j in new[i] do
        if j < i then
          mat[j][i] := mat[j][i] - 1;
        else
          mat[i][j] := mat[i][j] + 1;
        fi;
      od;
    od;
    for i in verts do
      for j in [i + 1 .. n] do
        x := mat[i][j];
        if x > 0 then
          for k in [1 .. x] do
            Add(new[j], i);
          od;
        elif x < 0 then
          for k in [1 .. -x] do
            Add(new[i], j);
          od;
        fi;
      od;
    od;
    gr := DigraphNC(new);
  else
    gr := DigraphCopy(digraph);
  fi;
  SetIsSymmetricDigraph(gr, true);
  return gr;
end);

#

InstallMethod(DigraphTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  if IsMultiDigraph(graph) then
    ErrorMayQuit("Digraphs: DigraphTransitiveClosure: usage,\n",
                 "the argument <graph> cannot have multiple edges,");
  fi;
  return DigraphTransitiveClosureNC(graph, false);
end);

#

InstallMethod(DigraphReflexiveTransitiveClosure, "for a digraph",
[IsDigraph],
function(graph)
  if IsMultiDigraph(graph) then
    ErrorMayQuit("Digraphs: DigraphReflexiveTransitiveClosure: usage,\n",
                 "the argument <graph> cannot have multiple edges,");
  fi;
  return DigraphTransitiveClosureNC(graph, true);
end);

#

InstallGlobalFunction(DigraphTransitiveClosureNC,
function(graph, reflexive)
  local adj, m, n, verts, sorted, out, trans, reflex, mat, v, u;

  # <graph> is a digraph without multiple edges
  # <reflexive> is a boolean: true if we want the reflexive transitive closure

  adj   := OutNeighbours(graph);
  m     := DigraphNrEdges(graph);
  n     := DigraphNrVertices(graph);
  verts := DigraphVertices(graph);

  # Try correct method vis-a-vis complexity
  if m + n + (m * n) < (n * n * n) then
    sorted := DigraphTopologicalSort(graph);
    if sorted <> fail then # Method for big acyclic digraphs (loops allowed)
      out   := EmptyPlist(n);
      trans := EmptyPlist(n);
      for v in sorted do
        trans[v] := BlistList(verts, [v]);
        reflex   := false;
        for u in adj[v] do
          trans[v] := UnionBlist(trans[v], trans[u]);
          if u = v then
            reflex := true;
          fi;
        od;
        if (not reflexive) and (not reflex) then
          trans[v][v] := false;
        fi;
        out[v] := ListBlist(verts, trans[v]);
        trans[v][v] := true;
      od;
      out := DigraphNC(out);
    fi;
  fi;

  # Method for small or non-acyclic digraphs
  if not IsBound(out) then
    if reflexive then
      mat := DIGRAPH_REFLEX_TRANS_CLOSURE(graph);
    else
      mat := DIGRAPH_TRANS_CLOSURE(graph);
    fi;
    out := DigraphByAdjacencyMatrixNC(mat);
  fi;

  SetIsMultiDigraph(out, false);
  SetIsTransitiveDigraph(out, true);
  return out;
end);

InstallMethod(DigraphAllSimpleCircuits,
"for a digraph",
[IsDigraph],
function(digraph)
  local UNBLOCK, CIRCUIT, out, stack, endofstack, gr, scc, n, blocked, B,
  gr_comp, comp, s, loops, i;

    UNBLOCK := function(u)
      local w;
      blocked[u] := false;
      while not IsEmpty(B[u]) do
        w := B[u][1];
        Remove(B[u], 1);
        if blocked[w] then
          UNBLOCK(w);
        fi;
      od;
    end;

    CIRCUIT := function(v, component)
      local f, buffer, dummy, w;

      f := false;
      endofstack := endofstack + 1;
      stack[endofstack] := v;
      blocked[v] := true;

      for w in OutNeighboursOfVertex(component, v) do
        if w = 1 then
          buffer := stack{[1 .. endofstack]};
          Add(out, DigraphVertexLabels(component){buffer});
          f := true;
        elif blocked[w] = false then
          dummy := CIRCUIT(w, component);
          if dummy then
            f := true;
          fi;
        fi;
      od;

      if f then
        UNBLOCK(v);
      else
        for w in OutNeighboursOfVertex(component, v) do
          if not w in B[w] then
            Add(B[w], v);
          fi;
        od;
      fi;

      endofstack := endofstack - 1;
      return f;
    end;

    out := [];
    stack := [];
    endofstack := 0;

    # TODO should we also remove multiple edges, as they create extra work?
    # Reduce the digraph, remove loops, and store the correct vertex labels
    gr := DigraphRemoveLoops(ReducedDigraph(digraph));
    if DigraphVertexLabels(digraph) <> DigraphVertices(digraph) then
      SetDigraphVertexLabels(gr, Filtered(DigraphVertices(digraph),
                                          x -> OutDegrees(digraph) <> 0));
    fi;

    # Strongly connected components of the reduced graph
    scc := DigraphStronglyConnectedComponents(gr);

    # B and blocked only need to be as long as the longest connected component
    n := Maximum(List(scc.comps, Length));
    blocked := BlistList([1 .. n], []);
    B := List([1 .. n], x -> []);

    # Perform algorithm once per connected component of the whole digraph
    for gr_comp in scc.comps do
      n := Length(gr_comp);
      if n = 1 then
        continue;
      fi;
      gr_comp := InducedSubdigraph(gr, gr_comp);
      comp := gr_comp;
      s := 1;
      while s < n do
        if s <> 1 then
          comp := InducedSubdigraph(gr_comp, [s .. n]);
          comp := InducedSubdigraph(comp,
                                    DigraphStronglyConnectedComponent(comp, 1));
        fi;

        if not IsEmptyDigraph(comp) then
          # TODO would it be faster/better to create blocked as a new BlistList?
          # Are these things already going to be initialised anyway?
          for i in DigraphVertices(comp) do
            blocked[i] := false;
            B[i] := [];
          od;
          CIRCUIT(1, comp);
          s := s + 1;
        else
          s := n;
        fi;
      od;
    od;
    loops := List(DigraphLoops(digraph), x -> [x]);
    return Concatenation(loops, out);
end);

# The following method 'DIGRAPHS_Bipartite' was written by Isabella Scott
# It is the backend to IsBipartiteDigraph, Bicomponents, and DigraphColouring
# for a 2-colouring

# Can this be improved with a simple depth 1st search to remove need for
# symmetric closure, etc?

InstallMethod(DIGRAPHS_Bipartite, "for a digraph", [IsDigraph],
function(digraph)
  local n, colour, queue, i, node, node_neighbours, root, t;

  n := DigraphNrVertices(digraph);
  if n < 2 then
    return [false, fail];
  elif IsEmptyDigraph(digraph) then
    t := Concatenation(ListWithIdenticalEntries(n - 1, 1), [2]);
    return [true, Transformation(t)];
  fi;
  digraph := DigraphSymmetricClosure(DigraphRemoveAllMultipleEdges(digraph));
  colour := ListWithIdenticalEntries(n, 0);

  #This means there is a vertex we haven't visited yet
  while 0 in colour do
    root := Position(colour, 0);
    colour[root] := 1;
    queue := [root];
    Append(queue, OutNeighboursOfVertex(digraph, root));
    while queue <> [] do
      #Explore the first element of queue
      node := queue[1];
      node_neighbours := OutNeighboursOfVertex(digraph, node);
      for i in node_neighbours do
        #If node and its neighbour have the same colour, graph is not bipartite
        if colour[node] = colour[i] then
          return [false, fail, fail];
        elif colour[i] = 0 then # Give i opposite colour to node
          if colour[node] = 1 then
            colour[i] := 2;
          else
            colour[i] := 1;
          fi;
          Add(queue, i);
        fi;
      od;
      Remove(queue, 1);
    od;
  od;
  return [true, Transformation(colour)];
end);

#

InstallMethod(DigraphBicomponents, "for a digraph", [IsDigraph],
function(digraph)
  local b;

  # Attribute only applies to bipartite digraphs
  if not IsBipartiteDigraph(digraph) then
    return fail;
  fi;
  b := KernelOfTransformation(DIGRAPHS_Bipartite(digraph)[2],
                              DigraphNrVertices(digraph));
  return b;
end);

InstallMethod(DigraphLoops, "for a digraph", [IsDigraph],
function(gr)
  if HasDigraphHasLoops(gr) and not DigraphHasLoops(gr) then
    return [];
  fi;
  return Filtered(DigraphVertices(gr), x -> x in OutNeighboursOfVertex(gr, x));
end);
