# vcl_init

# noop backend is used so that the NGWAF may quickly inspect requests that are cache HIT.
backend F_noop_origin {
  .between_bytes_timeout = 10s;
  .connect_timeout = 1s;
  .first_byte_timeout = 1s;
  .host = "noop-caching.global.ssl.fastly.net";
  .host_header = "noop-caching.global.ssl.fastly.net";
  .always_use_host_header = true;
  .max_connections = 200;
  .port = "443";
  .ssl = true;
  .max_tls_version = "1.3";
  .min_tls_version = "1.1";
  .ssl_cert_hostname = "noop-caching.global.ssl.fastly.net";
  .ssl_check_cert = always;
  .ssl_sni_hostname = "noop-caching.global.ssl.fastly.net";
  .probe = {
        .dummy = true;
        .initial = 5;
        .request = "HEAD / HTTP/1.1"  "Host: noop-caching.global.ssl.fastly.net" "Connection: close";
        .threshold = 1;
        .timeout = 2s;
        .window = 5;
  }
}

# force cluster for all requests and on restarts. https://www.fastly.com/documentation/guides/vcl/clustering/#enabling-and-disabling-clustering
sub vcl_recv {
  set req.http.Fastly-Force-Shield = "1";

  # enable ngwaf logging headers
  if (req.restarts == 0 && fastly.ff.visits_this_service == 0) {
    set req.http.X-Sigsci-Response-Headers = "true";
  }
}

# On cache hit, send the request to NGWAF
sub vcl_hit {
  if (req.restarts < 1
    && !req.http.X-SigSci-No-Inspection) {
    # Exclude static files from cache HIT NGWAF inspection
    if (!(req.url.ext ~ "(?i)^(js|css|tff|woff|ico|png|jpg|jpeg)$")) {
      set req.http.X-SigSci-Cached-Inspect = "HIT";
      return(pass);
    }  
  }
}

# When there is a cache HIT, set the noop backend origin.
sub vcl_pass {
  if (req.http.X-SigSci-Cached-Inspect == "HIT") {
    set req.backend = F_noop_origin;
  }
}

# If BLOCKED or CHALLENGED is present, then return that response to the client
# If there is no action, then restart and serve content from cache
sub vcl_fetch {
  if (req.http.X-SigSci-Cached-Inspect == "HIT"
  && req.restarts < 1
  && !(beresp.http.X-SigSci-Tags ~ "(BLOCKED|CHALLENGED)")) {
      set req.http.x-restart-reason = "ngwaf-action=none";
      restart;
  }
}
