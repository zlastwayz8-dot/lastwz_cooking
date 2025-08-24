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

-- ✅ Función simplificada sin Config.ResultItems
function PrepareRecipesData(inventory)
    local recipesData = {}
    
    DebugPrint('Preparando recetas con inventario: ' .. json.encode(inventory))
    
    for _, recipe in ipairs(Config.Recipes) do
        local recipeData = {
            id = recipe.id,
            name = recipe.name,
            image = recipe.image,
            level = recipe.level,
            description = recipe.description,
            cookingTime = recipe.cookingTime,
            result = {
                name = recipe.name, -- ✅ Usar el nombre de la receta como nombre del resultado
                image = recipe.results.success.item -- ✅ Usar el nombre del item para la imagen
            },
            ingredients = {}
        }
        
        -- Verificar ingredientes disponibles
        for _, ingredient in ipairs(recipe.ingredients) do
            local ingredientConfig = Config.GetIngredient(ingredient.ingredient)
            
            -- ✅ VALIDACIÓN: Verificar que el ingrediente existe
            if not ingredientConfig then
                DebugPrint('❌ ERROR: Ingrediente no encontrado: ' .. tostring(ingredient.ingredient))
                DebugPrint('📋 Ingredientes disponibles en config:')
                for name, _ in pairs(Config.Ingredients) do
                    DebugPrint('   - ' .. name)
                end
                
                -- Crear ingrediente de fallback para evitar crash
                ingredientConfig = {
                    name = 'INGREDIENTE NO ENCONTRADO: ' .. ingredient.ingredient,
                    item = ingredient.ingredient
                }
            end
            
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
                image = ingredientConfig.item, -- ✅ Usar nombre del item para la imagen
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

-- Función para abrir interfaz de cocina
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
    
    -- Obtener inventario y preparar recetas
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

-- ✅ Cerrar interfaz de cocina - CORREGIDO
local function CloseCookingUI()
    if not isNuiOpen then
        return
    end
    
    DebugPrint('Cerrando interfaz de cocina...')
    
    -- ✅ IMPORTANTE: Asegurar que el focus se desactive ANTES de enviar mensaje
    SetNuiFocus(false, false)
    
    -- Pequeño delay para asegurar que el focus se desactive
    Wait(100)
    
    SendNUIMessage({
        type = 'closeCooking'
    })
    
    isNuiOpen = false
    
    if currentStation then
        stationsInUse[currentStation] = false
        TriggerServerEvent('survival-cooking:updateStationStatus', currentStation, false)
        currentStation = nil
    end
    
    DebugPrint('Interfaz de cocina cerrada correctamente')
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

-- Control con tecla E cerca de estaciones
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
        
        SetBlipSprite(blip, 568)
        SetBlipScale(blip, 0.7)
        SetBlipColour(blip, 2)
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
                
                local color = stationsInUse[i] and {255, 0, 0, 100} or {0, 255, 0, 100}
                
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

-- Cerrar NUI al desconectar - MEJORADO
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isNuiOpen then
            DebugPrint('Recurso deteniéndose - cerrando NUI')
            SetNuiFocus(false, false) -- ✅ Asegurar que se desactive el focus
            isNuiOpen = false
        end
    end
end)

-- Cerrar NUI con ESC - MEJORADO
RegisterCommand('+cookingEsc', function()
    if isNuiOpen then
        DebugPrint('ESC presionado - cerrando UI')
        CloseCookingUI()
    end
end)

RegisterKeyMapping('+cookingEsc', 'Cerrar interfaz de cocina', 'keyboard', 'ESCAPE')

-- ✅ NUEVO: Manejo de errores y cleanup adicional
CreateThread(function()
    while true do
        Wait(5000) -- Check cada 5 segundos
        
        -- Verificar si el NUI está abierto pero el jugador está lejos de estaciones
        if isNuiOpen then
            local nearStation = GetNearestStation()
            if not nearStation then
                DebugPrint('Jugador muy lejos de estación - cerrando UI automáticamente')
                CloseCookingUI()
            end
        end
    end
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    Wait(1000)
    DebugPrint('Cliente de cocina inicializado')
    DebugPrint('Estaciones configuradas: ' .. #Config.CookingStations)
    
    -- ✅ Validar configuración al inicio
    if Config.ValidateConfig then
        Config.ValidateConfig()
    end
    
    -- Mostrar coordenadas de estaciones para debugging
    for i, coords in ipairs(Config.CookingStations) do
        DebugPrint(string.format('Estación %d: %s', i, coords))
    end
end)