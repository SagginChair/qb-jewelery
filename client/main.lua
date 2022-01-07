local robberyAlert = false
local isLoggedIn = false
local firstAlarm = false

local PlayerJob = {}

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    onDuty = true
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    onDuty = true
end)

Citizen.CreateThread(function()
    Wait(500)
    if QBCore.Functions.GetPlayerData() ~= nil then
        PlayerJob = QBCore.Functions.GetPlayerData().job
        onDuty = true
    end
end)

function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        inRange = false

        if QBCore ~= nil then
            if isLoggedIn then
                PlayerData = QBCore.Functions.GetPlayerData()
                for case,_ in pairs(Config.Locations) do
                    -- if PlayerData.job.name ~= "police" then
                        local dist = #(pos - vector3(Config.Locations[case]["coords"]["x"], Config.Locations[case]["coords"]["y"], Config.Locations[case]["coords"]["z"]))
                        local storeDist = #(pos - vector3(Config.JewelleryLocation["coords"]["x"], Config.JewelleryLocation["coords"]["y"], Config.JewelleryLocation["coords"]["z"]))
                        if dist < 30 then
                            inRange = true

                            if dist < 0.6 then
                                if not Config.Locations[case]["isBusy"] and not Config.Locations[case]["isOpened"] then
                                    DrawText3Ds(Config.Locations[case]["coords"]["x"], Config.Locations[case]["coords"]["y"], Config.Locations[case]["coords"]["z"], '~r~[E]~w~ Break the display case')
                                    if IsControlJustPressed(0, 38) then
                                        QBCore.Functions.TriggerCallback('qb-jewellery:server:getCops', function(cops)
                                            if cops >= Config.RequiredCops then
                                                if validWeapon() then
                                                    smashVitrine(case)
                                                else
                                                    QBCore.Functions.Notify('This glass can only be broken with an ice pick..', 'error')
                                                end
                                            else
                                                QBCore.Functions.Notify('Not Enough Police ('.. Config.RequiredCops ..') Required', 'error')
                                            end                
                                        end)
                                    end
                                end
                            end

                            if storeDist < 2 then
                                if not firstAlarm then
                                    if validWeapon() then
                                        local data = {displayCode = '112', description = 'Suspicious Activity', isImportant = 0, recipientList = {'police'}, length = '10000', infoM = 'fa-info-circle', info = 'Vangelico Jewelry Store'}
                                        local dispatchData = {dispatchData = data, caller = 'Alarm', coords = vector3(-633.9, -241.7, 38.1)}
                                        TriggerServerEvent('wf-alerts:svNotify', dispatchData)
                                        firstAlarm = true
                                    end
                                end
                            end
                        end
                    -- end
                end
            end
        end

        if not inRange then
            Citizen.Wait(2000)
        end

        Citizen.Wait(3)
    end
end)

function loadParticle()
	if not HasNamedPtfxAssetLoaded("scr_jewelheist") then
    RequestNamedPtfxAsset("scr_jewelheist")
    end
    while not HasNamedPtfxAssetLoaded("scr_jewelheist") do
    Citizen.Wait(0)
    end
    SetPtfxAssetNextCall("scr_jewelheist")
end

function loadAnimDict(dict)  
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(3)
    end
end

function validWeapon()
    local ped = PlayerPedId()
    local pedWeapon = GetSelectedPedWeapon(ped)

    for k, v in pairs(Config.WhitelistedWeapons) do
        if pedWeapon == k then
            return true
        end
    end
    return false
end

local smashing = false

function smashVitrine(k)
    local animDict = "missheist_jewel"
    local animName = "smash_case"
    local ped = PlayerPedId()
    local plyCoords = GetOffsetFromEntityInWorldCoords(ped, 0, 0.6, 0)
    local pedWeapon = GetSelectedPedWeapon(ped)

    if math.random(1, 100) <= 80 and not IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
    elseif math.random(1, 100) <= 5 and IsWearingHandshoes() then
        TriggerServerEvent("evidence:server:CreateFingerDrop", plyCoords)
        QBCore.Functions.Notify("You've left a fingerprint on the glass", "error")
    end

    smashing = true

    QBCore.Functions.Progressbar("smash_vitrine", "Stealing", Config.WhitelistedWeapons[pedWeapon]["timeOut"], false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        TriggerServerEvent('qb-jewellery:server:setVitrineState', "isOpened", true, k)
        TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", false, k)
        TriggerServerEvent('qb-jewellery:server:vitrineReward')
        TriggerServerEvent('qb-jewellery:server:setTimeout')
        local data = {displayCode = '211A', description = 'Robbery', isImportant = 1, recipientList = {'police'}, length = '10000', infoM = 'fa-info-circle', info = 'Vangelico Jewelry Store'}
        local dispatchData = {dispatchData = data, caller = 'Alarm', coords = vector3(-633.9, -241.7, 38.1)}
        TriggerServerEvent('wf-alerts:svNotify', dispatchData)
        smashing = false
        TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
    end, function() -- Cancel
        TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", false, k)
        smashing = false
        TaskPlayAnim(ped, animDict, "exit", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
    end)
    TriggerServerEvent('qb-jewellery:server:setVitrineState', "isBusy", true, k)

    Citizen.CreateThread(function()
        while smashing do
            loadAnimDict(animDict)
            TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 2, 0, 0, 0, 0 )
            Citizen.Wait(500)
            TriggerServerEvent("InteractSound_SV:PlayOnSource", "breaking_vitrine_glass", 0.25)
            loadParticle()
            StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", plyCoords.x, plyCoords.y, plyCoords.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            Citizen.Wait(2500)
        end
    end)
end

RegisterNetEvent('qb-jewellery:client:setVitrineState')
AddEventHandler('qb-jewellery:client:setVitrineState', function(stateType, state, k)
    Config.Locations[k][stateType] = state
end)

RegisterNetEvent('qb-jewellery:client:setAlertState')
AddEventHandler('qb-jewellery:client:setAlertState', function(bool)
    robberyAlert = bool
end)

RegisterNetEvent('qb-jewellery:client:PoliceAlertMessage')
AddEventHandler('qb-jewellery:client:PoliceAlertMessage', function(title, coords, blip)
    if blip then
        TriggerEvent('qb-policealerts:client:AddPoliceAlert', {
            timeOut = 5000,
            alertTitle = title,
            details = {
                [1] = {
                    icon = '<i class="fas fa-gem"></i>',
                    detail = "Vangelico Jeweler",
                },
                [2] = {
                    icon = '<i class="fas fa-video"></i>',
                    detail = "31 | 32 | 33 | 34",
                },
                [3] = {
                    icon = '<i class="fas fa-globe-europe"></i>',
                    detail = "Rockford Dr",
                },
            },
            callSign = QBCore.Functions.GetPlayerData().metadata["callsign"],
        })
        PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
        Citizen.Wait(100)
        PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
        Citizen.Wait(100)
        PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
        local transG = 100
        local blip = AddBlipForRadius(coords.x, coords.y, coords.z, 100.0)
        SetBlipSprite(blip, 9)
        SetBlipColour(blip, 1)
        SetBlipAlpha(blip, transG)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString("911 - Suspicious Situation at Jewelry Store")
        EndTextCommandSetBlipName(blip)
        while transG ~= 0 do
            Wait(180 * 4)
            transG = transG - 1
            SetBlipAlpha(blip, transG)
            if transG == 0 then
                SetBlipSprite(blip, 2)
                RemoveBlip(blip)
                return
            end
        end
    else
        if not robberyAlert then
            PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
            TriggerEvent('qb-policealerts:client:AddPoliceAlert', {
                timeOut = 5000,
                alertTitle = title,
                details = {
                    [1] = {
                        icon = '<i class="fas fa-gem"></i>',
                        detail = "Vangelico Jewelry",
                    },
                    [2] = {
                        icon = '<i class="fas fa-video"></i>',
                        detail = "31 | 32 | 33 | 34",
                    },
                    [3] = {
                        icon = '<i class="fas fa-globe-europe"></i>',
                        detail = "Rockford Dr",
                    },
                },
                callSign = QBCore.Functions.GetPlayerData().metadata["callsign"],
            })
            robberyAlert = true
        end
    end
end)

function IsWearingHandshoes()
    local armIndex = GetPedDrawableVariation(PlayerPedId(), 3)
    local model = GetEntityModel(PlayerPedId())
    local retval = true
    if model == GetHashKey("mp_m_freemode_01") then
        if Config.MaleNoHandshoes[armIndex] ~= nil and Config.MaleNoHandshoes[armIndex] then
            retval = false
        end
    else
        if Config.FemaleNoHandshoes[armIndex] ~= nil and Config.FemaleNoHandshoes[armIndex] then
            retval = false
        end
    end
    return retval
end

Citizen.CreateThread(function()
    Dealer = AddBlipForCoord(Config.JewelleryLocation["coords"]["x"], Config.JewelleryLocation["coords"]["y"], Config.JewelleryLocation["coords"]["z"])

    SetBlipSprite (Dealer, 617)
    SetBlipDisplay(Dealer, 4)
    SetBlipScale  (Dealer, 0.7)
    SetBlipAsShortRange(Dealer, true)
    SetBlipColour(Dealer, 3)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Vangelico Jewelry")
    EndTextCommandSetBlipName(Dealer)
end)

RegisterNetEvent("qb-jewerly:ThermiteFront")
AddEventHandler("qb-jewerly:ThermiteFront", function()
    QBCore.Functions.TriggerCallback('qb-jewelery:server:IsDoorBusy', function(isBusy)
    	QBCore.Functions.TriggerCallback('qb-jewerly:server:get:checkitem', function(HasItems)  
    		if HasItems then
                if not isBusy then
                TriggerServerEvent('QBCore:Server:RemoveItem', "thermite", 1)
				QBCore.Functions.Progressbar("pickup_sla", "Placing Device", 1200, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					animDict = "anim@heists@ornate_bank@thermal_charge",
					anim = "thermal_charge",
					flags = 8,
				}, {}, {}, function() -- Done
                    exports["memorygame_2"]:thermiteminigame(7, 3, 3, 8,
                    function() -- Success
                        TriggerServerEvent('nui_doorlock:server:updateState', 9, false, false, false, true)
                        if math.random(1, 100) <= 35 then
                         TriggerServerEvent('qb-hud:server:GainStress', math.random(5, 8))
                        end
                         QBCore.Functions.Notify("Thermite Successful Door Opened", "success")
                         local ped = PlayerPedId()
                         local pos = GetEntityCoords(ped)
                         local s1, s2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
                         local street1 = GetStreetNameFromHashKey(s1)
                         local street2 = GetStreetNameFromHashKey(s2)
                         local streetLabel = street1
                         if street2 ~= nil then 
                             streetLabel = streetLabel .. " " .. street2
                         end
                         TriggerServerEvent("qb-Jewelry:server:callCops", "Chopshop", 0, streetLabel, pos)
                         -- Vangelico911Call()
                         firstAlarm = true
                         print("success")
                         copsCalled = true
                         TriggerServerEvent('qb-jewelery:server:SetThermite')
                         TriggerServerEvent('qb-jewellery:server:setTimeout')
                    end,
                    function() -- Failure
                        if math.random(1, 100) <= 75 then
                            TriggerServerEvent('qb-hud:server:GainStress', math.random(8, 15))
                        end
                        QBCore.Functions.Notify("You failed!")
                    end)
				end, function() --canccel
					QBCore.Functions.Notify("Cancelled..", "error")
				end)
            else
                QBCore.Functions.Notify("Fuse Already Burned", "error", 4500) 
            end
			else
   				QBCore.Functions.Notify("Missing Something", "error")
			end
		end)
    end)
end)

RegisterNetEvent("qb-jewerly:KeycardInside")
AddEventHandler("qb-jewerly:KeycardInside", function()
    QBCore.Functions.TriggerCallback('qb-jewelery:server:IsKeycardBusy', function(isBusy)
    	QBCore.Functions.TriggerCallback('qb-jewerly:server:get:checkitemkey', function(HasItems)
    		if HasItems then
                if not isBusy then
                TriggerServerEvent('QBCore:Server:RemoveItem', "security_card_01", 1)
				QBCore.Functions.Progressbar("pickup_sla", "Swiping", 1500, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					animDict = "mp_heists@keypad@",
					anim = "idle_a",
					flags = 49,
				}, {}, {}, function() -- Done
                    exports['varhack']:OpenHackingGame(function(success)
                        if success then
                            TriggerServerEvent('nui_doorlock:server:updateState', 10, false, false, false, true)
                            if math.random(1, 100) <= 35 then
                             TriggerServerEvent('qb-hud:server:GainStress', math.random(5, 8))
                            end
                             QBCore.Functions.Notify("Door Opened", "success")
                        local ped = PlayerPedId()
                        local pos = GetEntityCoords(ped)
                        local s1, s2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
                        local street1 = GetStreetNameFromHashKey(s1)
                        local street2 = GetStreetNameFromHashKey(s2)
                        local streetLabel = street1
                        if street2 ~= nil then 
                            streetLabel = streetLabel .. " " .. street2
                        end
                        TriggerServerEvent("qb-Jewelry:server:callCops", "Chopshop", 0, streetLabel, pos)
                        -- Vangelico911Call()
                        firstAlarm = true
                        print("success")
                        copsCalled = true
                        TriggerServerEvent('qb-jewelery:server:SetKeycard')
                        else
                            if math.random(1, 100) <= 75 then
                                TriggerServerEvent('qb-hud:server:GainStress', math.random(8, 15))
                            end
                            QBCore.Functions.Notify("You failed!")
                        end
                    end, 5, 5)
				end, function() --canccel
					QBCore.Functions.Notify("Cancelled..", "error")
				end)
            else
                QBCore.Functions.Notify("Security Lock Active", "error", 4500) 
            end
			else
   				QBCore.Functions.Notify("Missing Something", "error")
			end
		end)
    end)
end)

RegisterNetEvent("qb-jewerly:HackLaptop")
AddEventHandler("qb-jewerly:HackLaptop", function()
    QBCore.Functions.TriggerCallback('qb-jewelery:server:IsLaptopBusy', function(isBusy)
    	QBCore.Functions.TriggerCallback('qb-jewerly:server:get:checklaptop', function(HasItems)
    		if HasItems then
                if not isBusy then
                TriggerServerEvent('QBCore:Server:RemoveItem', "purpledongleempty", 1)
				QBCore.Functions.Progressbar("pickup_sla", "Inserting", 3000, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					animDict = "mp_common",
					anim = "givetake1_a",
					flags = 8,
                }, {}, {}, function() -- Done
                    exports["memorygame"]:thermiteminigame(12, 3, 5, 13,
                    function() -- Success
                        TriggerServerEvent('nui_doorlock:server:updateState', 9, false, false, false, true)
                        if math.random(1, 100) <= 35 then
                         TriggerServerEvent('qb-hud:server:GainStress', math.random(5, 8))
                        end
                         QBCore.Functions.Notify("Hack Successful Inserting USB", "success")
                         local ped = PlayerPedId()
                         local pos = GetEntityCoords(ped)
                         local s1, s2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
                         local street1 = GetStreetNameFromHashKey(s1)
                         local street2 = GetStreetNameFromHashKey(s2)
                         local streetLabel = street1
                         if street2 ~= nil then 
                             streetLabel = streetLabel .. " " .. street2
                         end
                         TriggerServerEvent("qb-Jewelry:server:callCops", "Chopshop", 0, streetLabel, pos)
                         -- Vangelico911Call()
                         firstAlarm = true
                         print("success")
                         copsCalled = true
                         TriggerServerEvent('qb-jewelery:server:SetLaptopHack')
                         Wait(5000)
                         QBCore.Functions.Notify("Vangelico Jewelery Data Collected", "success")
                         TriggerServerEvent('QBCore:Server:AddItem', "purpledongledata", 1)
                         TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["purpledongledata"], "add")
                    end,
                    function() -- Failure
                        if math.random(1, 100) <= 75 then
                            TriggerServerEvent('qb-hud:server:GainStress', math.random(8, 15))
                        end
                        QBCore.Functions.Notify("You failed!")
                    end)
				end, function() --canccel
					QBCore.Functions.Notify("Cancelled..", "error")
				end)
            else
                QBCore.Functions.Notify("Data Already Collected", "error", 4500) 
            end
			else
   				QBCore.Functions.Notify("Missing Something", "error")
			end
		end)
    end)
end)

    RegisterNetEvent('qb-Jewelry:client:callCops911')
    AddEventHandler('qb-Jewelry:client:callCops911', function(type, key, streetLabel, coords)
        if PlayerJob.name == "police" and onDuty then
            local bank = "Vehicle Robbery"
            if type == "Chopshop" then
                local pos = GetEntityCoords(PlayerPedId())
                local s1, s2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, pos.x, pos.y, pos.z, Citizen.PointerValueInt(),
                    Citizen.PointerValueInt())
                local street1 = GetStreetNameFromHashKey(s1)
                local street2 = GetStreetNameFromHashKey(s2)
                local streetLabel = street1
                if street2 ~= nil then
                    streetLabel = streetLabel .. " " .. street2
                end
                local data = {
                    displayCode = '10-31',
                    description = 'Robbery | CAM: 32, 33, 34, 35 ',
                    isImportant = 1,
                    recipientList = {'police'}, 
                    info = 'Vangelico Jewelry Store',
                    length = '15000',
                    infoM = 'fa-car',
                    -- info = PlayerJob.label
                }
            
                local dispatchData = {
                    dispatchData = data,
                    caller = 'Alarm', 
                    coords = pos,
                }
                TriggerServerEvent('wf-alerts:svNotify', dispatchData)
    
                local transG = 250
                local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                SetBlipSprite(blip, 674)
                SetBlipColour(blip, 3)
                SetBlipDisplay(blip, 4)
                SetBlipAlpha(blip, transG)
                SetBlipScale(blip, 1.0)
                SetBlipFlashes(blip, false)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString("911: Vehicle Robbery")
                EndTextCommandSetBlipName(blip)
                
                while transG ~= 0 do
                    Wait(180 * 4)
                    transG = transG - 1
                    SetBlipAlpha(blip, transG)
                    if transG == 0 then
                        SetBlipSprite(blip, 2)
                        RemoveBlip(blip)
                        return
                    end
                end
            end
        end
    end)

RegisterNetEvent("qb-jewerly:ATMRobbery")
AddEventHandler("qb-jewerly:ATMRobbery", function()
    QBCore.Functions.TriggerCallback('qb-jewelery:server:IsATMBusy', function(isBusy)
    	QBCore.Functions.TriggerCallback('qb-jewerly:server:get:checkatm', function(HasItems)
    		if HasItems then
                if not isBusy then
                TriggerServerEvent('QBCore:Server:RemoveItem', "thermite", 1)
				QBCore.Functions.Progressbar("pickup_sla", "Placing Device", 10000, false, true, {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				}, {
					animDict = "anim@heists@ornate_bank@thermal_charge",
					anim = "thermal_charge",
					flags = 49,
				}, {}, {}, function() -- Done
                    exports['varhack']:OpenHackingGame(function(success)
                        if success then
                            if math.random(1, 100) <= 35 then
                             TriggerServerEvent('qb-hud:server:GainStress', math.random(5, 8))
                            end
                             QBCore.Functions.Notify("Hack Successful", "success")
                        -- Vangelico911Call()
                        TriggerServerEvent('qb-jewelery:server:SetATMHack')
                        TriggerServerEvent('QBCore:Server:AddItem', "markedbills", Config.ATMRobberyReward)
                        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["markedbills"], "add")
                        local luck = math.random(1, 15)
                        local chance = math.random(1, 15)
                        if luck == chance then
                        TriggerServerEvent('QBCore:Server:AddItem', "usb_green", 1)
                        TriggerEvent("inventory:client:ItemBox", QBCore.Shared.Items["usb_green"], "add") 
                        end
                        else
                            if math.random(1, 100) <= 75 then
                                TriggerServerEvent('qb-hud:server:GainStress', math.random(8, 15))
                            end
                            QBCore.Functions.Notify("You failed!")
                        end
                    end, 5, 5)
				end, function() --canccel
					QBCore.Functions.Notify("Cancelled..", "error")
				end)
            else
                QBCore.Functions.Notify("Security Lock Active", "error", 4500) 
            end
			else
   				QBCore.Functions.Notify("Missing Something", "error")
			end
		end)
    end)
end)