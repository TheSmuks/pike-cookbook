---
id: internet-services
title: Internet Services
sidebar_label: Internet Services
---

# 18. Internet Services

## Simple DNS Lookups

```pike
// Recipe 18.1: DNS Lookups with Protocols.DNS - Pike 8
//--------------------------------------------------------------------------

import Protocols.DNS;
import Standards.DNS;

// Basic A record lookup (hostname to IP)
async void lookup_a(string hostname) {
    object client = Protocols.DNS.client();
    array(string) ips = [array](client->getaddrbyname(hostname));

    foreach(ips; string ip) {
        write("%s -> %s\n", hostname, ip);
    }
}

// Reverse DNS lookup (IP to hostname)
async void lookup_ptr(string ip) {
    object client = Protocols.DNS.client();
    string hostname = client->getnamebyaddr(ip);
    write("%s -> %s\n", ip, hostname);
}

// MX record lookup (mail servers)
async void lookup_mx(string domain) {
    object client = Protocols.DNS.client();
    mapping(string:mixed) result = client->lookup(
        domain, Protocol.DNS.MX
    );

    if(result->rcode == Protocol.DNS.NOERROR) {
        write("MX records for %s:\n", domain);
        foreach(result->an; mapping rr) {
            if(rr->type == Protocol.DNS.MX) {
                write("  Priority %d: %s\n", rr->preference, rr->exchange);
            }
        }
    }
}

// TXT record lookup (DKIM, SPF, verification records)
async void lookup_txt(string domain) {
    object client = Protocols.DNS.client();
    mapping(string:mixed) result = client->lookup(
        domain, Protocol.DNS.TXT
    );

    if(result->rcode == Protocol.DNS.NOERROR) {
        write("TXT records for %s:\n", domain);
        foreach(result->an; mapping rr) {
            if(rr->type == Protocol.DNS.TXT) {
                write("  %s\n", rr->txt);
            }
        }
    }
}

// AAAA record lookup (IPv6 addresses)
async void lookup_aaaa(string hostname) {
    object client = Protocols.DNS.client();
    mapping(string:mixed) result = client->lookup(
        hostname, Protocol.DNS.AAAA
    );

    if(result->rcode == Protocol.DNS.NOERROR) {
        write("IPv6 addresses for %s:\n", hostname);
        foreach(result->an; mapping rr) {
            if(rr->type == Protocol.DNS.AAAA) {
                write("  %s\n", rr->ipv6);
            }
        }
    }
}

// Async DNS queries with Future
async void async_lookup(string hostname) {
    object client = Protocols.DNS.async_client();
    Future(array(string)) future = client->getaddrbyname(hostname);
    array(string) ips = await future;

    write("Resolved %s: %s\n", hostname, ips*", ");
}

// Concurrent lookups
async void concurrent_lookups(array(string) hostnames) {
    array(Future) futures = map(hostnames, lambda(string host) {
        object client = Protocols.DNS.async_client();
        return client->getaddrbyname(host);
    });

    array(array(string)) results = await Future.all(futures);
    foreach(results; int i; array(string) ips) {
        write("%s -> %s\n", hostnames[i], ips*", ");
    }
}
```

## Being an FTP Client

```pike
// Recipe 18.2: FTP Operations with Protocols.FTP - Pike 8
//--------------------------------------------------------------------------

import Protocols.FTP;

// Basic FTP connection and file download
async void ftp_download(string host, string user, string pass,
                          string remote_file, string local_path) {
    object ftp = Protocols.FTP.client();

    // Connect and authenticate
    int result = await(ftp->connect(host));
    if (result != 220) {
        werror("FTP connection failed: %d\n", result);
        return;
    }

    result = await(ftp->login(user, pass));
    if (result != 230) {
        werror("FTP login failed: %d\n", result);
        return;
    }

    // Download file
    string data = await(ftp->get(remote_file));
    if (data) {
        object f = Stdio.File(local_path, "wct");
        f->write(data);
        f->close();
        write("Downloaded %s to %s\n", remote_file, local_path);
    }

    ftp->close();
}

// Upload file to FTP server
async void ftp_upload(string host, string user, string pass,
                        string local_file, string remote_path) {
    object ftp = Protocols.FTP.client();
    await(ftp->connect(host));
    await(ftp->login(user, pass));

    // Read local file
    string data = Stdio.read_file(local_file);

    // Upload to server
    int result = await(ftp->put(remote_path, data));
    if (result == 226) {
        write("Uploaded %s to %s\n", local_file, remote_path);
    }

    ftp->close();
}
```