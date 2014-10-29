#
# /etc/varnish/vcl_synth.vcl
#

sub vcl_synth {
    unset resp.http.Server;
    unset resp.http.X-Varnish;
    if (resp.status == 400) {
        set resp.http.Content-Type = "text/html; charset=iso-8859-1";
        synthetic({"<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>400 Bad Request</title>
</head><body>
<h1>Bad Request</h1>
</body></html>
"});
        return(deliver);
    }
    if (resp.status == 403) {
        set resp.http.Content-Type = "text/html; charset=iso-8859-1";
        synthetic({"<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>403 Forbidden</title>
</head><body>
<h1>Forbidden</h1>
<p>You don't have permission to access "} + regsub(req.url, "\?.*$", "") + {" on this server.</p>
</body></html>
"});
        return(deliver);
    }
    if (resp.status == 404) {
        set resp.http.Content-Type = "text/html; charset=iso-8859-1";
        synthetic({"<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL "} + regsub(req.url, "\?.*$", "") + {" was not found on this server.</p>
</body></html>
"});
        return(deliver);
    }
    if (resp.status == 301) {
        set resp.http.Location = resp.reason;
        set resp.reason = "Permanently";
        return(deliver);
    }
    if (resp.status == 302) {
        set resp.http.Location = resp.reason;
        set resp.reason = "Found";
        return(deliver);
    }
}