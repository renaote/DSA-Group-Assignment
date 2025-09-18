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
}
