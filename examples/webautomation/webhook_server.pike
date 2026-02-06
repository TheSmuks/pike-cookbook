#!/usr/bin/env pike
#pragma strict_types
// Webhook server using Protocols.HTTP.Server

class WebhookHandler
{
    private array(mapping(string:mixed)) event_log = ({});
    private string secret;

    void create(string|void sec)
    {
        secret = sec || "webhook_secret_key";
    }

    // Handle incoming webhook
    mapping(string:mixed) handle_webhook(mapping(string:mixed) headers, string body, string path)
    {
        write("Received webhook on %s\n", path);

        // Log event
        mapping event = ([
            "timestamp": Calendar.now()->format_time(),
            "path": path,
            "headers": headers,
            "body": body
        ]);

        event_log += ({ event });

        // Verify signature if present
        if (headers["x-hub-signature"] || headers["x-webhook-signature"]) {
            if (!verify_signature(headers, body)) {
                return generate_response(401, "Invalid signature");
            }
        }

        // Parse JSON body if present
        string content_type;
        if (headers["content-type"]) {
            content_type = (string)headers["content-type"];
        }

        if (content_type && has_prefix(content_type, "application/json")) {
            mixed data = Standards.JSON.decode(body);

            if (mappingp(data)) {
                mapping event_data = (mapping)data;
                string event_type;
                mixed ev = event_data["event"];
                mixed ty = event_data["type"];
                if (ev) {
                    event_type = stringp(ev) ? (string)ev : "unknown";
                } else if (ty) {
                    event_type = stringp(ty) ? (string)ty : "unknown";
                } else {
                    event_type = "unknown";
                }
                write("  Event type: %s\n", event_type);

                string event_id;
                if (event_data["id"]) {
                    event_id = (string)event_data["id"];
                } else {
                    event_id = "N/A";
                }
                write("  Event ID: %s\n", event_id);

                // Process specific event types
                process_event((mapping(string:mixed))event_data);
            }
        }

        return generate_response(200, "Webhook received");
    }

    // Verify webhook signature
    int verify_signature(mapping(string:mixed) headers, string body)
    {
        string sig_header;
        if (headers["x-hub-signature"]) {
            sig_header = (string)headers["x-hub-signature"];
        } else if (headers["x-webhook-signature"]) {
            sig_header = (string)headers["x-webhook-signature"];
        }

        if (!sig_header) {
            return 0;
        }

        // Parse signature (format: sha1=...)
        array(string) parts = sig_header / "=";
        if (sizeof(parts) != 2) {
            return 0;
        }

        string expected_sig = parts[1];

        // Compute HMAC using Crypto.HMAC
        object hmac = Crypto.HMAC(Crypto.SHA256);
        string computed = (string)hmac(secret, body);
        string computed_hex = String.string2hex(computed);

        return constant_time_compare(computed_hex, expected_sig);
    }

    // Constant-time string comparison
    private int constant_time_compare(string a, string b)
    {
        if (sizeof(a) != sizeof(b)) {
            return 0;
        }

        int result = 1;
        for (int i = 0; i < sizeof(a); i++) {
            if (a[i] != b[i]) {
                result = 0;
            }
        }
        return result;
    }

    // Process webhook event
    void process_event(mapping(string:mixed) data)
    {
        string event_type;
        if (data["event"]) {
            event_type = (string)data["event"];
        } else if (data["type"]) {
            event_type = (string)data["type"];
        } else {
            event_type = "unknown";
        }

        switch(event_type)
        {
            case "push":
                write("  Processing push event\n");
                string repo_name = "unknown";
                mixed repo_mixed = data["repository"];
                if (repo_mixed && mappingp(repo_mixed)) {
                    mapping r = (mapping)repo_mixed;
                    mixed name = r["name"];
                    if (stringp(name)) {
                        repo_name = (string)name;
                    }
                }
                write("    Repository: %s\n", repo_name);

                string ref = "unknown";
                if (data["ref"]) {
                    ref = (string)data["ref"];
                }
                write("    Ref: %s\n", ref);
                break;

            case "pull_request":
                write("  Processing pull request event\n");
                string action = "unknown";
                if (data["action"]) {
                    action = (string)data["action"];
                }
                write("    Action: %s\n", action);

                int number = 0;
                if (data["number"]) {
                    number = (int)data["number"];
                }
                write("    PR #%d\n", number);
                break;

            case "deployment":
                write("  Processing deployment event\n");
                string env = "unknown";
                mixed deployment_mixed = data["deployment"];
                if (deployment_mixed && mappingp(deployment_mixed)) {
                    mapping d = (mapping)deployment_mixed;
                    mixed environment = d["environment"];
                    if (stringp(environment)) {
                        env = (string)environment;
                    }
                }
                write("    Environment: %s\n", env);
                break;

            default:
                write("  Unknown event type: %s\n", event_type);
                break;
        }
    }

    // Generate HTTP response mapping
    mapping(string:mixed) generate_response(int status, string message)
    {
        mapping response_body = ([
            "status": status,
            "message": message,
            "timestamp": Calendar.now()->format_time()
        ]);

        string body = Standards.JSON.encode(response_body);

        return ([
            "data": body,
            "type": "application/json",
            "error": status,
            "size": sizeof(body),
            "extra_heads": ([
                "Connection": "close"
            ])
        ]);
    }

    // Get event log
    array(mapping(string:mixed)) get_events()
    {
        return event_log;
    }

    // Clear event log
    void clear_events()
    {
        event_log = ({});
    }
}

// HTTP server that receives webhooks
class WebhookServer
{
    private Protocols.HTTP.Server.Port port;
    private WebhookHandler handler;
    private int server_port;

    void create(int port_num, string|void secret)
    {
        server_port = port_num;
        handler = WebhookHandler(secret);

        port = Protocols.HTTP.Server.Port(handle_request, server_port);
    }

    // Handle incoming HTTP request
    void handle_request(Protocols.HTTP.Server.Request req)
    {
        string path = req->not_query;
        string method = req->request_type;

        write("%s: %s\n", upper_case(method), path);

        if (method == "POST") {
            // Read request body
            string body = req->body_raw || "";

            // Handle webhook
            mixed headers = req->headers;
            mixed response;
            if (mappingp(headers)) {
                response = handler->handle_webhook((mapping(string:mixed))headers, body, path);
            } else {
                response = handler->handle_webhook(([]), body, path);
            }
            if (mappingp(response)) {
                req->response_and_finish((mapping(string:mixed))response);
            }
        } else if (method == "GET") {
            // Provide status information
            if (path == "/status") {
                mixed status = ([
                    "status": "running",
                    "webhooks_received": sizeof(handler->get_events()),
                    "timestamp": Calendar.now()->format_time()
                ]);

                if (mappingp(status)) {
                    string body = Standards.JSON.encode((mapping)status, Standards.JSON.PIKE_CANONICAL);
                    mixed resp_data = ([
                    "data": body,
                    "type": "application/json",
                    "error": 200,
                    "size": sizeof(body)
                ]);
                    if (mappingp(resp_data)) {
                        mapping(string:mixed) resp = (mapping(string:mixed))resp_data;
                        req->response_and_finish(resp);
                    }
                }
            } else {
                string body = "Webhook Server is running. GET /status for info.";
                mixed resp_data = ([
                    "data": body,
                    "type": "text/plain",
                    "error": 200,
                    "size": sizeof(body)
                ]);
                mapping(string:mixed) resp = (mapping(string:mixed))resp_data;
                req->response_and_finish(resp);
            }
        } else {
            mapping(string:mixed) resp = ([
                "data": "",
                "type": "text/plain",
                "error": 405,
                "size": 0
            ]);
            req->response_and_finish(resp);
        }
    }

    // Start server
    void start()
    {
        write("Webhook server listening on port %d\n", server_port);
        write("Endpoints:\n");
        write("  POST /webhook - Receive webhooks\n");
        write("  GET /status - Server status\n");
        write("\nWaiting for webhooks...\n\n");

        // Keep server running - wait indefinitely
        sleep(-1);
    }
}

int main(int argc, array(string) argv)
{
    int port = 8080;
    string secret = "my_webhook_secret";

    if (argc > 1) {
        port = (int)argv[1];
    }
    if (argc > 2) {
        secret = argv[2];
    }

    write("=== Webhook Server ===\n\n");

    WebhookServer server = WebhookServer(port, secret);
    server->start();

    return -1;  // Keep running
}
