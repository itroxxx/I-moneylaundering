local QBCore = nil
local ESX = nil

CreateThread(function()
    if Config.Framework == 'QBCore' then
        QBCore = exports['qb-core']:GetCoreObject()
        print("QBCore framework detected")
    elseif Config.Framework == 'ESX' then
        ESX = exports['es_extended']:getSharedObject()
        print("ESX framework detected")
    end
end)

RegisterServerEvent('money_laundering:washMoney')
AddEventHandler('money_laundering:washMoney', function(coords)
    local source = source
    local dirtyAmount = Config.DirtyMoneyAmount
    local cleanAmount = Config.CleanMoneyAmount

    print("Received washMoney event from client...")

    if Config.Framework == 'QBCore' then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            if player.Functions.RemoveItem('markedbills', dirtyAmount) then
                TriggerClientEvent('money_laundering:progress', source, coords)
                Citizen.Wait(Config.WashTime)
                player.Functions.AddMoney('cash', cleanAmount)
                print("QBCore: Player " .. source .. " washed " .. dirtyAmount .. " dirty money and received " .. cleanAmount .. " clean money")
            else
                TriggerClientEvent('ox_lib:notify', source, { type = 'error', text = 'Not enough dirty money' })
            end
        else
            print("QBCore: Player not found")
        end
    elseif Config.Framework == 'ESX' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if xPlayer.getInventoryItem('black_money').count >= dirtyAmount then
                xPlayer.removeInventoryItem('black_money', dirtyAmount)
                TriggerClientEvent('money_laundering:progress', source, coords)
                Citizen.Wait(Config.WashTime)
                xPlayer.addMoney(cleanAmount)
                print("ESX: Player " .. source .. " washed " .. dirtyAmount .. " dirty money and received " .. cleanAmount .. " clean money")
            else
                TriggerClientEvent('ox_lib:notify', source, { type = 'error', text = 'Not enough dirty money' })
            end
        else
            print("ESX: Player not found")
        end
    end
end)

RegisterServerEvent('money_laundering:stopWashing')
AddEventHandler('money_laundering:stopWashing', function()
    local source = source
    print("Player " .. source .. " stopped washing money")
end)

RegisterServerEvent('money_laundering:plantC4')
AddEventHandler('money_laundering:plantC4', function(washerId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == 'police' then
        TriggerClientEvent('money_laundering:triggerC4', -1, washerId)
    end
end)

RegisterServerEvent('money_laundering:destroyWasher')
AddEventHandler('money_laundering:destroyWasher', function(washerId)
    MySQL.Async.execute('UPDATE washers SET open = 0 WHERE id = @id', {
        ['@id'] = washerId
    })
    TriggerClientEvent('money_laundering:removeWasherProp', -1, washerId)
end)