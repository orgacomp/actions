#!/bin/sh -l
set -x
cd "$GITHUB_WORKSPACE/$GITHUB_BASE_REF" || exit
git config --global --add safe.directory $GITHUB_WORKSPACE

test_labfiles() {
    # Remember current branch name
    work_branch=$GITHUB_HEAD_REF
    # Checkout PR target
    git fetch origin "$GITHUB_BASE_REF" --depth=1 || return 0
    git checkout "$GITHUB_BASE_REF" || return 0
    mkdir -p /tmp || true
    cp .labfiles /tmp/labfiles || return 0
    git checkout "$work_branch"
    git diff --name-only "origin/$GITHUB_BASE_REF..." >> /tmp/modified_files
    if ! cmp /tmp/labfiles /tmp/modified_files ; then
        body=$(grep -v -F -f /tmp/labfiles /tmp/modified_files)
        echo 'corrupt=true' >> $GITHUB_OUTPUT
        echo 'modfiles=$body' >> $GITHUB_OUTPUT
        return 1
    fi
}

test_labfiles || exit 1
exit 1
make "$1" | tee "$1".txt
body=$(grep "Score = " "$1.txt")
echo 'result=$body' >> $GITHUB_OUTPUT
