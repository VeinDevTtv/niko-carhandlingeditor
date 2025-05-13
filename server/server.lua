-- Cache for handling data
local handlingCache = {}
local savePath = GetResourcePath(GetCurrentResourceName()) .. "/" .. Config.SavePath

-- Ensure data directory exists
CreateThread(function()
    local dataDir = GetResourcePath(GetCurrentResourceName()) .. "/data"
    
    -- Create directory using FiveM native API for cross-platform compatibility
    local dirPath = savePath:match("(.+)/") or ""
    if dirPath ~= "" then
        -- Ensures all parent directories exist
        CreateDirectory(dirPath)
    end
end)

-- Load handling data from file
local function LoadHandlingData()
    if not DoesFileExist(savePath) then
        -- Create empty file if it doesn't exist
        SaveResourceFile(GetCurrentResourceName(), Config.SavePath, "{}", -1)
        return {}
    end
    
    local fileContent = LoadResourceFile(GetCurrentResourceName(), Config.SavePath)
    if not fileContent or fileContent == "" then
        return {}
    end
    
    local success, result = pcall(function()
        return json.decode(fileContent)
    end)
    
    if success then
        return result
    else
        print("^1[ERROR] Failed to load handling data: " .. tostring(result) .. "^7")
        return {}
    end
end

-- Save handling data to file
local function SaveHandlingData()
    local success, result = pcall(function()
        return json.encode(handlingCache)
    end)
    
    if success then
        SaveResourceFile(GetCurrentResourceName(), Config.SavePath, result, -1)
        return true
    else
        print("^1[ERROR] Failed to save handling data: " .. tostring(result) .. "^7")
        return false
    end
end

-- Initialize handling cache on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    print("^2[INFO] Loading car handling data...^7")
    handlingCache = LoadHandlingData()
    print("^2[INFO] Car handling data loaded successfully^7")
end)

-- Save handling data on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    if next(handlingCache) ~= nil then
        print("^2[INFO] Saving car handling data...^7")
        SaveHandlingData()
        print("^2[INFO] Car handling data saved successfully^7")
    end
end)

-- Check if player has permission to use handling editor
RegisterNetEvent('niko:checkHandlingPermission')
AddEventHandler('niko:checkHandlingPermission', function()
    local src = source
    local hasPermission = IsPlayerAceAllowed(src, Config.PermissionAce)
    TriggerClientEvent('niko:handlingPermissionResult', src, hasPermission)
end)

-- Save handling data for a vehicle
RegisterNetEvent('niko:saveHandling')
AddEventHandler('niko:saveHandling', function(hash, handlingData)
    local src = source
    
    -- Convert hash to string for JSON storage
    local hashStr = tostring(hash)
    
    -- Add some basic validation to prevent exploits
    local validData = {}
    for field, value in pairs(handlingData) do
        if type(value) == "table" then
            -- Handle vector values
            validData[field] = {
                x = tonumber(value.x) or 0,
                y = tonumber(value.y) or 0,
                z = tonumber(value.z) or 0
            }
        elseif type(value) == "number" then
            -- Handle numeric values (apply reasonable limits to prevent exploits)
            if field == "fMass" then
                validData[field] = math.max(1, math.min(20000, value))
            elseif field:find("^f") then -- Float values
                validData[field] = math.max(-1000000, math.min(1000000, value))
            else -- Integer values including flags
                validData[field] = math.floor(value)
            end
        end
    end
    
    -- Save to cache
    handlingCache[hashStr] = validData
    
    -- Save immediately if persistence is enabled
    if Config.PersistAcrossRestarts then
        SaveHandlingData()
    end
end)

-- Request saved handling data
RegisterNetEvent('niko:requestSavedHandling')
AddEventHandler('niko:requestSavedHandling', function(hash)
    local src = source
    local hashStr = tostring(hash)
    
    if handlingCache[hashStr] then
        TriggerClientEvent('niko:loadSavedHandling', src, handlingCache[hashStr])
    end
end)

-- Helper function to check if file exists
function DoesFileExist(path)
    local f = io.open(path, "r")
    if f then f:close() return true else return false end
end 