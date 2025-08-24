// ========================================
// VARIABLES GLOBALES
// ========================================

let gameState = {
    recipes: [],
    selectedRecipe: null,
    isCooking: false,
    cooking: { fire: 0, progress: 0, quality: 100 }
};

let gameInterval = null;
let isProcessing = false;

// ✅ CONFIGURACIÓN DE PATH DE IMÁGENES
const INVENTORY_IMAGES_PATH = 'https://cfx-nui-inventory_images/images/';
const IMAGE_EXTENSION = '.webp';

// ========================================
// FUNCIONES DE UTILIDAD
// ========================================

// ✅ Función para obtener URL completa de imagen
function getItemImageUrl(itemName) {
    return `${INVENTORY_IMAGES_PATH}${itemName}${IMAGE_EXTENSION}`;
}

// ✅ Función para crear elemento de imagen con fallback - CORREGIDA PARA EVITAR PARPADEO
function createItemImage(itemName, altText = '', className = '') {
    const img = document.createElement('img');
    img.src = getItemImageUrl(itemName);
    img.alt = altText || itemName;
    img.className = className;
    
    // ✅ PREVENIR PARPADEO: Establecer opacity inicial
    img.style.opacity = '0';
    img.style.transition = 'opacity 0.3s ease';
    
    // ✅ Evento cuando la imagen se carga correctamente
    img.onload = function() {
        this.style.opacity = '1';
    };
    
    // ✅ Fallback si la imagen no carga
    img.onerror = function() {
        this.style.display = 'none';
        // Crear un icono de fallback
        const fallbackIcon = document.createElement('div');
        fallbackIcon.className = 'item-fallback-icon';
        fallbackIcon.innerHTML = '<i class="fas fa-utensils"></i>';
        fallbackIcon.style.opacity = '1';
        this.parentNode.appendChild(fallbackIcon);
    };
    
    return img;
}

// Validar estado del juego
function validateGameState() {
    if (isProcessing) {
        return { valid: false, error: 'Procesando otra acción...' };
    }
    
    if (!gameState.selectedRecipe) {
        return { valid: false, error: 'No hay receta seleccionada' };
    }
    
    if (gameState.isCooking) {
        return { valid: false, error: 'Ya está cocinando' };
    }
    
    const canCook = gameState.selectedRecipe.ingredients.every(ing => 
        ing.available >= ing.required
    );
    
    if (!canCook) {
        return { valid: false, error: 'Ingredientes insuficientes' };
    }
    
    return { valid: true };
}

// ========================================
// FUNCIONES DE RENDERIZADO
// ========================================

// Inicializar interfaz
function initInterface() {
    try {
        // Resetear estado
        gameState = {
            recipes: [],
            selectedRecipe: null,
            isCooking: false,
            cooking: { fire: 0, progress: 0, quality: 100 }
        };
        
        renderRecipes();
        updateInterface();
        
        console.log('Interfaz inicializada correctamente');
    } catch (error) {
        console.error('Error inicializando interfaz:', error);
    }
}

// ✅ Renderizar lista de recetas - SIN PARPADEO
function renderRecipes() {
    const container = document.getElementById('recipesList');
    if (!container) {
        console.error('Contenedor de recetas no encontrado');
        return;
    }
    
    container.innerHTML = '';

    if (!gameState.recipes || gameState.recipes.length === 0) {
        container.innerHTML = '<div style="text-align: center; color: var(--tarkov-primary); font-size: 11px; padding: 20px;">Cargando recetas...</div>';
        return;
    }

    gameState.recipes.forEach(recipe => {
        try {
            const canCook = recipe.ingredients.every(ing => ing.available >= ing.required);
            
            const item = document.createElement('div');
            item.className = `recipe-item ${gameState.selectedRecipe?.id === recipe.id ? 'selected' : ''}`;
            item.onclick = () => selectRecipe(recipe);
            
            const recipeIcon = document.createElement('div');
            recipeIcon.className = 'recipe-icon';
            const recipeImg = createItemImage(recipe.image, recipe.name, 'recipe-image');
            recipeIcon.appendChild(recipeImg);
            
            const recipeInfo = document.createElement('div');
            recipeInfo.className = 'recipe-info';
            recipeInfo.innerHTML = `
                <div class="recipe-name">${recipe.name}</div>
                <div class="recipe-level">${recipe.level}</div>
                <div class="recipe-available" style="color: ${canCook ? 'var(--tarkov-success)' : 'var(--tarkov-danger)'}">
                    ${canCook ? 'Disponible' : 'Sin ingredientes'}
                </div>
            `;
            
            item.appendChild(recipeIcon);
            item.appendChild(recipeInfo);
            container.appendChild(item);
        } catch (error) {
            console.error('Error renderizando receta:', recipe.id, error);
        }
    });
}

// Seleccionar receta
function selectRecipe(recipe) {
    try {
        gameState.selectedRecipe = recipe;
        document.getElementById('selectedRecipeTitle').textContent = recipe.name;
        document.getElementById('selectedRecipeDesc').textContent = recipe.description;
        
        // ✅ Mostrar imagen del resultado en el plato central - SIN PARPADEO
        const foodContent = document.getElementById('foodContent');
        foodContent.innerHTML = '';
        const resultImg = createItemImage(recipe.result.image, recipe.result.name, 'food-result-image');
        foodContent.appendChild(resultImg);
        
        renderIngredients();
        renderExpectedResults();
        renderRecipes();
        updateCookButton();
    } catch (error) {
        console.error('Error seleccionando receta:', error);
    }
}

// ✅ Renderizar ingredientes requeridos - SIN PARPADEO
function renderIngredients() {
    const container = document.getElementById('ingredientsList');
    if (!container) return;
    
    container.innerHTML = '';

    if (!gameState.selectedRecipe) {
        container.innerHTML = '<div style="text-align: center; color: var(--tarkov-primary); font-size: 11px; padding: 20px;">Selecciona una receta</div>';
        return;
    }

    gameState.selectedRecipe.ingredients.forEach(ingredient => {
        const hasEnough = ingredient.available >= ingredient.required;
        const item = document.createElement('div');
        item.className = `ingredient-slot ${hasEnough ? 'required' : 'missing'}`;
        
        const ingredientIcon = document.createElement('div');
        ingredientIcon.className = 'ingredient-icon';
        const ingredientImg = createItemImage(ingredient.image, ingredient.name, 'ingredient-image');
        ingredientIcon.appendChild(ingredientImg);
        
        const ingredientInfo = document.createElement('div');
        ingredientInfo.className = 'ingredient-info';
        ingredientInfo.innerHTML = `
            <div class="ingredient-name">${ingredient.name}</div>
            <div class="ingredient-count">${ingredient.available}/${ingredient.required}</div>
        `;
        
        item.appendChild(ingredientIcon);
        item.appendChild(ingredientInfo);
        container.appendChild(item);
    });
}

// ✅ Renderizar resultados esperados - SIN PARPADEO
function renderExpectedResults() {
    const container = document.getElementById('expectedResultsList');
    if (!container) return;
    
    container.innerHTML = '';

    if (!gameState.selectedRecipe) return;

    const result = gameState.selectedRecipe.result;
    const item = document.createElement('div');
    item.className = 'result-item';
    
    const resultIcon = document.createElement('div');
    resultIcon.className = 'result-icon';
    const resultImg = createItemImage(result.image, result.name, 'result-image');
    resultIcon.appendChild(resultImg);
    
    const resultInfo = document.createElement('div');
    resultInfo.className = 'result-info';
    resultInfo.innerHTML = `
        <div class="result-name">${result.name}</div>
        <div class="result-chance">Solo si calidad ≥ 30%</div>
    `;
    
    item.appendChild(resultIcon);
    item.appendChild(resultInfo);
    container.appendChild(item);
}

// Actualizar botón de cocinar
function updateCookButton() {
    const button = document.getElementById('cookButton');
    if (!button) return;
    
    if (!gameState.selectedRecipe) {
        button.disabled = true;
        button.textContent = 'SELECCIONA RECETA';
        return;
    }

    const canCook = gameState.selectedRecipe.ingredients.every(ing => ing.available >= ing.required);
    
    if (gameState.isCooking) {
        button.disabled = true;
        button.textContent = 'COCINANDO...';
    } else if (canCook) {
        button.disabled = false;
        button.textContent = 'COMENZAR COCCIÓN';
    } else {
        button.disabled = true;
        button.textContent = 'SIN INGREDIENTES';
    }
}

// ========================================
// CONTROLES DEL MINIJUEGO
// ========================================

// Acciones de control
function controlAction(type) {
    if (!gameState.isCooking) return;

    try {
        const control = document.querySelector(`.control-${type}`);
        if (!control) {
            console.error(`Control no encontrado: ${type}`);
            return;
        }

        control.classList.add('active');
        
        setTimeout(() => {
            control.classList.remove('active');
        }, 500);

        switch(type) {
            case 'fire':
                gameState.cooking.fire = Math.min(100, gameState.cooking.fire + 20);
                break;
            case 'water':
                gameState.cooking.fire = Math.max(0, gameState.cooking.fire - 10);
                gameState.cooking.quality = Math.min(100, gameState.cooking.quality + 5);
                break;
            case 'stir':
                gameState.cooking.quality = Math.min(100, gameState.cooking.quality + 10);
                break;
            case 'seasoning':
                gameState.cooking.quality = Math.min(100, gameState.cooking.quality + 15);
                break;
        }
    } catch (error) {
        console.error('Error en controlAction:', error);
    }
}

// Comenzar cocción
function startCooking() {
    if (isProcessing) return;
    
    try {
        const validation = validateGameState();
        if (!validation.valid) {
            console.log('Validación fallida:', validation.error);
            return;
        }

        isProcessing = true;

        // Enviar al cliente para procesar en servidor
        if (window.invokeNative) {
            window.invokeNative('sendNuiMessage', JSON.stringify({
                type: 'startCooking',
                recipeId: gameState.selectedRecipe.id
            }));
        }

        gameState.isCooking = true;
        gameState.cooking = { fire: 30, progress: 0, quality: 100 };
        
        const foodContent = document.getElementById('foodContent');
        if (foodContent) {
            foodContent.classList.add('cooking');
        }

        updateCookButton();
        
        // Iniciar loop de cocción
        if (gameInterval) {
            clearInterval(gameInterval);
        }
        
        gameInterval = setInterval(() => {
            updateCooking();
            updateInterface();
            checkCookingComplete();
        }, 100);

        console.log('Cocción iniciada:', gameState.selectedRecipe.name);

    } catch (error) {
        console.error('Error iniciando cocción:', error);
        gameState.isCooking = false;
        updateCookButton();
    } finally {
        setTimeout(() => {
            isProcessing = false;
        }, 1000);
    }
}

// Actualizar proceso de cocción
function updateCooking() {
    if (!gameState.isCooking) return;

    try {
        // El fuego se consume
        gameState.cooking.fire = Math.max(0, gameState.cooking.fire - 0.2);
        
        // Progreso de cocción
        if (gameState.cooking.fire > 20) {
            gameState.cooking.progress += (gameState.cooking.fire / 100) * 0.8;
        }

        // Efectos en la calidad
        if (gameState.cooking.fire > 80) {
            gameState.cooking.quality = Math.max(0, gameState.cooking.quality - 0.3); // Se quema
        } else if (gameState.cooking.fire < 20 && gameState.cooking.progress < 80) {
            gameState.cooking.quality = Math.max(0, gameState.cooking.quality - 0.1); // Se enfría
        }
    } catch (error) {
        console.error('Error en updateCooking:', error);
    }
}

// Verificar si la cocción está completa
function checkCookingComplete() {
    if (gameState.cooking.progress >= 100) {
        completeCooking();
    }
}

// ✅ Completar cocción - SIN ALERTS, AUTO-CERRAR UI
function completeCooking() {
    try {
        if (gameInterval) {
            clearInterval(gameInterval);
            gameInterval = null;
        }
        
        gameState.isCooking = false;

        const foodContent = document.getElementById('foodContent');
        if (foodContent) {
            foodContent.classList.remove('cooking');
        }

        // Verificar si la calidad es suficiente para obtener el item
        const success = gameState.cooking.quality >= 30;
        
        if (success) {
            const result = gameState.selectedRecipe.result;
            finalizeCookingProcess(true, result, gameState.cooking.quality);
        } else {
            finalizeCookingProcess(false, null, gameState.cooking.quality);
        }
        
    } catch (error) {
        console.error('Error completando cocción:', error);
        resetCooking();
    }
}

// ✅ NUEVA FUNCIÓN: Finalizar proceso sin alerts
function finalizeCookingProcess(success, result, quality) {
    console.log('Cocción finalizada:', success ? 'Éxito' : 'Fallo', 'Calidad:', Math.round(quality) + '%');

    // ✅ Comunicar con FiveM ANTES de cerrar
    if (window.invokeNative) {
        window.invokeNative('sendNuiMessage', JSON.stringify({
            type: 'cookingComplete',
            success: success,
            recipe: gameState.selectedRecipe.name,
            result: success ? result.name : null,
            quality: Math.round(quality)
        }));
    }
    
    // ✅ CERRAR UI AUTOMÁTICAMENTE después de 1 segundo
    setTimeout(() => {
        closeInterface();
    }, 1000);
}

// ✅ FUNCIONES ELIMINADAS: showResult y showFailureResult (ya no se usan)

// Resetear estado de cocción
function resetCooking() {
    try {
        if (gameInterval) {
            clearInterval(gameInterval);
            gameInterval = null;
        }
        
        gameState.selectedRecipe = null;
        gameState.cooking = { fire: 0, progress: 0, quality: 100 };
        gameState.isCooking = false;
        
        document.getElementById('selectedRecipeTitle').textContent = 'Selecciona una Receta';
        document.getElementById('selectedRecipeDesc').textContent = 'Elige una receta del panel izquierdo para comenzar a cocinar';
        document.getElementById('foodContent').innerHTML = '<i class="fas fa-utensils"></i>';
        
        renderRecipes();
        renderIngredients();
        renderExpectedResults();
        updateCookButton();
    } catch (error) {
        console.error('Error reseteando cocción:', error);
    }
}

// Actualizar interfaz
function updateInterface() {
    try {
        const fireProgress = document.getElementById('fireProgress');
        const cookingProgress = document.getElementById('cookingProgress');
        const qualityProgress = document.getElementById('qualityProgress');
        
        if (fireProgress) fireProgress.style.width = `${gameState.cooking.fire}%`;
        if (cookingProgress) cookingProgress.style.width = `${gameState.cooking.progress}%`;
        if (qualityProgress) qualityProgress.style.width = `${gameState.cooking.quality}%`;
    } catch (error) {
        console.error('Error actualizando interfaz:', error);
    }
}

// ✅ Cerrar interfaz - MEJORADO
function closeInterface() {
    if (isProcessing) {
        console.log('Cerrando interfaz cancelado - procesando');
        return;
    }
    
    try {
        isProcessing = true;
        
        console.log('Iniciando cierre de interfaz...');
        
        if (gameInterval) {
            clearInterval(gameInterval);
            gameInterval = null;
        }
        
        // Resetear estado del juego
        gameState.isCooking = false;
        gameState.selectedRecipe = null;
        gameState.cooking = { fire: 0, progress: 0, quality: 100 };
        
        // Limpiar efectos visuales
        const foodContent = document.getElementById('foodContent');
        if (foodContent) {
            foodContent.classList.remove('cooking');
            foodContent.innerHTML = '<i class="fas fa-utensils"></i>';
        }
        
        // ✅ IMPORTANTE: Notificar a FiveM ANTES de ocultar
        if (window.invokeNative) {
            window.invokeNative('sendNuiMessage', JSON.stringify({
                type: 'closeUI'
            }));
        }
        
        // ✅ Delay pequeño para asegurar que FiveM procese el mensaje
        setTimeout(() => {
            // Ocultar interfaz
            document.body.style.display = 'none';
            console.log('Interfaz cerrada correctamente');
        }, 50);
        
    } catch (error) {
        console.error('Error cerrando interfaz:', error);
    } finally {
        setTimeout(() => {
            isProcessing = false;
        }, 200);
    }
}

// ========================================
// EVENT LISTENERS
// ========================================

// Event listeners para FiveM
window.addEventListener('message', function(event) {
    try {
        const data = event.data;
        console.log('Mensaje recibido:', data.type, data);
        
        switch(data.type) {
            case 'openCooking':
                isProcessing = true;
                
                // Resetear estado antes de abrir
                gameState.isCooking = false;
                gameState.selectedRecipe = null;
                gameState.cooking = { fire: 0, progress: 0, quality: 100 };
                
                // Cargar recetas
                if (data.recipes && Array.isArray(data.recipes)) {
                    gameState.recipes = data.recipes;
                    console.log('Recetas cargadas:', data.recipes.length);
                    renderRecipes();
                    renderIngredients();
                    renderExpectedResults();
                }
                
                document.body.style.display = 'flex';
                console.log('Interfaz abierta');
                
                setTimeout(() => { isProcessing = false; }, 500);
                break;
                
            case 'updateRecipes':
                if (data.recipes && Array.isArray(data.recipes)) {
                    gameState.recipes = data.recipes;
                    renderRecipes();
                    if (gameState.selectedRecipe) {
                        const updatedRecipe = data.recipes.find(r => r.id === gameState.selectedRecipe.id);
                        if (updatedRecipe) {
                            gameState.selectedRecipe = updatedRecipe;
                            renderIngredients();
                        }
                    }
                }
                break;
                
            case 'closeCooking':
                closeInterface();
                break;
                
            case 'ingredientsReady':
                console.log('Ingredientes preparados para cocción');
                break;
                
            default:
                console.log('Mensaje desconocido:', data.type);
                break;
        }
    } catch (error) {
        console.error('Error procesando mensaje:', error);
        isProcessing = false;
    }
});

// Controles de teclado
document.addEventListener('keydown', function(event) {
    try {
        switch(event.code) {
            case 'Escape':
                event.preventDefault();
                closeInterface();
                break;
                
            case 'Space':
                event.preventDefault();
                const cookButton = document.getElementById('cookButton');
                if (cookButton && !cookButton.disabled && !gameState.isCooking) {
                    startCooking();
                }
                break;
                
            case 'Digit1':
            case 'Numpad1':
                event.preventDefault();
                controlAction('fire');
                break;
                
            case 'Digit2':
            case 'Numpad2':
                event.preventDefault();
                controlAction('water');
                break;
                
            case 'Digit3':
            case 'Numpad3':
                event.preventDefault();
                controlAction('stir');
                break;
                
            case 'Digit4':
            case 'Numpad4':
                event.preventDefault();
                controlAction('seasoning');
                break;
        }
    } catch (error) {
        console.error('Error en controles de teclado:', error);
    }
});

// Inicializar al cargar
document.addEventListener('DOMContentLoaded', function() {
    try {
        // Ocultar interfaz por defecto
        document.body.style.display = 'none';
        
        // Inicializar interfaz
        initInterface();
        
        console.log('Sistema de cocina inicializado correctamente');
    } catch (error) {
        console.error('Error en inicialización:', error);
    }
});

// Manejo de errores globales
window.addEventListener('error', function(event) {
    console.error('Error global en UI de cocina:', event.error);
    
    // Intentar resetear si hay error crítico
    if (gameState.isCooking) {
        try {
            if (gameInterval) {
                clearInterval(gameInterval);
                gameInterval = null;
            }
            gameState.isCooking = false;
        } catch (cleanupError) {
            console.error('Error durante cleanup:', cleanupError);
        }
    }
    
    isProcessing = false;
});

// ✅ Prevenir cierre accidental con clicks fuera
document.addEventListener('click', function(event) {
    // Solo cerrar si se hace clic específicamente en el botón de cerrar
    if (event.target.classList.contains('close-button')) {
        closeInterface();
        event.stopPropagation();
        event.preventDefault();
    }
});

// ✅ Prevenir context menu y drag
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});

document.addEventListener('dragstart', function(event) {
    event.preventDefault();
});