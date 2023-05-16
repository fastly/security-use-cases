# vcl recv

# enable ngwaf logging headers
if (req.restarts == 0 && fastly.ff.visits_this_service == 0) {
    set req.http.X-Sigsci-Response-Headers = "true";
}

