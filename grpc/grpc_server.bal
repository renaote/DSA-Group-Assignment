import ballerina/grpc;
import ballerina/grpc;

// service name must match proto
service "Greeter" on new grpc:Listener(9090) {
    remote function ping(Ping req) returns Pong {
        return { msg: "PONG: " + req.msg + " (day 1 ✅)" };
    }
}
