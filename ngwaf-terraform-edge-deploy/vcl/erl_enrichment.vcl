#vcl_init

penaltybox rl_default_pb {}
ratecounter rl_default_rc {}

sub rate_limit_process {
  if(fastly.ff.visits_this_service == 0 && req.restarts == 0){

    declare local var.rl_client_id STRING;
    # set var.rl_client_id = req.http.rl-key;
    set var.rl_client_id = client.ip;

    # unset the request header if it exists.
    unset bereq.http.erl-60s;

    if (std.strlen(var.rl_client_id) > 0){
        if(ratelimit.check_rate(
            var.rl_client_id, # identifier
            rl_default_rc, #rate counter
            1, # delta
            60, # window
            100, # limit
            rl_default_pb, #penalty box
            2m
            )){
                set bereq.http.erl-60s = "99999";
            } else {
                set bereq.http.erl-60s = ratecounter.rl_default_rc.bucket.60s;
            }
        }
    }
}

sub vcl_miss {
    call rate_limit_process;
}

sub vcl_pass {
    call rate_limit_process;
}