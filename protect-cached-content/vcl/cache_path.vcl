# vcl_hash
# Add the path and generation to the hash.
# if (req.url.path ~ "/_fs-ch-1T1wmsGaOgGaSxcX/script.js") {
#     set req.hash += req.url;
#     set req.hash += req.http.host;
#     set req.hash += req.vcl.generation;
#     return (hash);
# }

# cache req.url.path instead of req.url
set req.hash += req.url.path;
set req.hash += req.http.host;
set req.hash += req.vcl.generation;
return (hash);
