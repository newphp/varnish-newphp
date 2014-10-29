vcl 4.0;
# Based on: https://github.com/mattiasgeniar/varnish-4.0-configuration-templates/blob/master/default.vcl
# Corrected & improved for 4.0.2 by jnerin@gmail.com
import std;
import directors;

C{
    #include <syslog.h>
}C

backend default {
    .host = "127.0.0.1";
    .port = "81";
    .connect_timeout = 1s;
    .first_byte_timeout = 120s;
}
#/backend default #############################################################

backend sc063141e {
    .host = "192.99.20.30";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 300s;
}
#/backend sc063141e ###########################################################

backend google_cloud_storage {
    .host = "c.storage.googleapis.com.";
    .port = "80";
    .connect_timeout = 2s;
    .first_byte_timeout = 300s;
}
#/backend google_cloud_storage ################################################

backend sc0630b63 {
    .host = "192.99.11.99";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 30s;
}
#/backend sc0630b63 ###########################################################

backend OVHCDN {
    .host = "213.186.33.104";
    .port = "80";
    .connect_timeout = 5s;
    .first_byte_timeout = 30s;
}
#/backend OVHCDN ##############################################################

acl purge {
    # ACL we'll use later to allow purges
    "localhost";
    "127.0.0.1";
    "::1";
    "192.99.20.30";
    "192.241.234.95";
    "94.75.230.14";
    "106.185.45.193";
    "96.126.101.136";
}

acl editors {
    # ACL to honor the "Cache-Control: no-cache" header to force a refresh but only from selected IPs
    "localhost";
    "127.0.0.1";
    "::1";
    "106.185.45.193";
    "96.126.101.136";
}

sub vcl_init {
    # Called when VCL is loaded, before any requests pass through it. Typically used to initialize VMODs.
    # new vdir = directors.round_robin();
    # vdir.add_backend(default);
    # vdir.add_backend(default2);
}

sub vcl_recv {
    if (req.url == "/__varnish_status") {
        return(synth(204));
    }
}

# Load vcl_synth
include "/etc/varnish/vcl_synth.vcl";

# Custom Block Rules
include "/etc/varnish/self_defined_rules.vcl";

# Varnish FireWall Rules
include "/etc/varnish/vfw/vfw.vcl";

sub vcl_recv {
    # Called at the beginning of a request, after the complete request has been received and parsed. Its purpose is to decide whether or not to serve the request, how to do it, and, if applicable, which backend to use.
    # also used to modify the request

    if (req.restarts == 0) {
        set req.http.X-Client-IP = client.ip;
    }

    if (req.http.host == "sd.3cdn.com") {
        set req.backend_hint = google_cloud_storage;
        ## varnish hotlink
        if (!(req.http.referer ~ "http://.*\.showsday\.com/" ||
            req.http.referer ~ "http://sd\.3cdn\.com/" ||
            req.http.referer ~ "http://.*\.seriestime\.com/" ||
            req.http.referer ~ "http://.*\.uu8u\.net/") &&
            req.http.referer &&
            req.url ~ "^[^\?]+\.(jpe?g|png|gif)$")
        {
            return(synth(403));
        }
    }
    if (req.http.host == "sd.3cdn.com") {
        set req.backend_hint = google_cloud_storage;
        ## varnish hotlink
        if (!(req.http.referer ~ "http://.*\.showsday\.com/" ||
            req.http.referer ~ "http://sd\.3cdn\.com/" ||
            req.http.referer ~ "http://.*\.seriestime\.com/" ||
            req.http.referer ~ "http://.*\.uu8u\.net/") &&
            req.http.referer &&
            req.url ~ "^[^\?]+\.(jpe?g|png|gif)$")
        {
            return(synth(403));
        }
    }
    elseif(req.http.host == "st.3cdn.com") {
        set req.backend_hint = google_cloud_storage;
        set req.http.host = "sd.3cdn.com";
        ## varnish hotlink
        if (!(req.http.referer ~ "http://.*\.seriestime\.com/" ||
            req.http.referer ~ "http://st\.3cdn\.com/" ||
            req.http.referer ~ "http://.*\.uu8u\.net/") &&
            req.http.referer &&
            req.url ~ "^[^\?]+\.(jpe?g|png|gif)$")
        {
            return(synth(403));
        }
    }
    elseif(req.http.host == "screenshot.uu8u.net") {
        set req.backend_hint = google_cloud_storage;
        set req.http.host = "screenshot.uu8u.net";
    }
    elseif (req.http.host == "img.subox.net" || req.http.host == "box.uu8u.net" ) {
        set req.backend_hint = google_cloud_storage;
        set req.http.host = "86.rr.nu";
    }
    elseif (req.http.host == "www.showsday.com" || req.http.host == "showsday.com" ||
        req.http.host == "www.jionghost.com" || req.http.host == "jionghost.com" ||
        req.http.host == "cncq.showsday.com" ||
        req.http.host == "www.seriestime.com" || req.http.host == "seriestime.com" ||
        req.http.host == "www.do4movie.com" || req.http.host == "do4movie.com" ||
        req.http.host == "www.fmovief.net" || req.http.host == "fmovief.net" ||
        req.http.host == "www.ftubef.com" || req.http.host == "ftubef.com") {
        set req.backend_hint = sc063141e;
    }

    elseif (req.http.host == "fts.3cdn.com") {
        set req.backend_hint = OVHCDN;
        set req.http.host = "fts.3cdn.com";
        ## varnish hotlink
        if (!(req.http.referer ~ "http://.*\.freetubespot\.com/" ||
            req.http.referer ~ "http://fts\.3cdn\.com/" ||
            req.http.referer ~ "http://.*\.uu8u\.net/") &&
            req.http.referer &&
            req.url ~ "^[^\?]+\.(jpe?g|png|gif)$") {
            return(synth(403));
        }
    }
    elseif(req.http.host == "freetubespot.com" || req.http.host == "www.freetubespot.com") {
        set req.backend_hint = sc0630b63;
        set req.http.host = "www.freetubespot.com";
    }

    else {
        return(synth(400));
    }

    # Normalize the header, remove the port (in case you're testing this on various TCP ports)
    # set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");

    # Normalize the query arguments
    set req.url = std.querysort(req.url);

    # Allow purging
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) { # purge is the ACL defined at the begining
            # Not from an allowed IP? Then die with an error.
            return(synth(405, "This IP is not allowed to send PURGE requests."));
        }
        # If you got this stage (and didn't error out above), purge the cached result
        return(purge);
    }

    # Only deal with "normal" types
    if (req.method != "GET" &&
            req.method != "HEAD" &&
            req.method != "PUT" &&
            req.method != "POST" &&
            req.method != "TRACE" &&
            req.method != "OPTIONS" &&
            req.method != "PATCH" &&
            req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return(pipe);
    }

    # Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
    if (req.http.Upgrade ~ "(?i)websocket") {
        return(pipe);
    }

    # Only cache GET or HEAD requests. This makes sure the POST requests are always passed.
    if (req.method != "GET" && req.method != "HEAD") {
        return(pass);
    }

    # Some generic URL manipulation, useful for all templates that follow
    # First remove the Google Analytics added parameters, useless for our backend
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|utm_content|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Strip hash, server doesn't need it.
    if (req.url ~ "\#") {
        set req.url = regsub(req.url, "\#.*$", "");
    }

    # Strip a trailing ? if it exists
    if (req.url ~ "\?$") {
        set req.url = regsub(req.url, "\?$", "");
    }

    # Some generic cookie manipulation, useful for all templates that follow
    # Remove the "has_js" cookie
    set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");

    # Remove any Google Analytics based cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

    # Remove the Quant Capital cookies (added by some plugin, all __qca)
    set req.http.Cookie = regsuball(req.http.Cookie, "__qc.=[^;]+(; )?", "");

    # Remove the AddThis cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__atuvc=[^;]+(; )?", "");

    # Remove a ";" prefix in the cookie if present
    set req.http.Cookie = regsuball(req.http.Cookie, "^;\s*", "");

    # Are there cookies left with only spaces or that are empty?
    if (req.http.cookie ~ "^\s*$") {
        unset req.http.cookie;
    }

    # Normalize Accept-Encoding header
    # straight from the manual: https://www.varnish-cache.org/docs/3.0/tutorial/vary.html
    # TODO: Test if it's still needed, Varnish 4 now does this by itself if http_gzip_support = on
    # https://www.varnish-cache.org/docs/trunk/users-guide/compression.html
    # https://www.varnish-cache.org/docs/trunk/phk/gzip.html
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elseif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    if (req.http.Cache-Control ~ "(?i)no-cache" && client.ip ~ editors) { # create the acl editors if you want to restrict the Ctrl-F5
        # http://varnish.projects.linpro.no/wiki/VCLExampleEnableForceRefresh
        # Ignore requests via proxy caches and badly behaved crawlers
        # like msnbot that send no-cache with every request.
        if (! (req.http.Via || req.http.User-Agent ~ "(?i)bot" || req.http.X-Purge)) {
            set req.hash_always_miss = true;
        }
    }

    # Large static files are delivered directly to the end-user without
    # waiting for Varnish to fully read the file first.
    # Varnish 4 fully supports Streaming, so set do_stream in vcl_backend_response()
    if (req.url ~ "^[^?]*\.(rar|tar|tgz|gz|wav|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av])(\?.*)?$") {
        unset req.http.Cookie;
        return(hash);
    }

    # Remove all cookies for static files
    # A valid discussion could be held on this line: do you really need to cache static files that don't cause load? Only if you have memory left.
    # Sure, there's disk I/O, but chances are your OS will already have these files in their buffers (thus memory).
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/
    if (req.url ~ "^[^?]*\.(bmp|css|doc|eot|gif|ico|jpe?g|js|less|pdf|png|rtf|swf|txt|woff|xml|zip)(\?.*)?$") {
        unset req.http.Cookie;
        if (req.url ~ "^[^?]*\.(js|css|ico|gif|png|jpe?g|bmp|swf|xml)(\?.*)?$") {
            set req.url = regsub(req.url, "\?.*$", "");
        }
        return(hash);
    }

    if (req.http.Authorization) {
        # Not cacheable by default
        return(pass);
    }

    return(hash);
}

sub vcl_pipe {
    # Called upon entering pipe mode. In this mode, the request is passed on to the backend, and any further data from both the client and backend is passed on unaltered until either end closes the connection. Basically, Varnish will degrade into a simple TCP proxy, shuffling bytes back and forth. For a connection in pipe mode, no other VCL subroutine will ever get called after vcl_pipe.

    # Note that only the first request to the backend will have
    # X-Forwarded-For set.  If you use X-Forwarded-For and want to
    # have it set for all requests, make sure to have:
    # set bereq.http.connection = "close";
    # here.  It is not set by default as it might break some broken web
    # applications, like IIS with NTLM authentication.
    #set bereq.http.Connection = "Close";

    # Implementing websocket support (https://www.varnish-cache.org/docs/4.0/users-guide/vcl-example-websockets.html)
    if (req.http.upgrade) {
        set bereq.http.upgrade = req.http.upgrade;
    }

    return(pipe);
}

sub vcl_pass {
# Called upon entering pass mode. In this mode, the request is passed on to the backend, and the backend's response is passed on to the client, but is not entered into the cache. Subsequent requests submitted over the same client connection are handled normally.

    # return(pass);
}

# The data on which the hashing will take place
sub vcl_hash {
    hash_data(req.url);

    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # hash cookies for requests that have them
    if (req.http.Cookie) {
        hash_data(req.http.Cookie);
    }
}

sub vcl_hit {
# Called when a cache lookup is successful.

    if (obj.ttl >= 0s) {
        # A pure unadultered hit, deliver it
        return(deliver);
    }

    # We have no fresh fish. Lets look at the stale ones.
    if (std.healthy(req.backend_hint)) {
        # Backend is healthy. Limit age to 10s.
            if (obj.ttl + 10s > 0s) {
                  #set req.http.grace = "normal(limited)";
                  return(deliver);
            } else {
                  # No candidate for grace. Fetch a fresh object.
            return(fetch);
           }
    } else {
        # backend is sick - use full grace
            if (obj.ttl + obj.grace > 0s) {
                  #set req.http.grace = "full";
            return(deliver);
        } else {
            # no graced object.
            return(fetch);
        }
    }

    # fetch & deliver once we get the result
    return(fetch);    # Dead code, keep as a safeguard
}

# Handle the HTTP request coming from our backend
sub vcl_backend_response {
# Called after the response headers has been successfully retrieved from the backend.

    # Enable cache for all static files
    # The same argument as the static caches from above: monitor your cache size, if you get data nuked out of it, consider giving up the static file cache.
    # Before you blindly enable this, have a read here: http://mattiasgeniar.be/2012/11/28/stop-caching-static-files/
    if (bereq.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|gif|gz|ico|jpe?g|js|less|pdf|png|rar|rtf|swf|tar|tgz|txt|wav|woff|xml|zip)(\?.*)?$") {
        unset beresp.http.set-cookie;
    }

    # Large static files are delivered directly to the end-user without
    # waiting for Varnish to fully read the file first.
    # Varnish 4 fully supports Streaming, so use streaming here to avoid locking.
    if (bereq.url ~ "^[^?]*\.(rar|tar|tgz|gz|wav|bz2|xz|7z|avi|mov|ogm|mpe?g|mk[av])(\?.*)?$") {
        set beresp.do_stream = true;
        set beresp.do_gzip = false;
    }

    if (beresp.http.content-type ~ "text") {
        set beresp.do_gzip = true;
    }

    if (bereq.url ~ "^[^?]*\.(js|css)(\?.*)?$") {
        set beresp.ttl = 2h;
    }

    if (bereq.url ~ "^[^?]*\.(bmp|gif|ico|jpe?g|png|swf|xml|zip)(\?.*)?$") {
        set beresp.ttl = 30d;
    }

    if (bereq.url ~ "^[^?]*\.(php|php5)(\?.*)?$") {
        set beresp.ttl = 0s;
    }

    # Sometimes, a 301 or 302 redirect formed via Apache's mod_rewrite can mess with the HTTP port that is being passed along.
    # This often happens with simple rewrite rules in a scenario where Varnish runs on :80 and Apache on :8080 on the same box.
    # A redirect can then often redirect the end-user to a URL on :8080, where it should be :80.
    # This may need finetuning on your setup.
    #
    # To prevent accidental replace, we only filter the 301/302 redirects for now.
    if (beresp.status == 301 || beresp.status == 302) {
        set beresp.http.Location = regsub(beresp.http.Location, ":[0-9]+", "");
    }

    # Set 2min cache if unset for static files
    if (beresp.ttl <= 0s || beresp.http.Set-Cookie || beresp.http.Vary == "*") {
        set beresp.ttl = 120s; # Important, you shouldn't rely on this, SET YOUR HEADERS in the backend
        set beresp.uncacheable = true;
        return(deliver);
    }

    # Allow stale content, in case the backend goes down.
    # make Varnish keep all objects for 6 hours beyond their TTL
    set beresp.grace = 6h;

    return(deliver);
}

# The routine when we deliver the HTTP request to the user
# Last chance to modify headers that are sent to the client
sub vcl_deliver {
# Called before a cached object is delivered to the client.

    if (obj.hits > 0) { # Add debug header to see if it's a HIT/MISS and the number of hits, disable when not needed
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
        unset resp.http.Age;
    }
    # Please note that obj.hits behaviour changed in 4.0, now it counts per objecthead, not per object
    # and obj.hits may not be reset in some cases where bans are in use. See bug 1492 for details.
    # So take hits with a grain of salt
    # set resp.http.X-Cache-Hits = obj.hits;

    # Remove some headers: PHP version
    unset resp.http.X-Powered-By;

    # Remove some headers: Apache version & OS
    unset resp.http.Server;
    unset resp.http.X-Varnish;
    unset resp.http.Via;

    return(deliver);
}

sub vcl_backend_error {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    set beresp.http.Retry-After = "5";
    synthetic( {"<!DOCTYPE html>
<html>
  <head>
    <title>"} + beresp.status + " " + beresp.reason + {"</title>
  </head>
  <body>
    <h1>Error "} + beresp.status + " " + beresp.reason + {"</h1>
    <p>"} + beresp.reason + {"</p>
    <h3>Guru Meditation:</h3>
    <p>XID: "} + bereq.xid + {"</p>
    <hr>
    <p>Varnish cache server</p>
  </body>
</html>
"} );
    return(deliver);
}
