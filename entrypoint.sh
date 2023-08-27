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
    output=$(grep -v -F -f /tmp/labfiles /tmp/modified_files)
    if [ -n "$output" ] ; then
        body=$output
        
        echo "### Se rechaza el PR :( " >> $GITHUB_STEP_SUMMARY
        echo "#### Los siguientes archivos no pueden ser modificados" >> $GITHUB_STEP_SUMMARY
        echo "$body" >> $GITHUB_STEP_SUMMARY

        return 1
    fi
}

ls -al
cd code
make tester
./tester | tee tester.txt
RETURN=${PIPESTATUS[0]}

echo "### Test results" >> $GITHUB_STEP_SUMMARY
echo '```console'>> $GITHUB_STEP_SUMMARY
echo "$(cat tester.txt)" >> $GITHUB_STEP_SUMMARY
echo '```'
exit $RETURN