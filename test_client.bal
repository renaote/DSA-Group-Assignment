import ballerina/http;
import ballerina/io;
import ballerina/test;

// Test configuration
configurable string testServiceUrl = "http://localhost:8080";

@test:Config
function testAssetCRUDOperations() returns error? {
    http:Client client = check new (testServiceUrl);
    
    // Test 1: Create Asset
    json createPayload = {
        "assetTag": "TEST-001",
        "name": "Test Equipment",
        "faculty": "Computing & Informatics", 
        "department": "Software Engineering",
        "status": "ACTIVE",
        "acquiredDate": "2024-09-20",
        "components": {},
        "schedules": {},
        "workOrders": {}
    };
    
    http:Response createResponse = check client->post("/assets", createPayload);
    test:assertEquals(createResponse.statusCode, 201, "Asset creation should return 201");
    
    // Test 2: Get Asset
    http:Response getResponse = check client->get("/assets/TEST-001");
    test:assertEquals(getResponse.statusCode, 200, "Asset retrieval should return 200");
    
    // Test 3: Update Asset
    json updatePayload = {
        "name": "Updated Test Equipment",
        "status": "UNDER_REPAIR"
    };
    
    http:Response updateResponse = check client->put("/assets/TEST-001", updatePayload);
    test:assertEquals(updateResponse.statusCode, 200, "Asset update should return 200");
    
    // Test 4: Delete Asset
    http:Response deleteResponse = check client->delete("/assets/TEST-001");
    test:assertTrue(deleteResponse.statusCode == 200 || deleteResponse.statusCode == 204, 
                   "Asset deletion should return 200 or 204");
}

@test:Config
function testAssetFiltering() returns error? {
    http:Client client = check new (testServiceUrl);
    
    // Test: Get all assets
    http:Response allResponse = check client->get("/assets");
    test:assertEquals(allResponse.statusCode, 200, "Get all assets should return 200");
    
    // Test: Get assets by faculty
    string facultyEndpoint = "/assets?faculty=Computing%20%26%20Informatics";
    http:Response facultyResponse = check client->get(facultyEndpoint);
    test:assertEquals(facultyResponse.statusCode, 200, "Faculty filtering should return 200");
    
    // Test: Get overdue assets
    http:Response overdueResponse = check client->get("/assets/overdue");
    test:assertEquals(overdueResponse.statusCode, 200, "Overdue check should return 200");
}

@test:Config
function testComponentManagement() returns error? {
    http:Client client = check new (testServiceUrl);
    
    // First create a test asset
    json assetPayload = {
        "assetTag": "COMP-TEST",
        "name": "Component Test Asset",
        "faculty": "Engineering",
        "department": "Mechanical", 
        "status": "ACTIVE",
        "acquiredDate": "2024-09-20",
        "components": {},
        "schedules": {},
        "workOrders": {}
    };
    
    _ = check client->post("/assets", assetPayload);
    
    // Test: Add Component
    json componentPayload = {
        "componentId": "COMP-001",
        "name": "Test Component", 
        "description": "A test component",
        "status": "ACTIVE"
    };
    
    http:Response addCompResponse = check client->post("/assets/COMP-TEST/components", componentPayload);
    test:assertEquals(addCompResponse.statusCode, 201, "Component addition should return 201");
    
    // Test: Remove Component  
    http:Response removeCompResponse = check client->delete("/assets/COMP-TEST/components/COMP-001");
    test:assertTrue(removeCompResponse.statusCode == 200 || removeCompResponse.statusCode == 204,
                   "Component removal should return 200 or 204");
    
    // Cleanup
    _ = check client->delete("/assets/COMP-TEST");
}

@test:Config 
function testScheduleManagement() returns error? {
    http:Client client = check new (testServiceUrl);
    
    // First create a test asset
    json assetPayload = {
        "assetTag": "SCH-TEST",
        "name": "Schedule Test Asset",
        "faculty": "Engineering", 
        "department": "Civil",
        "status": "ACTIVE",
        "acquiredDate": "2024-09-20",
        "components": {},
        "schedules": {},
        "workOrders": {}
    };
    
    _ = check client->post("/assets", assetPayload);
    
    // Test: Add Schedule
    json schedulePayload = {
        "scheduleId": "SCH-001",
        "frequency": "MONTHLY",
        "nextDueDate": "2024-10-20",
        "description": "Monthly maintenance check"
    };
    
    http:Response addSchResponse = check client->post("/assets/SCH-TEST/schedules", schedulePayload);
    test:assertEquals(addSchResponse.statusCode, 201, "Schedule addition should return 201");
    
    // Test: Remove Schedule
    http:Response removeSchResponse = check client->delete("/assets/SCH-TEST/schedules/SCH-001");
    test:assertTrue(removeSchResponse.statusCode == 200 || removeSchResponse.statusCode == 204,
                   "Schedule removal should return 200 or 204");
    
    // Cleanup
    _ = check client->delete("/assets/SCH-TEST");
}

@test:Config
function testErrorScenarios() returns error? {
    http:Client client = check new (testServiceUrl);
    
    // Test: Get non-existent asset
    http:Response notFoundResponse = check client->get("/assets/DOESNT-EXIST");
    test:assertEquals(notFoundResponse.statusCode, 404, "Non-existent asset should return 404");
    
    // Test: Invalid payload
    json invalidPayload = {
        "invalidField": "invalidValue"
    };
    
    http:Response badRequestResponse = check client->post("/assets", invalidPayload);
    test:assertEquals(badRequestResponse.statusCode, 400, "Invalid payload should return 400");
}

public function main() returns error? {
    io:println("Running Asset Management Client Tests...\n");
    
    test:TestSuite testSuite = test:TestSuite {};
    
    // Run individual tests
    error? result1 = testAssetCRUDOperations();
    if result1 is error {
        io:println(string `CRUD Test Failed: ${result1.message()}`);
    } else {
        io:println(" CRUD Operations Test Passed");
    }
    
    error? result2 = testAssetFiltering();
    if result2 is error {
        io:println(string `Filtering Test Failed: ${result2.message()}`);
    } else {
        io:println(" Asset Filtering Test Passed");
    }
    
    error? result3 = testComponentManagement();
    if result3 is error {
        io:println(string `Component Management Test Failed: ${result3.message()}`);
    } else {
        io:println(" Component Management Test Passed");
    }
    
    error? result4 = testScheduleManagement();
    if result4 is error {
        io:println(string `Schedule Management Test Failed: ${result4.message()}`);
    } else {
        io:println(" Schedule Management Test Passed");
    }
    
    error? result5 = testErrorScenarios();
    if result5 is error {
        io:println(string `Error Scenarios Test Failed: ${result5.message()}`);
    } else {
        io:println(" Error Scenarios Test Passed");
    }
    
    io:println("\n=== All Tests Complete ===");
}