---
id: web-automation
title: Web Automation
sidebar_label: Web Automation
---

# 20. Web Automation

## Introduction

Web automation in Pike 8 involves HTTP requests, HTML parsing, form submission, session management, and building web crawlers. This chapter covers practical recipes for automating web interactions using modern Pike features.

Key modules used:

```pike
// Web automation modules in Pike 8
Protocols.HTTP      // HTTP client and server
Standards.XML        // XML/HTML parsing
Standards.JSON       // JSON encoding/decoding
Concurrent.Future    // Async operations
Protocols.HTTP.Query // HTTP query object
MIME.encode_base64    // Base64 encoding
Crypto.SHA256        // Cryptographic functions
```

## Fetching a URL

Simple GET request with Protocols.HTTP:

```pike
// Basic HTTP GET request
Protocols.HTTP.Query q = Protocols.HTTP.get_url("https://example.com");

if (q->status == 200) {
    write("Success: %d bytes\n", sizeof(q->data()));
    write("Content-Type: %s\n", q->headers["content-type"]);
    write(q->data());  // Page content
} else {
    werror("HTTP Error: %d %s\n", q->status, q->status_desc);
}

// With custom headers
mapping headers = ([
    "User-Agent": "PikeBot/1.0",
    "Accept": "application/json"
]);

q = Protocols.HTTP.get_url("https://api.example.com/data", headers);
```

Async HTTP requests with Future/Promise:

```pike
// Async HTTP GET with callback
Protocols.HTTP.Query q = Protocols.HTTP.Query();
q->set_callbacks(
    lambda() { werror("Connection failed\n"); },
    lambda(Protocols.HTTP.Query r) {
        write("Got %d bytes\n", sizeof(r->data()));
    }
);
q->async_request("https://example.com", "GET", ([]));

// Using Concurrent.Future
Concurrent.Promise p = Concurrent.Promise();
q->set_callbacks(
    lambda() { p->fail("Failed"); },
    lambda(Protocols.HTTP.Query r) {
        p->success(r->data());
    }
);
```

## Automating Form Submission

POST form data:

```pike
// GET form submission
mapping form_data = ([
    "name": "John Doe",
    "email": "john@example.com",
    "category": "general"
]);

// Build query string
array(string) params = map(indices(form_data), lambda(string key) {
    return Protocols.HTTP.uri_encode(key) + "=" +
           Protocols.HTTP.uri_encode(form_data[key]);
});
string query_string = params * "&";
string url = "https://example.com/search?" + query_string;

// POST form submission
Protocols.HTTP.Query q = Protocols.HTTP.post_url(
    "https://example.com/submit",
    form_data,
    ([
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "Pike FormBot/1.0"
    ])
);
```

Submit JSON data:

```pike
// Submit JSON via POST
mapping data = ([
    "user": (mapping)[
        "name": "Jane Doe",
        "email": "jane@example.com"
    ],
    "action": "update"
]);

string json_body = Standards.JSON.encode(data);

mapping(string:string) headers = ([
    "Content-Type": "application/json",
    "Accept": "application/json"
]);

Protocols.HTTP.Query q = Protocols.HTTP.do_method(
    "POST",
    "https://api.example.com/endpoint",
    ([]),  // query variables
    headers,
    0,     // follow redirects
    json_body
);

if (q->status >= 200 && q->status < 300) {
    mapping response = Standards.JSON.decode(q->data());
}
```

## Extracting URLs

Extract links from HTML:

```pike
// Fetch HTML and extract links
Protocols.HTTP.Query q = Protocols.HTTP.get_url("https://example.com");
string html = q->data();

// Extract all href attributes
object re = Regexp.PCRE.Simple("<a\\s+href=\"([^\"]+)\"[^>]*>([^<]*)</a>");

array(string) links = ({});
int pos = 0;

while (pos < sizeof(html)) {
    array(string) match = re->match(html, pos);
    if (!match) break;

    string url = match[1];
    string text = match[2];

    links += (([ "url": url, "text": text ]));

    pos = html->search(match[0], pos) + sizeof(match[0]);
}

foreach(links, mapping link) {
    write("%s -> %s\n", link->text, link->url);
}
```

## HTML Parsing with Standards.XML

Parse well-formed HTML/XML:

```pike
// Parse XHTML/well-formed HTML
Standards.XML.Node root = Standards.XML.parse(html);

// Extract title
array(Standards.XML.Node) titles = root->get_elements("title");
if (sizeof(titles)) {
    write("Title: %s\n", titles[0]->get_text());
}

// Extract all paragraphs
array(Standards.XML.Node) paragraphs = root->get_elements("p");
foreach(paragraphs, Standards.XML.Node p) {
    mapping attrs = p->get_attributes();
    string id = attrs && attrs->id ? attrs->id : "no-id";
    write("[%s]: %s\n", id, p->get_text());
}

// Extract list items
array(Standards.XML.Node) lists = root->get_elements("ul");
if (sizeof(lists)) {
    array(Standards.XML.Node) items = lists[0]->get_elements("li");
    foreach(items, Standards.XML.Node item) {
        write("- %s\n", item->get_text());
    }
}
```

## Converting ASCII to HTML

```pike
// Escape special characters for HTML
string html_escape(string text) {
    text = replace(text, "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, "\"", "&quot;");
    text = replace(text, "'", "&#39;");
    return text;
}

write(html_escape("<script>alert('XSS')</script>"));
// Output: &lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;
```

## Converting HTML to ASCII

```pike
// Strip HTML tags
string strip_html(string html) {
    // Remove all tags
    string text = Regexp.PCRE.Simple("<[^>]+>")->replace(html, "");

    // Decode common entities
    text = replace(text, "&amp;", "&");
    text = replace(text, "&lt;", "<");
    text = replace(text, "&gt;", ">");
    text = replace(text, "&quot;", "\"");
    text = replace(text, "&nbsp;", " ");

    return text;
}

string html = "<p>Hello <b>world</b>!</p>";
write(strip_html(html));
// Output: Hello world!
```

## Session Management and Cookies

Handle cookies and maintain sessions:

```pike
// Parse Set-Cookie header
class CookieJar {
    private mapping(string:mapping) cookies = ([]);

    void set_cookie(string cookie_str, string|void domain) {
        // Parse: name=value; Expires=date; Path=/; Domain=.example.com
        array(string) parts = cookie_str / ";";

        string name;
        string value;

        foreach(parts, string part) {
            part = String.trim_whitespace(part);
            array(string) nv = part / "=";

            if (sizeof(nv) == 2) {
                if (!name) {
                    name = nv[0];
                    value = nv[1];
                }
            }
        }

        if (name && domain) {
            cookies[name] = ([ "value": value, "domain": domain ]);
        }
    }

    string cookie_header(string url) {
        array(string) pairs = map(indices(cookies), lambda(string name) {
            return name + "=" + cookies[name]->value;
        });
        return pairs * "; ";
    }
}

// Use with HTTP requests
CookieJar jar = CookieJar();

// Receive cookie
Protocols.HTTP.Query q = Protocols.HTTP.get_url("https://example.com/login");
jar->set_cookie(q->headers["set-cookie"], "example.com");

// Send cookie with subsequent request
mapping headers = (["Cookie": jar->cookie_header("https://example.com")]);
q = Protocols.HTTP.get_url("https://example.com/profile", headers);
```

## Authentication

HTTP Basic Authentication:

```pike
// Basic Auth header
string credentials = "user:pass";
string encoded = MIME.encode_base64(credentials);

mapping(string:string) headers = ([
    "Authorization": "Basic " + encoded
]);

Protocols.HTTP.Query q = Protocols.HTTP.get_url(
    "https://api.example.com/protected",
    headers
);
```

Bearer token (OAuth2/JWT):

```pike
// Bearer token authentication
string access_token = "your_token_here";

mapping(string:string) headers = ([
    "Authorization": "Bearer " + access_token,
    "Content-Type": "application/json"
]);

Protocols.HTTP.Query q = Protocols.HTTP.get_url(
    "https://api.example.com/resource",
    headers
);
```

## REST API Client

Full REST API client with error handling:

```pike
// High-level REST client
class RESTClient {
    private string base_url;
    private string|void auth_token;

    void create(string url, string|void token) {
        base_url = url;
        auth_token = token;
    }

    mapping get(string endpoint, mapping|void params) {
        mapping(string:string) headers = ([
            "Accept": "application/json"
        ]);

        if (auth_token) {
            headers["Authorization"] = "Bearer " + auth_token;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(
            base_url + endpoint,
            headers
        );

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data())
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }

    mapping post(string endpoint, mapping data) {
        mapping(string:string) headers = ([
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]);

        if (auth_token) {
            headers["Authorization"] = "Bearer " + auth_token;
        }

        string body = Standards.JSON.encode(data);
        Protocols.HTTP.Query q = Protocols.HTTP.do_method(
            "POST", base_url + endpoint, ([]), headers, 0, body
        );

        // Similar error handling as GET...
    }
}

// Usage
RESTClient api = RESTClient("https://api.example.com");
mapping result = api->get("/users/1");

if (result->success) {
    mapping user = result->data;
    write("User: %s\n", user->name);
}
```

## Webhook Handler

Simple webhook server:

```pike
// Webhook server using Protocols.HTTP.Server
class WebhookHandler {
    void handle(Protocols.HTTP.Server.Request req) {
        method m = req->request_type;

        if (m == "POST") {
            string body = req->body_raw || "";

            // Parse JSON payload
            mapping data = Standards.JSON.decode(body);

            werror("Received webhook: %s\n", data->event || "unknown");

            // Send response
            string resp = Standards.JSON.encode(([
                "status": "received"
            ]));

            req->response_and_finish(sprintf(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n%s",
                resp
            ));
        }
    }
}

// Start server
Protocols.HTTP.Server.Port port = Protocols.HTTP.Server.Port();
port->bind(8080, WebhookHandler()->handle);
```

## Rate Limiting

Polite crawler with rate limiting:

```pike
// Rate limiter
class RateLimiter {
    private float min_interval;
    private int last_request = 0;

    void create(int requests_per_second) {
        min_interval = 1.0 / requests_per_second;
    }

    void throttle() {
        int current = time();
        float elapsed = current - last_request;

        if (elapsed < min_interval) {
            float sleep_time = min_interval - elapsed;
            sleep((int)(sleep_time * 1000000) / 1000);
        }

        last_request = time();
    }
}

// Usage
RateLimiter limiter = RateLimiter(2);  // 2 requests per second

for (int i = 1; i <= 10; i++) {
    limiter->throttle();
    Protocols.HTTP.get_url(sprintf("https://example.com/page/%d", i));
    write("Fetched page %d\n", i);
}
```

## Creating a Web Crawler

Basic web crawler:

```pike
// Simple web crawler
class WebCrawler {
    private string start_url;
    private int max_depth;
    private set(string) visited = (<>);
    private array(string) queue = ({});
    private RateLimiter limiter;

    void create(string url, int|void depth, int|void rps) {
        start_url = url;
        max_depth = depth || 3;
        limiter = RateLimiter(rps || 2);
        queue += ({url});
    }

    array(string) extract_links(string html) {
        array(string) links = ({});
        object re = Regexp.PCRE.Simple("<a\\s+href=['\"]([^'\"]+)['\"]");

        int pos = 0;
        while (pos < sizeof(html)) {
            array(string) match = re->match(html, pos);
            if (!match) break;
            links += ({match[1]});
            pos = html->search(match[0], pos) + sizeof(match[0]);
        }
        return links;
    }

    void crawl() {
        while (sizeof(queue)) {
            string url = queue[0];
            queue = queue[1..];

            if (visited[url]) continue;
            visited[url] = 1;

            limiter->throttle();
            Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

            if (q && q->status == 200) {
                write("Crawled: %s (%d bytes)\n", url, sizeof(q->data()));

                array(string) links = extract_links(q->data());
                queue += links;
            }
        }
    }
}

// Usage
WebCrawler crawler = WebCrawler("https://example.com", 2, 1);
crawler->crawl();
```

## Handling JavaScript-Heavy Sites

Pike cannot execute JavaScript directly. For JS-heavy sites:

```pike
// Strategy 1: Discover hidden API endpoints
string html = Protocols.HTTP.get_url("https://example.com")->data();

// Look for API calls in JavaScript
array(string) patterns = ({
    "fetch\\(['\"]([^'\"]+)['\"]",
    "\\.get\\(['\"]([^'\"]+)['\"]",
    "[\"']url[\"']:\\s*[\"']([^'\"]+)[\"']"
});

foreach(patterns, string pattern) {
    object re = Regexp.PCRE.Simple(pattern);
    array(string) matches = re->split(html);
    if (sizeof(matches) > 1) {
        write("Found API endpoint: %s\n", matches[1]);
    }
}

// Strategy 2: Use headless browser (via external tool)
// Call Node.js script with Puppeteer from Pike
object proc = Process.popen("node render.js https://example.com", "r");
string rendered_html = proc->read();
proc->close();

// Now parse the rendered HTML
```

## Program: Web Scraper

Complete web scraper example:

```pike
#!/usr/bin/env pike
#pragma strict_types

int main(int argc, array(string) argv) {
    if (argc < 2) {
        werror("Usage: %s <url>\n", argv[0]);
        return 1;
    }

    string url = argv[1];

    // Fetch page
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status != 200) {
        werror("HTTP Error: %d\n", q->status);
        return 1;
    }

    string html = q->data();

    // Extract title
    object re = Regexp.PCRE.Simple("<title>([^<]*)</title>");
    array(string) title_match = re->split(html);
    if (sizeof(title_match) > 1) {
        write("Title: %s\n", title_match[1]);
    }

    // Extract all links
    re = Regexp.PCRE.Simple("<a\\s+href=\"([^\"]+)\"[^>]*>([^<]*)</a>");
    array(string) links = ({});
    int pos = 0;

    while (pos < sizeof(html)) {
        array(string) match = re->match(html, pos);
        if (!match) break;

        write("  %s -> %s\n", match[2], match[1]);
        pos = html->search(match[0], pos) + sizeof(match[0]);
    }

    return 0;
}
```