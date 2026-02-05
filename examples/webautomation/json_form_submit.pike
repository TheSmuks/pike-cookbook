#!/usr/bin/env pike
#pragma strict_types
// Submit JSON data via POST

int main()
{
    string url = "https://httpbin.org/post";

    // Prepare JSON data
    mapping data = ([
        "user": ([
            "name": "Jane Doe",
            "email": "jane@example.com",
            "age": 28
        ]),
        "preferences": ([
            "theme": "dark",
            "notifications": true,
            "language": "en"
        ]),
        "tags": ({"developer", "pike", "automation"})
    ]);

    string json_body = Standards.JSON.encode(data);

    // Send JSON request
    mapping(string:string) headers = ([
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Pike JSONClient/1.0"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.do_method(
        "POST",
        url,
        ([]),
        headers,
        0,
        json_body
    );

    if (q->status >= 200 && q->status < 300) {
        write("JSON submitted successfully!\n");
        mapping response = Standards.JSON.decode(q->data());
        write("\nEchoed JSON data:\n");
        write("%s\n", Standards.JSON.encode(response->json, Standards.JSON.HUMAN_READABLE));
        return 0;
    } else {
        werror("Request failed: %d\n", q->status);
        return 1;
    }
}
