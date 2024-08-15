sub vcl_recv {
    if (req.url ~ "/fastly/logo") {
        set req.url = "/static-assets/challenge-robot.jpg";
    }
}