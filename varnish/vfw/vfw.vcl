#
# /etc/varnish/vfw/vfw.vcl
#

sub vcl_recv {
    set req.http.X-VFW-ClientIP = client.ip;
    set req.http.X-VFW-Method = req.method;
    set req.http.X-VFW-Proto = req.proto;
    set req.http.X-VFW-URL = req.http.host + req.url;
    set req.http.X-VFW-UA = req.http.user-agent;
    if (req.url ~ "(i)^/[^?]+\.(css|js|jp(e)?g|ico|png|gif|txt|gz(ip)?|zip|rar|iso|lzma|bz(2)?|t(ar\.)?gz|t(ar\.)?bz)(\?.*)?$") {
        set req.http.X-VFW-Static = "y";
    }
}

sub vfw_main {
    if (req.http.X-VFW-Threat) {
        call vfw_block;
    }
}

sub vfw_block {
    call vfw_log;
    return(synth(404));
}

sub vfw_log {
    # C{
    #     static const struct gethdr_s VFW_THREAT    = { HDR_REQ, "\015X-VFW-Threat:" };
    #     static const struct gethdr_s VFW_RULEID    = { HDR_REQ, "\015X-VFW-RuleID:" };
    #     static const struct gethdr_s VFW_CLIENTIP  = { HDR_REQ, "\017X-VFW-ClientIP:" };
    #     static const struct gethdr_s VFW_METHOD    = { HDR_REQ, "\015X-VFW-Method:" };
    #     static const struct gethdr_s VFW_URL       = { HDR_REQ, "\012X-VFW-URL:" };
    #     static const struct gethdr_s VFW_PROTO     = { HDR_REQ, "\014X-VFW-Proto:" };
    #     static const struct gethdr_s VFW_UA        = { HDR_REQ, "\011X-VFW-UA:" };

    #     syslog(LOG_INFO, "<VFW> %f [%s/ruleid:%s]: %s - %s http://%s %s - %s",
    #         VRT_r_now(ctx),
    #         VRT_GetHdr(ctx, &VFW_THREAT),
    #         VRT_GetHdr(ctx, &VFW_RULEID),
    #         VRT_GetHdr(ctx, &VFW_CLIENTIP),
    #         VRT_GetHdr(ctx, &VFW_METHOD),
    #         VRT_GetHdr(ctx, &VFW_URL),
    #         VRT_GetHdr(ctx, &VFW_PROTO),
    #         VRT_GetHdr(ctx, &VFW_UA)
    #     );
    # }C
}

sub vcl_synth {
    unset resp.http.Server;
    unset resp.http.X-Varnish;
    return(deliver);
}

# Generic attacks
include "/etc/varnish/vfw/generic.vcl";

# SQL Injection
include "/etc/varnish/vfw/sql.vcl";

sub vcl_hash {
    unset req.http.X-VFW-ClientIP;
    unset req.http.X-VFW-Method;
    unset req.http.X-VFW-Proto;
    unset req.http.X-VFW-URL;
    unset req.http.X-VFW-UA;
}