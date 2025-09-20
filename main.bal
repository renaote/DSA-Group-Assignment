import ballerina/http;
import ballerina/log;
import ballerina/time;

// ---------- Simple shapes for work orders + tasks ----------
// Types are now imported from types.bal

// ---------- Asset domain ----------
// Types are now imported from types.bal

// ---------- In-memory “database” ----------
// AssetDatabase class removed; now imported from database.bal

// ---------- Helpers ----------
function nextWorkOrderId(WorkOrder[] list) returns string {
    int maxId = 0;
    foreach var w in list {
        int idNum = 0;
        int|error maybeId = int:fromString(w.id);
        if maybeId is int { idNum = <int>maybeId; }
        if idNum > maxId { maxId = idNum; }
    }
    return (maxId + 1).toString();
}

function nextTaskId(Task[] list) returns string {
    int maxId = 0;
    foreach var t in list {
        int idNum = 0;
        int|error maybeId = int:fromString(t.id);
        if maybeId is int { idNum = <int>maybeId; }
        if idNum > maxId { maxId = idNum; }
    }
    return (maxId + 1).toString();
}

function findWOIndex(WorkOrder[] list, string id) returns int {
    int i = 0;
    foreach var w in list {
        if w.id == id { return i; }
        i += 1;
    }
    return -1;
}
function findTaskIndex(Task[] list, string id) returns int {
    int i = 0;
    foreach var t in list {
        if t.id == id { return i; }
        i += 1;
    }
    return -1;
}

function readString(map<anydata> m, string key, boolean required = true) returns string|error {
    anydata? v = m[key];
    if v is string {
        string s = v.trim();
        if required && s.length() == 0 {
            return error("'" + key + "' is required");
        }
        return s;
    }
    if required {
        return error("'" + key + "' is required and must be a string");
    }
    return "";
}

function toStatus(string s) returns Status|error {
    if s == "ACTIVE" || s == "UNDER_REPAIR" || s == "DISPOSED" {
        return <Status>s;
    }
    return error("invalid status: " + s + " (use ACTIVE|UNDER_REPAIR|DISPOSED)");
}

function createSuccessResponse(string message, json? data, int statusCode) returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setJsonPayload({
        "success": true,
        "message": message,
        "data": data
    });
    return res;
}

function createErrorResponse(string errorMessage, int statusCode) returns http:Response {
    http:Response res = new;
    res.statusCode = statusCode;
    res.setJsonPayload({
        "success": false,
        "error": errorMessage
    });
    return res;
}

// ---------- API ----------
final AssetDatabase assetDB = new;
listener http:Listener apiListener = new (9090);

service /api/assets on apiListener {

    // Create asset
    resource function post .(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Creating new asset");

        json|error jp = req.getJsonPayload();
        if jp is error {
            return caller->respond(createErrorResponse("Invalid JSON: " + jp.message(), 400));
        }
        if !(jp is map<anydata>) {
            return caller->respond(createErrorResponse("Asset data must be a JSON object", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        string assetTag = check readString(m, "assetTag");
        string name     = check readString(m, "name");
        string faculty  = check readString(m, "faculty");
        string dept     = check readString(m, "department");
        string statusS  = check readString(m, "status");
        Status status   = check toStatus(statusS);
        string acquired = check readString(m, "acquiredDate");

        Asset newAsset = {
            assetTag,
            name,
            faculty,
            department: dept,
            status,
            acquiredDate: acquired,
            components: [],
            schedule: [],
            workOrders: []
        };

        Asset|error created = assetDB.createAsset(newAsset);
        if created is error {
            return caller->respond(createErrorResponse(created.message(), 400));
        }
        return caller->respond(createSuccessResponse("Asset created successfully", <json>created, 201));
    }

    // List assets and faculty filtering
    resource function get .(http:Caller caller, http:Request req) returns error? {
        string? facultyParam = req.getQueryParamValue("faculty");
        
        if facultyParam is string && facultyParam.trim().length() > 0{
            Asset[] facultyAssets = assetDB.getAssetsByFaculty(facultyParam);
            json data = {
                count: facultyAssets.length(),
                faculty: facultyParam,
                assets: <json>facultyAssets
            };
            return caller->respond(createSuccessResponse("Assets filtered by faculty", data, 200));
        } else {
            Asset[] all = assetDB.getAllAssets();
            json data = {count: all.length(), assets: <json>all};
            return caller->respond(createSuccessResponse("Assets retrieved successfully", data, 200));
        }
    }

    //Get overdue maintenance assets - New Endpoint(Atuhe's responsibility but was missing)
    resource function get overdue(http:Caller caller) returns error? {
        Asset[] overdueAssets = assetDB.getOverdueMaintenanceAssets();
        json data = {
            count: overdueAssets.length(),
            assets: <json>overdueAssets
        };
        return caller->respond(createSuccessResponse("Overdue assets retrieved succefully", data, 200));
    
    }
    
    // Get one asset
    resource function get [string assetTag](http:Caller caller) returns error? {
        Asset|error a = assetDB.getAssetByTag(assetTag);
        if a is error {
            return caller->respond(createErrorResponse(a.message(), 404));
        }
        return caller->respond(createSuccessResponse("Asset retrieved successfully", <json>a, 200));
    }

    // Update asset - NEW ENDPOINT (Ndina's responsibility but was missing)
    resource function put [string assetTag](http:Caller caller, http:Request req) returns error? {
        json|error jp = req.getJsonPayload();
        if jp is error {
            return caller->respond(createErrorResponse("Invalid JSON: " + jp.message(), 400));
        }
        if !(jp is map<anydata>) {
            return caller->respond(createErrorResponse("Update data must be a JSON object", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        // Create AssetUpdate record
        AssetUpdate updateData = {
            assetTag: assetTag,
            name: m["name"] is string ? <string>m["name"] : (),
            faculty: m["faculty"] is string ? <string>m["faculty"] : (),
            department: m["department"] is string ? <string>m["department"] : (),
            status: m["status"] is string ? check toStatus(<string>m["status"]) : (),
            acquiredDate: m["acquiredDate"] is string ? <string>m["acquiredDate"] : ()
        };

        Asset|error updated = assetDB.updateAsset(assetTag, updateData);
        if updated is error {
            return caller->respond(createErrorResponse(updated.message(), 404));
        }
        return caller->respond(createSuccessResponse("Asset updated successfully", <json>updated, 200));
    }

    // Delete asset - NEW ENDPOINT (Ndina's responsibility but was missing)
    resource function delete [string assetTag](http:Caller caller) returns error? {
        error? result = assetDB.deleteAsset(assetTag);
        if result is error {
            return caller->respond(createErrorResponse(result.message(), 404));
        }
        return caller->respond(createSuccessResponse("Asset deleted successfully", (), 204));
    }

    // Add component to asset - NEW ENDPOINT (Ndati's responsibility but was missing)
    resource function post [string assetTag]/components(http:Caller caller, http:Request req) returns error? {
        json|error jp = req.getJsonPayload();
        if jp is error {
            return caller->respond(createErrorResponse("Invalid JSON: " + jp.message(), 400));
        }
        if !(jp is map<anydata>) {
            return caller->respond(createErrorResponse("Component data must be a JSON object", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        // Generate component ID
        string componentId = "COMP-" + (check assetDB.getAssetCount()).toString() + "-" + time:utcNow()[0].toString();
        
        Components component = {
            id: componentId,
            name: check readString(m, "name"),
            description: check readString(m, "description", false),
            installedDate: time:utcToCivil(time:utcNow())
        };

        Asset|error updated = assetDB.addComponent(assetTag, component);
        if updated is error {
            return caller->respond(createErrorResponse(updated.message(), 404));
        }
        return caller->respond(createSuccessResponse("Component added successfully", <json>component, 201));
    }

    // Remove component from asset - NEW ENDPOINT (Ndati's responsibility but was missing)
    resource function delete [string assetTag]/components/[string componentId](http:Caller caller) returns error? {
        Asset|error updated = assetDB.removeComponent(assetTag, componentId);
        if updated is error {
            return caller->respond(createErrorResponse(updated.message(), 404));
        }
        return caller->respond(createSuccessResponse("Component removed successfully", (), 204));
    }

    // Add schedule to asset - NEW ENDPOINT (Ndati's responsibility but was missing)
    resource function post [string assetTag]/schedules(http:Caller caller, http:Request req) returns error? {
        json|error jp = req.getJsonPayload();
        if jp is error {
            return caller->respond(createErrorResponse("Invalid JSON: " + jp.message(), 400));
        }
        if !(jp is map<anydata>) {
            return caller->respond(createErrorResponse("Schedule data must be a JSON object", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        // Generate schedule ID
        string scheduleId = "SCH-" + (check assetDB.getAssetCount()).toString() + "-" + time:utcNow()[0].toString();
        
        MaintenanceSchedule schedule = {
            id: scheduleId,
            scheduleType: check readString(m, "scheduleType"),
            description: check readString(m, "description", false),
            lastServiceDate: time:utcToCivil(time:utcNow()),
            nextDueDate: m["nextDueDate"] is string ? 
                time:utcToCivil(check time:utcFromString(<string>m["nextDueDate"] + "T00:00:00Z")) :
                time:utcToCivil(time:utcNow())
        };

        Asset|error updated = assetDB.addScheduleToAsset(assetTag, schedule);
        if updated is error {
            return caller->respond(createErrorResponse(updated.message(), 404));
        }
        return caller->respond(createSuccessResponse("Schedule added successfully", <json>schedule, 201));
    }

    // Remove schedule from asset - NEW ENDPOINT (Ndati's responsibility but was missing)
    resource function delete [string assetTag]/schedules/[string scheduleId](http:Caller caller) returns error? {
        Asset|error updated = assetDB.removeScheduleFromAsset(assetTag, scheduleId);
        if updated is error {
            return caller->respond(createErrorResponse(updated.message(), 404));
        }
        return caller->respond(createSuccessResponse("Schedule removed successfully", (), 204));
    }

    // 1) Open a work order
    resource function post [string assetTag]/workorders(http:Caller c, http:Request req) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;

        json|error jp = req.getJsonPayload();
        if jp is error || !(jp is map<anydata>) {
            return c->respond(createErrorResponse("Invalid JSON body", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        string title = check readString(m, "title");
        WorkOrder wo = { id: nextWorkOrderId(asset.workOrders), title, description: "", openedDate: time:utcToCivil(time:utcNow()), closedDate: time:utcToCivil(time:utcNow()), status: "open", tasks: [] };
        WorkOrder[] workOrders = asset.workOrders.clone();
        workOrders.push(wo);

        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            department: asset.department,
            status: asset.status,
            acquiredDate: asset.acquiredDate,
            components: asset.components,
            schedule: asset.schedule,
            workOrders: <readonly>workOrders
        };
        check assetDB.deleteAsset(asset.assetTag);
        Asset|error created = assetDB.createAsset(updatedAsset);
        if created is error {
            return c->respond(createErrorResponse(created.message(), 400));
        }
        return c->respond(createSuccessResponse("work order opened", <json>wo, 201));
    }

    // 2) Update a work order
    resource function put [string assetTag]/workorders/[string woId](http:Caller c, http:Request req) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;

        int i = findWOIndex(asset.workOrders, woId);
        if i == -1 { return c->respond(createErrorResponse("work order not found", 404)); }

        json|error jp = req.getJsonPayload();
        if jp is error || !(jp is map<anydata>) {
            return c->respond(createErrorResponse("Invalid JSON body", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        WorkOrder[] workOrders = asset.workOrders.clone();
        anydata? rt = m["title"];
        if rt is string {
            string t = rt.trim();
            if t.length() == 0 { return c->respond(createErrorResponse("invalid title", 400)); }
            workOrders[i].title = t;
        }
        anydata? rs = m["status"];
        if rs is string {
            workOrders[i].status = rs;
        }
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            department: asset.department,
            status: asset.status,
            acquiredDate: asset.acquiredDate,
            components: asset.components,
            schedule: asset.schedule,
            workOrders: <readonly>workOrders
        };
        check assetDB.deleteAsset(asset.assetTag);
        Asset|error created = assetDB.createAsset(updatedAsset);
        if created is error {
            return c->respond(createErrorResponse(created.message(), 400));
        }
        return c->respond(createSuccessResponse("work order updated", <json>workOrders[i], 200));
    }

    // 3) Close a work order
    resource function post [string assetTag]/workorders/[string woId]/close(http:Caller c) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;

        int i = findWOIndex(asset.workOrders, woId);
        if i == -1 { return c->respond(createErrorResponse("work order not found", 404)); }

        WorkOrder[] workOrders = asset.workOrders.clone();
        workOrders[i].status = "closed";
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            department: asset.department,
            status: asset.status,
            acquiredDate: asset.acquiredDate,
            components: asset.components,
            schedule: asset.schedule,
            workOrders: <readonly>workOrders
        };
        check assetDB.deleteAsset(asset.assetTag);
        Asset|error created = assetDB.createAsset(updatedAsset);
        if created is error {
            return c->respond(createErrorResponse(created.message(), 400));
        }
        return c->respond(createSuccessResponse("work order closed", <json>workOrders[i], 200));
    }

    // 4) Add a task
    resource function post [string assetTag]/workorders/[string woId]/tasks(http:Caller c, http:Request req) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;

        int wi = findWOIndex(asset.workOrders, woId);
        if wi == -1 { return c->respond(createErrorResponse("work order not found", 404)); }

        json|error jp = req.getJsonPayload();
        if jp is error || !(jp is map<anydata>) {
            return c->respond(createErrorResponse("Invalid JSON body", 400));
        }
        map<anydata> m = <map<anydata>>jp;

        string title = check readString(m, "title");
        Task task = { id: nextTaskId(asset.workOrders[wi].tasks), description: title, status: "todo", assignedTo: (), dueDate: time:utcToCivil(time:utcNow()), completedDate: () };
        Task[] tasks = asset.workOrders[wi].tasks.clone();
        tasks.push(task);
        WorkOrder[] workOrders = asset.workOrders.clone();
        workOrders[wi].tasks = tasks;
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            department: asset.department,
            status: asset.status,
            acquiredDate: asset.acquiredDate,
            components: asset.components,
            schedule: asset.schedule,
            workOrders: <readonly>workOrders
        };
        check assetDB.deleteAsset(asset.assetTag);
        Asset|error created = assetDB.createAsset(updatedAsset);
        if created is error {
            return c->respond(createErrorResponse(created.message(), 400));
        }
        return c->respond(createSuccessResponse("task added", <json>workOrders[wi], 201));
    }

    // 5) Remove a task
    resource function delete [string assetTag]/workorders/[string woId]/tasks/[string taskId](http:Caller c) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;

        int wi = findWOIndex(asset.workOrders, woId);
        if wi == -1 { return c->respond(createErrorResponse("work order not found", 404)); }

        int ti = findTaskIndex(asset.workOrders[wi].tasks, taskId);
        if ti == -1 { return c->respond(createErrorResponse("task not found", 404)); }

        Task[] tasks = asset.workOrders[wi].tasks.clone();
        _ = tasks.remove(ti);
        WorkOrder[] workOrders = asset.workOrders.clone();
        workOrders[wi].tasks = tasks;
        Asset updatedAsset = {
            assetTag: asset.assetTag,
            name: asset.name,
            faculty: asset.faculty,
            department: asset.department,
            status: asset.status,
            acquiredDate: asset.acquiredDate,
            components: asset.components,
            schedule: asset.schedule,
            workOrders: <readonly>workOrders
        };
        check assetDB.deleteAsset(asset.assetTag);
        Asset|error created = assetDB.createAsset(updatedAsset);
        if created is error {
            return c->respond(createErrorResponse(created.message(), 400));
        }
        return c->respond(createSuccessResponse("task removed", <json>workOrders[wi], 200));
    }

    // Helper: list work orders for an asset
    resource function get [string assetTag]/workorders(http:Caller c) returns error? {
        Asset|error ar = assetDB.getAssetByTag(assetTag);
        if ar is error { return c->respond(createErrorResponse(ar.message(), 404)); }
        Asset asset = ar;
        return c->respond(createSuccessResponse("work orders", <json>asset.workOrders, 200));
    }
}


public function main() {
    log:printInfo("🚀 Server started on http://localhost:9090");
}
