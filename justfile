_default:
  @ just --list --unsorted

# One-time post-clone setup: installs the prepare-commit-msg hook from
# scripts/git-hooks/ so every commit in this clone auto-adds the DCO
# Signed-off-by trailer. See CONTRIBUTING.md ("Developer Certificate of Origin").
setup-dev:
  #!/bin/sh
  set -eu
  git config core.hooksPath scripts/git-hooks
  chmod +x scripts/git-hooks/prepare-commit-msg
  echo "✅ DCO prepare-commit-msg hook installed for this clone"

# Symlink this checkout into Neovim's native pack path and build the parser
install-local:
  #!/bin/sh
  set -eu
  data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
  target="$data_dir/nvim/site/pack/awsum/start/awsum-nvim"
  src="{{justfile_directory()}}"
  trap 'rc=$?; [ $rc -ne 0 ] && [ -z "${__quiet_fail:-}" ] && printf "\n\n❌ awsum-nvim install failed (exit %d)\n\n" "$rc"; exit $rc' EXIT

  if [ -L "$target" ]; then
    existing=$(readlink "$target")
    if [ "$existing" = "$src" ]; then
      echo "Symlink already in place: $target -> $src"
    else
      __quiet_fail=1
      printf '\n❌ Refusing to overwrite existing symlink:\n  %s -> %s\nRun `just uninstall-local` first.\n\n' "$target" "$existing"
      exit 1
    fi
  elif [ -e "$target" ]; then
    __quiet_fail=1
    printf '\n❌ Refusing to overwrite non-symlink path: %s\n\n' "$target"
    exit 1
  else
    mkdir -p "$(dirname "$target")"
    ln -s "$src" "$target"
    echo "Symlinked: $target -> $src"
  fi

  just build-parser

  printf '\n\n✅ awsum-nvim installed successfully!\n\n'

# Remove the symlink created by install-local. Parser binary in parser/ is left intact.
uninstall-local:
  #!/bin/sh
  set -eu
  data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
  target="$data_dir/nvim/site/pack/awsum/start/awsum-nvim"
  trap 'rc=$?; [ $rc -ne 0 ] && [ -z "${__quiet_fail:-}" ] && printf "\n\n❌ awsum-nvim uninstall failed (exit %d)\n\n" "$rc"; exit $rc' EXIT

  if [ -L "$target" ]; then
    rm "$target"
    printf '\n\n✅ awsum-nvim uninstalled (removed %s)\n\n' "$target"
  elif [ -e "$target" ]; then
    __quiet_fail=1
    printf '\n❌ Refusing to remove non-symlink path: %s\n\n' "$target"
    exit 1
  else
    echo "Nothing to do — $target does not exist."
  fi

# Compile parser/awsum.{so,dll} from vendored src/parser.c + src/scanner.c
build-parser:
  nvim --headless --noplugin -c "set rtp+=." -c "lua require('awsum.build_parser').build()" -c "q"

# Re-vendor parser sources and queries from the sibling tree-sitter-awsum at <ref>
vendor-update ref:
  scripts/vendor-update.sh {{ref}}

# Verify vendored files match tree-sitter-awsum at the pinned ref (CI gates this)
check:
  scripts/check-drift.sh

# Confirm potentially dangerous actions with a specific confirmation input (e.g. version, environment name)
[private]
manual-confirmation-input message required_confirmation:
  #!/bin/sh
  set -eu

  message="{{ message }}"
  required_confirmation="{{ required_confirmation }}"

  echo "$message"
  echo "Type '$required_confirmation' to confirm:"
  read response

  if [ "$response" != "$required_confirmation" ]; then
    echo "Confirmation failed. Exiting..."
    exit 1
  fi

# Tag and push the version currently in lua/awsum/version.lua. Run after the prep PR is merged into main.
release:
  #!/bin/sh
  set -eu
  git checkout main
  git pull
  version=$(grep -m1 '^return' lua/awsum/version.lua | sed 's/.*"\(.*\)".*/\1/')
  just manual-confirmation-input "About to tag and push v$version" "$version"
  git tag -a "v$version" -m "Release $version"
  git push origin "v$version"
