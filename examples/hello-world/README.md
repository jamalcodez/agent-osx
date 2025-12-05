# Hello World Example

This example demonstrates the complete Agent OS workflow by building a simple "Hello World" feature. It's perfect for understanding how Agent OS works from start to finish.

## What We'll Build

A simple web page that:
1. Displays "Hello, World!" as a heading
2. Has a button that changes the greeting when clicked
3. Includes basic styling

## Prerequisites

- Agent OS installed in your project
- An AI coding tool (Claude Code, Cursor, etc.)

## Step-by-Step Workflow

### 1. Shape the Specification

Start the specification process:

```bash
# In Claude Code
/shape-spec
```

When prompted, describe your feature:

> "I want to create a simple web page with a 'Hello, World!' heading and a button that cycles through different greetings when clicked. The page should be styled with a clean, modern look."

Agent OS will ask clarifying questions about:
- What greetings to cycle through
- Styling preferences
- Whether to use a framework or vanilla JavaScript
- Browser compatibility requirements

### 2. Write the Technical Specification

Once requirements are gathered, create the technical specification:

```bash
/write-spec
```

This will produce a detailed spec including:
- HTML structure
- CSS styling requirements
- JavaScript functionality
- File organization

### 3. Create Implementation Tasks

Break the spec into actionable tasks:

```bash
/create-tasks
```

Expected tasks might include:
1. Create HTML file with basic structure
2. Add CSS styling
3. Implement JavaScript greeting logic
4. Test the functionality

### 4. Implement the Feature

Build the feature:

```bash
/implement-tasks
```

The AI will create the files based on the specification and tasks.

### 5. Review the Result

After implementation, you should have:
- `index.html` - The main web page
- `style.css` - Styling for the page
- `script.js` - Interactive functionality

Open `index.html` in your browser to see the result!

## Expected Output

### index.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello World</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1 id="greeting">Hello, World!</h1>
        <button id="changeGreeting">Change Greeting</button>
    </div>
    <script src="script.js"></script>
</body>
</html>
```

### style.css
```css
body {
    font-family: Arial, sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    margin: 0;
    background-color: #f0f0f0;
}

.container {
    text-align: center;
    background: white;
    padding: 2rem;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

h1 {
    color: #333;
    margin-bottom: 1rem;
}

button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 0.5rem 1rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
}

button:hover {
    background-color: #0056b3;
}
```

### script.js
```javascript
const greetings = [
    "Hello, World!",
    "Hola, Mundo!",
    "Bonjour, le Monde!",
    "Hallo, Welt!",
    "Ciao, Mondo!"
];

let currentIndex = 0;

document.getElementById('changeGreeting').addEventListener('click', () => {
    currentIndex = (currentIndex + 1) % greetings.length;
    document.getElementById('greeting').textContent = greetings[currentIndex];
});
```

## What You Learned

Through this simple example, you've experienced:
1. **Specification gathering** - How Agent OS helps clarify requirements
2. **Technical planning** - Translating requirements into implementation details
3. **Task breakdown** - Organizing work into manageable steps
4. **Implementation** - Following specifications to build features
5. **Consistency** - How structured workflows lead to predictable results

## Next Steps

Try extending this example:
- Add more greetings
- Include animations
- Add a counter for clicks
- Style it for mobile devices

Each extension is an opportunity to practice the Agent OS workflow!

## Troubleshooting

If something doesn't work:
1. Check that all files are created
2. Verify file names match exactly
3. Ensure the script tag points to the correct JavaScript file
4. Open browser developer tools to check for errors

Remember: The power of Agent OS is in the process, not just the code. Following the structured workflow ensures quality and consistency, even for simple projects.