const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// In-memory data store (for demo purposes)
let users = [
    { id: 1, name: 'John Doe', email: 'john@example.com', active: true },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com', active: true },
    { id: 3, name: 'Bob Johnson', email: 'bob@example.com', active: false }
];

let nextId = 4;

// Routes
app.get('/', (req, res) => {
    res.json({
        message: 'DevOps Demo API',
        version: '1.0.0',
        endpoints: {
            health: '/health',
            users: '/api/users',
            user: '/api/users/:id'
        }
    });
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage()
    });
});

// Get all users
app.get('/api/users', (req, res) => {
    const { active } = req.query;
    let filteredUsers = users;

    if (active !== undefined) {
        const isActive = active === 'true';
        filteredUsers = users.filter(user => user.active === isActive);
    }

    res.json({
        users: filteredUsers,
        count: filteredUsers.length
    });
});

// Get user by ID
app.get('/api/users/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const user = users.find(u => u.id === id);

    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
});

// Create new user
app.post('/api/users', (req, res) => {
    const { name, email } = req.body;

    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email are required' });
    }

    // Check if email already exists
    if (users.find(u => u.email === email)) {
        return res.status(409).json({ error: 'Email already exists' });
    }

    const newUser = {
        id: nextId++,
        name,
        email,
        active: true
    };

    users.push(newUser);
    res.status(201).json(newUser);
});

// Update user
app.put('/api/users/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === id);

    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    const { name, email, active } = req.body;

    if (email && users.find(u => u.email === email && u.id !== id)) {
        return res.status(409).json({ error: 'Email already exists' });
    }

    users[userIndex] = {
        ...users[userIndex],
        ...(name && { name }),
        ...(email && { email }),
        ...(active !== undefined && { active })
    };

    res.json(users[userIndex]);
});

// Delete user
app.delete('/api/users/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const userIndex = users.findIndex(u => u.id === id);

    if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
    }

    users.splice(userIndex, 1);
    res.status(204).send();
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    // express.json() sets err.status=400 / err.type='entity.parse.failed'
    // on malformed JSON — honor it instead of blanket-500ing client errors.
    const status = err.status || err.statusCode || 500;
    const message = status === 400 ? 'Invalid JSON payload' : 'Something went wrong!';
    res.status(status).json({ error: message });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

// Only start a real listener when run directly (`node app.js`).
// Under Jest/supertest, `require('./app')` should just hand back the
// Express app — supertest binds its own ephemeral port per request,
// so listening here would race tests and cause EADDRINUSE.
if (require.main === module) {
    const server = app.listen(port, () => {
        console.log(`DevOps Demo API running on port ${port}`);
    });

    process.on('SIGTERM', () => {
        console.log('SIGTERM received, shutting down gracefully');
        server.close(() => {
            console.log('Process terminated');
        });
    });
}

module.exports = app;
