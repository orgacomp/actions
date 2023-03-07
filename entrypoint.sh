#!/bin/sh -l

cd "$GITHUB_WORKSPACE/tp1" || exit
command -v git || { apt update -y && apt install git -y ; }

test_labfiles() {
    # Remember current branch name
    work_branch="$(git rev-parse --abbrev-ref HEAD)"
    # Checkout PR target
    git fetch origin "$GITHUB_BASE_REF" --depth=1 || return 0
    git checkout "$GITHUB_BASE_REF" || return 0
    mkdir -p /tmp || true
    cp .labfiles /tmp/labfiles || return 0
    git checkout "$work_branch"
    git diff --name-only "origin/$GITHUB_BASE_REF..." >> /tmp/modified_files
    if ! cmp /tmp/labfiles /tmp/modified_files ; then
        body=$(grep -v -F -f /tmp/labfiles /tmp/modified_files)
        echo "::set-output name=corrupt::true"
        echo "::set-output name=modfiles::$body"
        return 1
    fi
}

test_labfiles || exit 1

make "$1" | tee "$1".txt
body=$(grep "Score = " "$1.txt")
echo "::set-output name=result::$body"
