#!/bin/bash -l
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
    git fetch origin "$work_branch"
    git checkout "$work_branch"
    git diff --name-only "origin/$GITHUB_BASE_REF..." >> /tmp/modified_files
    cat /tmp/modified_files
    cat /tmp/labfiles
    if ! cmp /tmp/labfiles /tmp/modified_files ; then
        body=$(grep -v -F -f /tmp/labfiles /tmp/modified_files)
        
        echo "### Se rechaza el PR :( " >> $GITHUB_STEP_SUMMARY
        echo "#### Los siguientes archivos no pueden ser modificados" >> $GITHUB_STEP_SUMMARY
        echo "$body" >> $GITHUB_STEP_SUMMARY

        return 1
    fi
}

test_labfiles || exit 1

make "$1" | tee "$1".txt
RETURN=${PIPESTATUS[0]}
body=$(grep "Score = " "$1.txt")


echo "### $1 results" >> $GITHUB_STEP_SUMMARY
echo '```console'>> $GITHUB_STEP_SUMMARY
echo "$(cat "$1".txt)" >> $GITHUB_STEP_SUMMARY
echo '```'
echo "result=$body" >> $GITHUB_OUTPUT
exit $RETURN