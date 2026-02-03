---
id: web-automation
title: Web Automation
sidebar_label: Web Automation
---

# Web Automation

## Introduction

Web automation in Pike 8 involves HTTP requests, HTML parsing, form submission, session management, and building web crawlers. This section covers practical recipes for automating web interactions using modern Pike features.

**What this covers:**
- HTTP GET and POST requests with `Protocols.HTTP`
- HTML parsing and link extraction
- Form submission and cookie handling
- JSON API integration
- Web scraping and crawling
- Rate limiting and politeness policies

**Why use it:**
- Automate web interactions and testing
- Build web scrapers and crawlers
- Integrate with REST APIs
- Monitor websites and services
- Aggregate web data

:::tip
For server-side web applications, see [CGI Programming](/docs/network/cgi-programming). This section focuses on client-side automation.
:::

---

## Fetching a URL

### Simple HTTP GET Request

```pike
//-----------------------------
// Recipe: HTTP GET request with error handling
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

void main() {
    string url = "https://example.com";

    // Simple GET request
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status == 200) {
        write("Success: %d bytes\n", sizeof(q->data()));
        write("Content-Type: %s\n", q->headers["content-type"]);

        // Display first 200 chars
        write("Preview: %s\n", q->data()[0..199]);
    } else {
        werror("HTTP Error: %d %s\n", q->status, q->status_desc);
    }
}
```

### GET Request with Custom Headers

```pike
//-----------------------------
// Recipe: HTTP GET with custom headers
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

void main() {
    // Custom headers
    mapping(string:string) headers = ([
        "User-Agent": "PikeBot/1.0",
        "Accept": "application/json",
        "Accept-Language": "en-US,en;q=0.9"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(
        "https://api.example.com/data",
        headers
    );

    if (q->status == 200) {
        write("%s\n", q->data());
    }
}
```

### Async HTTP Request

```pike
//-----------------------------
// Recipe: Asynchronous HTTP GET
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

void main() {
    Protocols.HTTP.Query q = Protocols.HTTP.Query();

    // Set callbacks for async operation
    q->set_callbacks(
        lambda() { werror("Connection failed\n"); },
        lambda(Protocols.HTTP.Query r) {
            write("Got %d bytes\n", sizeof(r->data()));
        }
    );

    q->async_request("https://example.com", "GET", ([]));

    // Keep program alive
    sleep(5);
}
```

---

## Automating Form Submission

### POST Form Data

```pike
//-----------------------------
// Recipe: Submit form with POST data
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

void main() {
    // Form data
    mapping(string:string) form_data = ([
        "username": "alice",
        "email": "alice@example.com",
        "message": "Hello from Pike!"
    ]);

    // Build query string
    array(string) params = map(indices(form_data), lambda(string key) {
        return Protocols.HTTP.uri_encode(key) + "=" +
               Protocols.HTTP.uri_encode(form_data[key]);
    });
    string query_string = params * "&";

    // POST the form
    Protocols.HTTP.Query q = Protocols.HTTP.post_url(
        "https://example.com/submit",
        form_data,
        ([
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Pike FormBot/1.0"
        ])
    );

    if (q->status >= 200 && q->status < 300) {
        write("Form submitted successfully\n");
        write("Response: %s\n", q->data());
    }
}
```

### JSON POST Request

```pike
//-----------------------------
// Recipe: Submit JSON data via POST
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)
#require constant(Standards.JSON)

void main() {
    // JSON payload
    mapping data = ([
        "user": ([
            "name": "Jane Doe",
            "email": "jane@example.com",
            "age": 28
        ]),
        "action": "create"
    ]);

    string json_body = Standards.JSON.encode(data);

    mapping(string:string) headers = ([
        "Content-Type": "application/json",
        "Accept": "application/json"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.do_method(
        "POST",
        "https://api.example.com/users",
        ([]),  // query variables
        headers,
        0,     // follow redirects
        json_body
    );

    if (q->status >= 200 && q->status < 300) {
        mapping response = Standards.JSON.decode(q->data());
        write("Created user: %s\n", response->user->name);
    }
}
```

---

## Extracting URLs

### Link Extraction from HTML

```pike
//-----------------------------
// Recipe: Extract all links from HTML
//-----------------------------

#pragma strict_types

void main() {
    string url = "https://example.com";
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

    if (q->status != 200) {
        werror("Failed to fetch page\n");
        exit(1);
    }

    string html = q->data();

    // Extract all href attributes
    object re = Regexp.PCRE.Simple("<a\\s+href=\"([^\"]+)\"[^>]*>([^<]*)</a>");
    array(string) links = ({});
    int pos = 0;

    while (pos < sizeof(html)) {
        array(string) match = re->match(html, pos);
        if (!match) break;

        string link_url = match[1];
        string link_text = match[2];
        links += (["url": link_url, "text": link_text]);

        pos = html->search(match[0], pos) + sizeof(match[0]);
    }

    // Display links
    foreach(links; mapping link) {
        write("[%s] %s\n", link->text, link->url);
    }

    write("\nFound %d links\n", sizeof(links));
}
```

---

## HTML Parsing with Standards.XML

### Parse Structured HTML

```pike
//-----------------------------
// Recipe: Parse XHTML with Standards.XML
//-----------------------------

#pragma strict_types

void main() {
    string html = #"
<html>
        <head><title>Test Page</title></head>
        <body>
            <h1>Welcome</h1>
            <p id='intro'>This is <b>introductory</b> text.</p>
            <ul>
                <li>Item 1</li>
                <li>Item 2</li>
            </ul>
        </body>
    </html>";

    // Parse XHTML
    Standards.XML.Node root = Standards.XML.parse(html);

    // Extract title
    array(Standards.XML.Node) titles = root->get_elements("title");
    if (sizeof(titles)) {
        write("Title: %s\n", titles[0]->get_text());
    }

    // Extract paragraph by ID
    array(Standards.XML.Node) paras = root->get_elements("p");
    foreach(paras; Standards.XML.Node p) {
        mapping attrs = p->get_attributes();
        if (attrs && attrs->id == "intro") {
            write("Intro paragraph: %s\n", p->get_text());
        }
    }

    // Extract list items
    array(Standards.XML.Node) lists = root->get_elements("ul");
    if (sizeof(lists)) {
        array(Standards.XML.Node) items = lists[0]->get_elements("li");
        foreach(items; Standards.XML.Node item) {
            write("- %s\n", item->get_text());
        }
    }
}
```

---

## Converting ASCII to HTML

### HTML Escaping

```pike
//-----------------------------
// Recipe: Escape special characters for HTML
//-----------------------------

#pragma strict_types

string html_escape(string text) {
    text = replace(text, "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, "\"", "&quot;");
    text = replace(text, "'", "&#39;");
    return text;
}

void main() {
    string unsafe = "<script>alert('XSS')</script>";

    write("Original: %s\n", unsafe);
    write("Escaped:  %s\n", html_escape(unsafe));
    // Output: &lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;
}
```

---

## Session Management and Cookies

### Cookie Handling

```pike
//-----------------------------
// Recipe: Parse and manage cookies
//-----------------------------

#pragma strict_types

mapping(string:string) parse_cookie_header(string cookie_header) {
    mapping(string:string) cookies = ([]);

    foreach(cookie_header / ";"; string cookie) {
        string trimmed = String.trim_whites(cookie);
        int pos = search(trimmed, "=");

        if (pos > 0) {
            string name = trimmed[0..pos-1];
            string value = trimmed[pos+1..];
            cookies[name] = value;
        }
    }

    return cookies;
}

void main() {
    // Simulate receiving cookies
    string cookie_header = "session=abc123; user=john; theme=dark";

    mapping(string:string) cookies = parse_cookie_header(cookie_header);

    write("Cookies:\n");
    foreach(cookies; string name; string value) {
        write("  %s: %s\n", name, value);
    }
}
```

---

## Authentication

### HTTP Basic Auth

```pike
//-----------------------------
// Recipe: Basic authentication
//-----------------------------

#pragma strict_types
#require constant(MIME)

void main() {
    string credentials = "user:pass";
    string encoded = MIME.encode_base64(credentials);

    mapping(string:string) headers = ([
        "Authorization": "Basic " + encoded
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(
        "https://api.example.com/protected",
        headers
    );

    if (q->status == 200) {
        write("Authenticated successfully\n");
        write("%s\n", q->data()[0..299]);
    } else if (q->status == 401) {
        werror("Authentication failed\n");
    }
}
```

### Bearer Token (OAuth2/JWT)

```pike
//-----------------------------
// Recipe: Bearer token authentication
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

void main() {
    string access_token = "your_token_here";

    mapping(string:string) headers = ([
        "Authorization": "Bearer " + access_token,
        "Content-Type": "application/json"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(
        "https://api.example.com/resource",
        headers
    );

    if (q->status == 200) {
        mapping data = Standards.JSON.decode(q->data());
        write("Resource: %O\n", data);
    }
}
```

---

## REST API Client

### High-Level REST Client

```pike
//-----------------------------
// Recipe: REST API client class
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)
#require constant(Standards.JSON)

class RESTClient {
    private string base_url;
    private string|void auth_token;

    void create(string url, void|string token) {
        base_url = url;
        auth_token = token;
    }

    mapping get(string endpoint, void|mapping params) {
        return request("GET", endpoint, 0, params);
    }

    mapping post(string endpoint, void|mapping data) {
        return request("POST", endpoint, data, 0);
    }

    mapping put(string endpoint, void|mapping data) {
        return request("PUT", endpoint, data, 0);
    }

    mapping delete(string endpoint) {
        return request("DELETE", endpoint, 0, 0);
    }

    private mapping request(string method, string endpoint,
                         void|mapping data, void|mapping params) {
        mapping(string:string) headers = ([
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]);

        if (auth_token) {
            headers["Authorization"] = "Bearer " + auth_token;
        }

        string body = "";
        if (data && sizeof(data)) {
            body = Standards.JSON.encode(data);
        }

        // Build URL with params
        string url = base_url + endpoint;
        if (params && sizeof(params)) {
            array(string) items = map(indices(params), lambda(string key) {
                return key + "=" + params[key];
            });
            url += "?" + items * "&";
        }

        Protocols.HTTP.Query q = Protocols.HTTP.do_method(
            method, url, ([]), headers, 0, body
        );

        if (q->status >= 200 && q->status < 300) {
            return ([
                "success": 1,
                "status": q->status,
                "data": Standards.JSON.decode(q->data() || "{}")
            ]);
        } else {
            return ([
                "success": 0,
                "status": q->status,
                "error": q->status_desc
            ]);
        }
    }
}

// Usage
void main() {
    RESTClient api = RESTClient("https://api.example.com");

    mapping result = api->get("/users/1");
    if (result->success) {
        mapping user = result->data;
        write("User: %s\n", user->name);
    } else {
        werror("Error: %s\n", result->error);
    }
}
```

---

## Rate Limiting

### Polite Crawler

```pike
//-----------------------------
// Recipe: Rate limiter for web requests
//-----------------------------

#pragma strict_types

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

void main() {
    RateLimiter limiter = RateLimiter(2);  // 2 requests/sec

    array(string) urls = ({
        "https://example.com/page1",
        "https://example.com/page2",
        "https://example.com/page3"
    });

    foreach(urls; string url) {
        limiter->throttle();

        Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);
        if (q->status == 200) {
            write("Fetched: %s (%d bytes)\n", url, sizeof(q->data()));
        }
    }
}
```

---

## Creating a Web Crawler

### Basic Web Crawler

```pike
//-----------------------------
// Recipe: Simple web crawler
//-----------------------------

#pragma strict_types
#require constant(Protocols.HTTP)

class WebCrawler {
    private string start_url;
    private int max_depth;
    private set(string) visited = (<>);
    private array(string) queue = ({});
    private RateLimiter limiter;

    void create(string url, void|int depth, void|int rps) {
        start_url = url;
        max_depth = depth || 2;
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

void main() {
    WebCrawler crawler = WebCrawler("https://example.com", 2, 1);
    crawler->crawl();
}
```

---

## See Also

- [Sockets](/docs/network/sockets) - Low-level socket programming
- [CGI Programming](/docs/network/cgi-programming) - Server-side web scripting
- [Internet Services](/docs/network/internet-services) - Email, FTP, DNS
- [Strings](/docs/basics/strings) - Text processing
- [Pattern Matching](/docs/basics/pattern-matching) - Advanced text parsing
