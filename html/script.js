// Global variables
let currentVehicleData = null;
let categories = null;
let flagDefinitions = null;

// Initialize the app
document.addEventListener('DOMContentLoaded', function() {
    // NUI event listener
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.action === 'open') {
            showUI();
            setupUI(data.data);
        }
    });
    
    // Setup navigation
    setupNavigation();
    
    // Setup action buttons
    setupActionButtons();
    
    // Add ESC key listener
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeEditor();
        }
    });
});

// Show the UI
function showUI() {
    const app = document.getElementById('app');
    app.classList.add('visible');
    app.classList.remove('hiding');
}

// Hide the UI with animation
function hideUI() {
    const app = document.getElementById('app');
    app.classList.add('hiding');
    
    // Remove the visible class after animation completes
    setTimeout(() => {
        app.classList.remove('visible');
        app.classList.remove('hiding');
    }, 300); // Match the animation duration in CSS
}

// Setup UI with vehicle data
function setupUI(data) {
    currentVehicleData = data;
    categories = data.categories;
    flagDefinitions = data.flagDefinitions;
    
    // Update car model
    document.getElementById('car-model').textContent = data.model + ' (' + data.hash + ')';
    
    // Apply accent color if provided
    if (data.accent) {
        document.documentElement.style.setProperty('--accent-color', data.accent);
    }
    
    // Generate fields for each category
    for (const [category, fields] of Object.entries(categories)) {
        const container = document.getElementById(category + '-fields');
        container.innerHTML = ''; // Clear previous fields
        
        if (category === 'Flags') {
            setupFlagsUI(container, data.handling);
        } else {
            setupFieldsUI(container, fields, data.handling);
        }
    }
    
    // Show the first category
    showCategory('Dynamics');
}

// Setup regular fields UI
function setupFieldsUI(container, fields, handling) {
    fields.forEach(field => {
        const value = handling[field];
        
        if (typeof value === 'object' && value !== null) {
            // Handle vector values
            const fieldElement = document.createElement('div');
            fieldElement.className = 'field-item';
            fieldElement.innerHTML = `
                <label>${field}</label>
                <div class="vector-labels">
                    <span>X</span>
                    <span>Y</span>
                    <span>Z</span>
                </div>
                <div class="vector-inputs">
                    <input type="number" id="${field}.x" value="${value.x}" step="0.01">
                    <input type="number" id="${field}.y" value="${value.y}" step="0.01">
                    <input type="number" id="${field}.z" value="${value.z}" step="0.01">
                </div>
            `;
            
            // Add event listeners
            const inputs = fieldElement.querySelectorAll('input');
            inputs.forEach(input => {
                input.addEventListener('change', function() {
                    updateHandling(input.id, parseFloat(input.value));
                });
            });
            
            container.appendChild(fieldElement);
        } else {
            // Handle scalar values
            const fieldElement = document.createElement('div');
            fieldElement.className = 'field-item';
            
            // Determine if this is a float or integer
            const isFloat = field.startsWith('f');
            const isFlag = field.endsWith('Flags');
            
            if (isFlag) {
                // If it's a flag value, use a number input
                fieldElement.innerHTML = `
                    <label>${field}</label>
                    <input type="number" id="${field}" value="${value}" min="0">
                    <div class="range-value">${value}</div>
                `;
            } else {
                // Create min/max values and step based on field type
                let min = 0;
                let max = 100;
                let step = 0.01;
                
                // Customize ranges for specific fields
                if (field === 'fMass') {
                    min = 1;
                    max = 10000;
                    step = 50;
                } else if (field === 'fInitialDriveForce') {
                    max = 2;
                    step = 0.01;
                } else if (field === 'fDriveBiasFront') {
                    max = 1;
                    step = 0.01;
                } else if (field === 'fTractionCurveMax') {
                    max = 10;
                    step = 0.1;
                } else if (field.includes('Suspension')) {
                    min = -1;
                    max = 10;
                    step = 0.1;
                } else if (field.includes('Damage')) {
                    max = 10;
                    step = 0.1;
                }
                
                fieldElement.innerHTML = `
                    <label>${field}</label>
                    <input type="range" id="${field}_range" min="${min}" max="${max}" step="${step}" value="${value}">
                    <input type="number" id="${field}" value="${value}" step="${step}">
                `;
                
                // Add event listeners for both range and number inputs
                const rangeInput = fieldElement.querySelector(`#${field}_range`);
                const numberInput = fieldElement.querySelector(`#${field}`);
                
                rangeInput.addEventListener('input', function() {
                    numberInput.value = rangeInput.value;
                    updateHandling(field, parseFloat(rangeInput.value));
                });
                
                numberInput.addEventListener('change', function() {
                    rangeInput.value = numberInput.value;
                    updateHandling(field, parseFloat(numberInput.value));
                });
            }
            
            container.appendChild(fieldElement);
        }
    });
}

// Setup flags UI
function setupFlagsUI(container, handling) {
    // Create flag sections for each flag type
    const flagTypes = {
        'handlingFlags': 'Handling Flags',
        'damageFlags': 'Damage Flags',
        'strModelFlags': 'Model Flags'
    };
    
    for (const [flagField, flagTitle] of Object.entries(flagTypes)) {
        const flagValue = handling[flagField];
        
        const flagSection = document.createElement('div');
        flagSection.className = 'flag-section';
        flagSection.innerHTML = `
            <h3>${flagTitle}</h3>
            <div class="flag-grid" id="${flagField}_grid"></div>
        `;
        
        container.appendChild(flagSection);
        
        // Add flag checkboxes
        const flagGrid = flagSection.querySelector(`#${flagField}_grid`);
        
        // Create 32 checkboxes for each bit
        for (let bit = 0; bit < 32; bit++) {
            const isBitSet = (flagValue & (1 << bit)) !== 0;
            const flagLabel = (flagDefinitions && flagDefinitions[bit]) ? flagDefinitions[bit] : `Bit ${bit}`;
            
            const flagItem = document.createElement('div');
            flagItem.className = 'flag-item';
            flagItem.innerHTML = `
                <input type="checkbox" id="${flagField}_bit_${bit}" ${isBitSet ? 'checked' : ''}>
                <label for="${flagField}_bit_${bit}">${flagLabel}</label>
            `;
            
            // Add event listener for flag toggle
            const checkbox = flagItem.querySelector(`#${flagField}_bit_${bit}`);
            checkbox.addEventListener('change', function() {
                let newValue = handling[flagField];
                
                if (checkbox.checked) {
                    newValue |= (1 << bit);
                } else {
                    newValue &= ~(1 << bit);
                }
                
                updateHandling(flagField, newValue);
            });
            
            flagGrid.appendChild(flagItem);
        }
    }
}

// Setup navigation between categories
function setupNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', function() {
            const category = this.getAttribute('data-category');
            showCategory(category);
        });
    });
}

// Show a specific category
function showCategory(category) {
    // Hide all categories
    document.querySelectorAll('.category-container').forEach(container => {
        container.classList.add('hidden');
    });
    
    // Show the selected category
    document.getElementById(category).classList.remove('hidden');
    
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
        if (item.getAttribute('data-category') === category) {
            item.classList.add('active');
        }
    });
}

// Setup action buttons
function setupActionButtons() {
    // Save button
    document.getElementById('save-btn').addEventListener('click', function() {
        saveHandling();
    });
    
    // Reset button
    document.getElementById('reset-btn').addEventListener('click', function() {
        resetHandling();
    });
    
    // Close button
    document.getElementById('close-btn').addEventListener('click', function() {
        closeEditor();
    });
}

// Helper function to get the parent resource name
function GetParentResourceName() {
    return window.location.href.split('/')[3] || 'niko-carhandlingeditor';
}

// Send handling update to client
function updateHandling(field, value) {
    fetch(`https://${GetParentResourceName()}/update`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            field: field,
            value: value
        })
    });
    
    // Update our local data
    if (field.includes('.')) {
        const [baseField, component] = field.split('.');
        currentVehicleData.handling[baseField][component] = value;
    } else {
        currentVehicleData.handling[field] = value;
    }
}

// Save handling settings
function saveHandling() {
    fetch(`https://${GetParentResourceName()}/save`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            hash: currentVehicleData.hash,
            handling: currentVehicleData.handling
        })
    });
}

// Reset handling to original values
function resetHandling() {
    fetch(`https://${GetParentResourceName()}/reset`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    }).then(() => {
        // UI will be reloaded with updated values
    });
}

// Close the editor
function closeEditor() {
    hideUI();
    
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    });
} 