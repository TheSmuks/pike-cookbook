#!/usr/bin/env pike
#pragma strict_types
// Strategies for handling JavaScript-heavy websites

/*
 * IMPORTANT: Pike cannot execute JavaScript directly.
 * For JS-heavy sites, use these strategies:
 *
 * 1. Look for underlying JSON/API endpoints
 * 2. Use headless browser integration (Selenium, Puppeteer)
 * 3. Reverse-engineer the API calls
 * 4. Use specialized web scraping services
 */

int main()
{
    write("=== JavaScript-Heavy Site Strategies ===\n\n");

    // Strategy 1: Discover API endpoints
    discover_api_endpoints();

    // Strategy 2: Inspect network traffic patterns
    analyze_network_patterns();

    // Strategy 3: Use documented APIs when available
    use_documented_api();

    return 0;
}

// Strategy 1: Discover hidden API endpoints
void discover_api_endpoints()
{
    write("Strategy 1: Discover API Endpoints\n");
    write("----------------------------------\n");

    // Fetch the main page
    string url = "https://example.com";
    Protocols.HTTP.Query q = 0;

    mixed err = catch {
        q = Protocols.HTTP.get_url(url);
    };

    if (err || !q || q->status != 200) {
        write("Note: Network unavailable - using demo HTML\n");
        write("This example would fetch and analyze JavaScript from a real site.\n\n");
        return;
    }

    string html = q->data();

    // Look for API calls in JavaScript
    array(string) patterns = ({
        "fetch\\(['\"]([^'\"]+)['\"]",
        "\\.get\\(['\"]([^'\"]+)['\"]",
        "\\.post\\(['\"]([^'\"]+)['\"]",
        "api_url\\s*=\\s*['\"]([^'\"]+)['\"]",
        "endpoint['\"]:\\s*['\"]([^'\"]+)['\"]",
        "\"url\":\\s*['\"]([^'\"]+)['\"]"
    });

    write("Searching for API endpoints in JavaScript...\n");

    foreach(patterns, string pattern) {
        object re = Regexp.SimpleRegexp(pattern);
        mixed matches = re->split(html);

        if (arrayp(matches) && sizeof((array)matches) > 1) {
            array(string) match_array = (array(string))matches;
            write("  Found potential endpoint: %s\n", match_array[1]);
        }
    }

    write("\n");
}

// Strategy 2: Analyze network patterns
void analyze_network_patterns()
{
    write("Strategy 2: Analyze Network Patterns\n");
    write("------------------------------------\n");

    // Common API endpoint patterns
    array(string) api_patterns = ({
        "/api/v1/",
        "/api/v2/",
        "/rest/",
        "/graphql",
        "/_api/",
        "/.netlify/functions",
        "/api/data"
    });

    write("Common API patterns to look for:\n");
    foreach(api_patterns, string pattern) {
        write("  - %s\n", pattern);
    }

    write("\nRecommendations:\n");
    write("  1. Use browser DevTools Network tab\n");
    write("  2. Look for XHR/Fetch requests\n");
    write("  3. Check WebSocket connections\n");
    write("  4. Examine request headers and payloads\n");
    write("  5. Identify authentication methods\n");

    write("\n");
}

// Strategy 3: Use documented APIs
void use_documented_api()
{
    write("Strategy 3: Use Documented APIs\n");
    write("-------------------------------\n");

    // Example: Many SPAs have public APIs
    // Check for: /api-docs, /swagger, /openapi.json

    string base_url = "https://api.github.com";

    write("Example: Using GitHub's documented API\n");
    write("Fetching user information...\n");

    mapping headers = ([
        "User-Agent": "Pike WebAutomation/1.0",
        "Accept": "application/vnd.github.v3+json"
    ]);

    Protocols.HTTP.Query q = 0;

    mixed err = catch {
        q = Protocols.HTTP.get_url(
            base_url + "/users/pike-language",
            (mapping(string:string|array(string)))headers
        );
    };

    if (err || !q) {
        write("Note: Network unavailable - API call skipped\n");
        write("With network access, this would fetch user info from GitHub API\n");
        write("  Expected: Login, Name, Public repos count\n\n");
        return;
    }

    if (q->status == 200) {
        mixed parse_err = catch {
            mixed decoded = Standards.JSON.decode(q->data());
            if (mappingp(decoded)) {
                mapping data = (mapping)decoded;
                write("  Login: %s\n", (string)data->login);
                mixed name = data->name;
                write("  Name: %s\n", name ? (string)name : "N/A");
                write("  Public repos: %d\n", (int)data->public_repos);
            }
        };
        if (parse_err) {
            write("Note: Failed to parse API response\n");
        }
    } else {
        write("Note: API returned status %d\n", q->status);
    }

    write("\n");
}

// Strategy 4: Headless browser integration (conceptual)
void headless_browser_integration()
{
    write("Strategy 4: Headless Browser Integration\n");
    write("----------------------------------------\n");
    write("For sites that require JavaScript execution:\n\n");

    write("Options:\n");
    write("  1. Selenium WebDriver: Use Process.popen() to drive selenium-server\n");
    write("  2. Puppeteer/Playwright: Call Node.js scripts from Pike\n");
    write("  3. External services: Browserbase, Browserless, ScrapingBee\n\n");

    write("Example: Calling Playwright from Pike\n");
    write("  - Create Node.js script that uses Playwright\n");
    write("  - Call it with Process.popen()\n");
    write("  - Pass URLs and selectors as arguments\n");
    write("  - Return rendered HTML or extracted data\n\n");
}
