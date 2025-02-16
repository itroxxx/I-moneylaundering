local QBCore = nil
local ESX = nil

Citizen.CreateThread(function()
    while not QBCore and not ESX do
        if Config.Framework == 'QBCore' then
            QBCore = exports['qb-core']:GetCoreObject()
        elseif Config.Framework == 'ESX' then
            ESX = exports['es_extended']:getSharedObject()
        end
        Citizen.Wait(100)
    end

    while true do
        local playerDataLoaded = false
        if Config.Framework == 'QBCore' then
            local playerData = QBCore.Functions.GetPlayerData()
            if playerData and playerData.citizenid then
                playerDataLoaded = true
            end
        elseif Config.Framework == 'ESX' then
            local playerData = ESX.GetPlayerData()
            if playerData and playerData.identifier then
                playerDataLoaded = true
            end
        end

        if playerDataLoaded then
            break
        end

        Citizen.Wait(100)
    end

    for _, washer in pairs(Config.Washers) do
        local canSeeBlip = false
        if washer.job then
            if Config.Framework == 'QBCore' then
                local playerData = QBCore.Functions.GetPlayerData()
                canSeeBlip = playerData.job.name == washer.job
            elseif Config.Framework == 'ESX' then
                local playerData = ESX.GetPlayerData()
                canSeeBlip = playerData.job.name == washer.job
            end
        else
            canSeeBlip = true
        end

        if canSeeBlip and washer.showBlip then
            local blip = AddBlipForCoord(washer.coords.x, washer.coords.y, washer.coords.z)
            SetBlipSprite(blip, washer.blipSettings.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, washer.blipSettings.scale)
            SetBlipColour(blip, washer.blipSettings.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(washer.blipSettings.name)
            EndTextCommandSetBlipName(blip)
        end


        local existingProp = GetClosestObjectOfType(washer.coords.x, washer.coords.y, washer.coords.z, 1.0, GetHashKey(washer.prop), false, false, false)
        if existingProp == 0 then
            local prop = CreateObject(GetHashKey(washer.prop), washer.coords.x, washer.coords.y, washer.coords.z, false, false, false)
            SetEntityHeading(prop, washer.coords.w)
            FreezeEntityPosition(prop, true)
            PlaceObjectOnGroundProperly(prop) 

            exports.ox_target:addLocalEntity(prop, {
                {
                    name = 'money_laundering',
                    label = 'Pese Rahaa',
                    icon = 'fas fa-money-bill-wave',
                    distance = 2.0,
                    onSelect = function()
                        StartWashingMoney(washer.coords)
                    end,
                    canInteract = function(entity, distance, coords, name, bone)
                        if washer.job then
                            if Config.Framework == 'QBCore' then
                                local playerData = QBCore.Functions.GetPlayerData()
                                return playerData.job.name == washer.job
                            elseif Config.Framework == 'ESX' then
                                local playerData = ESX.GetPlayerData()
                                return playerData.job.name == washer.job
                            end
                        else
                            return true
                        end
                    end
                }
            })
        end
    end
end)

function StartWashingMoney(coords)
    local playerPed = PlayerPedId()
    print("Starting money laundering...")


    RequestAnimDict("amb@world_human_clipboard@male@base")
    while not HasAnimDictLoaded("amb@world_human_clipboard@male@base") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "amb@world_human_clipboard@male@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))

            if distance > 5.0 or IsControlJustReleased(0, 73) then 
                if exports.ox_lib:progressActive() then
                    exports.ox_lib:cancelProgress()
                end
                ClearPedTasks(playerPed) 
                TriggerServerEvent('money_laundering:stopWashing')
                break
            end

            if not exports.ox_lib:progressActive() then
                TriggerServerEvent('money_laundering:washMoney', coords)
                Citizen.Wait(Config.WashTime)
            end
        end
    end)
end

RegisterNetEvent('money_laundering:progress')
AddEventHandler('money_laundering:progress', function(coords)
    print("Progress event triggered...")
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))

    Citizen.CreateThread(function()
        while exports.ox_lib:progressActive() do
            Citizen.Wait(0)
            playerCoords = GetEntityCoords(playerPed)
            distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))

            if distance > 5.0 then
                print('Money laundering cancelled due to distance')
                exports.ox_lib:cancelProgress()
                ClearPedTasks(playerPed) 
                TriggerServerEvent('money_laundering:stopWashing')
                return
            end
        end
    end)

    if exports.ox_lib:progressCircle({
        duration = Config.WashTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
    }) then
        print('Money laundering complete')
    else
        print('Money laundering cancelled')
    end
end)

RegisterCommand('plantc4', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestWasher, closestDistance = nil, 5.0

    for _, washer in pairs(Config.Washers) do
        local distance = #(playerCoords - vector3(washer.coords.x, washer.coords.y, washer.coords.z))
        if distance < closestDistance then
            closestWasher = washer
            closestDistance = distance
        end
    end

    if closestWasher then
        RequestAnimDict("anim@heists@ornate_bank@thermal_charge")
        while not HasAnimDictLoaded("anim@heists@ornate_bank@thermal_charge") do
            Citizen.Wait(100)
        end
        TaskPlayAnim(playerPed, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 8.0, -8.0, -1, 49, 0, false, false, false)
        Citizen.Wait(5000) 
        ClearPedTasks(playerPed)

        TriggerServerEvent('money_laundering:plantC4', closestWasher.id)
    else
        print("No washer nearby to plant C4.")
    end
end, false)

RegisterNetEvent('money_laundering:triggerC4')
AddEventHandler('money_laundering:triggerC4', function(washerId)
    local washer = Config.Washers[washerId]
    if washer then
        local countdown = math.random(10, 30) 

        Citizen.CreateThread(function()
            while countdown > 0 do
                Citizen.Wait(0)
                DrawTextOnScreen("Explosion in: " .. countdown .. "s")
                Citizen.Wait(1000)
                countdown = countdown - 1
            end

            AddExplosion(washer.coords.x, washer.coords.y, washer.coords.z, 2, 1.0, true, false, 1.0)
            TriggerServerEvent('money_laundering:destroyWasher', washerId)

            local existingProp = GetClosestObjectOfType(washer.coords.x, washer.coords.y, washer.coords.z, 1.0, GetHashKey(washer.prop), false, false, false)
            if existingProp ~= 0 then
                DeleteObject(existingProp)
            end
        end)
    end
end)

RegisterNetEvent('money_laundering:removeWasherProp')
AddEventHandler('money_laundering:removeWasherProp', function(washerId)
    local washer = Config.Washers[washerId]
    if washer then
        local existingProp = GetClosestObjectOfType(washer.coords.x, washer.coords.y, washer.coords.z, 1.0, GetHashKey(washer.prop), false, false, false)
        if existingProp ~= 0 then
            DeleteObject(existingProp)
        end
    end
end)

function DrawTextOnScreen(text)
    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + 1000
        while GetGameTimer() < endTime do
            Citizen.Wait(0)
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextDropShadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(text)
            DrawText(0.5, 0.8)
        end
    end)
end