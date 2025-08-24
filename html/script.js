// Estado del juego
let gameState = {
    recipes: [
        {
            id: 1,
            name: 'Sopa de Carne',
            icon: 'fas fa-bowl-food',
            level: 'Lv. 1',
            description: 'Sopa básica con carne enlatada y verduras. Perfecta para sobrevivir.',
            ingredients: [
                { name: 'Carne Enlatada', icon: 'fas fa-can-food', required: 1, available: 2 },
                { name: 'Verduras', icon: 'fas fa-carrot', required: 1, available: 3 },
                { name: 'Agua', icon: 'fas fa-droplet', required: 1, available: 5 }
            ],
            cookingTime: 45,
            result: { name: 'Sopa de Carne', icon: 'fas fa-bowl-food' }
        },
        {
            id: 2,
            name: 'Guiso de Frijoles',
            icon: 'fas fa-seedling',
            level: 'Lv. 2',
            description: 'Nutritivo guiso que te dará energía para explorar.',
            ingredients: [
                { name: 'Frijoles', icon: 'fas fa-seedling', required: 2, available: 4 },
                { name: 'Especias', icon: 'fas fa-pepper-hot', required: 1, available: 1 },
                { name: 'Aceite', icon: 'fas fa-oil-can', required: 1, available: 2 }
            ],
            cookingTime: 60,
            result: { name: 'Guiso de Frijoles', icon: 'fas fa-seedling' }
        },
        {
            id: 3,
            name: 'Pasta Simple',
            icon: 'fas fa-wheat-awn',
            level: 'Lv. 1',
            description: 'Comida rápida cuando tienes prisa y zombies cerca.',
            ingredients: [
                { name: 'Pasta', icon: 'fas fa-wheat-awn', required: 1, available: 1 },
                { name: 'Aceite', icon: 'fas fa-oil-can', required: 1, available: 2 },
                { name: 'Agua', icon: 'fas fa-droplet', required: 2, available: 5 }
            ],
            cookingTime: 30,
            result: { name: 'Pasta Cocida', icon: 'fas fa-wheat-awn' }
        }
    ],
    selectedRecipe: null,
    cooking: {
        fire: 0,
        progress: 0,
        quality: 100
    },
    isCooking: false
};

let gameInterval = null;

// Inicializar interfaz
function initInterface() {
    renderRecipes();
    updateInterface();
}

// Renderizar lista de recetas
function renderRecipes() {
    const container = document.getElementById('recipesList');
    container.innerHTML = '';

    gameState.recipes.forEach(recipe => {
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
    });
}

// Seleccionar receta
function selectRecipe(recipe) {
    gameState.selectedRecipe = recipe;
    document.getElementById('selectedRecipeTitle').textContent = recipe.name;
    document.getElementById('selectedRecipeDesc').textContent = recipe.description;
    document.getElementById('foodContent').innerHTML = `<i class="${recipe.icon}"></i>`;
    
    renderIngredients();
    renderExpectedResults();
    renderRecipes();
    updateCookButton();
}

// Renderizar ingredientes requeridos
function renderIngredients() {
    const container = document.getElementById('ingredientsList');
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

// Acciones de control
function controlAction(type) {
    if (!gameState.isCooking) return;

    const control = document.querySelector(`.control-${type}`);
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
}

// Comenzar cocción
function startCooking() {
    if (!gameState.selectedRecipe || gameState.isCooking) return;

    // Consumir ingredientes
    gameState.selectedRecipe.ingredients.forEach(ingredient => {
        ingredient.available -= ingredient.required;
    });

    gameState.isCooking = true;
    gameState.cooking = { fire: 30, progress: 0, quality: 100 };
    
    const foodContent = document.getElementById('foodContent');
    foodContent.classList.add('cooking');

    updateCookButton();
    renderIngredients();

    // Iniciar loop de cocción
    gameInterval = setInterval(() => {
        updateCooking();
        updateInterface();
        checkCookingComplete();
    }, 100);
}

// Actualizar proceso de cocción
function updateCooking() {
    if (!gameState.isCooking) return;

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
}

// Verificar si la cocción está completa
function checkCookingComplete() {
    if (gameState.cooking.progress >= 100) {
        completeCooking();
    }
}

// Completar cocción
function completeCooking() {
    clearInterval(gameInterval);
    gameState.isCooking = false;

    const foodContent = document.getElementById('foodContent');
    foodContent.classList.remove('cooking');

    // Verificar si la calidad es suficiente para obtener el item
    const success = gameState.cooking.quality >= 30;
    
    if (success) {
        const result = gameState.selectedRecipe.result;
        showResult(result, gameState.cooking.quality);
    } else {
        showFailureResult(gameState.cooking.quality);
    }
    
    resetCooking();
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
    gameState.selectedRecipe = null;
    gameState.cooking = { fire: 0, progress: 0, quality: 100 };
    
    document.getElementById('selectedRecipeTitle').textContent = 'Selecciona una Receta';
    document.getElementById('selectedRecipeDesc').textContent = 'Elige una receta del panel izquierdo para comenzar a cocinar';
    document.getElementById('foodContent').innerHTML = '<i class="fas fa-utensils"></i>';
    
    renderRecipes();
    renderIngredients();
    renderExpectedResults();
    updateCookButton();
}

// Actualizar interfaz
function updateInterface() {
    document.getElementById('fireProgress').style.width = `${gameState.cooking.fire}%`;
    document.getElementById('cookingProgress').style.width = `${gameState.cooking.progress}%`;
    document.getElementById('qualityProgress').style.width = `${gameState.cooking.quality}%`;
}

// Cerrar interfaz
function closeInterface() {
    if (window.invokeNative) {
        window.invokeNative('sendNuiMessage', JSON.stringify({
            type: 'closeUI'
        }));
    } else {
        document.body.style.display = 'none';
    }
}

// Event listeners para FiveM
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'openCooking':
            document.body.style.display = 'flex';
            break;
        case 'closeCooking':
            closeInterface();
            break;
        case 'updateIngredients':
            // Actualizar disponibilidad de ingredientes
            break;
    }
});

// Controles de teclado
document.addEventListener('keydown', function(event) {
    switch(event.code) {
        case 'Escape':
            closeInterface();
            break;
        case 'Space':
            event.preventDefault();
            if (document.getElementById('cookButton').disabled === false) {
                startCooking();
            }
            break;
        case 'Digit1':
            controlAction('fire');
            break;
        case 'Digit2':
            controlAction('water');
            break;
        case 'Digit3':
            controlAction('stir');
            break;
        case 'Digit4':
            controlAction('seasoning');
            break;
    }
});

// Inicializar al cargar
document.addEventListener('DOMContentLoaded', initInterface);