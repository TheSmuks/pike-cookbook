#!/usr/bin/env pike
#pragma strict_types
// Form submission with GET method

int main()
{
    // GET form submission - data in URL query string
    string base_url = "https://httpbin.org/get";

    mapping(string:string) form_data = ([
        "name": "John Doe",
        "email": "john@example.com",
        "category": "general"
    ]);

    // Build query string
    array(string) params = ({});
    foreach(form_data; string key; string value) {
        params += ({ Protocols.HTTP.uri_encode(key) + "=" +
                    Protocols.HTTP.uri_encode(value) });
    }
    string query_string = params * "&";

    string full_url = base_url + "?" + query_string;

    // Submit form
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(full_url);

    if (q->status == 200) {
        write("Form submitted successfully!\n");
        write("Response:\n");
        write(q->data());
        return 0;
    } else {
        werror("Form submission failed: %d\n", q->status);
        return 1;
    }
}
