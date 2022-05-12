#!/usr/bin/env bash
###############
## VARIABLES ##
###############
RELEASE_VERSION=$1

CHANGELOG_FILE=CHANGELOG.md
ITEM="## [${RELEASE_VERSION}] - $(date '+%Y-%m-%d')"


NAT='0|[1-9][0-9]*'
ALPHA_NUM='[0-9]*[A-Za-z-][0-9A-Za-z-]*'
IDENT="$NAT|$ALPHA_NUM"
FIELD='[0-9A-Za-z-]+'

SEMVER_REGEX="\
^[vV]?\
($NAT)\\.($NAT)\\.($NAT)\
(\\-(${IDENT})(\\.(${IDENT}))*)?\
(\\+${FIELD}(\\.${FIELD})*)?$"

function error {
  echo -e "$1" >&2
  exit 1
}

function validate_version {
  local version=$1
  if [[ "$version" =~ $SEMVER_REGEX ]]; then
    # if a second argument is passed, store the result in var named by $2
    if [ "$#" -eq "2" ]; then
      local major=${BASH_REMATCH[1]}
      local minor=${BASH_REMATCH[2]}
      local patch=${BASH_REMATCH[3]}
      local prere=${BASH_REMATCH[4]}
      local build=${BASH_REMATCH[8]}
      eval "$2=(\"$major\" \"$minor\" \"$patch\" \"$prere\" \"$build\")"
    else
      echo "$version"
    fi
  else
    error "version $version does not match the semver scheme 'X.Y.Z(-PRERELEASE)(+BUILD)'."
  fi
}

check_item_version() {
  if grep -Fxq "$ITEM" $CHANGELOG_FILE; then
    error "Version item already exists
  $ITEM"
  fi
}

add_compare_line_version() {
  search="\[Unreleased\]:(.+compare\/)(.+)(...HEAD)"
  changed="[Unreleased]:\1${RELEASE_VERSION}\3\n\[${RELEASE_VERSION}\]:\1\2...${RELEASE_VERSION}"
  sed -i -E "s/^${search}/${changed}/" $CHANGELOG_FILE
}

add_new_item_version() {
  new_item=$(<<<"$line" sed 's/[].*[]/\\&/g')
  sed -i "s/$new_item/## [Unreleased]\n\n\n\n\n\n\n$ITEM/" $CHANGELOG_FILE
}

process_main() {
  printf -- 'Validate semver version...\n';
  validate_version "${RELEASE_VERSION}"

  if [ -f "$CHANGELOG_FILE" ]; then
    printf -- 'Check if the version exists...\n';
    check_item_version
    while read line; do
      if [[ $line == "## [Unreleased]"* ]]; then
        printf -- 'Add new item...\n';
          add_new_item_version
        printf -- 'Change compare line...\n';
          add_compare_line_version
      fi
    done < $CHANGELOG_FILE
  else
    error "$CHANGELOG_FILE not exists"
  fi
}

process_main
