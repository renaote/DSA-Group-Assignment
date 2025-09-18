import ballerina/http;
import ballerina/log;


final AssetDatabase assetDB = new;


listener http:Listener apiListener = new (9090);

type not record {
    
};

service /api/assets on apiListener {

    resource function post .(http:Caller caller, http:Request request) returns error? {
        log:printInfo("Creating new asset");
        
        json|error payload = request.getJsonPayload();
        if payload is error {
            return caller->respond(createErrorResponse("Invalid JSON: " + payload.message(), 400));
        }
        
        if !(payload is map<anydata>) {
            return caller->respond(createErrorResponse("Asset data must be a JSON object", 400));
        }
        
        map<anydata> data = <map<anydata>>payload;
        

        anydata assetTag = data["assetTag"];
        anydata name = data["name"];
        anydata faculty = data["faculty"];
        anydata department = data["department"];
        anydata status = data["status"];
        anydata acquiredDate = data["acquiredDate"];
        

        if assetTag is () || name is () || faculty is () || department is () || status is () || acquiredDate is () {
            return caller->respond(createErrorResponse("Missing required fields", 400));
        }
        

        Asset newAsset = {
            assetTag: assetTag.toString(),
            name: name.toString(),
            faculty: faculty.toString(),
            department: department.toString(),
            status: <Status>status.toString(),
            acquiredDate: acquiredDate.toString(),
            components: [],
            schedule: [],
            workOrders: []
        };
        
        
        Asset|error result = assetDB.createAsset(newAsset);
        if result is error {
            return caller->respond(createErrorResponse(result.message(), 400));
        }
        
        return caller->respond(createSuccessResponse("Asset created successfully", <json>result, 201));
    }

    
    resource function get .(http:Caller caller) returns error? {
        log:printInfo("Getting all assets");
        
        Asset[] allAssets = assetDB.getAllAssets();
        
        return caller->respond(createSuccessResponse(
            "Assets retrieved successfully", 
            <json>{
                count: allAssets.length(),
                assets: <json>allAssets
            },
            200
        ));
    }

    
    resource function get [string assetTag](http:Caller caller) returns error? {
        log:printInfo("Getting asset: " + assetTag);
        
        Asset|error asset = assetDB.getAssetByTag(assetTag);
        if asset is error {
            return caller->respond(createErrorResponse(asset.message(), 404));
        }
        
        return caller->respond(createSuccessResponse("Asset retrieved successfully", <json>asset, 200));
    }
}  
function createSuccessResponse(string message, json? data, int statusCode) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload({
        success: true,
        message: message,
        data: data
    });
    return response;
}

function createErrorResponse(string errorMessage, int statusCode) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload({
        success: false,
        "error": errorMessage
    });
    return response;
}

public function main() {
    log:printInfo("🚀 Server started on http://localhost:9090");
}