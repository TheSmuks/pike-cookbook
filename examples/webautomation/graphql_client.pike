#!/usr/bin/env pike
#pragma strict_types
// GraphQL client for modern APIs

class GraphQLClient
{
    private string endpoint;
    private string|void auth_token;
    private mapping(string:string) default_headers = ([
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "Pike GraphQLClient/1.0"
    ]);

    void create(string url, string|void token)
    {
        endpoint = url;
        auth_token = token;
    }

    // Execute GraphQL query
    mapping query(string query_string, mapping|void variables)
    {
        mapping payload = ([
            "query": query_string
        ]);

        if (variables) {
            payload->variables = variables;
        }

        mapping headers = copy_value(default_headers);

        if (auth_token) {
            headers["Authorization"] = "Bearer " + auth_token;
        }

        Protocols.HTTP.Query q = Protocols.HTTP.do_method(
            "POST",
            endpoint,
            ([]),
            headers,
            0,
            Standards.JSON.encode(payload)
        );

        if (q->status >= 200 && q->status < 300) {
            mapping response = Standards.JSON.decode(q->data());

            if (response->errors) {
                werror("GraphQL Errors:\n");
                foreach(response->errors, mapping err) {
                    werror("  %s\n", err->message);
                }
            }

            return response;
        } else {
            werror("HTTP Error: %d\n", q->status);
            return (["error": sprintf("HTTP %d", q->status)]);
        }
    }

    // Execute mutation
    mapping mutation(string mutation_string, mapping|void variables)
    {
        return query(mutation_string, variables);
    }
}

int main()
{
    write("=== GraphQL Client Example ===\n\n");

    // Example with public GitHub GraphQL API
    string endpoint = "https://api.github.com/graphql";

    // Note: You need a real GitHub token for this to work
    // string token = getenv("GITHUB_TOKEN");
    // GraphQLClient client = GraphQLClient(endpoint, token);

    // Example query structure
    string example_query = #"
    query {
        repository(owner: \"pike-language\", name: \"pike\") {
            name
            description
            stargazerCount
            updatedAt
        }
    }
    ";

    write("Example GraphQL query:\n");
    write("%s\n", example_query);

    write("\nTo use GraphQL APIs:\n");
    write("1. Obtain authentication token if required\n");
    write("2. Build query string\n");
    write("3. Pass variables separately\n");
    write("4. Execute with client->query()\n");
    write("5. Handle response->data or response->errors\n");

    // Simulated response structure
    write("\nResponse structure:\n");
    write("  response->data - The actual data\n");
    write("  response->errors - Array of errors if any\n");
    write("  response->extensions - Metadata\n");

    return 0;
}

// Real example with a public GraphQL API
void public_graphql_example()
{
    write("\n=== Public GraphQL API Example ===\n");

    // Using the public SpaceX GraphQL API
    GraphQLClient client = GraphQLClient("https://api.spacex.land/graphql");

    string query = #"
    {
        launchesPast(limit: 3) {
            mission_name
            launch_date_local
            rocket {
                rocket_name
            }
        }
    }
    ";

    mapping response = client->query(query);

    if (response->data) {
        write("Recent SpaceX launches:\n");
        foreach(response->data->launchesPast, mapping launch) {
            write("  - %s (%s)\n",
                  launch->mission_name,
                  launch->launch_date_local[0..9]);
        }
    }
}
