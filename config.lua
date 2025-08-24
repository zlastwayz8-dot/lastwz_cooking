Config = {}

-- ========================================
-- CONFIGURACIÓN GENERAL DEL SISTEMA
-- ========================================

Config.Framework = 'qb-core' -- 'qb-core' o 'esx'
Config.Inventory = 'qb-inventory' -- 'qb-inventory', 'ox_inventory', 'esx_inventory'

Config.Debug = false -- Mensajes de debug en consola
Config.UseProgressBar = true -- Usar barra de progreso durante cocción
Config.ProgressBarTime = 2000 -- Tiempo en ms para la barra de progreso

Config.CookingStations = {
    vector3(-1196.43, -890.85, 13.9), -- Vespucci Beach
    vector3(1961.64, 5184.33, 47.98), -- Grapeseed
    vector3(2556.75, 4681.03, 34.08), -- Mount Chiliad
}

-- ========================================
-- CONFIGURACIÓN DEL MINIJUEGO
-- ========================================

Config.Minigame = {
    FireDecayRate = 0.2, -- Velocidad de pérdida de fuego por tick
    QualityBurnRate = 0.3, -- Pérdida de calidad cuando se quema
    QualityColdRate = 0.1, -- Pérdida de calidad cuando se enfría
    ProgressRate = 0.8, -- Velocidad de progreso de cocción
    MinQualityForSuccess = 30, -- Calidad mínima para obtener el item
    
    Controls = {
        fire = 20, -- Cantidad de fuego que se añade
        water = -10, -- Cantidad de fuego que se quita (+ calidad)
        stir = 10, -- Cantidad de calidad que se añade
        seasoning = 15, -- Cantidad de calidad que se añade
    }
}

-- ========================================
-- INGREDIENTES DISPONIBLES
-- ========================================

Config.Ingredients = {
    ['canned_meat'] = {
        name = 'Carne Enlatada',
        icon = 'fas fa-can-food',
        item = 'canned_meat', -- Nombre del item en el inventario
    },
    ['vegetables'] = {
        name = 'Verduras',
        icon = 'fas fa-carrot',
        item = 'vegetables',
    },
    ['water_bottle'] = {
        name = 'Agua',
        icon = 'fas fa-droplet',
        item = 'water_bottle',
    },
    ['beans'] = {
        name = 'Frijoles',
        icon = 'fas fa-seedling',
        item = 'beans',
    },
    ['spices'] = {
        name = 'Especias',
        icon = 'fas fa-pepper-hot',
        item = 'spices',
    },
    ['cooking_oil'] = {
        name = 'Aceite',
        icon = 'fas fa-oil-can',
        item = 'cooking_oil',
    },
    ['pasta'] = {
        name = 'Pasta',
        icon = 'fas fa-wheat-awn',
        item = 'pasta',
    }
}

-- ========================================
-- RECETAS DE COCINA
-- ========================================

Config.Recipes = {
    -- Receta básica - Sopa de Carne
    {
        id = 1,
        name = 'Sopa de Carne',
        icon = 'fas fa-bowl-food',
        level = 'Lv. 1',
        description = 'Sopa básica con carne enlatada y verduras. Perfecta para sobrevivir.',
        cookingTime = 45, -- Tiempo en segundos (usado para referencia, el minijuego controla el tiempo real)
        difficulty = 'easy', -- 'easy', 'medium', 'hard'
        
        ingredients = {
            { ingredient = 'canned_meat', required = 1 },
            { ingredient = 'vegetables', required = 1 },
            { ingredient = 'water_bottle', required = 1 }
        },
        
        results = {
            success = {
                item = 'meat_soup',
                amount = 1,
                metadata = {
                    hunger = 60,
                    thirst = 20,
                    description = 'Una deliciosa sopa de carne casera'
                }
            },
            failure = {
                item = 'burnt_food',
                amount = 1,
                metadata = {
                    hunger = 5,
                    description = 'Comida quemada, barely edible'
                }
            }
        }
    },
    
    -- Receta intermedia - Guiso de Frijoles
    {
        id = 2,
        name = 'Guiso de Frijoles',
        icon = 'fas fa-seedling',
        level = 'Lv. 2',
        description = 'Nutritivo guiso que te dará energía para explorar.',
        cookingTime = 60,
        difficulty = 'medium',
        
        ingredients = {
            { ingredient = 'beans', required = 2 },
            { ingredient = 'spices', required = 1 },
            { ingredient = 'cooking_oil', required = 1 }
        },
        
        results = {
            success = {
                item = 'bean_stew',
                amount = 1,
                metadata = {
                    hunger = 80,
                    thirst = 10,
                    health = 15,
                    description = 'Un nutritivo guiso de frijoles'
                }
            },
            failure = {
                item = 'burnt_food',
                amount = 1,
                metadata = {
                    hunger = 5,
                    description = 'Comida quemada, barely edible'
                }
            }
        }
    },
    
    -- Receta rápida - Pasta Simple
    {
        id = 3,
        name = 'Pasta Simple',
        icon = 'fas fa-wheat-awn',
        level = 'Lv. 1',
        description = 'Comida rápida cuando tienes prisa y zombies cerca.',
        cookingTime = 30,
        difficulty = 'easy',
        
        ingredients = {
            { ingredient = 'pasta', required = 1 },
            { ingredient = 'cooking_oil', required = 1 },
            { ingredient = 'water_bottle', required = 2 }
        },
        
        results = {
            success = {
                item = 'cooked_pasta',
                amount = 1,
                metadata = {
                    hunger = 50,
                    thirst = 5,
                    description = 'Pasta simple pero sabrosa'
                }
            },
            failure = {
                item = 'burnt_food',
                amount = 1,
                metadata = {
                    hunger = 5,
                    description = 'Comida quemada, barely edible'
                }
            }
        }
    }
}

-- ========================================
-- CONFIGURACIÓN DE ITEMS DE RESULTADO
-- ========================================

Config.ResultItems = {
    ['meat_soup'] = {
        name = 'Sopa de Carne',
        description = 'Una deliciosa sopa de carne casera',
        weight = 0.8,
        stackable = true,
        close = true,
    },
    ['bean_stew'] = {
        name = 'Guiso de Frijoles',
        description = 'Un nutritivo guiso de frijoles',
        weight = 0.9,
        stackable = true,
        close = true,
    },
    ['cooked_pasta'] = {
        name = 'Pasta Cocida',
        description = 'Pasta simple pero sabrosa',
        weight = 0.6,
        stackable = true,
        close = true,
    },
    ['burnt_food'] = {
        name = 'Comida Quemada',
        description = 'Comida arruinada, barely comestible',
        weight = 0.3,
        stackable = true,
        close = true,
    }
}

-- ========================================
-- MENSAJES Y NOTIFICACIONES
-- ========================================

Config.Messages = {
    ['no_ingredients'] = 'No tienes suficientes ingredientes para esta receta',
    ['cooking_started'] = 'Has comenzado a cocinar %s',
    ['cooking_success'] = '¡Has cocinado %s con éxito! (Calidad: %d%%)',
    ['cooking_failed'] = 'Has arruinado la comida... (Calidad: %d%%)',
    ['station_in_use'] = 'Esta estación de cocina está siendo utilizada',
    ['too_far'] = 'Estás demasiado lejos de la estación de cocina',
    ['inventory_full'] = 'Tu inventario está lleno',
}

-- ========================================
-- FUNCIONES DE UTILIDAD
-- ========================================

-- Obtener receta por ID
function Config.GetRecipe(id)
    for i = 1, #Config.Recipes do
        if Config.Recipes[i].id == id then
            return Config.Recipes[i]
        end
    end
    return nil
end

-- Obtener ingrediente por nombre
function Config.GetIngredient(name)
    return Config.Ingredients[name]
end

-- Verificar si el jugador puede cocinar una receta
function Config.CanCookRecipe(playerId, recipeId)
    local recipe = Config.GetRecipe(recipeId)
    if not recipe then return false end
    
    -- Aquí iría la lógica de verificación de inventario
    -- Esta función se implementaría en el server.lua
    return true
end
