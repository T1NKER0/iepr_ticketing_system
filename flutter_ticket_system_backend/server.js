// server.js
require('dotenv').config(); // Import and configure dotenv
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const dbManager = require('./db/dbmanager'); // Import the query manager
const emailjs = require('emailjs-com'); // Make sure to import Email.js
const bodyParser = require('body-parser');
const nodemailer = require('nodemailer');


const app = express();
//IMPLEMENTAR LUEGO ACCESSO DE UN SOLO DOMINIO
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());  // to parse JSON request body

const JWT_SECRET = process.env.JWT_SECRET;

// Route for user login
app.post("/", async (req, res) => {
    try {
        const { signInEmail, accessCredentials } = req.body;

        // Buscar usuario
        const auth = await dbManager.getUser(signInEmail, accessCredentials);
        if (!auth) {
            console.log("Invalid credentials for:", signInEmail);
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const authId = auth[process.env.FIELD_USER_AUTH];
        console.log("User found:", auth);

        // Obtener rol usando async/await
        console.log("Ejecutando getRoleByUserId con authId:", authId);
        const roleResult = await dbManager.getRoleByUserId(signInEmail);
        console.log("Resultado de getRoleByUserId:", roleResult);

        if (!roleResult) {
            console.log("No role assigned for user:", authId);
            return res.status(400).json({ message: "No roles assigned" });
        }

        const permissionId = roleResult[process.env.FIELD_ROLE_ASSIGNED];
        console.log(`Role found for user ${authId}:`, permissionId);

        const permissions = { 1: "main", 3: "top" };
        const permission = permissions[permissionId] || "unknown";

        console.log(`Mapped role for user ${authId}:`, permission);

        let flag = await dbManager.getUserLogin(signInEmail);
        console.log('User login flag: ' + flag);

        if (flag == true)
        {
            //dbManager.insertLoginRecord(authID);
        }
        // Generar JWT
        const token = jwt.sign(
            { authId, permission },
            process.env.JWT_SECRET,
            { expiresIn: "1h" }
        );

        return res.json({
            message: "Login successful",
            access: {
                id: auth[process.env.FIELD_USERNAME],
                unique: auth[process.env.FIELD_EMAIL],
                accessedBy: auth[process.env.FIELD_EMAIL],
                loginFirst: flag
            },
            permission: permission,
            token: token,
        });
    } catch (err) {
        console.error("Error during authentication:", err);
        return res.status(500).json({ error: "Server error" });
    }
});

app.post('/requests', async (req, res) => {
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

        // Crear el ticket
        const result = await dbManager.createTicket(subject, request, uniqueId);

        // Configurar el transporter de Nodemailer
        const transporter = nodemailer.createTransport({
            service: 'gmail', // o el servicio que utilices
            auth: {
                user: 'marcos.santana@estadisticas.pr', // Tu correo
                pass: 'aaaz rywz hhct lldo', // Tu contraseña de correo o contraseña de aplicación
            },
            logger: true, // Enable logging
    debug: true // Enable debug output
        });

        // Configurar el email
        const mailOptions = {
            from: 'marcos.santana@estadisticas.pr', // Tu correo
            to: ['marcos.santana@estadisticas.pr', 'suat.giray@estadisticas.pr'], // Correo del destinatario (usuario)
            subject: subject, // Asunto del ticket
            text: request + "\n\n This request was sent by user: " + uniqueId, // Descripción del ticket
        };

        // Enviar el correo
        transporter.sendMail(mailOptions, (error, info) => {
            if (error) {
                console.log('Error al enviar el correo:', error);
            } else {
                console.log('Correo enviado: ' + info.response);
            }
        });

        // Responder con éxito
        return res.status(200).json({
            message: 'Ticket created successfully',
            [process.env.FIELD_TICKET]: result.insertId,
        });

    } catch (err) {
        console.error('Error:', err);
        return res.status(500).json({ message: err.message || 'Error creating ticket' });
    }
});

// Route to get a specific ticket by ID
app.get('/request/:id', async (req, res) => {
    const ticketId = req.params.id;
    const token = req.headers['authorization'];
  
    if (!token) {
      return res.status(401).json({ message: 'No authentication token provided' });
    }
  
    try {
      // Verify the token
      const decoded = await new Promise((resolve, reject) => {
        jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
          if (err) reject('Invalid token');
          resolve(decoded);
        });
      });
  
      // Get the ticket details
      const result = await dbManager.getTicketById(ticketId);
      return res.status(200).json({ request: result });
    } catch (err) {
      console.error("Error fetching ticket:", err);
      return res.status(500).json({ message: 'Error fetching ticket details' });
    }
  });
  

  app.post('/assign-request', async (req, res) => {
    const { requestId, authId } = req.body;
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verificar token
        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
                if (err) reject('Invalid token');
                resolve(decoded);
            });
        });
        const adminEmail = authId;  // Make sure to get the admin's email from your DB
        console.log("Admin Email:", adminEmail);
        // Asignar ticket
        const result = await dbManager.assignTicket(requestId, authId);
        
        // Configurar el transporter de Nodemailer
        const transporter = nodemailer.createTransport({
            service: 'gmail', // or other service
            auth: {
                user: 'marcos.santana@estadisticas.pr', // Tu correo
                pass: 'aaaz rywz hhct lldo', // Tu contraseña de correo o contraseña de aplicación
            },
            logger: true, // Enable logging
            debug: true // Enable debug output
        });

        const name = await dbManager.getTicketNameById(requestId);

        // Configurar el email
        const mailOptions = {
            from: 'marcos.santana@estadisticas.pr', // Your email
            to: adminEmail, // Admin's email
            //to: 'marcos.santana@estadisticas.pr',
            subject: `Ticket: ${name} has been Assigned`, // Subject of the email
            text: `The ticket with subject ${name} has been assigned to you. Login to the ticketing system to view details.`, // Message content
        };

        // Enviar el email
        try {
            await transporter.sendMail(mailOptions);
            console.log('Email sent to admin successfully');
        } catch (emailError) {
            console.error('Error sending email:', emailError);
            // You can still proceed without email but log the error
        }

        return res.status(200).json(result); // Respond with the result of the ticket assignment
    } catch (err) {
        console.error("Error assigning ticket:", err);
        return res.status(500).json({ message: err.message || "Error assigning ticket" });
    }
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

// Route to delete a user by username
app.delete('/delete-user/:target', async (req, res) => {
    const {  target } = req.params;
    const token = req.headers['authorization'];

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verifying the token
        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
                if (err) reject('Invalid token');
                resolve(decoded);
            });
        });

        // Call the delete method from dbManager
        const result = await dbManager.deleteUserByUsername(target);

        console.log("Target: " + target);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        return res.status(200).json({ message: 'User deleted successfully' });

    } catch (err) {
        console.error("Error deleting user:", err);
        return res.status(500).json({ message: 'Error deleting user' });
    }
});

app.put('/reset-password/:target', async (req, res) => { // 🔄 Cambia DELETE por PUT (mejor práctica)
    const { target, newCredentials } = req.body; // La nueva contraseña debe venir en el cuerpo

    if (!newCredentials) {
        return res.status(400).json({ message: 'New password is required' });
    }

    const token = req.headers['authorization'];
    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verifying the token
        const decoded = jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);

        // Call the method to change password
        const result = await dbManager.changePassword(target, newCredentials);
        dbManager.deleteLogin(target);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        return res.status(200).json({ message: 'Password updated successfully' });

    } catch (err) {
        console.error("Error resetting password:", err);
        return res.status(500).json({ message: 'Error resetting password' });
    }
});

app.put('/update-password/:target', async (req, res) => { // 🔄 Cambia DELETE por PUT (mejor práctica)
    //const { target, newCredentials } = req.body; // La nueva contraseña debe venir en el cuerpo
    const target = req.params.target; // Extract target from URL params
    const { newCredentials } = req.body; // Get new password from the body


    if (!newCredentials) {
        return res.status(400).json({ message: 'New password is required' });
    }

    const token = req.headers['authorization'];
    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verifying the token
        const decoded = jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);

        // Call the method to change password
        const result = await dbManager.changePassword(target, newCredentials);
        dbManager.insertLoginRecord(target);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        return res.status(200).json({ message: 'Password updated successfully' });

    } catch (err) {
        console.error("Error resetting password:", err);
        return res.status(500).json({ message: 'Error resetting password' });
    }
});

// Route to get all users
app.get('/admins', async (req, res) => {
    try {
        // Get all users asynchronously using the getAllUsers function
        const admins = await dbManager.getAllAdmins();

        // Return the results in the response
        return res.status(200).json({ admins: admins });
    } catch (err) {
        // If an error occurs, send an error response
        console.error('Error fetching users:', err);
        return res.status(500).json({ message: 'Error fetching users' });
    }
});

app.get('/my-requests', async (req, res) => {
    try {
        const authId = req.query.email; // Get user_id from query parameter

        if (!authId) {
            return res.status(400).json({ message: "User ID is required" });
        }

        const tickets = await dbManager.getMyTickets(authId);
        return res.status(200).json({ tickets: tickets });
    } catch (err) {
        console.error('Error fetching tickets:', err);
        return res.status(500).json({ message: 'Error fetching tickets' });
    }
});

// Route to update the priority of a ticket
app.put('/update-request-urgent', async (req, res) => {
    const { requestId, urgent } = req.body;
    const token = req.headers['authorization'];

    // Validation checks
    if (!requestId || !urgent) {
        return res.status(400).json({ message: 'Ticket ID and priority are required.' });
    }

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verify the token
        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
                if (err) reject('Invalid token');
                resolve(decoded);
            });
        });

        // Log requestId and urgency for debugging
        console.log(`Received request to update ticket ID: ${requestId} with urgency: ${urgent}`);

        // Update the ticket priority in the database
        const result = await dbManager.updateTicketPriority(requestId, urgent);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Ticket not found' });
        }

        return res.status(200).json({ message: 'Ticket priority updated successfully' });
    } catch (err) {
        console.error("Error updating ticket priority:", err);
        return res.status(500).json({ message: 'Error updating ticket priority' });
    }
});

// Route to update the priority of a ticket
app.put('/update-request-state', async (req, res) => {
    const { requestId, state } = req.body;
    const token = req.headers['authorization'];

    // Validation checks
    if (!requestId || !state) {
        return res.status(400).json({ message: 'Ticket ID and state are required.' });
    }

    if (!token) {
        return res.status(401).json({ message: 'No authentication token provided' });
    }

    try {
        // Verify the token
        const decoded = await new Promise((resolve, reject) => {
            jwt.verify(token.replace('Bearer ', ''), JWT_SECRET, (err, decoded) => {
                if (err) reject('Invalid token');
                resolve(decoded);
            });
        });

        // Log requestId and urgency for debugging
        console.log(`Received request to update ticket ID: ${requestId} with state: ${state}`);

        // Update the ticket priority in the database
        const result = await dbManager.updateTicketStatus(requestId, state);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Ticket not found' });
        }

        return res.status(200).json({ message: 'Ticket status updated successfully' });
    } catch (err) {
        console.error("Error updating ticket status:", err);
        return res.status(500).json({ message: 'Error updating ticket status' });
    }
});

// Route to get all users
app.get('/targets', async (req, res) => {
    try {
        // Get all users asynchronously using the getAllUsers function
        const targets = await dbManager.getAllUsers();

        // Return the results in the response
        return res.status(200).json({ targets: targets });
    } catch (err) {
        // If an error occurs, send an error response
        console.error('Error fetching users:', err);
        return res.status(500).json({ message: 'Error fetching users' });
    }
});

// Endpoint to assign a ticket to a user
app.post('/assign-ticket', async (req, res) => {
    const { ticketId, email } = req.body;
  
    if (!ticketId || !email) {
      return res.status(400).json({ message: 'Ticket ID and User ID are required.' });
    }
  
    try {
      // Assign the ticket
      const result = await dbManager.assignTicket(ticketId, email);
      res.status(200).json(result);
    } catch (error) {
      res.status(500).json({ message: 'Error assigning ticket.', error: error.message });
    }
  }); 

  

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});