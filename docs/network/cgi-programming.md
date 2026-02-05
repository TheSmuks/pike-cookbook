---
id: cgi-programming
title: CGI Programming
sidebar_label: CGI Programming
---

# CGI Programming

## Introduction

CGI (Common Gateway Interface) enables web servers to execute programs and display their output. Pike 8 provides excellent support for CGI programming through built-in modules for HTTP handling, form processing, and web response generation.

**What this covers:**
- CGI script fundamentals and environment variables
- Form processing (GET and POST requests)
- HTTP headers and redirects
- Cookie management and sessions
- Security best practices for web applications
- Debugging CGI scripts

**Why use it:**
- Build dynamic web applications
- Process web forms and user input
- Create RESTful APIs and web services
- Generate HTML responses dynamically

:::tip
For modern web applications, consider using [Web Automation](/docs/network/web-automation) with dedicated HTTP servers instead of CGI.
:::

---

## Writing a CGI Script

### Complete CGI Script Template

```pike
//-----------------------------
// Recipe: CGI script with GET and POST handling
//-----------------------------

#pragma strict_types
#pragma no_clone

import Protocols.HTTP;

// URL decoding function
string url_decode(string s) {
    return replace(replace(replace(s, "+", " "),
        "%20", " "),
        "\\\", "\");
}

// URL encoding function
string url_encode(string s) {
    return Protocols.HTTP.http_encode_url(s);
}

// Parse query string or POST data
mapping(string:string) parse_form_data() {
    mapping(string:string) form = ([]);
    string data;
    string method = getenv("REQUEST_METHOD") || "GET";

    if (method == "GET") {
        data = getenv("QUERY_STRING") || "";
    } else if (method == "POST") {
        int length = (int)(getenv("CONTENT_LENGTH") || "0");
        if (length > 0 && length < 1048576) {  // 1MB limit
            data = Stdio.stdin->read(length);
        }
    }

    if (data) {
        foreach(data / "&"; string pair) {
            array(string) parts = pair / "=";
            if (sizeof(parts) == 2) {
                string key = url_decode(parts[0]);
                string value = url_decode(parts[1]);
                form[key] = value;
            }
        }
    }

    return form;
}

// Send HTTP headers
void send_headers(string|void content_type, int|void status) {
    if (!content_type) content_type = "text/html";
    if (!status) status = 200;

    write("Status: %d\r\n", status);
    write("Content-Type: %s; charset=utf-8\r\n\r\n", content_type);
}

// Main entry point
void main() {
    mapping(string:string) form = parse_form_data();
    send_headers();

    write("<!DOCTYPE html>\n");
    write("<html><head><title>CGI Test</title></head>\n");
    write("<body><h1>CGI Script Working!</h1>\n");
    write("<p>Method: %s</p>\n", getenv("REQUEST_METHOD") || "UNKNOWN");

    if (sizeof(form)) {
        write("<h2>Form Data:</h2><ul>\n");
        foreach(form; string key; string value) {
            write("<li>%s: %s</li>\n", key, value);
        }
        write("</ul>\n");
    }

    write("</body></html>\n");
}
```

:::note
Always send HTTP headers **before** any content output. The `\r\n\r\n` sequence marks the end of headers.
:::

---

## Redirecting Error Messages

### Error Handling and Redirection

```pike
//-----------------------------
// Recipe: Capture and display errors in browser
//-----------------------------

#pragma strict_types
#pragma no_clone

constant ERROR_LOG_FILE = "/tmp/cgi_errors.log";

mapping(string:string) error_data = ([
    "has_error": "0",
    "error_message": "",
    "backtrace": ""
]);

void install_error_handler() {
    master()->set_inhibit_compile_errors(lambda(mixed err) {
        error_data["has_error"] = "1";
        error_data["error_message"] = sprintf("%O", err);
    });

    // Redirect stderr to file
    Stdio.File(ERROR_LOG_FILE, "wac")->dup2(stderr);
}

void send_error_page(string title, string message, string|void backtrace) {
    write("Status: 500 Internal Server Error\r\n");
    write("Content-Type: text/html; charset=utf-8\r\n\r\n");

    string safe_title = replace(replace(replace(title, "<", "&lt;"), ">", "&gt;"), "\"", "&quot;");
    string safe_message = replace(replace(replace(message, "\n", "<br>"), "<", "&lt;"), ">", "&gt;");

    write("<!DOCTYPE html><html><head><title>Error</title>\n");
    write("<style>body{font-family:Arial;margin:40px;background:#f0f0f0;}\n");
    write(".error-box{background:#fff;border-left:4px solid #d32f2f;padding:20px;}\n");
    write(".error-title{color:#d32f2f;margin-top:0;}</style></head>\n");
    write("<body><div class='error-box'>\n");
    write("<h2 class='error-title'>%s</h2>\n", safe_title);
    write("<p>%s</p>\n", safe_message);
    if (backtrace) {
        write("<pre>%s</pre>\n", backtrace);
    }
    write("</div></body></html>\n");
}

void log_error(string message) {
    string timestamp = Calendar.ISO.now()->format_time();
    string remote = getenv("REMOTE_ADDR") || "unknown";
    string log_entry = sprintf("[%s] %s: %s\n", timestamp, remote, message);
    Stdio.File f = Stdio.File(ERROR_LOG_FILE, "wac");
    if (f) {
        f->write(log_entry);
        f->close();
    }
}

mixed safe_execute(function():mixed cb) {
    install_error_handler();

    mixed result = catch {
        return cb();
    };

    if (result) {
        string err_msg = describe_error(result);
        log_error(err_msg);
        send_error_page("Application Error", err_msg, backtrace());
        return 0;
    }

    if (error_data["has_error"] == "1") {
        log_error(error_data["error_message"]);
        send_error_page("Compilation Error", error_data["error_message"]);
        return 0;
    }

    return UNDEFINED;
}

void main() {
    mixed err = safe_execute(lambda() {
        // Your CGI code here
        write("Content-Type: text/html\r\n\r\n");
        write("<h1>Hello World!</h1>\n");
    });

    if (err) {
        // Error was already handled
        return;
    }
}
```

---

## Writing a Safe CGI Program

### Security Best Practices

```pike
//-----------------------------
// Recipe: Security-focused CGI programming
//-----------------------------

#pragma strict_types
#pragma no_clone

import Protocols.HTTP;

constant MAX_POST_SIZE = 1048576;  // 1MB limit
constant MAX_FIELD_LENGTH = 1000;

// HTML escape to prevent XSS
string html_escape(string s) {
    return replace(replace(replace(replace(s, "&", "&amp;"),
        "<", "&lt;"),
        ">", "&gt;"),
        "\"", "&quot;");
}

// Validate and sanitize input
string|zero validate_string(string input, void|bool allow_html) {
    // Check length
    if (sizeof(input) > MAX_FIELD_LENGTH) {
        return 0;
    }

    // Trim whitespace
    string result = String.trim_whites(input);

    // Check for null bytes
    if (has_value(result, "\0")) {
        return 0;
    }

    // Remove HTML unless explicitly allowed
    if (!allow_html) {
        result = html_escape(result);
    }

    return result;
}

// Validate email
int is_valid_email(string email) {
    if (!email || sizeof(email) < 3 || sizeof(email) > 254)
        return 0;

    return Regexp.SimpleRegexp("^[\\w._%+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$")->match(email);
}

// Rate limiting
mapping(string:int) rate_limits = ([]);
int rate_limit_window = 60;
int max_requests_per_window = 10;

int check_rate_limit(string identifier) {
    int now = time();
    if (!rate_limits[identifier]) {
        rate_limits[identifier] = now;
        return 1;
    }

    int elapsed = now - rate_limits[identifier];
    if (elapsed >= rate_limit_window) {
        rate_limits[identifier] = now;
        return 1;
    }

    return 0;  // Rate limited
}

void main() {
    // Check rate limit
    string ip = getenv("REMOTE_ADDR") || "unknown";
    if (!check_rate_limit(ip)) {
        write("Status: 429 Too Many Requests\r\n\r\nRate limit exceeded.");
        return;
    }

    // Parse form safely
    mapping(string:string) form = parse_form_data();

    // Validate email if provided
    if (form->email && !is_valid_email(form->email)) {
        write("Content-Type: text/html\r\n\r\n");
        write("<h2>Invalid email address</h2>\n");
        return;
    }

    // Send safe response
    write("Content-Type: text/html\r\n\r\n");
    write("<h1>Hello, %s!</h1>\n", html_escape(form->name || "Guest"));
}
```

:::warning
Always validate and sanitize user input to prevent XSS, SQL injection, and other attacks.
:::

---

## Redirecting to a Different Location

### HTTP Redirects

```pike
//-----------------------------
// Recipe: HTTP redirects for CGI
//-----------------------------

#pragma strict_types
#pragma no_clone

// 301 Moved Permanently
void redirect_permanent(string url) {
    write("Status: 301 Moved Permanently\r\n");
    write("Location: %s\r\n", url);
    write("Content-Type: text/html\r\n\r\n");
    write("<!DOCTYPE html><html><head><title>Moved</title></head>\n");
    write("<body><h1>301 Moved Permanently</h1>\n");
    write("<p>This resource has moved to <a href='%s'>%s</a>.</p>\n", url, url);
    write("</body></html>\n");
}

// 302 Found (temporary redirect)
void redirect_temporary(string url) {
    write("Status: 302 Found\r\n");
    write("Location: %s\r\n", url);
    write("Content-Type: text/html\r\n\r\n");
    write("<!DOCTYPE html><html>\n");
    write("<head><meta http-equiv='refresh' content='0;url=%s'>\n", url);
    write("<title>Redirect</title></head>\n");
    write("<body><h1>Redirecting...</h1></body></html>\n");
}

// Safe redirect with validation
int is_safe_url(string url) {
    if (!url) return 0;

    // Allow relative URLs
    if (has_prefix(url, "/")) return 1;

    // Allow absolute URLs only from whitelist
    string host = getenv("HTTP_HOST") || "localhost";
    array(string) allowed = ({ host, "www." + host });

    foreach(allowed; string allowed_host) {
        if (has_prefix(url, "http://" + allowed_host) ||
            has_prefix(url, "https://" + allowed_host)) {
            return 1;
        }
    }

    return 0;
}

void safe_redirect(string url) {
    if (!url || !is_safe_url(url)) {
        url = "/";
    }
    redirect_temporary(url);
}

void main() {
    string redirect_target = getenv("QUERY_STRING");
    if (redirect_target && has_prefix(redirect_target, "url=")) {
        string url = Protocols.HTTP.http_decode_url(redirect_target[4..]);
        safe_redirect(url);
    } else {
        write("Content-Type: text/html\r\n\r\n");
        write("<h1>Redirect Examples</h1>\n");
    }
}
```

---

## Formatting Lists and Tables with HTML Shortcuts

### HTML Helper Functions

```pike
//-----------------------------
// Recipe: HTML generation helpers
//-----------------------------

#pragma strict_types
#pragma no_clone

// HTML escape
string h(string s) {
    return replace(replace(replace(replace(s, "&", "&amp;"),
        "<", "&lt;"),
        ">", "&gt;"),
        "\"", "&quot;");
}

// Unordered list
string ul(array(string) items) {
    array(string) lis = map(items, lambda(string item) {
        return "  <li>" + h(item) + "</li>";
    });
    return "<ul>\n" + lis * "\n" + "\n</ul>";
}

// Table generator
string table(array(array(string)) rows, array(string)|void headers) {
    string html = "<table>\n";

    if (headers) {
        html += "  <tr>\n";
        foreach(headers; string h) {
            html += sprintf("    <th>%s</th>\n", h);
        }
        html += "  </tr>\n";
    }

    foreach(rows; array(string) row) {
        html += "  <tr>\n";
        foreach(row; string cell) {
            html += sprintf("    <td>%s</td>\n", h(cell));
        }
        html += "  </tr>\n";
    }

    html += "</table>\n";
    return html;
}

// Form generator
string form(string action, string content, void|int use_post) {
    string method = use_post ? "POST" : "GET";
    return sprintf("<form action='%s' method='%s'>\n%s\n</form>\n",
                  action, method, content);
}

void main() {
    write("Content-Type: text/html\r\n\r\n");

    array(string) fruits = ({"Apple", "Banana", "Cherry"});
    array(array(string)) data = ({
        ({"Alice", "30", "NYC"}),
        ({"Bob", "25", "LA"})
    });

    write("<!DOCTYPE html><html><head><title>HTML Helpers</title>\n");
    write("<style>table{border-collapse:collapse;}th,td{border:1px solid #ccc;padding:8px;}</style>\n");
    write("</head><body>\n");

    write("<h1>Fruits:</h1>\n");
    write(ul(fruits));

    write("<h1>Data Table:</h1>\n");
    write(table(data, ({"Name", "Age", "City"})));

    write("</body></html>\n");
}
```

---

## Managing Cookies

### Cookie Handling

```pike
//-----------------------------
// Recipe: Cookie management for CGI
//-----------------------------

#pragma strict_types
#pragma no_clone

// Parse Cookie header
mapping(string:string) parse_cookies() {
    mapping(string:string) cookies = ([]);
    string cookie_header = getenv("HTTP_COOKIE") || "";

    if (cookie_header != "") {
        foreach(cookie_header / ";"; string cookie) {
            string trimmed = String.trim_whites(cookie);
            int pos = search(trimmed, "=");
            if (pos > 0) {
                string name = trimmed[0..pos-1];
                string value = trimmed[pos+1..];
                cookies[name] = value;
            }
        }
    }

    return cookies;
}

// Set cookie with attributes
void set_cookie(string name, string value,
                void|int lifetime, void|string path) {
    if (!path) path = "/";
    if (!lifetime) lifetime = 3600;

    int expiry = time() + lifetime;
    string date = Calendar.Second(expiry)->format_http();

    string cookie = sprintf("%s=%s; Expires=%s; Path=%s",
                            name, value, date, path);
    write("Set-Cookie: %s\r\n", cookie);
}

// Delete cookie
void delete_cookie(string name, void|string path) {
    if (!path) path = "/";
    set_cookie(name, "", 1, path);
}

// Session management
class Session {
    string session_id;
    mapping(string:mixed) data = ([]);
    int created;
    int timeout = 1800;

    void create(string|void id) {
        created = time();
        if (id) {
            session_id = id;
        } else {
            session_id = String.hash2(sprintf("%d.%s", time(), Crypto.Random.random_string(16)), "SHA256");
        }
    }

    int is_expired() {
        return (time() - created) > timeout;
    }

    mixed get(string key) {
        return data[key];
    }

    void set(string key, mixed value) {
        data[key] = value;
    }
}

mapping(string:Session) sessions = ([]);

Session|zero get_session(string|void session_id) {
    // Clean expired sessions
    foreach(indices(sessions); string id) {
        if (sessions[id]->is_expired()) {
            m_delete(sessions, id);
        }
    }

    if (session_id && sessions[session_id]) {
        return sessions[session_id];
    }

    // Create new session
    Session new_session = Session();
    sessions[new_session->session_id] = new_session;
    return new_session;
}

void main() {
    mapping(string:string) cookies = parse_cookies();
    Session session = get_session(cookies["session_id"]);

    // Send session cookie
    set_cookie("session_id", session->session_id, 3600);

    write("Content-Type: text/html\r\n\r\n");
    write("<h1>Session ID: %s</h1>\n", session->session_id);
}
```

---

## Debugging CGI Scripts

### HTTP Debug Tools

```pike
//-----------------------------
// Recipe: CGI debugging tools
//-----------------------------

#pragma strict_types
#pragma no_clone

constant DEBUG_LOG = "/tmp/http_debug.log";

void debug_log(string message) {
    string timestamp = Calendar.ISO.now()->format_time();
    Stdio.File f = Stdio.File(DEBUG_LOG, "wac");
    if (f) {
        f->write(sprintf("[%s] %s\n", timestamp, message));
        f->close();
    }
}

// Dump all environment variables
string dump_cgi_environment() {
    string output = "=== CGI Environment ===\n";
    array(string) vars = ({
        "REQUEST_METHOD", "REQUEST_URI", "QUERY_STRING",
        "CONTENT_TYPE", "CONTENT_LENGTH", "HTTP_USER_AGENT",
        "REMOTE_ADDR", "HTTP_REFERER", "HTTP_COOKIE"
    });

    foreach(vars; string var) {
        string value = getenv(var);
        output += sprintf("%s: %s\n", var, value || "(not set)");
    }

    return output;
}

void main() {
    // Log request
    string remote = getenv("REMOTE_ADDR") || "unknown";
    string uri = getenv("REQUEST_URI") || "/";
    debug_log(sprintf("%s %s from %s", getenv("REQUEST_METHOD"), uri, remote));

    // Check for debug mode
    string debug = getenv("QUERY_STRING");
    if (debug == "debug" || debug == "1") {
        write("Content-Type: text/plain\r\n\r\n");
        write(dump_cgi_environment());
    } else {
        write("Content-Type: text/html\r\n\r\n");
        write("<h1>CGI Debug Tool</h1>\n");
        write("<p>Add ?debug to URL for diagnostic info.</p>\n");
    }
}
```

---

## See Also

- [Web Automation](/docs/network/web-automation) - HTTP clients and APIs
- [Internet Services](/docs/network/internet-services) - Email, FTP, DNS
- [File Access](/docs/files/file-access) - Working with files
- [Strings](/docs/basics/strings) - Text processing
