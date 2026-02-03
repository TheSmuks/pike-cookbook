#!/usr/bin/env pike
#pragma strict_types
// Webhook server using Protocols.HTTP.Server

class WebhookHandler
{
    private mapping(string:mixed) event_log = ({});
    private string secret;

    void create(string|void sec)
    {
        secret = sec || "webhook_secret_key";
    }

    // Handle incoming webhook
    string handle_webhook(mapping headers, string body, string path)
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
        if (has_prefix((headers["content-type"] || ""), "application/json")) {
            mixed data = Standards.JSON.decode(body);

            if (mappingp(data)) {
                write("  Event type: %s\n", data->event || data->type || "unknown");
                write("  Event ID: %s\n", data->id || "N/A");

                // Process specific event types
                process_event(data);
            }
        }

        return generate_response(200, "Webhook received");
    }

    // Verify webhook signature
    int verify_signature(mapping headers, string body)
    {
        string sig_header = headers["x-hub-signature"] ||
                           headers["x-webhook-signature"];

        if (!sig_header) {
            return 0;  // No signature to verify
        }

        // Parse signature (format: sha1=...)
        array(string) parts = sig_header / "=";
        if (sizeof(parts) != 2) {
            return 0;
        }

        string expected_sig = parts[1];

        // Compute HMAC
        string computed = Crypto.SHA256.hmac(secret, body);
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
    void process_event(mapping data)
    {
        string event_type = data->event || data->type;

        switch(event_type)
        {
            case "push":
                write("  Processing push event\n");
                write("    Repository: %s\n", data->repository->name || "unknown");
                write("    Ref: %s\n", data->ref || "unknown");
                break;

            case "pull_request":
                write("  Processing pull request event\n");
                write("    Action: %s\n", data->action || "unknown");
                write("    PR #%d\n", data->number || 0);
                break;

            case "deployment":
                write("  Processing deployment event\n");
                write("    Environment: %s\n", data->deployment->environment || "unknown");
                break;

            default:
                write("  Unknown event type: %s\n", event_type);
                break;
        }
    }

    // Generate HTTP response
    string generate_response(int status, string message)
    {
        mapping response = ([
            "status": status,
            "message": message,
            "timestamp": Calendar.now()->format_time()
        ]);

        string body = Standards.JSON.encode(response);

        return sprintf("HTTP/1.1 %d OK\r\n"
                      "Content-Type: application/json\r\n"
                      "Content-Length: %d\r\n"
                      "Connection: close\r\n"
                      "\r\n"
                      "%s",
                      status, sizeof(body), body);
    }

    // Get event log
    array(mapping) get_events()
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

        port = Protocols.HTTP.Server.Port();
        port->bind(server_port, handle_request);
    }

    // Handle incoming HTTP request
    void handle_request(Protocols.HTTP.Server.Request req)
    {
        string path = req->not_query;
        method method = req->request_type;

        write("%s: %s\n", upper_case(method), path);

        if (method == "POST") {
            // Read request body
            string body = req->body_raw || "";

            // Handle webhook
            string response = handler->handle_webhook(req->headers, body, path);
            req->response_and_finish(response);
        } else if (method == "GET") {
            // Provide status information
            if (path == "/status") {
                mapping status = ([
                    "status": "running",
                    "webhooks_received": sizeof(handler->get_events()),
                    "timestamp": Calendar.now()->format_time()
                ]);

                string body = Standards.JSON.encode_pretty(status);
                string resp = sprintf("HTTP/1.1 200 OK\r\n"
                                     "Content-Type: application/json\r\n"
                                     "Content-Length: %d\r\n"
                                     "\r\n%s",
                                     sizeof(body), body);
                req->response_and_finish(resp);
            } else {
                string body = "Webhook Server is running. GET /status for info.";
                string resp = sprintf("HTTP/1.1 200 OK\r\n"
                                     "Content-Type: text/plain\r\n"
                                     "Content-Length: %d\r\n"
                                     "\r\n%s",
                                     sizeof(body), body);
                req->response_and_finish(resp);
            }
        } else {
            req->response_and_finish("HTTP/1.1 405 Method Not Allowed\r\n\r\n");
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

        // Keep server running
        return -1;
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
