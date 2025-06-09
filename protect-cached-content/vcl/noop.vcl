sub vcl_recv {
    error 600;
}

sub vcl_error {
  if (obj.status == 600) {
    set obj.status = 200;
    set obj.response = "OK";
    return (deliver);
  }
}
