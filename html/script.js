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
let isProcessing = false; // ✅ Variable que faltaba

// ========================================
// FUNCIONES DE UTILIDAD
// ========================================

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

// Renderizar lista de recetas
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
            
            item.innerHTML = `
                <div class="recipe-icon"><i class="${recipe.icon}"></i></div>
                <div class="recipe-info">
                    <div class="recipe-name">${recipe.name}</div>
                    <div class="recipe-level">${recipe.level}</div>
                    <div class="recipe-available" style="color: ${canCook ? 'var(--tarkov-success)' : 'var(--tarkov-danger)'}">
                        ${canCook ? 'Disponible' : 'Sin ingredientes'}
                    </div>
                </div>
            `;
            
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
        document.getElementById('foodContent').innerHTML = `<i class="${recipe.icon}"></i>`;
        
        renderIngredients();
        renderExpectedResults();
        renderRecipes();
        updateCookButton();
    } catch (error) {
        console.error('Error seleccionando receta:', error);
    }
}

// Renderizar ingredientes requeridos
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
        
        item.innerHTML = `
            <div class="ingredient-icon"><i class="${ingredient.icon}"></i></div>
            <div class="ingredient-info">
                <div class="ingredient-name">${ingredient.name}</div>
                <div class="ingredient-count">${ingredient.available}/${ingredient.required}</div>
            </div>
        `;
        
        container.appendChild(item);
    });
}

// Renderizar resultados esperados
function renderExpectedResults() {
    const container = document.getElementById('expectedResultsList');
    if (!container) return;
    
    container.innerHTML = '';

    if (!gameState.selectedRecipe) return;

    const result = gameState.selectedRecipe.result;
    const item = document.createElement('div');
    item.className = 'result-item';
    
    item.innerHTML = `
        <div class="result-icon"><i class="${result.icon}"></i></div>
        <div class="result-info">
            <div class="result-name">${result.name}</div>
            <div class="result-chance">Solo si calidad ≥ 30%</div>
        </div>
    `;
    
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
            alert(validation.error);
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

// Completar cocción
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
            showResult(result, gameState.cooking.quality);
        } else {
            showFailureResult(gameState.cooking.quality);
        }
        
        resetCooking();
    } catch (error) {
        console.error('Error completando cocción:', error);
        resetCooking();
    }
}

// Mostrar resultado exitoso
function showResult(result, quality) {
    const message = `¡Cocción exitosa!\n${result.name}\nCalidad: ${Math.round(quality)}%`;
    alert(message);

    // Comunicar con FiveM
    if (window.invokeNative) {
        window.invokeNative('sendNuiMessage', JSON.stringify({
            type: 'cookingComplete',
            success: true,
            recipe: gameState.selectedRecipe.name,
            result: result.name,
            quality: Math.round(quality)
        }));
    }
}

// Mostrar resultado fallido
function showFailureResult(quality) {
    const message = `¡Cocción fallida!\nComida arruinada\nCalidad: ${Math.round(quality)}%\n\nNo obtuviste ningún item.`;
    alert(message);

    // Comunicar con FiveM
    if (window.invokeNative) {
        window.invokeNative('sendNuiMessage', JSON.stringify({
            type: 'cookingComplete',
            success: false,
            recipe: gameState.selectedRecipe.name,
            result: null,
            quality: Math.round(quality)
        }));
    }
}

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

// Cerrar interfaz
function closeInterface() {
    if (isProcessing) return;
    
    try {
        isProcessing = true;
        
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
        
        // Notificar a FiveM
        if (window.invokeNative) {
            window.invokeNative('sendNuiMessage', JSON.stringify({
                type: 'closeUI'
            }));
        }
        
        // Ocultar interfaz
        document.body.style.display = 'none';
        
        console.log('Interfaz cerrada correctamente');
        
    } catch (error) {
        console.error('Error cerrando interfaz:', error);
    } finally {
        isProcessing = false;
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

// Prevenir cierre accidental con clicks fuera
document.addEventListener('click', function(event) {
    // Solo cerrar si se hace clic específicamente en el botón de cerrar
    if (event.target.classList.contains('close-button')) {
        closeInterface();
    }
});