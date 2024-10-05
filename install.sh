#!/bin/zsh
set -euo pipefail

function main() {
    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    pushd "$TEMP_DIR" > /dev/null

    # Get latest version
    LATEST_VERSION=$(curl -s -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/macvmio/curie/releases/latest)

    TAG_NAME=$(printf "%s\n" "$LATEST_VERSION" | python3 -c "import sys, json; print(json.load(sys.stdin)['tag_name'])")
    PKG_URL=$(printf "%s\n" "$LATEST_VERSION" | python3 -c "import sys, json; print(json.load(sys.stdin)['assets'][1]['browser_download_url'])")
    CURIE_FILENAME="curie-$TAG_NAME.pkg"

    # Download .pkg file
    echo "Will download $CURIE_FILENAME (latest version)"
    curl --progress-bar -L -o "$CURIE_FILENAME" "$PKG_URL" 

    # Verify signature
    echo "Will check $CURIE_FILENAME signature"
    pkgutil --check-signature "$CURIE_FILENAME" > /dev/null

    # Install (requires sudo)
    echo "Will install $CURIE_FILENAME in /usr/local/bin/ (requires sudo)"
    sudo installer -pkg "$CURIE_FILENAME" -target /usr/local/bin/ > /dev/null

    popd > /dev/null

    echo "Installation completed"
}

main
