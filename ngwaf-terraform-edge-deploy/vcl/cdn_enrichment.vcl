#vcl_recv

if(fastly.ff.visits_this_service == 0 && req.restarts == 0){
    set req.http.Fastly-Client-IP = client.ip;
    set req.http.Client-JA3 = tls.client.ja3_md5;
    set req.http.asn = client.as.number;
    set req.http.proxy-type = client.geo.proxy_type;
    set req.http.proxy-desc = client.geo.proxy_description;
}
