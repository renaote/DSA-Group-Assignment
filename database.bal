import ballerina/time;
public isolated class AssetDatabase {

    private final table<Asset> key(assetTag) assets = table [];
    
   public isolated function createAsset(Asset asset) returns Asset|error {
    lock {
        if self.assets.hasKey(asset.assetTag) {
            return error("Asset tag '" + asset.assetTag + "' already exists");
        }
        
        self.assets.add(asset);
        return asset;
    }
   }
   
    public isolated function getAllAssets() returns Asset[] {
        return from var asset in self.assets select asset;
    }

    public isolated function getAssetByTag(string assetTag) returns Asset|error {
        Asset? asset = self.assets[assetTag];
        
        if asset is () {
            return error("Asset with tag '" + assetTag + "' not found");
        }
        return asset;
    }

     public isolated function updateAsset(string assetTag, AssetUpdate updateData) returns Asset|error {
        Asset? existingAsset = self.assets[assetTag];
        if existingAsset is () {
            return error("Asset with tag '" + assetTag + "' not found");
        }
        

       Asset updatedAsset = {
    assetTag: assetTag,
    name: updateData.name ?: existingAsset.name,
    faculty: updateData.faculty ?: existingAsset.faculty,
    department: updateData.department ?: existingAsset.department,
    status: updateData.status ?: existingAsset.status,
    acquiredDate: updateData.acquiredDate ?: existingAsset.acquiredDate,  // ← FIXED: acquiredDate
    components: existingAsset.components,
    schedule: existingAsset.schedule,
    workOrders: existingAsset.workOrders
};

        _ = self.assets.remove(assetTag);
    self.assets.add(updatedAsset);
    return updatedAsset;
}

 public isolated function deleteAsset(string assetTag) returns error? {
        if !self.assets.hasKey(assetTag) {
            return error("Asset with tag '" + assetTag + "' not found");
        }
        _ = self.assets.remove(assetTag);
    }

     public isolated function isAssetTagUnique(string assetTag) returns boolean {
        return !self.assets.hasKey(assetTag);
    }

    public isolated function getAssetsByFaculty(string faculty) returns Asset[] {
        return from var asset in self.assets
            where asset.faculty == faculty
            select asset;
    }

public isolated function getAssetCount() returns int {
        return self.assets.length();
    }
    
     public isolated function getAssetsByStatus(Status status) returns Asset[] {
        return from var asset in self.assets
            where asset.status == status
            select asset;
    }

     public isolated function assetExists(string assetTag) returns boolean {
        return self.assets.hasKey(assetTag);
    }
    //Method to add a component to an asset
    public isolated function addComponent(string assetTag, Components component) returns Asset|error {
        lock {
            //Checks if asset exists
            Asset? asset = self.assets[assetTag];
            if asset is () {
                return error("Asset with tag '" + assetTag + "' not found");
            }
            //Updates the asset record
            Components[] updatedComponents = asset.components.clone();
            updatedComponents.push(component);
            Asset updatedAsset = {
                assetTag: asset.assetTag,
                name: asset.name,
                faculty: asset.faculty,
                department: asset.department,
                status: asset.status,
                acquiredDate: asset.acquiredDate,
                components: <readonly>updatedComponents,
                schedule: asset.schedule,
                workOrders: asset.workOrders
            };
            _ = self.assets.remove(assetTag);
            self.assets.add(updatedAsset);
            return updatedAsset;
        }
    }
//Method to remove a component from an asset
    public isolated function removeComponent(string assetTag, string componentId) returns Asset|error {
        lock {
            //Checks if asset exists
            Asset? asset = self.assets[assetTag];
            if asset is () {
                return error("Asset with tag '" + assetTag + "' not found");
            }
            Components[] updatedComponents = [];
            foreach var comp in asset.components {
                if comp.id != componentId {
                    updatedComponents.push(comp);
                }
            }
            //Updates the asset record
            Asset updatedAsset = {
                assetTag: asset.assetTag,
                name: asset.name,
                faculty: asset.faculty,
                department: asset.department,
                status: asset.status,
                acquiredDate: asset.acquiredDate,
                components: <readonly>updatedComponents,
                schedule: asset.schedule,
                workOrders: asset.workOrders
            };
            _ = self.assets.remove(assetTag);
            self.assets.add(updatedAsset);
            return updatedAsset;
        }
    }

//Method to add a maintenance schedule to an asset
    public isolated function addScheduleToAsset(string assetTag, MaintenanceSchedule scheduleItem) returns Asset|error {
        lock {
            //Checks if asset exists
            Asset? asset = self.assets[assetTag];
            if asset is () {
                return error("Asset with tag '" + assetTag + "' not found");
            }
            MaintenanceSchedule[] updatedSchedule = asset.schedule.clone();
            updatedSchedule.push(scheduleItem);
            Asset updatedAsset = {
                assetTag: asset.assetTag,
                name: asset.name,
                faculty: asset.faculty,
                department: asset.department,
                status: asset.status,
                acquiredDate: asset.acquiredDate,
                components: asset.components,
                schedule: <readonly>updatedSchedule,
                workOrders: asset.workOrders
            };
            _ = self.assets.remove(assetTag);
            self.assets.add(updatedAsset);
            return updatedAsset;
        }
    }
//Method to remove a maintenance schedule from an asset
    public isolated function removeScheduleFromAsset(string assetTag, string scheduleId) returns Asset|error {
        lock {
            //Checks if asset exists
            Asset? asset = self.assets[assetTag];
            if asset is () {
                return error("Asset with tag '" + assetTag + "' not found");
            }
            MaintenanceSchedule[] updatedSchedule = [];
            foreach var sched in asset.schedule {
                if sched.id != scheduleId {
                    updatedSchedule.push(sched);
                }
            }
            //Updates the asset record
            Asset updatedAsset = {
                assetTag: asset.assetTag,
                name: asset.name,
                faculty: asset.faculty,
                department: asset.department,
                status: asset.status,
                acquiredDate: asset.acquiredDate,
                components: asset.components,
                schedule: <readonly>updatedSchedule,
                workOrders: asset.workOrders
            };
            _ = self.assets.remove(assetTag);
            self.assets.add(updatedAsset);
            return updatedAsset;
        }
    }
    
  public isolated function getOverdueMaintenanceAssets() returns Asset[] {
    lock {
        time:Date currentDate = time:utcToCivil(time:utcNow());
        Asset[] overdueAssets = [];
        
        foreach var asset in self.assets {
            foreach var schedule in asset.schedule {
                // Check if the schedule has a due date and if it's overdue
                if schedule.nextDueDate is time:Date && schedule.nextDueDate < currentDate {
                    overdueAssets.push(asset);
                    break;
                }
            }
        }
        return overdueAssets;
    }
}
