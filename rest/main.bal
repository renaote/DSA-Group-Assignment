// mini REST sanity check
import ballerina/http;

service / on new http:Listener(8080) {
    resource function get hi() returns string {
        return "hello from rest";
    }
}
