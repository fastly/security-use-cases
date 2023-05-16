# vcl_fetch, https://fiddle.fastly.dev/fiddle/af2551ed
set beresp.http.log-timing:fetch = time.elapsed.usec;
set beresp.http.log-timing:misspass = req.http.log-timing:misspass;
set beresp.http.log-timing:do_stream = beresp.do_stream;

set beresp.http.log-origin:method = bereq.method;
set beresp.http.log-origin:url = bereq.url;
set beresp.http.log-origin:host = bereq.http.host;
set beresp.http.log-origin:ip = beresp.backend.ip;
set beresp.http.log-origin:port = beresp.backend.port;
set beresp.http.log-origin:name = beresp.backend.name;
set beresp.http.log-origin:status = beresp.status;
set beresp.http.log-origin:reason = beresp.response;

if (req.backend.is_origin) {
  set beresp.http.log-origin:shield = server.datacenter;
}