# 🍳 Sistema de Cocina de Supervivencia para FiveM (TGIANN-INVENTORY)

Un sistema completo de cocina con minijuego interactivo para servidores de QBCore usando **tgiann-inventory**. Los jugadores pueden cocinar recetas usando ingredientes y un minijuego de gestión de fuego y calidad.

## 📋 Características

- **Compatible con tgiann-inventory**: Totalmente optimizado para tgiann-inventory con todas sus funcionalidades
- **Minijuego Interactivo**: Sistema de cocción en tiempo real con controles de fuego, agua, remover y sazón
- **Sistema de Calidad**: La calidad de la comida depende de qué tan bien gestiones el proceso de cocción
- **Múltiples Recetas**: Sistema configurable de recetas con diferentes niveles de dificultad
- **Verificación de Ingredientes**: El sistema verifica automáticamente si tienes los ingredientes necesarios
- **Interfaz Moderna**: UI con diseño Tarkov-style completamente funcional
- **Estaciones de Cocina**: Múltiples ubicaciones configurables donde cocinar
- **Sistema de Blips**: Marcadores en el mapa para encontrar estaciones
- **Comandos de Admin**: Herramientas para administradores
- **Items Funcionales**: Los items cocinados tienen animaciones, props y efectos de status

## 🚀 Instalación

### 1. Archivos del Recurso
```
[tu-carpeta-resources]/
└── survival-cooking/
    ├── fxmanifest.lua
    ├── config.lua
    ├── client.lua
    ├── server.lua
    └── html/
        ├── index.html
        ├── style.css
        └── script.js
```

### 2. Configuración de tgiann-inventory

#### Añadir Items a `tgiann-inventory/items.lua`:
Copia todos los items del archivo `items_for_tgiann.lua` al archivo items.lua de tgiann-inventory.

#### Imágenes necesarias para `tgiann-inventory/html/images/`:
- `canned_meat.png`
- `vegetables.png`
- `water_bottle.png`
- `beans.png`
- `spices.png`
- `cooking_oil.png`
- `pasta.png`
- `meat_soup.png`
- `bean_stew.png`
- `cooked_pasta.png`
- `burnt_food.png`

### 3. Server.cfg
```
ensure tgiann-inventory
ensure survival-cooking
```

### 4. Reiniciar Recursos
```
restart tgiann-inventory
start survival-cooking
```

## 🎮 Uso del Sistema

### Para Jugadores:
1. **Encontrar Estación**: Ve a una de las estaciones marcadas en el mapa
2. **Interactuar**: Presiona `E` cerca de la estación para abrir la interfaz
3. **Seleccionar Receta**: Elige una receta del panel izquierdo
4. **Verificar Ingredientes**: Asegúrate de tener todos los ingredientes necesarios
5. **Cocinar**: Haz clic en "COMENZAR COCCIÓN" o presiona `Espacio`
6. **Minijuego**: 
   - `1` o clic en 🔥 para añadir fuego
   - `2` o clic en 💧 para enfriar y mejorar calidad
   - `3` o clic en 🥄 para remover y mejorar calidad
   - `4` o clic en 🌶️ para añadir sazón (mejor al final)
7. **Resultado**: Necesitas mínimo 30% de calidad para obtener el item
8. **Usar Items**: Los items cocinados tienen animaciones y efectos automáticos

### Controles:
- `E` - Interactuar con estación
- `ESC` - Cerrar interfaz
- `Espacio` - Comenzar cocción
- `1,2,3,4` - Controles del minijuego

## ⚙️ Configuración

### Estaciones de Cocina (config.lua):
```lua
Config.CookingStations = {
    vector3(-1196.43, -890.85, 13.9), -- Vespucci Beach
    vector3(1961.64, 5184.33, 47.98), -- Grapeseed
    vector3(2556.75, 4681.03, 34.08), -- Mount Chiliad
}
```

### Añadir Nueva Receta:
```lua
{
    id = 4, -- ID único
    name = 'Nueva Receta',
    icon = 'fas fa-bowl-food',
    level = 'Lv. 1',
    description = 'Descripción de la receta',
    cookingTime = 45,
    difficulty = 'easy',
    
    ingredients = {
        { ingredient = 'canned_meat', required = 1 },
        { ingredient = 'vegetables', required = 1 }
    },
    
    results = {
        success = { item = 'nuevo_item', amount = 1 },
        failure = { item = 'burnt_food', amount = 1 }
    }
}
```

### Configurar Minijuego:
```lua
Config.Minigame = {
    FireDecayRate = 0.2, -- Velocidad de pérdida de fuego
    QualityBurnRate = 0.3, -- Pérdida cuando se quema
    QualityColdRate = 0.1, -- Pérdida cuando se enfría
    ProgressRate = 0.8, -- Velocidad de progreso
    MinQualityForSuccess = 30, -- Calidad mínima para éxito
}
```

## 🛠️ Comandos de Admin

### `/darIngredientes`
Otorga ingredientes básicos para testing (requiere permisos de admin).

### `/resetEstaciones`
Resetea todas las estaciones de cocina en caso de problemas.

### `/cocina`
Abre la interfaz de cocina directamente (para testing).

## 🔧 Solución de Problemas

### Problemas Comunes:

**La interfaz no abre:**
- Verifica que el recurso esté iniciado
- Revisa la consola F8 por errores de JavaScript
- Asegúrate de estar cerca de una estación
- Verifica que tgiann-inventory esté funcionando correctamente

**No tengo ingredientes:**
- Usa `/darIngredientes` como admin
- Verifica que los items estén en tgiann-inventory/items.lua
- Reinicia tgiann-inventory si añadiste items nuevos

**Las estaciones no aparecen:**
- Revisa las coordenadas en config.lua
- Verifica que los blips estén activados
- Reinicia el recurso

**Error de inventario lleno:**
- Libera espacio en tu inventario
- Con tgiann-inventory, si no hay espacio, el item se dropeará al suelo automáticamente

**Los items no tienen efectos:**
- Verifica que añadiste las configuraciones client en items.lua
- Asegúrate de que tgiann-inventory tenga las funciones de status activadas
- Revisa que las animaciones y props estén configurados correctamente

## 🎯 Ventajas de tgiann-inventory

### Funcionalidades Avanzadas:
- **Animaciones Automáticas**: Los items de comida se usan con animaciones realistas
- **Props Dinámicos**: Los items aparecen en la mano del jugador cuando se usan  
- **Sistema de Status**: Hunger, thirst y health se restauran automáticamente
- **Notificaciones Integradas**: Mensajes cuando se usan los items
- **Anti-Pérdida**: Si el inventario está lleno, los items se dropean en lugar de perderse
- **Stacking Avanzado**: Sistema de apilamiento similar a Minecraft

## 📝 Personalización

### Cambiar Colores de la UI:
Edita las variables CSS en `html/style.css`:
```css
:root {
    --tarkov-primary: #c7c5b3;
    --tarkov-secondary: #9a2040;
    --tarkov-bg: #191919b1;
}
```

### Añadir Más Ingredientes:
1. Añade el ingrediente a `Config.Ingredients`
2. Añade el item a qb-core
3. Actualiza las recetas que lo usen

## 📊 Sistema de Logs

Si tienes `qb-logs` instalado, descomenta la línea en `server.lua`:
```lua
-- TriggerEvent('qb-logs:server:CreateLog', 'cooking', action, 'blue', logMessage)
```

## 🤝 Soporte

Para soporte y reportar bugs:
- Revisa que todos los archivos estén en su lugar
- Verifica la consola por errores
- Asegúrate de tener las dependencias instaladas

## 📄 Licencia

Este recurso es de código abierto. Úsalo y modifícalo según tus necesidades.

## 🔄 Versiones

### v1.0.0
- Sistema base de cocina
- Interfaz completa
- 3 recetas iniciales
- Minijuego funcional
- Comandos de admin
- Sistema de estaciones
