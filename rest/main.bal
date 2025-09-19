import ballerina/http;

listener http:Listener ep = new (9090);

service / on ep {
    resource function get hello() returns json {
        return { msg: "hello, REST! day 1" };
    }
}
