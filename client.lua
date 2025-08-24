local QBCore = exports['qb-core']:GetCoreObject()

-- Variables locales
local isNuiOpen = false
local currentRecipes = {}
local currentStation = nil
local stationsInUse = {}

-- ========================================
-- FUNCIONES DE UTILIDAD
-- ========================================

-- Debug print
local function DebugPrint(msg)
    if Config.Debug then
        print('^3[COOKING]^7 ' .. msg)
    end
end

-- Notificación
local function Notify(msg, type)
    QBCore.Functions.Notify(msg, type or 'primary', 5000)
end

-- Verificar distancia a estación más cercana
local function GetNearestStation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestStation = nil
    local closestDistance = math.huge
    
    for i, stationCoords in ipairs(Config.CookingStations) do
        local distance = #(playerCoords - stationCoords)
        if distance < closestDistance then
            closestDistance = distance
            closestStation = i
        end
    end
    
    if closestDistance <= 3.0 then
        return closestStation, closestDistance
    end
    
    return nil, closestDistance
end

-- ========================================
-- PREPARAR DATOS DE RECETAS
-- ========================================

-- ✅ Función corregida para preparar datos de recetas
function PrepareRecipesData(inventory)
    local recipesData = {}
    
    DebugPrint('Preparando recetas con inventario: ' .. json.encode(inventory))
    
    for _, recipe in ipairs(Config.Recipes) do
        local recipeData = {
            id = recipe.id,
            name = recipe.name,
            icon = recipe.icon,
            level = recipe.level,
            description = recipe.description,
            cookingTime = recipe.cookingTime,
            result = {
                name = Config.ResultItems[recipe.results.success.item].name,
                icon = recipe.icon
            },
            ingredients = {}
        }
        
        -- Verificar ingredientes disponibles
        for _, ingredient in ipairs(recipe.ingredients) do
            local ingredientConfig = Config.GetIngredient(ingredient.ingredient)
            local available = 0
            
            -- Contar items en inventario
            if inventory then
                for _, item in pairs(inventory) do
                    if item.name == ingredientConfig.item then
                        available = available + item.amount
                    end
                end
            end
            
            table.insert(recipeData.ingredients, {
                name = ingredientConfig.name,
                icon = ingredientConfig.icon,
                required = ingredient.required,
                available = available
            })
        end
        
        table.insert(recipesData, recipeData)
    end
    
    DebugPrint('Recetas preparadas: ' .. #recipesData)
    return recipesData
end

-- ========================================
-- MANEJO DE NUI
-- ========================================

-- ✅ Función corregida para abrir interfaz de cocina
local function OpenCookingUI()
    -- Verificar que no esté ya abierta
    if isNuiOpen then
        DebugPrint('UI ya está abierta')
        return
    end
    
    local nearestStation, distance = GetNearestStation()
    
    if not nearestStation then
        Notify(Config.Messages['too_far'], 'error')
        return
    end
    
    if stationsInUse[nearestStation] then
        Notify(Config.Messages['station_in_use'], 'error')
        return
    end
    
    -- Verificar que el jugador no esté en vehículo
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        Notify('No puedes cocinar dentro de un vehículo', 'error')
        return
    end
    
    DebugPrint('Abriendo interfaz de cocina...')
    
    -- ✅ Obtener inventario y preparar recetas
    QBCore.Functions.TriggerCallback('survival-cooking:getPlayerInventory', function(inventory)
        DebugPrint('Inventario recibido: ' .. json.encode(inventory))
        
        local recipesData = PrepareRecipesData(inventory)
        
        DebugPrint('Enviando datos al NUI: ' .. json.encode({
            type = 'openCooking',
            recipes = recipesData
        }))
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'openCooking',
            recipes = recipesData
        })
        
        isNuiOpen = true
        currentStation = nearestStation
        stationsInUse[nearestStation] = true
        
        DebugPrint('Interfaz de cocina abierta en estación: ' .. nearestStation)
    end)
end

-- Cerrar interfaz de cocina
local function CloseCookingUI()
    if not isNuiOpen then
        return
    end
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeCooking'
    })
    
    isNuiOpen = false
    
    if currentStation then
        stationsInUse[currentStation] = false
        TriggerServerEvent('survival-cooking:updateStationStatus', currentStation, false)
        currentStation = nil
    end
    
    DebugPrint('Interfaz de cocina cerrada')
end

-- ========================================
-- EVENTOS NUI
-- ========================================

-- Manejar mensajes de NUI
RegisterNUICallback('closeUI', function(data, cb)
    DebugPrint('NUI: Cerrando UI')
    CloseCookingUI()
    cb('ok')
end)

RegisterNUICallback('cookingComplete', function(data, cb)
    DebugPrint('NUI: Cocción completada: ' .. json.encode(data))
    
    if data.success then
        Notify(string.format(Config.Messages['cooking_success'], data.result, data.quality), 'success')
    else
        Notify(string.format(Config.Messages['cooking_failed'], data.quality), 'error')
    end
    
    -- Enviar resultado al servidor
    TriggerServerEvent('survival-cooking:completeCooking', {
        success = data.success,
        recipe = data.recipe,
        result = data.result,
        quality = data.quality
    })
    
    cb('ok')
end)

RegisterNUICallback('startCooking', function(data, cb)
    DebugPrint('NUI: Iniciando cocción: ' .. json.encode(data))
    
    -- Verificar ingredientes en servidor antes de permitir cocinar
    QBCore.Functions.TriggerCallback('survival-cooking:canCookRecipe', function(canCook, message)
        if canCook then
            -- Consumir ingredientes
            TriggerServerEvent('survival-cooking:consumeIngredients', data.recipeId)
            
            if Config.UseProgressBar then
                QBCore.Functions.Progressbar('cooking_prep', 'Preparando ingredientes...', Config.ProgressBarTime, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function() -- Done
                    -- Ingredientes preparados, continuar con minijuego
                    SendNUIMessage({
                        type = 'ingredientsReady'
                    })
                end, function() -- Cancel
                    Notify('Preparación cancelada', 'error')
                    CloseCookingUI()
                end)
            else
                -- Si no hay barra de progreso, continuar directamente
                SendNUIMessage({
                    type = 'ingredientsReady'
                })
            end
        else
            Notify(message or Config.Messages['no_ingredients'], 'error')
        end
    end, data.recipeId)
    
    cb('ok')
end)

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

-- Actualizar estaciones en uso
RegisterNetEvent('survival-cooking:updateStationStatus', function(stationId, inUse)
    stationsInUse[stationId] = inUse
    DebugPrint('Estación ' .. stationId .. ' estado: ' .. tostring(inUse))
end)

-- Actualizar inventario en interfaz
RegisterNetEvent('survival-cooking:updateInventory', function()
    if isNuiOpen then
        QBCore.Functions.TriggerCallback('survival-cooking:getPlayerInventory', function(inventory)
            local recipesData = PrepareRecipesData(inventory)
            currentRecipes = recipesData
            SendNUIMessage({
                type = 'updateRecipes',
                recipes = recipesData
            })
        end)
    end
end)

-- ========================================
-- COMANDOS Y CONTROLES
-- ========================================

-- Comando para abrir cocina (para testing)
RegisterCommand('cocina', function()
    DebugPrint('Comando /cocina ejecutado')
    OpenCookingUI()
end)

-- ✅ Control mejorado con tecla E cerca de estaciones
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Solo verificar si no está ya cocinando
        if not isNuiOpen then
            for i, stationCoords in ipairs(Config.CookingStations) do
                local distance = #(playerCoords - stationCoords)
                
                if distance <= 3.0 then
                    sleep = 0
                    
                    -- Texto diferente según disponibilidad
                    local helpText = '[E] Cocinar'
                    if stationsInUse[i] then
                        helpText = 'Estación ocupada'
                    elseif IsPedInAnyVehicle(playerPed, false) then
                        helpText = 'Sal del vehículo'
                    end
                    
                    DrawText3D(stationCoords.x, stationCoords.y, stationCoords.z + 1.0, helpText)
                    
                    if distance <= 1.5 and not stationsInUse[i] and not IsPedInAnyVehicle(playerPed, false) then
                        if IsControlJustPressed(0, 38) then -- E key
                            DebugPrint('Tecla E presionada cerca de estación ' .. i)
                            OpenCookingUI()
                        end
                    end
                    
                    break
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Función para dibujar texto 3D
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- ========================================
-- MARKERS Y BLIPS
-- ========================================

-- Crear blips para estaciones de cocina
CreateThread(function()
    for i, coords in ipairs(Config.CookingStations) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        
        SetBlipSprite(blip, 568) -- Icono de comida
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2) -- Verde
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName("Estación de Cocina")
        EndTextCommandSetBlipName(blip)
    end
    
    DebugPrint('Blips de estaciones creados: ' .. #Config.CookingStations)
end)

-- Dibujar markers para estaciones
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for i, stationCoords in ipairs(Config.CookingStations) do
            local distance = #(playerCoords - stationCoords)
            
            if distance <= 50.0 then
                sleep = 0
                
                local color = stationsInUse[i] and {255, 0, 0, 100} or {0, 255, 0, 100} -- Rojo si en uso, verde si libre
                
                DrawMarker(
                    1, -- Tipo de marker
                    stationCoords.x, stationCoords.y, stationCoords.z - 1.0,
                    0.0, 0.0, 0.0, -- Dir
                    0.0, 0.0, 0.0, -- Rot
                    2.0, 2.0, 1.0, -- Scale
                    color[1], color[2], color[3], color[4], -- RGBA
                    false, -- Bob
                    true, -- Face camera
                    2, -- Rotate
                    false, -- Texture
                    false, false -- Draw on ents
                )
            end
        end
        
        Wait(sleep)
    end
end)

-- ========================================
-- CLEANUP
-- ========================================

-- Cerrar NUI al desconectar
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isNuiOpen then
            CloseCookingUI()
        end
    end
end)

-- Cerrar NUI con ESC
RegisterCommand('+cookingEsc', function()
    if isNuiOpen then
        DebugPrint('ESC presionado - cerrando UI')
        CloseCookingUI()
    end
end)

RegisterKeyMapping('+cookingEsc', 'Cerrar interfaz de cocina', 'keyboard', 'ESCAPE')

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    Wait(1000)
    DebugPrint('Cliente de cocina inicializado')
    DebugPrint('Estaciones configuradas: ' .. #Config.CookingStations)
    
    -- Mostrar coordenadas de estaciones para debugging
    for i, coords in ipairs(Config.CookingStations) do
        DebugPrint(string.format('Estación %d: %s', i, coords))
    end
end)