# vcl_init

# If there is a cache hit, then the request first goes to the NGWAF.
# If the Fastly NGWAF returns a block via a 406, then the block will be returned back to the client.
# If the Fastly NGWAF returns a block via a 567, then a VCL restart occurs
# the restarted request may then be served from cache. 

sub vcl_recv {
  set req.http.Fastly-Force-Shield = "1";
}

sub vcl_hit {
  if (req.restarts < 1) {
      set req.http.is-hit = "true";
      return(pass);
  } 
  # else {
  #     return(deliver);
  # }
}

sub vcl_fetch {
  if (req.http.is-hit == "true") {
      if (req.restarts < 1) {
        # If the waf inspection has "thumbsup" in the location header, then restart
        # Return a response from cache if possible
        # Otherwise, continue to the origin. Restarted request will not go through WAF

        if (beresp.http.location == "thumbsup") {            
          restart; 
        }
        if (beresp.status == 567) {
          restart; 
        }
        # If the waf does a block, then return the block. Do NOT restart
        # if (beresp.status == 406) {
        #   set req.http.is-bad = "true";
        # }
        # Other case with Fastly Bot Management
        # The NGWAF may return a 200 response for a challenge.
      }
  }
    
}

# https://dashboard.signalsciences.net/api/v0/corps/{CORP_SHORT_NAME}/sites/{WORKSPACE_SHORT_NAME}/responses

# if a rule is hit and there are no other block rules ... then return a 567

# How to test
###
# http https://bcunning-caching.global.ssl.fastly.net/anything/hookinheader11  -p=h | head -n1
# http https://bcunning-caching.global.ssl.fastly.net/anything/hookinheader11  -p=h | head -n1
# http https://bcunning-caching.global.ssl.fastly.net/anything/hookinheader2 block:1 -p=h | head -n1
# http https://bcunning-caching.global.ssl.fastly.net/anything/hookinheader2 pirate:1 -p=h | head -n1
###