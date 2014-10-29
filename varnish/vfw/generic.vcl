#
# /etc/varnish/vfw/generic.vcl
#

sub vcl_recv {
    if (req.http.User-Agent ~ "(?i)(metis|bilbo|n-stealth|black widow|brutus|cMicrosoftgichk|webtrends security|jaascois|pmafind|\.nasl|nsauditor|paros|nessus|nikto|webinspect|blackwidow)") {
        set req.http.X-VFW-Threat = "Bad User-Agent - Scanner";
        set req.http.X-VFW-RuleID = "generic.badua-1";
        call vfw_main;
    }

    if (req.http.User-Agent ~ "^(VLC|LSSRocketCrawler|NerdyBot|HTTPClient|Google-HTTP-Java-Client|Apache-HttpClient|Icarus6j|Downloads|Microsoft|Dolphin|NSPlayer)") {
        set req.http.X-VFW-Threat = "Bad User-Agent - Scanner";
        set req.http.X-VFW-RuleID = "generic.badua-2";
        call vfw_main;
    }

    if (req.url ~ "(?i)(<|%3C|)(\s|%20|\t|%09|\+)*(!|%21)--(\s|%20|\t|%09|\+)*(#|%23)(\s|%20|\t|%09|\+)*(e(cho|xec)|printenv|include|cmd)") {
        set req.http.X-VFW-Threat = "SSI Injection";
        set req.http.X-VFW-RuleID = "generic.ssi-1";
        call vfw_main;
    }

    if (req.http.X-VFW-Body) {
        # SSI Injection
        # - http://mod-security.svn.sourceforge.net/ (modsecurity_crs_40_generic_attacks.conf)
        if (req.http.X-VFW-Body ~ "(?i)(<|%3C|)(\s|%20|\t|%09|\+)*(!|%21)--(\s|%20|\t|%09|\+)*(#|%23)(\s|%20|\t|%09|\+)*(e(cho|xec)|printenv|include|cmd)") {
            set req.http.X-VFW-Threat = "SSI Injection";
            set req.http.X-VFW-RuleID = "generic.ssi-2";
            call vfw_main;
        }
    }
}
