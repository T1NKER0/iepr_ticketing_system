// server.js
require('dotenv').config(); // Import and configure dotenv
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const dbManager = require('./db/dbmanager'); // Import the query manager

const app = express();
app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET;

// Route for user login
app.post("/", async (req, res) => {
    try {
        const { signInEmail, accessCredentials } = req.body;

        // Buscar usuario
        const user = await dbManager.getUser(signInEmail, accessCredentials);
        if (!user) {
            console.log("Invalid credentials for:", signInEmail);
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const authId = user[process.env.FIELD_USER_AUTH];
        console.log("User found:", user);

        // Obtener rol usando async/await
        console.log("Ejecutando getRoleByUserId con authId:", authId);
        const roleResult = await dbManager.getRoleByUserId(authId);
        console.log("Resultado de getRoleByUserId:", roleResult);

        if (!roleResult) {
            console.log("No role assigned for user:", authId);
            return res.status(400).json({ message: "No roles assigned" });
        }

        const permissionId = roleResult[process.env.FIELD_ROLE_ASSIGNED];
        console.log(`Role found for user ${authId}:`, permissionId);

        const permissions = { 1: "1" };
        const permission = permissions[permissionId] || "unknown";

        console.log(`Mapped role for user ${authId}:`, permission);

        // Generar JWT
        const token = jwt.sign(
            { authId, permission },
            process.env.JWT_SECRET,
            { expiresIn: "1h" }
        );

        return res.json({
            message: "Login successful",
            access: {
                id: user[process.env.FIELD_USERNAME],
                unique: user[process.env.FIELD_USER_AUTH],
                accessedBy: user[process.env.FIELD_EMAIL],
            },
            permission: permission,
            token: token,
        });
    } catch (err) {
        console.error("Error during authentication:", err);
        return res.status(500).json({ error: "Server error" });
    }
});



// Route to create a ticket
app.post('/tickets', async (req, res) => {
    const { subject, request, uniqueId } = req.body;
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verificación del token usando jwt.verify
        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
                if (err) reject('Invalid token');
                resolve(decoded);
            });
        });

        // Usar decoded.uniqueId si es necesario para más validaciones o lógica

        // Crear el ticket de forma asíncrona
        const result = await dbManager.createTicket(subject, request, uniqueId);

        // Responder con éxito y enviar el id del ticket
        return res.status(200).json({
            message: 'Ticket created successfully',
            [process.env.FIELD_TICKET]: result.insertId,
        });
    } catch (err) {
        // Si hubo un error en la verificación del token o al crear el ticket
        console.error('Error:', err);
        return res.status(500).json({ message: err.message || 'Error creating ticket' });
    }
});


// Route to get a specific ticket by ID
app.get('/open-tickets', (req, res) => {
    const ticketId = req.params.id;
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).json({ message: 'Invalid token' });
        }

        const userId = decoded.userId;

        dbManager.getTicketById(ticketId, userId, decoded.role, (err, result) => {
            if (err) {
                console.error('Error fetching ticket:', err);
                return res.status(500).json({ message: 'Error fetching ticket' });
            }

            if (result.length === 0) {
                return res.status(404).json({ message: 'Ticket not found' });
            }

            res.status(200).json({ ticket: result[0] });
        });
    });
});



// Route to get all roles
app.get('/permissions', async (req, res) => {
    try {
        // Obtener los roles de forma asíncrona usando la función getRoles
        const results = await dbManager.getRoles();

        // Enviar la respuesta con los resultados
        return res.status(200).json({ permissions: results });
    } catch (err) {
        // Si ocurre un error, enviamos una respuesta de error
        console.error('Error fetching roles:', err);
        return res.status(500).json({ message: 'Error fetching roles' });
    }
});

// Route to get all tickets
app.get('/requests', async (req, res) => {
    try {
        // Obtener los  de forma asíncrona usando la función getRoles
        const results = await dbManager.getTickets();

        // Enviar la respuesta con los resultados
        return res.status(200).json({ tickets: results });
    } catch (err) {
        // Si ocurre un error, enviamos una respuesta de error
        console.error('Error fetching tickets:', err);
        return res.status(500).json({ message: 'Error fetching tickets' });
    }
});


// Route to create a new user with a role
app.post('/add-user', async (req, res) => {
    const { id, nameOfUser, accessEmail, accessCredentials, permission } = req.body;
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        const decoded = await jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);

        // Usamos el método createUserWithRole de manera asíncrona
        await dbManager.createUserWithRole(id, nameOfUser, accessEmail, accessCredentials, permission);

        return res.status(201).json({ message: 'User created successfully' });
    } catch (err) {
        console.error('Error creating user:', err);
        if (err.name === 'JsonWebTokenError') {
            return res.status(401).json({ message: 'Invalid token' });
        }
        return res.status(500).json({ message: 'Error creating user' });
    }
});




// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});