# pulltrigger
Bash script to trigger some things if the upstream git repo has changed. exectues a command (trigger) with last three arguments being branch, commit hash, and base64 encoding of the commit message. 
By default is configured to call trigger on every new commit of the master branch, and on the commits that whose message ends with "RUN BENCHMARKS"

test changes to initiate commit from remote
 aaa
