"""

    $ python invert_paths.py ../Data/tiny-paths.json ../Data/tiny-walls-2.json

    Total possible adjacencies: 40
    Open passages (edges):      25
    Walls:                      16
    Written to ../Data/tiny-walls-2.json

Given a maze export JSON (with meta, nodes, edges), produce the
_inverted_ wall list.

In the grid every cell has up to 4 neighbours (up, down, left, right).
The `edges` are open passages. The walls are all adjacent pairs that
are NOT in edges.

A cell with 1 open passage and 3 grid neighbours therefore gets 3 walls.

Usage:

    python maze_walls.py standalone_maze_out.json walls_out.json

Output shape:

    {
      "meta": { ... },
      "walls": [ [a, b], [a, b], ... ]
    }

Each wall entry is an [a, b] pair of adjacent cell indices (a < b)
between which a wall exists.
"""

import json
import argparse
import pathlib


def get_all_adjacencies(rows, cols):
    """Yield every pair of adjacent cells in the grid (right and down only,
    so each pair appears exactly once with smaller index first)."""
    for r in range(rows):
        for c in range(cols):
            index = r * cols + c
            # right neighbour
            if c + 1 < cols:
                yield (index, index + 1)
            # down neighbour
            if r + 1 < rows:
                yield (index, index + cols)


def compute_walls(data):
    meta = data["meta"]
    rows = meta["rows"]
    cols = meta["cols"]

    # Build a set of open passages as undirected sorted tuples.
    open_passages = set()
    for a, b in data["edges"]:
        pair = (min(a, b), max(a, b))
        open_passages.add(pair)

    # Every possible adjacency minus the open passages = walls.
    walls = []
    for pair in get_all_adjacencies(rows, cols):
        if pair not in open_passages:
            walls.append(list(pair))

    return walls


def main():
    parser = argparse.ArgumentParser(
        description="Convert a maze export to a wall list (the inverse of edges)."
    )
    parser.add_argument("input_file", type=pathlib.Path)
    parser.add_argument("output_file", type=pathlib.Path)
    args = parser.parse_args()

    if not args.input_file.exists():
        print(f"Input file {args.input_file} does not exist.")
        return

    data = json.loads(args.input_file.read_text())
    walls = compute_walls(data)

    meta = data["meta"]
    total_adj = (
        meta["rows"] * (meta["cols"] - 1)   # pairs sharing a row (right neighbours)
        + (meta["rows"] - 1) * meta["cols"] # pairs sharing a col (down neighbours)
    )

    result = {
        "meta": data["meta"],
        "walls": walls,
    }

    args.output_file.write_text(json.dumps(result, indent=2))

    print(f"Total possible adjacencies: {total_adj}")
    print(f"Open passages (edges):      {len(data['edges'])}")
    print(f"Walls:                      {len(walls)}")
    print(f"Written to {args.output_file}")


if __name__ == "__main__":
    main()
