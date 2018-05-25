#!/bin/bash
set -eux

function trigger_on_update {
    sep="[][(\ {2,}|\ *->\ *)]"
    cmd=$*
    # gitupdatemsg=$(cat msg.txt | grep "\->")
    gitupdatemsg=$(git remote -v update 2>&1 | grep "\->")
    while read -r branchmsg;  do
        uptodateregex='= \[up to date\].*'
        newbranchregex='\* \[new branch\].*'
        if [[ $branchmsg =~ $uptodateregex ]]; then
            continue
        fi

        if [[ $branchmsg =~ $newbranchregex ]]; then
            branch=$(echo $branchmsg | awk '{print $5}')
            commitrange='origin..HEAD'
        else
            branch=$(echo $branchmsg | awk '{print $2}')
            commitrange=$(echo $branchmsg | awk '{print $1}')             
        fi
        
        git checkout $branch
        git pull
        commitlist=$(git rev-list --ancestry-path $commitrange)
        for commithash in $commitlist; do
            commitmsg=$(git log --format=%B -n 1 $commithash)
            commitmsg64=$(echo "$commitmsg" | base64)
            $cmd $branch $commithash $commitmsg64
            exit $?
        done        
    done <<< "$gitupdatemsg"
}

function filter_commits {
    branch=${*: -3:1}
    commithash=${*: -2:1}
    commitmsg64=${*: -1}
    commimsg=$(echo "$commitmsg64" | base64 --decode)
    
    filterregex=".*RUN BENCHMARKS"
    if [[ $branch == master ]]; then
        $*
        return $?
    fi  
    if [[ $commitmsg =~ $filterregex ]]; then
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
