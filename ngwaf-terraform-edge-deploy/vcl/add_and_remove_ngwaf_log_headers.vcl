# vcl init

sub vcl_recv {
    # enable ngwaf logging headers
    if (req.restarts == 0) {
		if (fastly.ff.visits_this_service == 0) {
            set req.http.X-Sigsci-Response-Headers = "true";
        }
    }
}

# unset the sensitive headers before delivering to the client.
sub vcl_deliver {
    #FASTLY deliver
    set req.http.x-sigsci-agentresponse = resp.http.x-sigsci-agentresponse;
    set req.http.x-sigsci-decision-ms = resp.http.x-sigsci-decision-ms;
    set req.http.x-sigsci-tags = resp.http.x-sigsci-tags;

    unset resp.http.x-sigsci-agentresponse;
    unset resp.http.x-sigsci-decision-ms;
    unset resp.http.x-sigsci-tags;
}
