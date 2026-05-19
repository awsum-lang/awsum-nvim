#!/bin/sh
set -eu

# Pull parser sources and queries from the sibling tree-sitter-awsum repo,
# overwrite our vendored copies, and update .tree-sitter-awsum-rev.
#
# Two modes:
#   <tag-or-commit>  — reproducible: read files via `git show <ref>:path`.
#                      Used at release time. The ref is recorded as-is in
#                      .tree-sitter-awsum-rev so CI's release-time drift-check
#                      can verify reproducibility against the same upstream
#                      commit.
#   local            — dev-time: copy files from the sibling's working tree
#                      (uncommitted changes welcome). Records `local` in
#                      .tree-sitter-awsum-rev — a sentinel that any release
#                      run will refuse (it's not a valid git ref upstream),
#                      so you cannot accidentally tag a release with
#                      non-reproducible vendoring.

ref="${1:-}"
if [ -z "$ref" ]; then
  echo "usage: $0 <tag-or-commit> | local" >&2
  exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
target_dir=$(cd "$script_dir/.." && pwd)
ts_repo="$target_dir/../tree-sitter-awsum"

if [ ! -d "$ts_repo/.git" ]; then
  echo "error: tree-sitter-awsum repo not found at $ts_repo" >&2
  exit 1
fi

mkdir -p "$target_dir/src/tree_sitter" "$target_dir/queries/awsum"

# wipe vendored queries and re-populate from upstream — keeps the set in sync
# if upstream removes or renames a query file. Done in both modes.
rm -f "$target_dir/queries/awsum"/*.scm

if [ "$ref" = "local" ]; then
  if [ ! -f "$ts_repo/src/parser.c" ]; then
    echo "error: $ts_repo/src/parser.c missing — run 'npx tree-sitter generate' in the sibling first" >&2
    exit 1
  fi
  cp "$ts_repo/src/parser.c"             "$target_dir/src/parser.c"
  cp "$ts_repo/src/scanner.c"            "$target_dir/src/scanner.c"
  cp "$ts_repo/src/tree_sitter/parser.h" "$target_dir/src/tree_sitter/parser.h"
  for path in "$ts_repo/queries"/*.scm; do
    [ -e "$path" ] || continue
    cp "$path" "$target_dir/queries/awsum/$(basename "$path")"
  done
  echo "local" > "$target_dir/.tree-sitter-awsum-rev"
  echo "Vendored tree-sitter-awsum from sibling working tree (recorded as 'local' — release will refuse this until re-vendored from a tag)"
  exit 0
fi

cd "$ts_repo"
resolved=$(git rev-parse --verify "$ref^{commit}")
echo "Resolved $ref -> $resolved"

git show "$ref:src/parser.c"             > "$target_dir/src/parser.c"
git show "$ref:src/scanner.c"            > "$target_dir/src/scanner.c"
git show "$ref:src/tree_sitter/parser.h" > "$target_dir/src/tree_sitter/parser.h"

for path in $(git ls-tree -r --name-only "$ref" queries | grep '\.scm$'); do
  fname=$(basename "$path")
  git show "$ref:$path" > "$target_dir/queries/awsum/$fname"
done

echo "$ref" > "$target_dir/.tree-sitter-awsum-rev"
echo "Vendored tree-sitter-awsum at $ref"
