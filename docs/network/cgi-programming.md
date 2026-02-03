---
id: cgi-programming
title: CGI Programming
sidebar_label: CGI Programming
---
## 19. CGI Programming
### Introduction to CGI Programming
```pike
CGI (Common Gateway Interface) allows web servers to execute programs
and display their output. Pike provides built-in CGI support through
various modules including Protocols.HTTP and CGI.
Environment variables available in CGI:
REQUEST_METHOD, QUERY_STRING, CONTENT_TYPE, CONTENT_LENGTH
SCRIPT_NAME, PATH_INFO, PATH_TRANSLATED, SERVER_NAME, SERVER_PORT
HTTP_USER_AGENT, HTTP_REFERER, HTTP_COOKIE, REMOTE_ADDR, etc.
import Standards.JSON;
Display all CGI environment variables
void show_env_vars() {
write("Content-Type: text/html\r\n\r\n");
write("\n");
write("CGI Environment\n");
write("CGI Environment Variables\n");
write("\n");
foreach(getenv(); string key; string value) {
write("%s%s\n",
key, value);
}
write("\n");
}
Simple JSON endpoint
void json_endpoint() {
mapping(string:string) data = ([
"method": getenv("REQUEST_METHOD") || "UNKNOWN",
"query": getenv("QUERY_STRING") || "",
"user_agent": getenv("HTTP_USER_AGENT") || "Unknown",
"remote_addr": getenv("REMOTE_ADDR") || "Unknown"
]);
string json = Standards.JSON.encode(data);
write("Content-Type: application/json\r\n");
write("Access-Control-Allow-Origin: *\r\n");
write("\r\n");
write(json);
}
Main entry point - determine response type based on Accept header
void main() {
string accept = getenv("HTTP_ACCEPT") || "";
if (has_prefix(accept, "application/json")) {
json_endpoint();
} else {
show_env_vars();
}
}
```
### Writing a CGI Script
```pike
#pragma strict_types
#pragma no_clone
A complete CGI script that handles GET and POST requests
import Protocols.HTTP;
URL decoding function
string url_decode(string s) {
return replace(replace(replace(s, "+", " "),
"%20", " "),
"\\\\", "\");
}
URL encoding function
string url_encode(string s) {
return Protocols.HTTP.http_encode_url(s);
}
Parse query string or POST data into a mapping
mapping(string:string) parse_form_data() {
mapping(string:string) form = ([]);
string data;
string method = getenv("REQUEST_METHOD") || "GET";
if (method == "GET") {
data = getenv("QUERY_STRING") || "";
} else if (method == "POST") {
int length = (int)(getenv("CONTENT_LENGTH") || "0");
if (length > 0 && length ", ">"),
"\"", """);
}
Send HTTP headers
void send_headers(string|void content_type, int|void status) {
if (!content_type) content_type = "text/html";
if (!status) status = 200;
string status_text = ([
200: "OK",
301: "Moved Permanently",
302: "Found",
400: "Bad Request",
404: "Not Found",
500: "Internal Server Error"
])[status] || "OK";
write("Status: %d %s\r\n", status, status_text);
write("Content-Type: %s; charset=utf-8\r\n", content_type);
write("\r\n");
}
Generate HTML form
string generate_form(mapping(string:string) values) {
string name = html_escape(values->name || "");
string email = html_escape(values->email || "");
string message = html_escape(values->message || "");
return sprintf(#
Contact Form
body { font-family: Arial, sans-serif; margin: 40px; }
input, textarea { display: block; margin: 10px 0; padding: 8px; }
button { padding: 10px 20px; cursor: pointer; }
Contact Form
Name:
Email:
Message:
%s
Submit
", name, email, message);
}
Process form submission
string process_form(mapping(string:string) form) {
// Validate required fields
if (!form->name || !String.trim_all(form->name)) {
return "ErrorName is required.";
}
if (!form->email || !has_suffix(form->email, "@")) {
return "ErrorValid email is required.";
}
// In production, save to database or send email
string name = html_escape(form->name);
string email = html_escape(form->email);
string message = html_escape(form->message || "");
return sprintf(#
Thank You
Thank You!
Your message has been received:
Name: %s
Email: %s
Message: %s
", name, email, message);
}
Main entry point
void main() {
mapping(string:string) form = parse_form_data();
string output;
if (getenv("REQUEST_METHOD") == "POST") {
output = process_form(form);
} else {
output = generate_form(form);
}
send_headers();
write(output);
}
```
### Redirecting Error Messages
```pike
#pragma strict_types
#pragma no_clone
Capture and redirect error messages to browser instead of server log
constant ERROR_LOG_FILE = "/tmp/cgi_errors.log";
Custom error handler that captures errors
mapping(string:string) error_data = ([
"has_error": "0",
"error_message": "",
"backtrace": ""
]);
Install error handler at the start of your CGI script
void install_error_handler() {
master()->set_inhibit_compile_errors(lambda(mixed err) {
error_data["has_error"] = "1";
error_data["error_message"] = sprintf("%O", err);
});
// Redirect stderr to a file
Stdio.File(ERROR_LOG_FILE, "wac")->dup2(stderr);
}
Send error page to browser
void send_error_page(string title, string message, string|void backtrace) {
write("Content-Type: text/html; charset=utf-8\r\n");
write("Status: 500 Internal Server Error\r\n");
write("\r\n");
string safe_title = replace(replace(replace(title, "", ">"), "\"", """);
string safe_message = replace(replace(replace(message, "\n", "\n"), "", ">");
string safe_backtrace = backtrace ? replace(replace(backtrace, "\n", "\n"), "
Error
body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
.error-box { background: #fff; border-left: 4px solid #d32f2f; padding: 20px; }
.error-title { color: #d32f2f; margin-top: 0; }
.error-message { white-space: pre-wrap; }
.backtrace { background: #f5f5f5; padding: 15px; margin-top: 20px;
font-family: monospace; font-size: 12px; }
%s
%s", safe_title, safe_message);
if (safe_backtrace != "") {
write(sprintf("        Backtrace:%s\n", safe_backtrace));
}
write("    \n");
write("\n");
}
Log error to file with timestamp
void log_error(string message) {
string timestamp = Calendar.now()->format_time();
string remote = getenv("REMOTE_ADDR") || "unknown";
string uri = getenv("REQUEST_URI") || "unknown";
string log_entry = sprintf("[%s] %s %s: %s\n", timestamp, remote, uri, message);
Stdio.File f = Stdio.File();
if (f->open(ERROR_LOG_FILE, "wac")) {
f->write(log_entry);
f->close();
}
}
Wrapper function for safe execution
mixed safe_execute(function():mixed cb) {
install_error_handler();
mixed result = catch {
return cb();
};
if (result) {
// Error was caught
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
Example usage
void main() {
mixed err = safe_execute(lambda() {
// Your CGI code here
write("Content-Type: text/html\r\n\r\n");
write("Hello World!\n");
});
if (err) {
// Error was already handled by safe_execute
return;
}
}
```
### Fixing a 500 Server Error
```pike
#pragma strict_types
#pragma no_clone
Common causes of 500 errors and how to debug them
1. Check file permissions (must be executable)
$ chmod +x yourscript.pike
2. Check shebang line at top of file
#!/usr/bin/pike8
3. Ensure proper HTTP headers are sent FIRST
void debug_cgi() {
string debug = getenv("DEBUG_CGI") || "";
if (debug == "1") {
// Enable verbose error output for debugging
master()->set_inhibit_compile_errors(0);
add_constant("verbose_errors", 1);
}
}
Common 500 error causes checklist
mapping(string:string) check_environment() {
mapping(string:string) issues = ([]);
// Check if we have required CGI environment variables
if (!getenv("REQUEST_METHOD")) {
issues["no_cgi_env"] = "Not running in CGI environment";
}
// Check if we can write to stdout
Stdio.File stdout_file = Stdio.File(stdout);
if (!stdout_file || stdout_file->is_open()) {
issues["stdout_closed"] = "Cannot write to stdout";
}
return issues;
}
Send proper error response
void error_response(int code, string message) {
string title = ([
400: "Bad Request",
404: "Not Found",
500: "Internal Server Error",
503: "Service Unavailable"
])[code] || "Error";
write("Status: %d %s\r\n", code, title);
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(sprintf(#
%d %s
body{font-family:Arial,sans-serif;margin:40px;text-align:center;}
%d %s%s",
code, title, code, title, message));
}
Validate CGI script syntax before execution
int validate_script(string script_path) {
string content;
Stdio.File f = Stdio.File();
if (!f->open(script_path, "r")) {
return 0;  // Cannot open file
}
content = f->read();
f->close();
// Check for shebang
if (!has_prefix(content, "#!")) {
return 0;  // Missing shebang
}
// Check for main() function
if (!has_value(content, "void main()") &&
!has_value(content, "int main()")) {
return 0;  // Missing main() function
}
return 1;
}
Debug helper - outputs diagnostic information
void show_diagnostics() {
write("Content-Type: text/plain\r\n\r\n");
write("CGI Diagnostics\n===============\n\n");
write("Environment Variables:\n");
foreach (getenv(); string k; string v) {
write("  %s: %s\n", k, v);
}
write(sprintf("\nPike Version: %s\n", __VERSION__));
write(sprintf("Current Working Directory: %s\n", getcwd()));
}
Example CGI script with proper error handling
void main() {
// Enable debugging if requested
debug_cgi();
// Check environment
mapping(string:string) issues = check_environment();
if (sizeof(issues)) {
if (getenv("DEBUG_CGI") == "1") {
show_diagnostics();
} else {
error_response(500, "CGI environment error");
}
return;
}
// Your CGI code here - ALWAYS send headers first
mixed err = catch {
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write("\n");
write("Success\n");
write("CGI Script Working!\n");
};
if (err) {
error_response(500, sprintf("%O", err));
}
}
```
### Writing a Safe CGI Program
```pike
#pragma strict_types
#pragma no_clone
Security-focused CGI programming with input validation and XSS prevention
import Protocols.HTTP;
Configuration constants
constant MAX_POST_SIZE = 1048576;         // 1MB limit
constant MAX_FIELD_LENGTH = 1000;          // Per-field limit
constant ALLOWED_TAGS = (["b":1, "i":1, "em":1, "strong":1, "p":1, "br":1]);
HTML escape to prevent XSS attacks
string html_escape(string s) {
return replace(replace(replace(replace(s, "&", "&"),
"", ">"),
"\"", """);
}
Strip dangerous HTML tags (basic XSS prevention)
string sanitize_html(string html) {
// Remove script tags and content
string result = replace(html, " max_length) {
return 0;
}
// Trim whitespace
string result = String.trim_all(input);
// Check for null bytes
if (has_value(result, "\0")) {
return 0;
}
// Remove HTML unless explicitly allowed
if (!allow_html) {
result = html_escape(result);
} else {
result = sanitize_html(result);
}
return result;
}
Validate email format
int is_valid_email(string email) {
if (!email || sizeof(email)  254) {
return 0;
}
// Basic email validation using Regexp
return Regexp.simple(email, "^[\\w._%+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$");
}
Validate URL format
int is_valid_url(string url) {
if (!url) return 0;
// Check for allowed protocols only
array(string) allowed = ({"http://", "https://", "ftp://"});
foreach(allowed; string proto) {
if (has_prefix(url, proto)) return 1;
}
return 0;
}
Rate limiting using simple file-based storage
mapping(string:int) rate_limits = ([]);
int rate_limit_window = 60;  // seconds
int max_requests_per_window = 10;
int check_rate_limit(string identifier) {
int now = time();
if (!rate_limits[identifier]) {
rate_limits[identifier] = now;
return 1;
}
int last_request = rate_limits[identifier];
int elapsed = now - last_request;
if (elapsed >= rate_limit_window) {
rate_limits[identifier] = now;
return 1;
}
return 0;  // Rate limited
}
CSRF token generation and validation
string generate_csrf_token(string session_id) {
string secret = getenv("CSRF_SECRET") || "default-secret-change-me";
string timestamp = (string)time();
string data = session_id + timestamp + secret;
return String.hash2(data, "SHA256");
}
Parse and validate form data
mapping(string:string) parse_and_validate() {
mapping(string:string) form = ([]);
string data;
string method = getenv("REQUEST_METHOD") || "GET";
if (method == "POST") {
string content_length = getenv("CONTENT_LENGTH") || "0";
int len = (int)content_length;
// Enforce size limit
if (len > MAX_POST_SIZE) {
write("Status: 413 Payload Too Large\r\n\r\nRequest too large.");
return ([]);
}
if (len > 0) {
data = Stdio.File(stdin).read(len);
}
} else {
data = getenv("QUERY_STRING") || "";
}
if (data) {
foreach(data / "&"; string pair) {
array(string) parts = pair / "=";
if (sizeof(parts) == 2) {
string|zero val = validate_string(
Protocols.HTTP.http_decode_url(parts[1])
);
if (val) form[parts[0]] = val;
}
}
}
return form;
}
Send secure headers
void send_secure_headers() {
write("X-Content-Type-Options: nosniff\r\n");
write("X-Frame-Options: SAMEORIGIN\r\n");
write("X-XSS-Protection: 1; mode=block\r\n");
write("Content-Type: text/html; charset=utf-8\r\n");
write("\r\n");
}
Example safe CGI handler
void main() {
// Check rate limit by IP
string ip = getenv("REMOTE_ADDR") || "unknown";
if (!check_rate_limit(ip)) {
write("Status: 429 Too Many Requests\r\n\r\nRate limit exceeded.");
return;
}
mapping(string:string) form = parse_and_validate();
// Validate email if provided
if (form->email && !is_valid_email(form->email)) {
send_secure_headers();
write("Invalid email address\n");
return;
}
// Safe output with all input escaped
send_secure_headers();
write("\n");
write("Safe CGI\n");
write("Safe Form Submission\n");
if (form->name) {
write(sprintf("Hello, %s!\n", form->name));
}
write("\n");
}
```
### Making CGI Scripts Efficient
```pike
#pragma strict_types
#pragma no_clone
Efficiency techniques for CGI scripts in Pike
1. Use persistent connection for database access
constant DB_CACHE_FILE = "/tmp/cgi_db_cache.pike";
Simple in-memory cache (process-specific)
mapping(string:mixed) cache = ([]);
mapping(string:int) cache_times = ([]);
int cache_ttl = 300;  // 5 minutes
Get value from cache if available and fresh
mixed|zero cache_get(string key) {
if (cache[key] && cache_times[key]) {
if (time() - cache_times[key] 
%s
%s
;
string footer_template #
© 2024 My App
;
Efficient string builder for large output
class StringBuilder {
array(string) parts = ({});
int total_size = 0;
void append(string|mixed s) {
string str = (string)s;
parts += ({ str });
total_size += sizeof(str);
}
void appendf(string fmt, mixed... args) {
string str = sprintf(fmt, @args);
parts += ({ str });
total_size += sizeof(str);
}
string get() {
return parts * "";
}
int length() {
return total_size;
}
}
3. Lazy loading of expensive resources
class LazyLoader {
mixed value;
function(:mixed) loader;
int loaded = 0;
void create(function(:mixed) f) {
loader = f;
}
mixed get() {
if (!loaded) {
value = loader();
loaded = 1;
}
return value;
}
}
4. Batched database queries (simulated)
array(mapping) fetch_users_batch(array(int) user_ids) {
// In production, use a single IN query instead of N queries
// SELECT * FROM users WHERE id IN (1,2,3,...)
return ({});  // Simulated
}
5. Output buffering - send headers once, then body
class BufferedOutput {
StringBuilder buffer = StringBuilder();
int headers_sent = 0;
mapping(string:string) headers = ([
"Content-Type": "text/html; charset=utf-8"
]);
void set_header(string name, string value) {
headers[name] = value;
}
void write(string|mixed s) {
buffer->append(s);
}
void flush() {
if (!headers_sent) {
foreach(headers; string name; string value) {
write(sprintf("%s: %s\r\n", name, value));
}
write("\r\n");
headers_sent = 1;
}
if (buffer->length()) {
write(buffer->get());
buffer = StringBuilder();
}
}
}
6. Connection pooling helper
class ConnectionPool {
int max_connections;
array(object) pool;
int created = 0;
void create(int max) {
max_connections = max;
pool = ({});
}
object|zero acquire() {
if (sizeof(pool)) return pop(pool);
if (created set_header("X-Cache", "HIT");
out->write(cached);
out->flush();
return;
}
// Build response efficiently
out->set_header("X-Cache", "MISS");
StringBuilder sb = StringBuilder();
sb->append(header_template);
sb->appendf("Efficient CGI Page", "Efficient CGI Page");
// Add dynamic content
sb->append("Page generated at: ");
sb->append(ctime(time()));
sb->append("\n");
sb->append(footer_template);
string response = sb->get();
// Cache the response for GET requests
if (getenv("REQUEST_METHOD") == "GET") {
cache_set(cache_key, response);
}
out->write(response);
out->flush();
}
```
### Executing Commands Without Shell Escapes
```pike
#pragma strict_types
#pragma no_clone
Safely execute external commands without shell interpolation
NEVER use system() or popen() with user input - always use Process.spawn()
import Process;
WRONG - DANGEROUS - allows shell injection
// string input = getenv("QUERY_STRING");
// system("ls " + input);  // DON'T DO THIS!
RIGHT - SAFE - direct execution without shell
string safe_exec(string... args) {
Process.Process p = Process.spawn(args, ([
"stdout": Process.PIPE,
"stderr": Process.PIPE,
"stdin": Process.PIPE
]));
string output = p->stdout()->read();
string errors = p->stderr()->read();
int status = p->wait();
if (status != 0) {
return "Error: " + errors;
}
return output;
}
Validate filename to prevent path traversal
int is_safe_filename(string name) {
// Reject empty names
if (!name || sizeof(name) == 0) return 0;
// Reject path separators
if (has_value(name, "/") || has_value(name, "\\")) return 0;
// Reject path traversal attempts
if (has_value(name, "..")) return 0;
// Only allow alphanumeric, underscore, dash, and dot
int safe_chars = 0;
for (int i = 0; i = "a" && c = "A" && c = "0" && c stdout()->read();
string stderr = p->stderr()->read();
int exit_code = p->wait();
return ([
"stdout": stdout,
"stderr": stderr,
"exit_code": (string)exit_code,
"status": exit_code == 0 ? "success" : "error"
]);
}
Wrapper for handling file operations safely
string safe_file_info(string filename) {
if (!is_safe_filename(filename)) {
return "Error: Invalid filename";
}
// Use Process.spawn instead of system()
return safe_exec("/usr/bin/file", "/safe/uploads/" + filename);
}
Example CGI handler for safe command execution
void main() {
write("Content-Type: text/plain; charset=utf-8\r\n\r\n");
// Example: Safe directory listing
array(string) args = ({ "/bin/ls", "-la", "/safe" });
mapping(string:string) result = safe_command(args[0], args[1..]);
write("Command Result:\n");
write("Status: " + result["status"] + "\n");
write("Exit code: " + result["exit_code"] + "\n");
write("\nOutput:\n" + result["stdout"]);
if (result["stderr"]) {
write("\nErrors:\n" + result["stderr"]);
}
}
Also available: Process.popen() for reading command output
But always validate arguments before passing!
string safe_popen(string program, array(string) args) {
string output = "";
Process.Process p = Process.spawn(args, ([
"stdout": Process.PIPE
]));
output = p->stdout()->read();
p->wait();
return output;
}
```
### Formatting Lists and Tables with HTML Shortcuts
```pike
#pragma strict_types
#pragma no_clone
HTML helper functions for generating common UI elements
HTML tag builder helper
string tag(string name, string|void content, mapping(string:string)|void attrs) {
string attr_str = "";
if (attrs) {
foreach(attrs; string k; string v) {
attr_str += " " + k + "=\"" + v + "\"";
}
}
if (content) {
return sprintf("%s", name, attr_str, content, name);
}
return sprintf("", name, attr_str);
}
HTML escape function
string h(string s) {
return replace(replace(replace(replace(s, "&", "&"),
"", ">"),
"\"", """);
}
Unordered list generator
string ul(array(string) items, mapping(string:string)|void attrs) {
array(string) lis = ({});
foreach(items; string item) {
lis += ({ "  " + h(item) + "" });
}
return "\n" +
lis * "\n" + "\n";
}
Ordered list generator
string ol(array(string) items, int|void start) {
array(string) lis = ({});
foreach(items; string item) {
lis += ({ "  " + h(item) + "" });
}
string start_attr = start ? sprintf(" start=\"%d\"", start) : "";
return "\n" + (lis * "\n") + "\n";
}
Definition list generator
string dl(mapping(string:string) items) {
array(string) pairs = ({});
foreach(items; string term; string definition) {
pairs += ({ "  " + h(term) + "",
"  " + h(definition) + "" });
}
return "\n" + (pairs * "\n") + "\n";
}
Table generator from array of arrays
string table(array(array(string)) rows,
array(string)|void headers,
mapping(string:string)|void attrs) {
string attr_str = "";
if (attrs) {
foreach(attrs; string k; string v) {
attr_str += " " + k + "=\"" + v + "\"";
}
}
string html = "\n";
// Add header row if provided
if (headers) {
html += "  \n    \n";
foreach(headers; string h) {
html += sprintf("      %s\n", h(h));
}
html += "    \n  \n";
}
// Add data rows
html += "  \n";
foreach(rows; array(string) row; int row_idx) {
html += sprintf("    \n",
row_idx % 2 ? "odd" : "even");
foreach(row; string cell) {
html += sprintf("      %s\n", h(cell));
}
html += "    \n";
}
html += "  \n";
html += "";
return html;
}
Table from mapping (key-value pairs)
string kv_table(mapping(string:string) data,
string|void key_header,
string|void value_header) {
array(array(string)) rows = ({});
foreach(data; string k; string v) {
rows += ({ ({ k, v }) });
}
array(string) headers = ((key_header && value_header) ? ({key_header, value_header}) : UNDEFINED);
return table(rows, headers);
}
Form generator
string form(string action,
string|void method,
string|void content,
mapping(string:string)|void attrs) {
if (!method) method = "POST";
return sprintf("%s",
action, method,
attrs ? " enctype=\"multipart/form-data\"" : "",
content || "");
}
Select dropdown generator
string select(string name,
array(string) options,
string|void selected) {
string html = sprintf("\n", name);
foreach(options; string opt) {
string sel = (opt == selected) ? " selected" : "";
html += sprintf("  %s\n",
h(opt), sel, h(opt));
}
html += "";
return html;
}
Checkbox generator
string checkbox(string name, string value, int|void checked) {
string chk = checked ? " checked" : "";
return sprintf("",
name, h(value), chk);
}
Pagination links generator
string pagination(int current, int total, int per_page) {
int pages = (total + per_page - 1) / per_page;
string html = "\n";
if (current > 1) {
html += sprintf("  Prev\n", current - 1);
}
for (int i = 1; i %d\n", i, cls, i);
}
if (current Next\n", current + 1);
}
html += "";
return html;
}
Example usage in CGI
void main() {
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
// Sample data
array(string) fruits = ({"Apple", "Banana", "Cherry", "Date"});
array(array(string)) users = ({
({"Alice", "alice@example.com", "Admin"}),
({"Bob", "bob@example.com", "User"}),
({"Carol", "carol@example.com", "User"})
});
array(string) headers = ({"Name", "Email", "Role"});
write(#
HTML Helpers Demo
body { font-family: Arial, sans-serif; margin: 40px; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background: #4CAF50; color: white; }
.even { background: #f2f2f2; }
ul, ol { margin: 20px 0; }
HTML Helpers Demo
Unordered List");
write(ul(fruits));
write("
Ordered List");
write(ol(fruits, 5));
write("
Definition List");
write(dl((["Pike": "A dynamic programming language",
"CGI": "Common Gateway Interface"])));
write("
Data Table");
write(table(users, headers, (["class": "data-table"])));
write("
Pagination");
write(pagination(2, 45, 10));
write("\n");
}
```
### Redirecting to a Different Location
```pike
#pragma strict_types
#pragma no_clone
HTTP redirects for CGI applications
Simple 301 Moved Permanently redirect
void redirect_permanent(string url) {
write("Status: 301 Moved Permanently\r\n");
write(sprintf("Location: %s\r\n", url));
write("Content-Type: text/html\r\n");
write("\r\n");
write(sprintf(#
Moved
301 Moved Permanently
This resource has moved to %s.
", url, url));
}
Temporary 302 Found redirect (common for POST-Redirect-GET pattern)
void redirect_temporary(string url) {
write("Status: 302 Found\r\n");
write(sprintf("Location: %s\r\n", url));
write("Content-Type: text/html\r\n");
write("\r\n");
write(sprintf(#
Redirect
302 Found
Redirecting to %s...
window.location="%s";
", url, url, url));
}
303 See Other redirect (after POST to prevent resubmission)
void redirect_after_post(string url) {
write("Status: 303 See Other\r\n");
write(sprintf("Location: %s\r\n", url));
write("\r\n");
}
307 Temporary Redirect (preserves method)
void redirect_temp_preserve(string url) {
write("Status: 307 Temporary Redirect\r\n");
write(sprintf("Location: %s\r\n", url));
write("\r\n");
}
Safe redirect with validation (prevent open redirect attacks)
int is_safe_url(string url) {
// Reject empty URLs
if (!url) return 0;
// Allow relative URLs starting with /
if (has_prefix(url, "/")) return 1;
// Allow absolute URLs only from whitelist
string host = getenv("HTTP_HOST") || "localhost";
array(string) allowed_hosts = ({ host, "www." + host });
foreach(allowed_hosts; string allowed) {
if (has_prefix(url, "http://" + allowed) ||
has_prefix(url, "https://" + allowed)) {
return 1;
}
}
return 0;
}
void safe_redirect(string|void url) {
// Default to home if URL is invalid
if (!url || !is_safe_url(url)) {
url = "/";
}
redirect_temporary(url);
}
Build URL with query string
string build_url(string base, mapping(string:string) params) {
array(string) pairs = ({});
foreach(params; string key; string value) {
string encoded_key = Protocols.HTTP.http_encode_url(key);
string encoded_value = Protocols.HTTP.http_encode_url(value);
pairs += ({ encoded_key + "=" + encoded_value });
}
string separator = has_value(base, "?") ? "&" : "?";
return base + separator + pairs * "&";
}
Refresh meta redirect (client-side fallback)
void meta_redirect(string url, int|void delay) {
if (!delay) delay = 0;
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(sprintf(#
Redirecting...
body{font-family:Arial,sans-serif;text-align:center;margin-top:100px;}
Redirecting...
Please wait while we redirect you to %s.
setTimeout(function(){window.location="%s";},%d*1000);
", delay, url, url,
delay == 0 ? " style=\"display:none\"" : "",
url, url, delay));
}
Example: POST-Redirect-GET pattern to prevent form resubmission
void handle_form_post() {
// Process the form data...
// Store success message in session or cookie
set_cookie("flash_message", "Form submitted successfully!");
// Redirect to GET page
redirect_after_post("/thank-you");
}
Simple cookie setting helper
void set_cookie(string name, string value,
int|void lifetime,
string|void path,
string|void domain) {
if (!path) path = "/";
if (!lifetime) lifetime = 3600;  // 1 hour default
int expiry = time() + lifetime;
string date = Calendar.Second(expiry)->format_http();
string cookie = sprintf("%s=%s; Expires=%s; Path=%s",
name, value, date, path);
if (domain) cookie += "; Domain=" + domain;
// Set cookie via Set-Cookie header
write(sprintf("Set-Cookie: %s\r\n", cookie));
}
Example usage
void main() {
string redirect_target = getenv("QUERY_STRING");
if (redirect_target) {
// Parse the target parameter
mapping(string:string) params = ([]);
foreach(redirect_target / "&"; string pair) {
array(string) parts = pair / "=";
if (sizeof(parts) == 2) {
params[parts[0]] = Protocols.HTTP.http_decode_url(parts[1]);
}
}
// Safely redirect to target (prevents open redirect attacks)
safe_redirect(params->url);
} else {
// Show a page with redirect examples
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(#
Redirect Examples
HTTP Redirect Examples
Temporary redirect (302)
Safe redirect
Default redirect
");
}
}
```
### Debugging the Raw HTTP Exchange
```pike
#pragma strict_types
#pragma no_clone
HTTP debugging tools for CGI applications
import Protocols.HTTP;
Log file for HTTP debugging
constant DEBUG_LOG = "/tmp/http_debug.log";
Write debug information to log file
void debug_log(string message) {
string timestamp = Calendar.now()->format_time();
Stdio.File f = Stdio.File();
if (f->open(DEBUG_LOG, "wac")) {
f->write(sprintf("[%s] %s\n", timestamp, message));
f->close();
}
}
Dump all HTTP headers received
string dump_request_headers() {
string output = "=== HTTP Request Headers ===\n";
// Standard CGI environment variables that represent headers
array(string) http_vars = ({
"HTTP_ACCEPT", "HTTP_ACCEPT_CHARSET", "HTTP_ACCEPT_ENCODING",
"HTTP_ACCEPT_LANGUAGE", "HTTP_AUTHORIZATION", "HTTP_CONNECTION",
"HTTP_COOKIE", "HTTP_HOST", "HTTP_REFERER",
"HTTP_USER_AGENT", "HTTP_X_FORWARDED_FOR"
});
foreach(http_vars; string var) {
string value = getenv(var);
if (value) {
// Convert HTTP_XXX to readable header name
string header_name = replace(var->substring(5), "_", "-");
output += sprintf("%s: %s\n", header_name, value);
}
}
return output;
}
Dump all CGI environment variables
string dump_cgi_environment() {
string output = "=== CGI Environment ===\n";
array(string) cgi_vars = ({
"REQUEST_METHOD", "REQUEST_URI", "QUERY_STRING",
"CONTENT_TYPE", "CONTENT_LENGTH",
"SCRIPT_NAME", "PATH_INFO", "PATH_TRANSLATED",
"SERVER_NAME", "SERVER_PORT", "SERVER_PROTOCOL",
"REMOTE_ADDR", "REMOTE_HOST", "REMOTE_USER",
"AUTH_TYPE", "DOCUMENT_ROOT"
});
foreach(cgi_vars; string var) {
string value = getenv(var);
output += sprintf("%s: %s\n", var, value || "(not set)");
}
return output;
}
Read and dump raw POST data
string dump_post_data() {
string output = "=== POST Data ===\n";
string method = getenv("REQUEST_METHOD") || "GET";
string content_type = getenv("CONTENT_TYPE") || "";
output += sprintf("Method: %s\n", method);
output += sprintf("Content-Type: %s\n", content_type);
if (method == "POST") {
string length = getenv("CONTENT_LENGTH") || "0";
output += sprintf("Content-Length: %s\n", length);
int len = (int)length;
if (len > 0 && len = 2) {
output += sprintf("%s: %s\n", parts[0], parts[1] * "=");
}
}
}
return output;
}
Generate full HTTP request dump
string dump_full_request() {
string output = "";
output += dump_cgi_environment();
output += "\n";
output += dump_request_headers();
output += "\n";
output += dump_cookies();
output += "\n";
output += dump_post_data();
return output;
}
Save request info to debug log
void log_request() {
string remote = getenv("REMOTE_ADDR") || "unknown";
string method = getenv("REQUEST_METHOD") || "UNKNOWN";
string uri = getenv("REQUEST_URI") || "/";
debug_log(sprintf("%s %s from %s", method, uri, remote));
}
Pretty HTML output for debugging
string html_debug_output() {
string output = dump_full_request();
// Escape HTML and wrap in  tags
output = replace(replace(replace(output, "", ">"),
"\n", "\n");
return sprintf(#
HTTP Debug Info
body { font-family: monospace; margin: 20px; background: #1e1e1e; color: #d4d4d4; }
h1 { color: #4ec9b0; }
.section { color: #569cd6; font-weight: bold; margin-top: 20px; }
pre { background: #252526; padding: 15px; border-radius: 5px; }
HTTP Request Debug Information
%s
Timestamp: %s
",
output, ctime(time()));
}
Main debug CGI handler
void main() {
// Always log requests
log_request();
// Check if debugging is enabled
string debug = getenv("DEBUG_HTTP") || getenv("QUERY_STRING") || "";
if (debug == "1" || debug == "debug") {
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(html_debug_output());
} else {
// Normal request handling
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(#
HTTP Debug Tool
body{font-family:Arial,sans-serif;margin:40px;text-align:center;}
HTTP Debug Tool
Add ?debug to URL to see full HTTP request dump.
All requests are logged to: /tmp/http_debug.log
");
}
}
```
### Managing Cookies
```pike
#pragma strict_types
#pragma no_clone
Cookie management for CGI applications
Parse Cookie header into mapping
mapping(string:string) parse_cookies() {
mapping(string:string) cookies = ([]);
string cookie_header = getenv("HTTP_COOKIE") || "";
if (cookie_header != "") {
foreach(cookie_header / ";"; string cookie) {
string trimmed = String.trim_all(cookie);
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
Cookie attributes
class CookieAttributes {
string value;
int|void max_age;
int|void expires;
string|void domain;
string|void path;
int|void secure;
int|void http_only;
string|void same_site;  // "Strict", "Lax", or "None"
void create(string _value,
mapping(string:mixed)|void attrs) {
value = _value;
if (attrs) {
max_age = attrs["max_age"];
expires = attrs["expires"];
domain = attrs["domain"];
path = attrs["path"];
secure = attrs["secure"];
http_only = attrs["http_only"];
same_site = attrs["same_site"];
}
}
string format() {
string result = value;
if (max_age) {
result += sprintf("; Max-Age=%d", max_age);
}
if (expires) {
string date = Calendar.Second(expires)->format_http();
result += "; Expires=" + date;
}
if (path) {
result += "; Path=" + path;
}
if (domain) {
result += "; Domain=" + domain;
}
if (secure) {
result += "; Secure";
}
if (http_only) {
result += "; HttpOnly";
}
if (same_site) {
result += "; SameSite=" + same_site;
}
return result;
}
}
Set a cookie with full attribute support
void set_cookie(string name,
string|CookieAttributes value_or_attrs,
mapping(string:mixed)|void attrs) {
CookieAttributes cookie_attrs;
if (objectp(value_or_attrs)) {
cookie_attrs = value_or_attrs;
} else {
cookie_attrs = CookieAttributes(value_or_attrs, attrs);
}
string cookie = sprintf("%s=%s", name, cookie_attrs->format());
write(sprintf("Set-Cookie: %s\r\n", cookie));
}
Delete a cookie by setting max-age=0
void delete_cookie(string name, string|void path) {
if (!path) path = "/";
set_cookie(name, "", ([
"max_age": 0,
"path": path,
"expires": 1  // Unix timestamp 1 = past
]));
}
Session management using cookies
class Session {
string session_id;
mapping(string:mixed) data = ([]);
int created;
int last_activity;
int timeout = 1800;  // 30 minutes
void create(string|void id) {
created = time();
last_activity = created;
if (id) {
session_id = id;
} else {
session_id = generate_session_id();
}
}
string generate_session_id() {
string data = sprintf("%d.%s.%d",
time(),
String.string2hex(Crypto.Random.random_string(16)),
getpid());
return String.hash2(data, "SHA256");
}
int is_expired() {
return (time() - last_activity) > timeout;
}
void touch() {
last_activity = time();
}
mixed get(string key) {
return data[key];
}
void set(string key, mixed value) {
data[key] = value;
touch();
}
}
In-memory session store (for production, use database)
mapping(string:Session) sessions = ([]);
Session|zero get_session(string|void session_id) {
// Clean up expired sessions first
foreach (indices(sessions); string id) {
if (sessions[id]->is_expired()) {
m_delete(sessions, id);
}
}
if (session_id && sessions[session_id]) {
Session s = sessions[session_id];
s->touch();
return s;
}
// Create new session
Session new_session = Session();
sessions[new_session->session_id] = new_session;
return new_session;
}
Send session cookie
void send_session_cookie(Session session) {
set_cookie("session_id", session->session_id, ([
"http_only": 1,
"same_site": "Lax",
"path": "/",
"max_age": 3600
]));
}
Example usage: Counter with session persistence
void main() {
// Get session from cookie
mapping(string:string) cookies = parse_cookies();
Session session = get_session(cookies["session_id"]);
// Handle actions
string action = getenv("QUERY_STRING") || "";
if (action == "increment") {
int count = (int)(session->get("count") || "0");
session->set("count", (string)(count + 1));
} else if (action == "reset") {
session->set("count", "0");
}
// Ensure session cookie is set
send_session_cookie(session);
// Send response
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
int count = (int)(session->get("count") || "0");
write(sprintf(#
Session Counter
body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
.counter { font-size: 48px; margin: 20px 0; }
button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
Session Counter
Session ID: %s
%d
Increment
Reset
Refresh to persist. Close browser to end session.
",
session->session_id, count));
}
```
### Creating Sticky Widgets
```pike
#pragma strict_types
#pragma no_clone
Sticky widgets preserve user input across form submissions
HTML escape function
string h(string s) {
return replace(replace(replace(replace(s, "&", "&"),
"", ">"),
"\"", """);
}
Parse form data from GET or POST
mapping(string:string) parse_form() {
mapping(string:string) form = ([]);
string data;
string method = getenv("REQUEST_METHOD") || "GET";
if (method == "POST") {
string length = getenv("CONTENT_LENGTH") || "0";
if ((int)length > 0) {
data = Stdio.File(stdin).read((int)length);
}
} else {
data = getenv("QUERY_STRING") || "";
}
if (data) {
foreach(data / "&"; string pair) {
array(string) parts = pair / "=";
if (sizeof(parts) == 2) {
form[parts[0]] = Protocols.HTTP.http_decode_url(parts[1]);
}
}
}
return form;
}
Sticky text input
string sticky_input(string name,
string|void value,
mapping(string:string)|void attrs,
mapping(string:string) form) {
// Use submitted value or default
string display_value = form[name] || value || "";
string attr_str = sprintf("name=\"%s\" value=\"%s\"", name, h(display_value));
if (attrs) {
foreach(attrs; string k; string v) {
attr_str += sprintf(" %s=\"%s\"", k, h(v));
}
}
return "";
}
Sticky textarea
string sticky_textarea(string name,
string|void value,
mapping(string:string)|void attrs,
mapping(string:string) form) {
string display_value = form[name] || value || "";
string attr_str = sprintf("name=\"%s\"", name);
if (attrs) {
foreach(attrs; string k; string v) {
attr_str += sprintf(" %s=\"%s\"", k, h(v));
}
}
return sprintf("%s",
attr_str, h(display_value));
}
Sticky checkbox
string sticky_checkbox(string name,
string value,
int|void default_checked,
mapping(string:string)|void attrs,
mapping(string:string) form) {
// Check if this checkbox was submitted
int checked = default_checked || 0;
if (form[name] == value) {
checked = 1;
} else if (indices(form) [name] && form[name] != value) {
// Checkbox exists in form but has different value = unchecked
checked = 0;
}
string attr_str = sprintf("type=\"checkbox\" name=\"%s\" value=\"%s\"",
name, h(value));
if (checked) attr_str += " checked";
if (attrs) {
foreach(attrs; string k; string v) {
attr_str += sprintf(" %s=\"%s\"", k, h(v));
}
}
return "";
}
Sticky radio button group
string sticky_radio(string name,
array(array(string)) options,  // ({({value, label}), ...})
string|void selected,
mapping(string:string) form) {
string current = form[name] || selected || "";
string html = "";
foreach(options; array(string) option) {
string value = option[0];
string label = option[1];
string sel = (value == current) ? " checked" : "";
html += sprintf(" %s\n",
name, h(value), sel, h(label));
}
return html;
}
Sticky select dropdown
string sticky_select(string name,
array(array(string)) options,
string|void selected,
int|void multiple,
mapping(string:string) form) {
string current = form[name] || selected || "";
string html = sprintf("\n",
name, multiple ? " multiple" : "");
foreach(options; array(string) option) {
string value = option[0];
string label = option[1];
string sel = (value == current) ? " selected" : "";
html += sprintf("  %s\n",
h(value), sel, h(label));
}
html += "";
return html;
}
Sticky multiselect (returns array of values)
string sticky_multiselect(string name,
array(array(string)) options,
array(string)|void selected,
mapping(string:string) form) {
// Parse multiple values from form (e.g., "name=val1&name=val2")
array(string) current = selected || ({});
// Collect all submitted values for this name
// (In a real implementation, you'd parse all values for the same key)
if (form[name] && form[name] != "") {
current = ({ form[name] });
}
string html = sprintf("\n", name);
foreach(options; array(string) option) {
string value = option[0];
string label = option[1];
string sel = has_value(current, value) ? " selected" : "";
html += sprintf("  %s\n",
h(value), sel, h(label));
}
html += "";
return html;
}
Complete sticky form example
void main() {
mapping(string:string) form = parse_form();
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(#
Sticky Form Demo
body { font-family: Arial, sans-serif; margin: 40px; }
fieldset { border: 1px solid #ddd; padding: 20px; margin-bottom: 20px; border-radius: 8px; }
legend { font-weight: bold; padding: 0 10px; }
label { display: block; margin: 10px 0 5px; }
input[type="text"], textarea, select { width: 300px; padding: 8px; }
textarea { height: 80px; }
button { padding: 10px 20px; cursor: pointer; }
.result { background: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
Sticky Form Widgets Demo
Submit the form - your values will be preserved!");
// Show submitted values
if (sizeof(form)) {
write("Submitted values:\n");
foreach(form; string k; string v) {
write(sprintf("%s: %s\n", k, h(v)));
}
write("\n");
}
// Generate sticky form
write("\n");
write("  \n");
write("    Personal Information\n");
write("    Name:\n");
write("    " + sticky_input("name", "Enter your name", (["placeholder": "John Doe"]), form) + "\n");
write("    Email:\n");
write("    " + sticky_input("email", "", (["type": "email", "placeholder": "john@example.com"]), form) + "\n");
write("  \n");
write("  \n");
write("    Preferences\n");
write("    Favorite Color:\n");
write("    " + sticky_select("color", ({
({"red", "Red"}), ({"green", "Green"}), ({"blue", "Blue"}), ({"purple", "Purple"})
}), "blue", 0, form) + "\n");
write("    "\n");
write("  \n");
write("    Options\n");
write("    "\n");
write("      " + sticky_checkbox("subscribe", "yes", 1, ([]), form) + " Subscribe to newsletter\n");
write("    \n");
write("  \n");
write("  \n");
write("    Message\n");
write("    "Your message:\n");
write("    " + sticky_textarea("message", "Type here...", (["rows": "4"]), form) + "\n");
write("  \n");
write("  Submit\n");
write("  Reset\n");
write("\n");
write("\n");
}
```
### Writing a Multiscreen CGI Script
```pike
#pragma strict_types
#pragma no_clone
Multiscreen/state-driven CGI application with navigation
HTML escape function
string h(string s) {
return replace(replace(replace(replace(s, "&", "&"),
"", ">"),
"\"", """);
}
Parse form data
mapping(string:string) parse_form() {
mapping(string:string) form = ([]);
string data = getenv("QUERY_STRING") || "";
string method = getenv("REQUEST_METHOD") || "GET";
if (method == "POST") {
string length = getenv("CONTENT_LENGTH") || "0";
if ((int)length > 0) {
data = Stdio.File(stdin).read((int)length);
}
}
if (data) {
foreach(data / "&"; string pair) {
array(string) parts = pair / "=";
if (sizeof(parts) == 2) {
form[parts[0]] = Protocols.HTTP.http_decode_url(parts[1]);
}
}
}
return form;
}
Application state (session data)
class AppState {
string current_screen;
mapping(string:string) data = ([]);
array(string) errors = ({});
array(string) messages = ({});
void create(string starting_screen) {
current_screen = starting_screen;
}
void set_screen(string screen) {
current_screen = screen;
}
void set_data(string key, string value) {
data[key] = value;
}
string|zero get_data(string key) {
return data[key];
}
void add_error(string error) {
errors += ({ error });
}
void add_message(string message) {
messages += ({ message });
}
}
Navigation helper
string nav_link(string screen, string label) {
return sprintf("%s", screen, label);
}
Render common header
string render_header(AppState state) {
return sprintf(#
Multi-Screen App - %s
body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
nav { background: #333; padding: 15px 20px; }
nav a { color: white; text-decoration: none; margin-right: 20px; }
nav a:hover { text-decoration: underline; }
nav a.active { font-weight: bold; color: #4CAF50; }
.container { max-width: 800px; margin: 30px auto; padding: 30px; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
.error { background: #ffebee; color: #c62828; padding: 10px; border-radius: 4px; margin: 10px 0; }
.message { background: #e8f5e9; color: #2e7d32; padding: 10px; border-radius: 4px; margin: 10px 0; }
h1 { margin-top: 0; color: #333; }
label { display: block; margin: 15px 0 5px; font-weight: bold; }
input, select, textarea { width: 100%%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; }
button { background: #4CAF50; color: white; border: none; padding: 12px 24px; border-radius: 4px; cursor: pointer; }
button:hover { background: #45a049; }
%s
",
String.capitalize(state->current_screen),
nav_link("home", "Home") + " " +
nav_link("form", "Form") + " " +
nav_link("confirm", "Confirm") + " " +
nav_link("result", "Result")
);
}
Render common footer
string render_footer() {
return "
";
}
Screen: Home
string screen_home(AppState state) {
return render_header(state) + sprintf(#
Welcome to the Multi-Screen Application
This is a demonstration of a state-driven CGI application in Pike.
Navigate through the screens using the menu above:
Home - This page
Form - Enter your information
Confirm - Review before submitting
Result - See the final output
Get Started
") + render_footer();
}
Screen: Form
string screen_form(AppState state, mapping(string:string) form) {
string name = form["name"] || state->get_data("name") || "";
string email = form["email"] || state->get_data("email") || "";
string interest = form["interest"] || state->get_data("interest") || "coding";
return render_header(state) + sprintf(#
Enter Your Information
Name:
Email:
Area of Interest:
Programming
Design
Business
Other
Continue to Confirm
",
h(name), h(email),
interest == "coding" ? " selected" : "",
interest == "design" ? " selected" : "",
interest == "business" ? " selected" : "",
interest == "other" ? " selected" : ""
) + render_footer();
}
Screen: Confirm
string screen_confirm(AppState state, mapping(string:string) form) {
// Save form data to state
if (form["name"]) state->set_data("name", form["name"]);
if (form["email"]) state->set_data("email", form["email"]);
if (form["interest"]) state->set_data("interest", form["interest"]);
string name = state->get_data("name") || "";
string email = state->get_data("email") || "";
string interest = state->get_data("interest") || "";
string interest_label = ([
"coding": "Programming",
"design": "Design",
"business": "Business",
"other": "Other"
])[interest] || interest;
return render_header(state) + sprintf(#
Confirm Your Information
Please review the information below before submitting:
Name:%s
Email:%s
Interest:%s
Confirm & Submit
Go Back
",
h(name), h(email), h(interest_label)
) + render_footer();
}
Screen: Result
string screen_result(AppState state) {
string name = state->get_data("name") || "Guest";
string ref_num = "REF-" + String.string2hex(Crypto.Random.random_string(4))[0..7];
return render_header(state) + sprintf(#
Thank You!
Submission Successful
Your information has been recorded.
Name: %s
Reference Number: %s
We've sent a confirmation email to your address.
Return Home
",
h(name), ref_num
) + render_footer();
}
Main application router
void main() {
mapping(string:string) form = parse_form();
string screen = form["screen"] || "home";
// Valid screens
array(string) valid_screens = ({"home", "form", "confirm", "result"});
if (search(valid_screens, screen) == -1) {
screen = "home";
}
// Create application state
AppState state = AppState(screen);
// Route to appropriate screen
string output;
switch (screen) {
case "home":
output = screen_home(state);
break;
case "form":
output = screen_form(state, form);
break;
case "confirm":
output = screen_confirm(state, form);
break;
case "result":
output = screen_result(state);
break;
default:
output = screen_home(state);
break;
}
// Send response
write("Content-Type: text/html; charset=utf-8\r\n\r\n");
write(output);
}
```
### Saving a Form to a File or Mail Pipe
```pike
```
### Program: chemiserie
```pike
```
