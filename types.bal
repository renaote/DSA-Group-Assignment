import ballerina/time;
public type AssetType "PRINTER"|"VEHICLE"|"ROUTER"|"COMPUTER"|"CAMERAS"|"AC"|"SERVER"|"PROJECTOR";

public type Status "ACTIVE"|"UNDER_REPAIR"|"DISPOSED";

public type Components record {|
string id;
string name;
string description;
time:Date installedDate;
Status status?;
|};

public type MaintenanceSchedule record {|
string id;
string scheduletype;
string description;
time:Date lastServiceDate;
time:Date nextDueDate;
boolean isOverDue?;
|};

public type Task record {|
string id;
string description;
string status;
time:Date assignedTo;
time:Date dueDate;
string completedDate?;
|};

public type WorkOrder record {|
string id;
string title;
string description;
time:Date openedDate;
time:Date closedDate;
string status;
Task[] tasks;


|};

public type Asset record {|
readonly string assetTag;
readonly string name;
readonly string faculty;
readonly string department;
readonly Status status;
readonly string acquiredDate;
readonly Components[] components;
readonly MaintenanceSchedule[] schedule;
readonly WorkOrder[] workOrders;
|};

public type AssetInput record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    Status status;
    string acquiredDate;

|};

public type ComponentsInput record {|
    string name;
    string description?;
    time:Date installedDate?;
    Status status?;
|};

public type MaintenanceScheduleInput record {|
    string scheduleType;
    string description;
    time:Date lastServiceDate;
    time:Date nextDueDate;
|};

public type TaskInput record {|
    string description;
    string status;
    string assignedTo?;
    time:Date dueDate?;
|};

public type WorkOrderInput record {|
    string title;
    string description;
    TaskInput[] tasks?;
|};


public type AssetUpdate record {|
    string assetTag;
    string name?;
    string faculty?;
    string department?;
    Status status?;
    string acquiredDate?;
|};

public type ComponentsUpdate record {|
    string id;  
    string name?;
    string description?;
    time:Date installedDate?;
    Status status?;
|};

public type MaintenanceScheduleUpdate record {|
    string id;  
    string scheduleType?;
    string description?;
    time:Date lastServiceDate?;
    time:Date nextDueDate?;
|};

public type WorkOrderUpdate record {|
    string id;  
    string title?;
    string description?;
    string status?;
    TaskUpdate[] tasks?;
|};

public type TaskUpdate record {|
    string id; 
    string description?;
    string status?;
    string assignedTo?;
    time:Date dueDate?;
    time:Date completedDate?;
|};
