#!/bin/sh
set -eu

# Pull parser sources and queries from the local tree-sitter-awsum sibling repo
# at the given ref (tag or commit), overwrite our vendored copies, and update
# .tree-sitter-awsum-rev. The ref is recorded so CI can verify no drift.

ref="${1:-}"
if [ -z "$ref" ]; then
  echo "usage: $0 <tag-or-commit>" >&2
  exit 2
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
target_dir=$(cd "$script_dir/.." && pwd)
ts_repo="$target_dir/../tree-sitter-awsum"

if [ ! -d "$ts_repo/.git" ]; then
  echo "error: tree-sitter-awsum repo not found at $ts_repo" >&2
  exit 1
fi

cd "$ts_repo"
resolved=$(git rev-parse --verify "$ref^{commit}")
echo "Resolved $ref -> $resolved"

mkdir -p "$target_dir/src/tree_sitter" "$target_dir/queries/awsum"

git show "$ref:src/parser.c"             > "$target_dir/src/parser.c"
git show "$ref:src/scanner.c"            > "$target_dir/src/scanner.c"
git show "$ref:src/tree_sitter/parser.h" > "$target_dir/src/tree_sitter/parser.h"

# wipe vendored queries and re-populate from upstream — keeps the set in sync
# if upstream removes or renames a query file.
rm -f "$target_dir/queries/awsum"/*.scm
for path in $(git ls-tree -r --name-only "$ref" queries | grep '\.scm$'); do
  fname=$(basename "$path")
  git show "$ref:$path" > "$target_dir/queries/awsum/$fname"
done

echo "$ref" > "$target_dir/.tree-sitter-awsum-rev"
echo "Vendored tree-sitter-awsum at $ref"
