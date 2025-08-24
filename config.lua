Config = {}

-- ========================================
-- CONFIGURACIÓN GENERAL DEL SISTEMA
-- ========================================

Config.Framework = 'qb-core'
Config.Inventory = 'tgiann-inventory'

Config.Debug = true
Config.UseProgressBar = true
Config.ProgressBarTime = 2000

Config.CookingStations = {
    vector3(1697.22, 2612.12, 45.56), -- Vespucci Beach
}

-- ========================================
-- CONFIGURACIÓN DEL MINIJUEGO
-- ========================================

Config.Minigame = {
    FireDecayRate = 0.2,
    QualityBurnRate = 0.3,
    QualityColdRate = 0.1,
    ProgressRate = 0.8,
    MinQualityForSuccess = 30,
    
    Controls = {
        fire = 20,
        water = -10,
        stir = 10,
        seasoning = 15,
    }
}

-- ========================================
-- INGREDIENTES DISPONIBLES
-- ========================================

Config.Ingredients = {
    ['canned_meat'] = {
        name = 'Carne Enlatada',
        item = 'canned_meat',
    },
    ['vegetables'] = {
        name = 'Verduras',
        item = 'vegetables',
    },
    ['water_bottle'] = {
        name = 'Agua',
        item = 'water_bottle',
    },
    ['beans'] = {
        name = 'Frijoles',
        item = 'beans',
    },
    ['spices'] = {
        name = 'Especias',
        item = 'spices',
    },
    ['cooking_oil'] = {
        name = 'Aceite',
        item = 'cooking_oil',
    },
    ['pasta'] = {
        name = 'Pasta',
        item = 'pasta',
    }
}

-- ========================================
-- RECETAS DE COCINA
-- ========================================

Config.Recipes = {
    {
        id = 1,
        name = 'Sopa de Carne',
        image = 'multi_layer_panel',
        level = 'Lv. 1',
        description = 'Sopa básica con carne enlatada y verduras. Perfecta para sobrevivir.',
        cookingTime = 45,
        difficulty = 'easy',
        
        ingredients = {
            { ingredient = 'padding_scraps', required = 1 },
            { ingredient = 'padding_scraps', required = 1 },
            { ingredient = 'padding_scraps', required = 1 }
        },
        
        results = {
            success = {
                item = 'multi_layer_panel',
                amount = 1
            },
            failure = {
                item = 'multi_layer_panel',
                amount = 1
            }
        }
    },
    
    {
        id = 2,
        name = 'Guiso de Frijoles',
        image = 'bean_stew',
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
                amount = 1
            },
            failure = {
                item = 'burnt_food',
                amount = 1
            }
        }
    },
    
    {
        id = 3,
        name = 'Pasta Simple',
        image = 'cooked_pasta',
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
                amount = 1
            },
            failure = {
                item = 'burnt_food',
                amount = 1
            }
        }
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