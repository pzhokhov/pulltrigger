#!/bin/bash
set -eux

function trigger_on_update {
    cmd=$*
    gitupdatemsg=$(git remote update 2>&1)
    # gitupdatemsg=$(cat msg.txt)
    branchlist=$(echo "$gitupdatemsg" | grep "\->" | awk '{print $2}')
    for branch in $branchlist; do
        commitrange=$(echo "$gitupdatemsg" | grep "\->" | grep $branch | awk '{print $1}')
        commitlist=$(git rev-list --ancestry-path $commitrange)

        for commithash in $commitlist; do
            commitmsg=$(git log --format=%B -n 1 $commithash)
            commitmsg64=$(echo "$commitmsg" | base64)
            $cmd $branch $commithash $commitmsg64
        done
    done
}

function filter_commits {
    branch=${*: -3:1}
    commithash=${*: -2:1}
    commitmsg64=${*: -1}
    commimsg=$(echo "$commitmsg64" | base64 --decode)

    if [[ $branch == master ]]; then
        $*
        return $?
    fi  
    if [[ $commitmsg =~ ".*RUN BENCHMARKS\Z" ]]; then
        $*
        return $?
    fi 
}

while true; 
do
    trigger_on_update filter_commits $1
    sleep 5
done
