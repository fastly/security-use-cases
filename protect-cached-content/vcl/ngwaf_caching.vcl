# vcl_init

backend F_dummy_origin {
  .between_bytes_timeout = 10s;
  .connect_timeout = 1s;
  .first_byte_timeout = 1s;
  .host = "127.0.0.1";
  .max_connections = 200;
  .port = "80";
  .share_key = "CFIpMui8uetgTCmdgzlBQ5";
}

sub vcl_recv {
  set req.http.Fastly-Force-Shield = "1";
}

sub vcl_hit {
  if (req.restarts < 1) {
      set req.http.is-hit = "true";
      return(pass);
  }
}

# sub vcl_miss {
#   if (req.http.dummy == "1") {
#     set req.backend = F_dummy_origin;
#   }
# }

sub vcl_pass {
  if (req.http.is-hit == "true") {
    set req.backend = F_dummy_origin;
  }
  # if (req.http.dummy == "1") {
  #   set req.backend = F_dummy_origin;
  # }
}

sub vcl_fetch {
  if (req.http.is-hit == "true") {
      if (req.restarts < 1) {
        # unset the req header before trying to set it to prevent spoofing
        unset req.http.ngwaf-action;
        # If BLOCKED is not present, then do a restart
        if (beresp.http.x-sigsci-tags ~ "BLOCKED") {
          set req.http.ngwaf-action = "1";
        }
        # If CHALLENGED is present, then do NOT restart
        if (beresp.http.x-sigsci-tags ~ "CHALLENGED") {
          set req.http.ngwaf-action = "1";
        }

        # If there is no action, then restart and serve content from cache
        if (req.http.ngwaf-action != "1") {
          set req.http.x-restart-reason = "ngwaf-action=none";
          restart;
        }
      }
  }
}

sub vcl_deliver {
    # stash response headers in request so they can be used in logging when using shielding
    if(fastly.ff.visits_this_service == 0){
      set resp.http.sigsci-agentresponse = resp.http.x-sigsci-agentresponse;
      set resp.http.sigsci-decision-ms = resp.http.x-sigsci-decision-ms;
      set resp.http.sigsci-tags = resp.http.x-sigsci-tags;
    }
}

# https://dashboard.signalsciences.net/api/v0/corps/{CORP_SHORT_NAME}/sites/{WORKSPACE_SHORT_NAME}/responses

# if a rule is hit and there are no other block rules ... then return a 567

