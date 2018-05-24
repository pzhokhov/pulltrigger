#!/bin/bash
set -eux

function trigger_on_update {
    sep="(\ {2,}|\ *->\ *)"
    cmd=$*
    gitupdatemsg=$(git remote -v update 2>&1 | grep "\->")

    # gitupdatemsg=$(cat msg.txt | grep "\->")
    branchlist=$(echo "$gitupdatemsg" | awk -F "$sep" '{print $2}')

    for branch in $branchlist; do
        commitrange=$(echo "$gitupdatemsg" | grep $branch | awk -F "$sep" '{print $1}')
        
        if [[ $commitrange == ' = [up to date]' ]]; then
            continue
        fi
        if [[ $commitrange == ' * [new branch]' ]]; then
            continue
        fi
    
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

git fetch origin
while true; 
do
    trigger_on_update filter_commits $1
    sleep 5
done
