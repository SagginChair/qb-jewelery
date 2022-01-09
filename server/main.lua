local timeOut = false
local boostingBusy = false
local keycardBusy = false
local laptopBusy = false
local atmBusy = false
local alarmTriggered = false

RegisterServerEvent('qb-jewellery:server:setVitrineState')
AddEventHandler('qb-jewellery:server:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
    TriggerClientEvent('qb-jewellery:client:setVitrineState', -1, stateType, state, k)
end)

RegisterServerEvent('qb-jewellery:server:vitrineReward')
AddEventHandler('qb-jewellery:server:vitrineReward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local otherchance = math.random(1, 25)
    local odd = math.random(1, 25)

    if otherchance == odd then
        local item = math.random(1, #Config.VitrineRewards)
        local amount = math.random(Config.VitrineRewards[item]["amount"]["min"], Config.VitrineRewards[item]["amount"]["max"])
        if Player.Functions.AddItem(Config.VitrineRewards[item]["item"], amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.VitrineRewards[item]["item"]], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket', 'error')
        end
    else
        local amount = math.random(4, 6)
        if Player.Functions.AddItem("rolex", amount) then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["rolex"], 'add')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have to much in your pocket..', 'error')
        end
    end
end)

RegisterServerEvent('qb-jewellery:server:setTimeout')
AddEventHandler('qb-jewellery:server:setTimeout', function()
    if not timeOut then
        timeOut = true
        TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", true)
        Citizen.CreateThread(function()
        Citizen.Wait(Config.Timeout)

            for k, v in pairs(Config.Locations) do
                Config.Locations[k]["isOpened"] = false
                TriggerClientEvent('qb-jewellery:client:setVitrineState', -1, 'isOpened', false, k)
                TriggerClientEvent('qb-jewellery:client:setAlertState', -1, false)
                TriggerEvent('qb-scoreboard:server:SetActivityBusy', "jewellery", false)
            end
            timeOut = false
            alarmTriggered = false
        end)
    end
end)

RegisterServerEvent('qb-jewellery:server:PoliceAlertMessage')
AddEventHandler('qb-jewellery:server:PoliceAlertMessage', function(title, coords, blip)
    local src = source
    local alertData = {
        title = title,
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = "Possible robbery going on at Vangelico Jewelry Store<br>Available camera's: 31, 32, 33, 34",
    }

    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                if blip then
                    if not alarmTriggered then
                        TriggerClientEvent("qb-phone:client:addPoliceAlert", v, alertData)
                        TriggerClientEvent("qb-jewellery:client:PoliceAlertMessage", v, title, coords, blip)
                        alarmTriggered = true
                    end
                else
                    TriggerClientEvent("qb-phone:client:addPoliceAlert", v, alertData)
                    TriggerClientEvent("qb-jewellery:client:PoliceAlertMessage", v, title, coords, blip)
                end
            end
        end
    end
end)

QBCore.Functions.CreateCallback('qb-jewellery:server:getCops', function(source, cb)
	local amount = 0
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
	end
	cb(amount)
end)

QBCore.Functions.CreateCallback('qb-jewerly:server:get:checkitem', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local thermite = Ply.Functions.GetItemByName("thermite")
    if thermite ~= nil then
        cb(true)
    else
        cb(false)
    end
end)


QBCore.Functions.CreateCallback('qb-jewerly:server:get:checkitemkey', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local thermite = Ply.Functions.GetItemByName("security_card_01")
    if thermite ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-jewerly:server:get:checklaptop', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local thermite = Ply.Functions.GetItemByName("purpledongleempty")
    if thermite ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

RegisterServerEvent('qb-Jewelry:server:callCops')
AddEventHandler('qb-Jewelry:server:callCops', function(type, bank, streetLabel, coords)
    
    local msg = ""
    msg = "Possible Sale of Narcotics"
    local alertData = {
        title = "Drugs",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = msg,
    }
    TriggerClientEvent("qb-Jewelry:client:callCops911", -1, type, bank, streetLabel, coords)
    TriggerClientEvent("qb-phone:client:addPoliceAlert", -1, alertData)
end)

RegisterServerEvent('qb-Jewelry:server:callatm')
AddEventHandler('qb-Jewelry:server:callatm', function(type, bank, streetLabel, coords)
    
    local msg = ""
    msg = "Possible Sale of Narcotics"
    local alertData = {
        title = "Drugs",
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = msg,
    }
    TriggerClientEvent("qb-Jewelry:client:callCops911", -1, type, bank, streetLabel, coords)
    TriggerClientEvent("qb-phone:client:addPoliceAlert", -1, alertData)
end)

--Busy Status Thermite
RegisterNetEvent('qb-jewelery:server:SetThermite')
AddEventHandler('qb-jewelery:server:SetThermite', function()
    if not boostingBusy then
        TriggerEvent('qb-Jewelery:server:ThermiteBusy')
        boostingBusy = true
    else
        TriggerClientEvent("QBCore:Notify", "I don't have a job for you right now", "error", 5000)
    end
end)

RegisterNetEvent('qb-Jewelery:server:ThermiteBusy')
AddEventHandler('qb-Jewelery:server:ThermiteBusy', function()
    if not boostingBusy then
        SetTimeout(Config.Timeout, function() -- 10 Min cooldown for other Vehicles to be Scratched
            timeOut = false
            boostingBusy = false
        end)
    end
end)

QBCore.Functions.CreateCallback('qb-jewelery:server:IsDoorBusy', function(source, cb)
    cb(boostingBusy)
end)

--Busy Status Thermite
RegisterNetEvent('qb-jewelery:server:SetKeycard')
AddEventHandler('qb-jewelery:server:SetKeycard', function()
    if not keycardBusy then
        TriggerEvent('qb-Jewelery:server:KeycardBusy')
        keycardBusy = true
    else
        TriggerClientEvent("QBCore:Notify", "I don't have a job for you right now", "error", 5000)
    end
end)

RegisterNetEvent('qb-Jewelery:server:KeycardBusy')
AddEventHandler('qb-Jewelery:server:KeycardBusy', function()
    if not keycardBusy then
        SetTimeout(Config.Keycard, function() -- 10 Min cooldown for other Vehicles to be Scratched
            timeOut = false
            keycardBusy = false
        end)
    end
end)

QBCore.Functions.CreateCallback('qb-jewelery:server:IsKeycardBusy', function(source, cb)
    cb(keycardBusy)
end)

--Busy Status Laptop
RegisterNetEvent('qb-jewelery:server:SetLaptopHack')
AddEventHandler('qb-jewelery:server:SetLaptopHack', function()
    if not laptopBusy then
        TriggerEvent('qb-Jewelery:server:LaptopBusy')
        laptopBusy = true
    else
        TriggerClientEvent("QBCore:Notify", "I don't have a job for you right now", "error", 5000)
    end
end)

RegisterNetEvent('qb-Jewelery:server:LaptopBusy')
AddEventHandler('qb-Jewelery:server:LaptopBusy', function()
    if not laptopBusy then
        SetTimeout(Config.Keycard, function() -- 10 Min cooldown for other Vehicles to be Scratched
            timeOut = false
            laptopBusy = false
        end)
    end
end)

QBCore.Functions.CreateCallback('qb-jewelery:server:IsLaptopBusy', function(source, cb)
    cb(laptopBusy)
end)

QBCore.Functions.CreateCallback('qb-jewerly:server:get:checkatm', function(source, cb)
    local src = source
    local Ply = QBCore.Functions.GetPlayer(src)
    local thermite = Ply.Functions.GetItemByName("thermite")
    if thermite ~= nil then
        cb(true)
    else
        cb(false)
    end
end)

--Busy Status Laptop
RegisterNetEvent('qb-jewelery:server:SetATMHack')
AddEventHandler('qb-jewelery:server:SetATMHack', function()
    if not atmBusy then
        TriggerEvent('qb-Jewelery:server:ATMBusy')
        atmBusy = true
    else
        TriggerClientEvent("QBCore:Notify", "I don't have a job for you right now", "error", 5000)
    end
end)

RegisterNetEvent('qb-Jewelery:server:ATMBusy')
AddEventHandler('qb-Jewelery:server:ATMBusy', function()
    if not atmBusy then
        SetTimeout(Config.ATMRobbery, function() -- 10 Min cooldown for other Vehicles to be Scratched
            timeOut = false
            atmBusy = false
        end)
    end
end)

QBCore.Functions.CreateCallback('qb-jewelery:server:IsATMBusy', function(source, cb)
    cb(atmBusy)
end)