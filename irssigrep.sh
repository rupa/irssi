#!/bin/bash
# quick irssi log grepper, doesn't track dates

# log timestamp mask
dt="[0-2][0-9]:[0-5][0-9]"

usage() {
 cat <<!
$(basename $0) [-a] [-cCOUNT] [-d] [-fFILE(s)] [-m] [-nNICK] [-tMASK] [-v] [SEARCH REGEX]
    -a        search actions only
    -cCOUNT   limit results to COUNT
    -d        put a timestamp above results
    -fFILE(s) search in FILE(s). globs are OK
    -l        jump to most recent occurrence of SEARCH
    -m        search msgs only
    -nNICK    only match utterances of NICK
    -tMASK    set timestamp mask. default: $dt
    -v        debug - print some variable values

examples:
    everything anyone said ending with "your mom"
        $(basename $0) your mom$
    everything nick said starting with "i hate"
        $(basename $0) -nnick ^i hate
    everytime anyone said "i love you" in any "chan.*" log
        $(basename $0) -f/logs/chan.* "^i love you$"

note:
    set aliases for commonly searched logs:
        alias chan="/path/to/irssigrep -f/path/to/logs/chan.\$(date +%Y)"
        alias chan-all="/path/to/irssigrep -f/path/to/logs/chan.*"

!
}

debug() {
 cat <<!
   file(s): "$fl"
      nick: "$nick"
    search: "$search"
     count: "$count"
 timestamp: "$dt"
         a: "$a"
         b: "$b"
!
}

for x; do case $x in
    -a) a=" \* "; b="";;
    -c*) count="-m ${x:2}";;
    -d) dt="$(date)\n\n";;
    -f*) files="${x:2}";;
    -h|--help) usage; exit;;
    -l) useless=1;;
    -m) a="<."; b=">";;
    -n*) nick="${x:2}";;
    -t*) dt="${x:2}";;
    -v) dbg=1;;
    *) search="$search $x";;
esac; shift; done

[ "$files" ] || {
    echo -e "ERROR: file not provided\n"
    usage
    exit
}

# reverse sort the filelist (alphabetically)
for x in $files; do fl="$x $fl"; done

# quick get with less (literal ^M)
if [ $useless ]; then
    set -- $search
    #less +"G?$*" $fl
    tac $fl | less +"/$*"
    exit
fi

# junk for matching msg lines
[ "$a" ] || {
    a="( \* |<.?)"
    b=">?"
}

# make regexes work like you'd expect
if [ "${search:1:1}" == "^" ]; then
    search=" ${search:2}"
elif [ "$search" ]; then
    search=" .*${search:1}"
fi

if [ "$dbg" ]; then
    debug
    echo $nick
else
    #echo -ne $dt
    tac $fl | egrep --line-buffered -i $count "^$dt $a${nick:-".*"}$b$search"
fi | less
