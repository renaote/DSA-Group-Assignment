import ballerina/io;

public function main() returns error? {
    GreeterClient c = check new ("http://localhost:9090");
    Pong res = check c->ping({ msg: "hey server, it's renate" });
    io:println(res.msg);
}
                                                                                                              