#!/bin/bash

#### not blocked request
echo "not blocked request"; echo
for i in {1..10} ; do 
    printf $i
    curl -i -sD - -o /dev/null \
        "https://bcunning-caching.global.ssl.fastly.net/anything/apple=theargs" | grep "X-Cache:"
done
# expect cache hits

#### blocked request
echo; echo "blocked request"; echo;
curl -is \
    "https://bcunning-caching.global.ssl.fastly.net/anything/apple=theargs" \
    -H 'pirate:1' | head -n1
# expect 406

#### bot challenge
echo; echo "client challenge"; echo;
curl -is \
    "https://bcunning-caching.global.ssl.fastly.net/anything/login" \
    | grep 'set-cookie'


#### RL demo
echo; echo "rate limiting"; echo;
for i in {1..10} ; do 
    sleep 2
    curl -is 'https://bcunning-ngwaf-lab.global.ssl.fastly.net/status/200' -H api-key:foo1 | head -n1
done

