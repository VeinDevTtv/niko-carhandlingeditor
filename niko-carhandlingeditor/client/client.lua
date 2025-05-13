-- Bit operation utility functions
function SetBit(value, bit) return value | (1 << bit) end
function ClearBit(value, bit) return value & ~(1 << bit) end
function HasBit(value, bit) return (value & (1 << bit)) ~= 0 end

-- Notification function (fallback if ox_lib is not available)
local function Notify(title, message, type)
    if Config.UseOxLib and lib then
        lib.notify({
            title = title,
            description = message,
            type = type
        })
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- Store original handling data for reset functionality
local originalHandling = {}
local currentVehicle = 0

-- Handling data categories and their fields
local handlingCategories = {
    Dynamics = {
        "fMass", "fInitialDragCoeff", "fDownforceModifier", "fPercentSubmerged", "vecCentreOfMassOffset",
        "vecInertiaMultiplier", "fDriveBiasFront", "nInitialDriveGears", "fInitialDriveForce", "fDriveInertia",
        "fClutchChangeRateScaleUpShift", "fClutchChangeRateScaleDownShift", "fInitialDriveMaxFlatVel",
        "fBrakeForce", "fBrakeBiasFront", "fHandBrakeForce"
    },
    Traction = {
        "fTractionCurveMax", "fTractionCurveMin", "fTractionCurveLateral", "fTractionSpringDeltaMax",
        "fLowSpeedTractionLossMult", "fCamberStiffnesss", "fTractionBiasFront", "fTractionLossMult"
    },
    Suspension = {
        "fSuspensionForce", "fSuspensionCompDamp", "fSuspensionReboundDamp", "fSuspensionUpperLimit",
        "fSuspensionLowerLimit", "fSuspensionRaise", "fSuspensionBiasFront", "fAntiRollBarForce",
        "fAntiRollBarBiasFront", "fRollCentreHeightFront", "fRollCentreHeightRear"
    },
    Damage = {
        "fDeformationDamageMult", "fCollisionDamageMult", "fWeaponDamageMult", "fEngineDamageMult",
        "fPetrolTankVolume", "fOilVolume"
    },
    Flags = {
        "handlingFlags", "damageFlags", "strModelFlags"
    }
}

-- Flag definitions for UI display
local handlingFlagDefinitions = {
    -- Handling flags (incomplete list - add more as needed)
    [0] = "1G_BOOST",
    [1] = "2G_BOOST",
    [2] = "NPC_ANTI_ROLL",
    [3] = "NPC_NEUTRAL_HANDL",
    [4] = "NO_HANDBRAKE",
    [5] = "STEER_REARWHEELS",
    [6] = "HB_REARWHEEL_STEER",
    [7] = "ALT_STEER_OPT",
    [8] = "WHEEL_F_NARROW2",
    [9] = "WHEEL_R_NARROW2",
    [10] = "WHEEL_F_WIDE",
    [11] = "WHEEL_R_WIDE",
    [12] = "HYDRAULIC_GEOM",
    [13] = "HYDRAULIC_INST",
    [14] = "HYDRAULIC_NONE",
    [15] = "NOS_INST",
    [16] = "OFFROAD_ABILITY",
    [17] = "OFFROAD_ABILITY2",
    [18] = "HALOGEN_LIGHTS",
    [19] = "PROC_REARWHEEL_1ST",
    [20] = "USE_MAXSP_LIMIT",
    [21] = "LOW_RIDER",
    [22] = "STREET_RACER",
    -- Additional flags would go here
}

-- Get all handling data for a vehicle
local function GetVehicleHandlingData(vehicle)
    if vehicle == 0 then return nil end
    
    local data = {}
    
    -- Loop through all handling categories
    for category, fields in pairs(handlingCategories) do
        for _, field in ipairs(fields) do
            -- Different getter based on field type
            if field == "vecCentreOfMassOffset" or field == "vecInertiaMultiplier" then
                local x = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field .. ".x")
                local y = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field .. ".y")
                local z = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field .. ".z")
                data[field] = {x = x, y = y, z = z}
            elseif field == "handlingFlags" or field == "damageFlags" or field == "strModelFlags" then
                data[field] = GetVehicleHandlingInt(vehicle, 'CHandlingData', field)
            else
                data[field] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
            end
        end
    end
    
    return data
end

-- Store original handling data for reset functionality
local function StoreOriginalHandling(vehicle)
    originalHandling[vehicle] = GetVehicleHandlingData(vehicle)
end

-- Send handling data to UI
local function SendHandlingDataToUI(vehicle)
    currentVehicle = vehicle
    
    -- Store original handling if not already stored
    if not originalHandling[vehicle] then
        StoreOriginalHandling(vehicle)
    end
    
    local data = GetVehicleHandlingData(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local hash = GetEntityModel(vehicle)
    
    SendNUIMessage({
        action = "open",
        data = {
            model = model,
            hash = hash,
            handling = data,
            categories = handlingCategories,
            flagDefinitions = handlingFlagDefinitions
        }
    })
end

-- Apply handling change to vehicle
local function ApplyHandlingChange(vehicle, field, value)
    if vehicle == 0 then return end
    
    -- Handle different field types
    if string.find(field, "vec") and string.find(field, ".") then
        -- Handle vector component change
        local baseField, component = field:match("(.+)%.(.+)")
        local currentValue = {}
        
        currentValue.x = GetVehicleHandlingFloat(vehicle, 'CHandlingData', baseField .. ".x")
        currentValue.y = GetVehicleHandlingFloat(vehicle, 'CHandlingData', baseField .. ".y")
        currentValue.z = GetVehicleHandlingFloat(vehicle, 'CHandlingData', baseField .. ".z")
        
        currentValue[component] = value
        
        SetVehicleHandlingVector(vehicle, 'CHandlingData', baseField, 
            vector3(currentValue.x, currentValue.y, currentValue.z))
    elseif field == "handlingFlags" or field == "damageFlags" or field == "strModelFlags" then
        -- Handle flags (integers)
        SetVehicleHandlingInt(vehicle, 'CHandlingData', field, tonumber(value))
    else
        -- Handle float values
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, tonumber(value))
    end
end

-- Reset handling to original values
local function ResetHandling(vehicle)
    if vehicle == 0 or not originalHandling[vehicle] then return end
    
    for field, value in pairs(originalHandling[vehicle]) do
        if type(value) == "table" then
            -- Handle vector values
            SetVehicleHandlingVector(vehicle, 'CHandlingData', field, 
                vector3(value.x, value.y, value.z))
        elseif field == "handlingFlags" or field == "damageFlags" or field == "strModelFlags" then
            -- Handle flags (integers)
            SetVehicleHandlingInt(vehicle, 'CHandlingData', field, value)
        else
            -- Handle float values
            SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, value)
        end
    end
    
    Notify("Handling Editor", "Handling reset to original values", "success")
end

-- Register command
RegisterCommand('handling', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        if Config.RequirePermission then
            TriggerServerEvent('niko:checkHandlingPermission')
        else
            SendHandlingDataToUI(veh)
            SetNuiFocus(true, true)
        end
    else
        Notify("Handling Editor", "Get in the driver seat first!", "error")
    end
end, false)

-- Command alias
RegisterCommand('carhandling', function()
    ExecuteCommand('handling')
end, false)

-- NUI Callbacks
RegisterNUICallback('update', function(data, cb)
    ApplyHandlingChange(currentVehicle, data.field, data.value)
    cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
    TriggerServerEvent('niko:saveHandling', data.hash, data.handling)
    Notify("Handling Editor", "Handling settings saved", "success")
    cb('ok')
end)

RegisterNUICallback('reset', function(data, cb)
    ResetHandling(currentVehicle)
    SendHandlingDataToUI(currentVehicle)
    cb('ok')
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Event handlers
RegisterNetEvent('niko:handlingPermissionResult')
AddEventHandler('niko:handlingPermissionResult', function(hasPermission)
    if hasPermission then
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            SendHandlingDataToUI(veh)
            SetNuiFocus(true, true)
        end
    else
        Notify("Handling Editor", "You don't have permission to use this command", "error")
    end
end)

RegisterNetEvent('niko:loadSavedHandling')
AddEventHandler('niko:loadSavedHandling', function(handlingData)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    
    if veh ~= 0 and handlingData then
        for field, value in pairs(handlingData) do
            ApplyHandlingChange(veh, field, value)
        end
        Notify("Handling Editor", "Saved handling settings applied", "success")
    end
end)

-- Check for saved handling when player enters a vehicle
AddEventHandler('gameEventTriggered', function(name, args)
    if name == "CEventNetworkPlayerEnteredVehicle" then
        local playerServerId = args[1]
        local vehicle = args[2]
        
        if NetworkGetEntityIsNetworked(vehicle) and Config.PersistAcrossRestarts then
            local hash = GetEntityModel(vehicle)
            TriggerServerEvent('niko:requestSavedHandling', hash)
        end
    end
end) 