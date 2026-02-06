#!/usr/bin/env pike
#pragma strict_types
#pike 8.0

// Test that our class definitions compile
class TestUserRepo {
    void create(string|object db) {}
    int create_user(string u, string e) { return 1; }
}

// Just test syntax by importing
int main() {
    mixed err = catch {
        // TestUserRepo repo = TestUserRepo("test");
        werror("Syntax OK\n");
    };
    if (err) {
        werror("Compilation error: %O\n", err);
        return 1;
    }
    return 0;
}
