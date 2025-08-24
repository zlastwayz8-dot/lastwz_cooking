local QBCore = exports['qb-core']:GetCoreObject()

-- Variables del servidor
local stationsInUse = {}
local playerCookingData = {} -- Para tracking de jugadores cocinando

-- ========================================
-- FUNCIONES DE UTILIDAD
-- ========================================

-- Debug print
local function DebugPrint(msg)
    if Config.Debug then
        print('^3[COOKING-SERVER]^7 ' .. msg)
    end
end

-- ✅ Obtener inventario del jugador - CORREGIDO
local function GetPlayerInventory(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local inventory = {}
    
    -- ✅ Usar export GetPlayerItems de tgiann-inventory
    local playerItems = exports['tgiann-inventory']:GetPlayerItems(source)
    
    if playerItems then
        for slot, item in pairs(playerItems) do
            if item and item.amount and item.amount > 0 then
                table.insert(inventory, {
                    name = item.name,
                    amount = item.amount,
                    slot = slot
                })
            end
        end
    end
    
    return inventory
end

-- ✅ Verificar si el jugador tiene suficientes ingredientes - CORREGIDO
local function HasEnoughIngredients(source, recipeId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local recipe = Config.GetRecipe(recipeId)
    if not recipe then return false end
    
    for _, ingredient in ipairs(recipe.ingredients) do
        local ingredientConfig = Config.GetIngredient(ingredient.ingredient)
        if not ingredientConfig then return false end
        
        -- ✅ Usar export HasItem de tgiann-inventory
        local hasEnough = exports['tgiann-inventory']:HasItem(source, ingredientConfig.item, ingredient.required)
        if not hasEnough then
            return false
        end
    end
    
    return true
end

-- ✅ Consumir ingredientes del inventario - CORREGIDO
local function ConsumeIngredients(source, recipeId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local recipe = Config.GetRecipe(recipeId)
    if not recipe then return false end
    
    -- Verificar primero que tenga todos los ingredientes
    if not HasEnoughIngredients(source, recipeId) then
        return false
    end
    
    -- ✅ Consumir ingredientes usando export RemoveItem de tgiann-inventory
    for _, ingredient in ipairs(recipe.ingredients) do
        local ingredientConfig = Config.GetIngredient(ingredient.ingredient)
        if ingredientConfig then
            local success = exports['tgiann-inventory']:RemoveItem(source, ingredientConfig.item, ingredient.required)
            if not success then
                DebugPrint('Error al consumir ingrediente: ' .. ingredientConfig.item)
                return false
            end
        end
    end
    
    return true
end

-- ✅ Dar item al jugador - CORREGIDO
local function GiveItemToPlayer(source, itemName, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- ✅ Usar export AddItem de tgiann-inventory
    local success = exports['tgiann-inventory']:AddItem(source, itemName, amount)
    
    if success then
        DebugPrint('Item añadido: ' .. itemName .. ' x' .. amount .. ' a jugador ' .. source)
        return true
    else
        DebugPrint('Error al añadir item: ' .. itemName .. ' - posiblemente inventario lleno')
        return false
    end
end

-- Verificar distancia del jugador a las estaciones
local function IsPlayerNearStation(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    
    for i, stationCoords in ipairs(Config.CookingStations) do
        local distance = #(playerCoords - vector3(stationCoords.x, stationCoords.y, stationCoords.z))
        if distance <= 5.0 then -- Un poco más de distancia permitida en el servidor
            return i
        end
    end
    
    return false
end

-- ========================================
-- CALLBACKS DE QBCORE
-- ========================================

-- ✅ Obtener inventario del jugador - CORREGIDO
QBCore.Functions.CreateCallback('survival-cooking:getPlayerInventory', function(source, cb)
    local inventory = GetPlayerInventory(source)
    DebugPrint('Inventario obtenido para jugador ' .. source .. ': ' .. #inventory .. ' items')
    cb(inventory)
end)

-- ✅ Verificar si puede cocinar una receta - CORREGIDO
QBCore.Functions.CreateCallback('survival-cooking:canCookRecipe', function(source, cb, recipeId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        cb(false, 'Jugador no encontrado')
        return
    end
    
    -- Verificar que esté cerca de una estación
    local nearStation = IsPlayerNearStation(source)
    if not nearStation then
        cb(false, Config.Messages['too_far'])
        return
    end
    
    -- Verificar que la estación no esté en uso
    if stationsInUse[nearStation] and stationsInUse[nearStation] ~= source then
        cb(false, Config.Messages['station_in_use'])
        return
    end
    
    -- Verificar ingredientes
    if not HasEnoughIngredients(source, recipeId) then
        cb(false, Config.Messages['no_ingredients'])
        return
    end
    
    cb(true, 'OK')
end)

-- ========================================
-- EVENTOS DE RED
-- ========================================

-- ✅ Consumir ingredientes para cocinar - CORREGIDO
RegisterNetEvent('survival-cooking:consumeIngredients', function(recipeId)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    -- Verificar que esté cerca de una estación
    local nearStation = IsPlayerNearStation(source)
    if not nearStation then
        TriggerClientEvent('QBCore:Notify', source, Config.Messages['too_far'], 'error')
        return
    end
    
    -- Marcar estación como en uso
    stationsInUse[nearStation] = source
    TriggerClientEvent('survival-cooking:updateStationStatus', -1, nearStation, true)
    
    -- Consumir ingredientes
    if ConsumeIngredients(source, recipeId) then
        local recipe = Config.GetRecipe(recipeId)
        TriggerClientEvent('QBCore:Notify', source, string.format(Config.Messages['cooking_started'], recipe.name), 'primary')
        
        -- Guardar datos de cocción del jugador
        playerCookingData[source] = {
            recipeId = recipeId,
            stationId = nearStation,
            startTime = os.time()
        }
        
        DebugPrint('Jugador ' .. source .. ' comenzó a cocinar receta ' .. recipeId .. ' en estación ' .. nearStation)
        
        -- Actualizar inventario en cliente
        TriggerClientEvent('survival-cooking:updateInventory', source)
    else
        -- Liberar estación si falló
        stationsInUse[nearStation] = nil
        TriggerClientEvent('survival-cooking:updateStationStatus', -1, nearStation, false)
        TriggerClientEvent('QBCore:Notify', source, Config.Messages['no_ingredients'], 'error')
    end
end)

-- ✅ Completar proceso de cocción - CORREGIDO
RegisterNetEvent('survival-cooking:completeCooking', function(cookingData)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    local playerData = playerCookingData[source]
    if not playerData then
        DebugPrint('No se encontraron datos de cocción para jugador ' .. source)
        return
    end
    
    local recipe = Config.GetRecipe(playerData.recipeId)
    if not recipe then
        DebugPrint('Receta no encontrada: ' .. playerData.recipeId)
        return
    end
    
    -- Liberar estación
    if playerData.stationId then
        stationsInUse[playerData.stationId] = nil
        TriggerClientEvent('survival-cooking:updateStationStatus', -1, playerData.stationId, false)
    end
    
    -- Determinar item a dar basado en el éxito
    local resultItem, resultAmount
    if cookingData.success then
        resultItem = recipe.results.success.item
        resultAmount = recipe.results.success.amount
        DebugPrint('Cocción exitosa - Item: ' .. resultItem .. ' x' .. resultAmount)
    else
        resultItem = recipe.results.failure.item
        resultAmount = recipe.results.failure.amount
        DebugPrint('Cocción fallida - Item: ' .. resultItem .. ' x' .. resultAmount)
    end
    
    -- Dar item al jugador
    if GiveItemToPlayer(source, resultItem, resultAmount) then
        DebugPrint('Item entregado a jugador ' .. source .. ': ' .. resultItem .. ' x' .. resultAmount)
    else
        -- Si el inventario está lleno, notificar al jugador
        TriggerClientEvent('QBCore:Notify', source, Config.Messages['inventory_full'], 'error')
        DebugPrint('Error: Inventario lleno para jugador ' .. source)
    end
    
    -- Limpiar datos de cocción
    playerCookingData[source] = nil
    
    -- Actualizar inventario en cliente
    TriggerClientEvent('survival-cooking:updateInventory', source)
end)

-- ========================================
-- EVENTOS DE JUGADOR
-- ========================================

-- Limpiar datos cuando el jugador se desconecta
RegisterNetEvent('QBCore:Server:PlayerDropped', function()
    local source = source
    
    -- Limpiar datos de cocción
    if playerCookingData[source] then
        local playerData = playerCookingData[source]
        
        -- Liberar estación si estaba en uso
        if playerData.stationId and stationsInUse[playerData.stationId] == source then
            stationsInUse[playerData.stationId] = nil
            TriggerClientEvent('survival-cooking:updateStationStatus', -1, playerData.stationId, false)
            DebugPrint('Estación ' .. playerData.stationId .. ' liberada por desconexión de jugador ' .. source)
        end
        
        playerCookingData[source] = nil
    end
end)

-- ========================================
-- COMANDOS DE ADMINISTRADOR
-- ========================================

-- ✅ Comando para dar ingredientes (para testing) - CORREGIDO
RegisterCommand('darIngredientes', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    -- Verificar permisos de admin
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'No tienes permisos', 'error')
        return
    end
    
    -- ✅ Dar ingredientes básicos usando tgiann-inventory exports correctos
    local ingredientsToGive = {
        'canned_meat',
        'vegetables', 
        'water_bottle',
        'beans',
        'spices',
        'cooking_oil',
        'pasta'
    }
    
    for _, item in ipairs(ingredientsToGive) do
        local success = exports['tgiann-inventory']:AddItem(source, item, 5)
        if success then
            DebugPrint('Añadido: ' .. item .. ' x5 a jugador ' .. source)
        else
            DebugPrint('Error añadiendo: ' .. item .. ' a jugador ' .. source)
        end
    end
    
    TriggerClientEvent('QBCore:Notify', source, 'Ingredientes añadidos al inventario', 'success')
end, false)

-- Comando para resetear estaciones
RegisterCommand('resetEstaciones', function(source, args)
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'No tienes permisos', 'error')
        return
    end
    
    stationsInUse = {}
    playerCookingData = {}
    
    for i = 1, #Config.CookingStations do
        TriggerClientEvent('survival-cooking:updateStationStatus', -1, i, false)
    end
    
    TriggerClientEvent('QBCore:Notify', source, 'Estaciones de cocina reseteadas', 'success')
    DebugPrint('Estaciones reseteadas por admin')
end, false)

-- ✅ Comando adicional para verificar inventario (debugging)
RegisterCommand('verificarInventario', function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('QBCore:Notify', source, 'No tienes permisos', 'error')
        return
    end
    
    local inventory = GetPlayerInventory(source)
    DebugPrint('=== INVENTARIO DEL JUGADOR ' .. source .. ' ===')
    for i, item in ipairs(inventory) do
        DebugPrint(string.format('Slot %s: %s x%d', item.slot, item.name, item.amount))
    end
    DebugPrint('=== FIN INVENTARIO ===')
    
    TriggerClientEvent('QBCore:Notify', source, 'Inventario mostrado en consola del servidor', 'primary')
end, false)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

-- Mensaje de inicio
CreateThread(function()
    Wait(1000)
    print('^2[SURVIVAL-COOKING]^7 Sistema de cocina cargado correctamente')
    print('^2[SURVIVAL-COOKING]^7 Framework: ' .. Config.Framework)
    print('^2[SURVIVAL-COOKING]^7 Inventario: ' .. Config.Inventory)
    print('^2[SURVIVAL-COOKING]^7 Estaciones configuradas: ' .. #Config.CookingStations)
    print('^2[SURVIVAL-COOKING]^7 Recetas disponibles: ' .. #Config.Recipes)
    
    -- ✅ Verificar que tgiann-inventory esté disponible
    local tgiannStatus = GetResourceState('tgiann-inventory')
    if tgiannStatus == 'started' then
        print('^2[SURVIVAL-COOKING]^7 tgiann-inventory detectado y funcionando')
    else
        print('^1[SURVIVAL-COOKING]^7 ERROR: tgiann-inventory no está iniciado!')
    end
end)

-- ========================================
-- SISTEMA DE LOGS (OPCIONAL)
-- ========================================

-- Función para logging de acciones importantes
local function LogCookingAction(source, action, data)
    if not Config.Debug then return end
    
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local logMessage = string.format('[COOKING-LOG] %s (%s) - %s: %s', 
        Player.PlayerData.name, 
        Player.PlayerData.citizenid, 
        action, 
        json.encode(data)
    )
    
    print(logMessage)
    
    -- ✅ Descomentar si tienes qb-logs
    -- TriggerEvent('qb-logs:server:CreateLog', 'cooking', action, 'blue', logMessage)
end