import ballerina/grpc;
import ballerina/protobuf;

public const string PING_DESC = "0A0A70696E672E70726F746F120464656D6F22180A0450696E6712100A036D736718012001280952036D736722180A04506F6E6712100A036D736718012001280952036D736732290A0747726565746572121E0A0470696E67120A2E64656D6F2E50696E671A0A2E64656D6F2E506F6E67620670726F746F33";

public isolated client class GreeterClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, PING_DESC);
    }

    isolated remote function ping(Ping|ContextPing req) returns Pong|grpc:Error {
        map<string|string[]> headers = {};
        Ping message;
        if req is ContextPing {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("demo.Greeter/ping", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Pong>result;
    }

    isolated remote function pingContext(Ping|ContextPing req) returns ContextPong|grpc:Error {
        map<string|string[]> headers = {};
        Ping message;
        if req is ContextPing {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("demo.Greeter/ping", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Pong>result, headers: respHeaders};
    }
}

public isolated client class GreeterPongCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendPong(Pong response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextPong(ContextPong response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextPing record {|
    Ping content;
    map<string|string[]> headers;
|};

public type ContextPong record {|
    Pong content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: PING_DESC}
public type Ping record {|
    string msg = "";
|};

@protobuf:Descriptor {value: PING_DESC}
public type Pong record {|
    string msg = "";
|};
