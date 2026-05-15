#!/bin/sh
set -eu

# Verify vendored tree-sitter sources match tree-sitter-awsum at the ref
# recorded in .tree-sitter-awsum-rev. CI gates the repo on this passing.

script_dir=$(cd "$(dirname "$0")" && pwd)
target_dir=$(cd "$script_dir/.." && pwd)
ts_repo="$target_dir/../tree-sitter-awsum"

if [ ! -f "$target_dir/.tree-sitter-awsum-rev" ]; then
  echo "error: .tree-sitter-awsum-rev not found" >&2
  exit 1
fi

if [ ! -d "$ts_repo/.git" ]; then
  echo "error: tree-sitter-awsum repo not found at $ts_repo" >&2
  exit 1
fi

ref=$(tr -d ' \n' < "$target_dir/.tree-sitter-awsum-rev")

cd "$ts_repo"
git rev-parse --verify "$ref^{commit}" > /dev/null

exit_code=0

check_one() {
  upstream_path="$1"
  vendored_path="$2"
  if ! git show "$ref:$upstream_path" | diff -q - "$target_dir/$vendored_path" > /dev/null 2>&1; then
    echo "DRIFT: $vendored_path differs from tree-sitter-awsum@$ref:$upstream_path"
    exit_code=1
  fi
}

check_one "src/parser.c"             "src/parser.c"
check_one "src/scanner.c"            "src/scanner.c"
check_one "src/tree_sitter/parser.h" "src/tree_sitter/parser.h"

# every upstream query at $ref must exist and match locally
for path in $(git ls-tree -r --name-only "$ref" queries | grep '\.scm$'); do
  fname=$(basename "$path")
  check_one "$path" "queries/awsum/$fname"
done

# any local query that does not exist upstream is also drift
for local_q in "$target_dir/queries/awsum"/*.scm; do
  [ -e "$local_q" ] || continue
  fname=$(basename "$local_q")
  if ! git cat-file -e "$ref:queries/$fname" 2>/dev/null; then
    echo "DRIFT: queries/awsum/$fname exists locally but not at tree-sitter-awsum@$ref"
    exit_code=1
  fi
done

if [ "$exit_code" -ne 0 ]; then
  echo
  echo "Run 'just vendor-update <ref>' to re-sync." >&2
  exit "$exit_code"
fi

echo "OK — vendored files match tree-sitter-awsum@$ref"
