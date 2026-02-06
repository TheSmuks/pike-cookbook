---
id: internet-services
title: Internet Services
sidebar_label: Internet Services
---

# Internet Services

## Introduction

Internet services enable communication over standard protocols like DNS, FTP, SMTP, and POP3. Pike 8 provides robust modules for implementing and interacting with these services through the `Protocols` module.

**What this covers:**
- DNS lookups (A, MX, TXT, AAAA records)
- FTP file transfer operations
- Email sending and receiving
- Working with internet protocols

**Why use it:**
- Build networked applications
- Implement email automation
- Create FTP clients and servers
- Perform DNS lookups dynamically

:::tip
Pike's `Protocols.DNS` module provides both synchronous and asynchronous DNS resolution methods.
:::

---

## Simple DNS Lookups

### A Record Lookup

```pike
//-----------------------------
// Recipe: DNS lookups with Protocols.DNS - Pike 8
//-----------------------------

#pragma strict_types
#require constant(Protocols.DNS)

import Protocols.DNS;
import Standards.DNS;

void main() {
    // A record lookup (hostname to IP)
    Protocols.DNS.Client client = Protocols.DNS.Client();

    array(string) ips = client->getaddrbyname("www.example.com");
    foreach(ips; string ip) {
        write("www.example.com -> %s\n", ip);
    }

    // Reverse DNS lookup (IP to hostname)
    string hostname = client->getnamebyaddr("93.184.216.34");
    write("93.184.216.34 -> %s\n", hostname);
}
```

### MX Record Lookup

```pike
//-----------------------------
// Recipe: MX record lookup for mail servers
//-----------------------------

#pragma strict_types
#require constant(Protocols.DNS)

void main() {
    Protocols.DNS.Client client = Protocols.DNS.Client();

    // MX record lookup
    mapping result = client->lookup(
        "example.com",
        Standards.DNS.MX
    );

    if (result->rcode == Standards.DNS.NOERROR) {
        write("MX records for %s:\n", "example.com");

        foreach(result->an; mapping rr) {
            if (rr->type == Standards.DNS.MX) {
                write("  Priority %d: %s\n",
                      rr->preference, rr->exchange);
            }
        }
    }
}
```

### TXT Record Lookup

```pike
//-----------------------------
// Recipe: TXT record lookup for verification
//-----------------------------

#pragma strict_types
#require constant(Protocols.DNS)

void main() {
    Protocols.DNS.Client client = Protocols.DNS.Client();

    // TXT record lookup (for SPF, DKIM, etc.)
    mapping result = client->lookup(
        "example.com",
        Standards.DNS.TXT
    );

    if (result->rcode == Standards.DNS.NOERROR) {
        write("TXT records for %s:\n", "example.com");

        foreach(result->an; mapping rr) {
            if (rr->type == Standards.DNS.TXT) {
                write("  %s\n", rr->txt);
            }
        }
    }
}
```

---

## Being an FTP Client

### FTP File Operations

```pike
//-----------------------------
// Recipe: FTP operations with Protocols.FTP - Pike 8
//-----------------------------

#pragma strict_types
#require constant(Protocols.FTP)

void main() {
    Protocols.FTP.Client ftp = Protocols.FTP.Client();

    // Connect and authenticate
    int result = ftp->connect("ftp.example.com");
    if (result != 220) {
        werror("FTP connection failed: %d\n", result);
        return;
    }

    result = ftp->login("username", "password");
    if (result != 230) {
        werror("FTP login failed: %d\n", result);
        return;
    }

    // Download file
    string data = ftp->get("remote_file.txt");
    if (data) {
        Stdio.File f = Stdio.File();
        if (!f->open("local_file.txt", "wct")) {
            werror("Failed to open local_file.txt: %s\n", strerror(f->errno()));
            return;
        }
        f->write(data);
        f->close();
        write("Downloaded remote_file.txt to local_file.txt\n");
    }

    // Upload file
    string content = Stdio.read_file("upload.txt");
    result = ftp->put("remote_upload.txt", content);
    if (result == 226) {
        write("Uploaded file successfully\n");
    }

    // List directory
    array(mapping) files = ftp->get_dir("/");
    foreach(files; mapping fileinfo) {
        write("  %s\n", fileinfo->filename);
    }

    ftp->quit();
}
```

---

## See Also

- [Sockets](/docs/network/sockets) - TCP/UDP programming
- [Web Automation](/docs/network/web-automation) - HTTP clients
- [CGI Programming](/docs/network/cgi-programming) - Web scripting
- [File Access](/docs/files/file-access) - Local file operations
