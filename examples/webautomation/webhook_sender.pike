#!/usr/bin/env pike
#pragma strict_types
// Send webhook notifications

class WebhookSender
{
    private string url;
    private string secret;

    void create(string webhook_url, string|void sec)
    {
        url = webhook_url;
        secret = sec || "";
    }

    // Send webhook with signature
    int send(mapping payload, mapping|void extra_headers)
    {
        string body = Standards.JSON.encode(payload);

        mapping headers = ([
            "Content-Type": "application/json",
            "User-Agent": "Pike WebhookSender/1.0"
        ]);

        // Add signature if secret provided
        if (secret) {
            string sig = Crypto.SHA256.hmac(secret, body);
            string sig_hex = String.string2hex(sig);
            headers["X-Webhook-Signature"] = "sha256=" + sig_hex;
        }

        if (extra_headers) {
            headers |= extra_headers;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.do_method(
            "POST",
            url,
            ([]),
            headers,
            0,
            body
        );

        return q->status >= 200 && q->status < 300;
    }

    // Send event-specific webhook
    int send_event(string event_type, mapping data)
    {
        mapping payload = ([
            "event": event_type,
            "timestamp": Calendar.now()->format_time(),
            "id": String.string2hex(random_string(16)),
            "data": data
        ]);

        return send(payload);
    }
}

int main()
{
    write("=== Webhook Sender Example ===\n\n");

    // Example: Send webhook to local server
    string url = "http://localhost:8080/webhook";
    string secret = "my_webhook_secret";

    WebhookSender sender = WebhookSender(url, secret);

    // Send different event types
    write("Sending push event...\n");
    int success = sender->send_event("push", ([
        "repository": ([
            "name": "example-repo",
            "owner": "pike-language"
        ]),
        "ref": "refs/heads/main",
        "commits": ([
            "id": "abc123",
            "message": "Update documentation",
            "author": ([
                "name": "Developer",
                "email": "dev@example.com"
            ])
        ])
    ]));

    write("  %s\n", success ? "✓ Sent" : "✗ Failed");

    // Send deployment event
    write("\nSending deployment event...\n");
    success = sender->send_event("deployment", ([
        "deployment": ([
            "id": 1,
            "environment": "production",
            "status": "success"
        ]),
        "repository": ([
            "name": "example-repo"
        ])
    ]));

    write("  %s\n", success ? "✓ Sent" : "✗ Failed");

    // Send custom webhook with headers
    write("\nSending custom webhook...\n");
    success = sender->send(([
        "event": "custom",
        "message": "Custom notification",
        "priority": "high"
    ]), ([
        "X-Priority": "high",
        "X-Source": "pike-webhook-sender"
    ]));

    write("  %s\n", success ? "✓ Sent" : "✗ Failed");

    return 0;
}

// Example: Slack webhook integration
void slack_webhook_example()
{
    write("\n=== Slack Webhook Example ===\n");

    // Slack incoming webhook URL (replace with actual URL)
    string slack_url = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL";

    mapping payload = ([
        "text": "New deployment to production!",
        "blocks": ({
            ([
                "type": "section",
                "text": ([
                    "type": "mrkdwn",
                    "text": "*New Deployment*\nSuccessfully deployed to production"
                ])
            ]),
            ([
                "type": "section",
                "fields": ({
                    ([
                        "type": "mrkdwn",
                        "text": "*Repository:*\npike-cookbook"
                    ]),
                    ([
                        "type": "mrkdwn",
                        "text": "*Environment:*\nProduction"
                    ])
                })
            ])
        })
    ]);

    WebhookSender sender = WebhookSender(slack_url);
    sender->send(payload);

    write("Slack notification sent!\n");
}

// Example: Discord webhook integration
void discord_webhook_example()
{
    write("\n=== Discord Webhook Example ===\n");

    string discord_url = "https://discord.com/api/webhooks/YOUR/WEBHOOK/URL";

    mapping payload = ([
        "username": "Deployment Bot",
        "avatar_url": "https://example.com/bot-avatar.png",
        "embeds": ({
            ([
                "title": "New Deployment",
                "description": "Successfully deployed to production",
                "color": 3066993,
                "fields": ({
                    ([
                        "name": "Repository",
                        "value": "pike-cookbook",
                        "inline": true
                    ]),
                    ([
                        "name": "Environment",
                        "value": "Production",
                        "inline": true
                    ])
                }),
                "timestamp": Calendar.now()->format_ymd() + "T" +
                            Calendar.now()->format_time() + "Z"
            ])
        })
    ]);

    WebhookSender sender = WebhookSender(discord_url);
    sender->send(payload);

    write("Discord notification sent!\n");
}
