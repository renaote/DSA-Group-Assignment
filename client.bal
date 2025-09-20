import ballerina/http;
import ballerina/io;
import ballerina/time;

// Client configuration 
configurable string serviceUrl = "http://localhost:9090/api/assets";

// Asset record definition 
type Asset record {
    string assetTag;
    string name;
    string faculty;
    string department;
    string status;
    string acquiredDate;
    Component[] components;
    MaintenanceSchedule[] schedule;
    WorkOrder[] workOrders;
};

// Component record 
type Component record {
    string id;
    string name;
    string description;
    string installedDate;
    string? status;
};

// Schedule record 
type MaintenanceSchedule record {
    string id;
    string scheduleType;
    string description;
    string lastServiceDate;
    string nextDueDate;
    boolean? isOverDue;
};

// Work order and task types
type Task record {
    string id;
    string description;
    string status;
    string? assignedTo;
    string dueDate;
    string? completedDate;
};

type WorkOrder record {
    string id;
    string title;
    string description;
    string openedDate;
    string closedDate;
    string status;
    Task[] tasks;
};

public function main() returns error? {
    http:Client assetClient = check new (serviceUrl);
    
    io:println("=== Asset Management System Client Demo ===\n");
    
    // 1. Create sample assets
    io:println("1. Creating sample assets...");
    check createSampleAssets(assetClient);
    
    // 2. View all assets
    io:println("\n2. Retrieving all assets...");
    check viewAllAssets(assetClient);
    
    // 3. Update an asset
    io:println("\n3. Updating asset EQ-001...");
    check updateAsset(assetClient);
    
    // 4. View assets by faculty
    io:println("\n4. Viewing assets by faculty (Computing & Informatics)...");
    check viewAssetsByFaculty(assetClient, "Computing & Informatics");
    
    // 5. Add component to asset
    io:println("\n5. Adding component to asset EQ-001...");
    check addComponentToAsset(assetClient);
    
    // 6. Add schedule to asset
    io:println("\n6. Adding maintenance schedule to asset EQ-001...");
    check addScheduleToAsset(assetClient);
    
    // 7. Check overdue items
    io:println("\n7. Checking for overdue maintenance items...");
    check checkOverdueItems(assetClient);
    
    // 8. Demonstrate work order functionality (Person 4's work)
    io:println("\n8. Testing work order management...");
    check demonstrateWorkOrders(assetClient);
    
    // 9. Clean up - delete test asset
    io:println("\n9. Cleaning up test data...");
    check deleteAsset(assetClient, "EQ-001");
    
    io:println("\n=== Client Demo Complete ===");
}

function createSampleAssets(http:Client client) returns error? {
    // Asset 1 - 3D Printer 
    json asset1 = {
        "assetTag": "EQ-001",
        "name": "3D Printer",
        "faculty": "Computing & Informatics",
        "department": "Software Engineering",
        "status": "ACTIVE",
        "acquiredDate": "2024-03-10"
    };
    
    // Asset 2 - Server
    json asset2 = {
        "assetTag": "SRV-002",
        "name": "Dell PowerEdge Server",
        "faculty": "Computing & Informatics", 
        "department": "Information Technology",
        "status": "ACTIVE",
        "acquiredDate": "2023-11-15"
    };
    
    // Asset 3 - Vehicle
    json asset3 = {
        "assetTag": "VH-003",
        "name": "Toyota Hilux",
        "faculty": "Engineering",
        "department": "Mechanical Engineering", 
        "status": "UNDER_REPAIR",
        "acquiredDate": "2022-08-20"
    };
    
    // Create assets via POST requests
    json[] assets = [asset1, asset2, asset3];
    
    foreach json asset in assets {
        http:Response response = check client->post("", asset);
        if response.statusCode == 201 {
            string tag = asset.assetTag.toString();
            string name = asset.name.toString();
            io:println(string ` Created asset: ${tag} - ${name}`);
        } else {
            string tag = asset.assetTag.toString();
            io:println(string ` Failed to create asset ${tag}: ${response.statusCode}`);
        }
    }
}

function viewAllAssets(http:Client client) returns error? {
    http:Response response = check client->get("");
    
    if response.statusCode == 200 {
        json payload = check response.getJsonPayload();
        io:println("All Assets:");
        io:println(payload.toString());
    } else {
        io:println(string `Failed to retrieve assets: ${response.statusCode}`);
    }
}

function updateAsset(http:Client client) returns error? {
    // Update asset EQ-001 status to UNDER_REPAIR
    json updatePayload = {
        "name": "3D Printer Pro",
        "status": "UNDER_REPAIR"
    };
    
    http:Response response = check client->put("/EQ-001", updatePayload);
    
    if response.statusCode == 200 {
        io:println(" Asset EQ-001 updated successfully");
        json payload = check response.getJsonPayload();
        io:println(payload.toString());
    } else {
        io:println(string ` Failed to update asset: ${response.statusCode}`);
    }
}

function viewAssetsByFaculty(http:Client client, string faculty) returns error? {
    // Based on our database.bal, this should be a query parameter
    string endpoint = string `?faculty=${faculty}`;
    
    http:Response response = check client->get(endpoint);
    
    if response.statusCode == 200 {
        json payload = check response.getJsonPayload();
        io:println(string `Assets in faculty '${faculty}':`);
        io:println(payload.toString());
    } else {
        io:println(string `Failed to retrieve assets by faculty: ${response.statusCode}`);
    }
}

function addComponentToAsset(http:Client client) returns error? {
    json newComponent = {
        "name": "Extruder Head",
        "description": "Primary extruder head for 3D printing",
        "installedDate": "2024-09-20"
    };
    
    
    http:Response response = check client->post("/EQ-001/components", newComponent);
    
    if response.statusCode == 201 {
        io:println(" Component added to asset EQ-001");
    } else {
        io:println(string ` Failed to add component: ${response.statusCode} (endpoint likely not implemented)`);
    }
}

function addScheduleToAsset(http:Client client) returns error? {
    json newSchedule = {
        "scheduleType": "QUARTERLY",
        "description": "Quarterly maintenance check and calibration",
        "lastServiceDate": "2024-06-20",
        "nextDueDate": "2024-08-20"
         // Past date for overdue testing
    };

    http:Response response = check client->post("/EQ-001/schedules", newSchedule);
    
    if response.statusCode == 201 {
        io:println(" Schedule added to asset EQ-001");
    } else {
        io:println(string ` Failed to add schedule: ${response.statusCode} (endpoint likely not implemented)`);
    }
}

function checkOverdueItems(http:Client client) returns error? {

    http:Response response = check client->get("/overdue");
    
    if response.statusCode == 200 {
        json payload = check response.getJsonPayload();
        io:println("Overdue Assets:");
        io:println(payload.toString());
    } else {
        io:println(string `Failed to retrieve overdue items: ${response.statusCode} (endpoint might not be implemented)`);
    }
}

function deleteAsset(http:Client client, string assetTag) returns error? {
    http:Response response = check client->delete(string `/${assetTag}`);
    
    if response.statusCode == 204 || response.statusCode == 200 {
        io:println(string ` Asset ${assetTag} deleted successfully`);
    } else {
        io:println(string ` Failed to delete asset ${assetTag}: ${response.statusCode}`);
    }
}

// Additional utility functions for comprehensive testing

function demonstrateErrorHandling(http:Client client) returns error? {
    io:println("\n=== Error Handling Demo ===");
    
    // Try to get non-existent asset
    http:Response response = check client->get("/assets/FAKE-001");
    io:println(string `Get non-existent asset: ${response.statusCode}`);
    
    // Try to create asset with duplicate tag
    Asset duplicateAsset = {
        assetTag: "EQ-001", // Assuming this already exists
        name: "Duplicate Asset",
        faculty: "Test Faculty",
        department: "Test Department",
        status: "ACTIVE",
        acquiredDate: "2024-01-01",
        components: {},
        schedules: {},
        workOrders: {}
    };
    
    response = check client->post("/assets", duplicateAsset);
    io:println(string `Create duplicate asset: ${response.statusCode}`);
}

function removeComponentFromAsset(http:Client client, string assetTag, string componentId) returns error? {
    http:Response response = check client->delete(string `/assets/${assetTag}/components/${componentId}`);
    
    if response.statusCode == 204 || response.statusCode == 200 {
        io:println(string ` Component ${componentId} removed from asset ${assetTag}`);
    } else {
        io:println(string ` Failed to remove component: ${response.statusCode}`);
    }
}

function removeScheduleFromAsset(http:Client client, string assetTag, string scheduleId) returns error? {
    http:Response response = check client->delete(string `/${assetTag}/schedules/${scheduleId}`);
    
    if response.statusCode == 204 || response.statusCode == 200 {
        io:println(string ` Schedule ${scheduleId} removed from asset ${assetTag}`);
    } else {
        io:println(string ` Failed to remove schedule: ${response.statusCode}`);
    }
}

// Function to test work order functionality (Renate's implementation)
function demonstrateWorkOrders(http:Client client) returns error? {
    // 1. Open a work order
    json workOrderPayload = {
        "title": "Extruder maintenance required"
    };
    
    http:Response response = check client->post("/EQ-001/workorders", workOrderPayload);
    
    if response.statusCode == 201 {
        io:println(" Work order opened for asset EQ-001");
        json payload = check response.getJsonPayload();
        
        // Extract work order ID from response
        json|error woData = payload.data;
        if woData is json && woData is map<json> {
            json|error woId = woData["id"];
            if woId is string {
                // 2. Add a task to the work order
                json taskPayload = {
                    "title": "Replace extruder nozzle"
                };
                
                http:Response taskResponse = check client->post(string `/EQ-001/workorders/${woId}/tasks`, taskPayload);
                if taskResponse.statusCode == 201 {
                    io:println(" Task added to work order");
                } else {
                    io:println(string ` Failed to add task: ${taskResponse.statusCode}`);
                }
                
                // 3. Update work order status
                json updatePayload = {
                    "status": "in-progress"
                };
                
                http:Response updateResponse = check client->put(string `/EQ-001/workorders/${woId}`, updatePayload);
                if updateResponse.statusCode == 200 {
                    io:println(" Work order status updated");
                } else {
                    io:println(string ` Failed to update work order: ${updateResponse.statusCode}`);
                }
                
                // 4. Close the work order
                http:Response closeResponse = check client->post(string `/EQ-001/workorders/${woId}/close`);
                if closeResponse.statusCode == 200 {
                    io:println(" Work order closed");
                } else {
                    io:println(string ` Failed to close work order: ${closeResponse.statusCode}`);
                }
            }
        }
    } else {
        io:println(string ` Failed to open work order: ${response.statusCode}`);
    }
}