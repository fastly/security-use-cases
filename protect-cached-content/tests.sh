#!/bin/bash

#### not blocked request
for i in {1..10} ; do 
    printf $i
    curl -i -sD - -o /dev/null \
        "https://bcunning-caching.global.ssl.fastly.net/anything/apple=theargs" | grep "X-Cache:"
done
# expect cache hits

#### blocked request
curl -s \
    -H 'pirate:1'\
    "https://bcunning-caching.global.ssl.fastly.net/anything/apple=theargs"
# expect 406


#### RL demo
# for i in {1..10} ; do 
#     sleep 2
#     curl -is 'https://bcunning-ngwaf-lab.global.ssl.fastly.net/anything/graphql' \
#     -H 'Connection: keep-alive' \
#     -H 'Origin: https://bcunning-ngwaf-graphql.global.ssl.fastly.net' \
#     -H 'Referer: https://bcunning-ngwaf-graphql.global.ssl.fastly.net/' \
#     -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36' \
#     -H 'accept: application/json, multipart/mixed' \
#     -H 'content-type: application/graphql' \
#     --data-raw $'query GetUser($id: ID!) {  # Duplicate variable definition!
#     user(foo: "alice") {
#         id
#         name
#     }
#     }' | head -n1
# done

