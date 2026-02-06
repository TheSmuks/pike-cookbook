#!/usr/bin/env pike
#pragma strict_types
// Multipart form data with file upload

int main(int argc, array(string) argv)
{
    if (argc < 2) {
        write("Usage: %s <file_to_upload>\n", argv[0]);
        write("Running in demo mode with a temporary test file ...\n");

        // Create a temporary test file
        string test_file = "/tmp/pike_upload_test.txt";
        Stdio.write_file(test_file, "This is a test file for multipart upload demonstration.\n");
        argv = ({ argv[0], test_file });
    }

    string filepath = argv[1];
    string filename = basename(filepath);

    Stdio.Stat stat = file_stat(filepath);
    if (!stat || !stat->isreg) {
        werror("File not found: %s\n", filepath);
        return 1;
    }

    string url = "https://httpbin.org/post";

    // Read file content
    string content = Stdio.read_file(filepath);

    // Create multipart form data
    string boundary = "----PikeBoundary" + String.string2hex(random_string(16));

    array(string) parts = ({});

    // Add form fields
    parts += ({
        "--" + boundary,
        "Content-Disposition: form-data; name=\"field1\"",
        "",
        "value1"
    });

    parts += ({
        "--" + boundary,
        "Content-Disposition: form-data; name=\"field2\"",
        "",
        "value2"
    });

    // Add file
    parts += ({
        "--" + boundary,
        sprintf("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"",
                filename),
        "Content-Type: application/octet-stream",
        "",
        content
    });

    parts += ({ "--" + boundary + "--", "" });

    string body = parts * "\r\n";

    // Send request
    mapping(string:string) headers = ([
        "Content-Type": "multipart/form-data; boundary=" + boundary,
        "User-Agent": "Pike UploadBot/1.0"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.do_method(
        "POST",
        url,
        ([]),  // query variables
        headers,
        0,     // follow redirects
        body   // request body
    );

    if (q->status >= 200 && q->status < 300) {
        write("File uploaded successfully!\n");
        write("Status: %d\n", q->status);
        write("File size: %d bytes\n", sizeof(content));
        return 0;
    } else {
        werror("Upload failed: %d %s\n", q->status, q->status_desc);
        return 1;
    }
}
