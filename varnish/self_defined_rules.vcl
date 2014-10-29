#
# /etc/varnish/vfw/custom_block.vcl
#

sub vcl_recv {
    # req.http.User-Agent
    # req.url

    if (req.http.User-Agent ~ "^(Java|Python\-urllib)" ||
        (req.http.User-Agent ~ "CFNetwork" && req.http.User-Agent ~ "Darwin") ||
        req.http.User-Agent ~ "^$") {
        return(synth(404));
    }
    elseif (req.http.User-Agent ~ "Firefox/3.6.16") {
        return(synth(901));
    }
}

sub vcl_synth {
    unset resp.http.Server;
    unset resp.http.X-Varnish;
    if (resp.status == 901) {
        set resp.status = 200;
        set resp.http.Content-Type = "text/html";
        synthetic({"<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>Please upgrade your firefox.</title>
</head><body>
<p>Your Firefox is too old, please <a href='http://www.firefox.com/'>upgrade</a>.</p>
</body></html>
"});
        return(deliver);
    }
}