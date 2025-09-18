import ballerina/http;
import ballerina/io;

public function main() returns error? {
    final http:Client c = check new ("http://localhost:8080");
    json r = check c->get("/hello");
    io:println(r.toJsonString());
}
