require('dotenv').config(); // Import and configure dotenv
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const crypto = require("crypto");

// Connect to the database using environment variables
const db = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});


/* Connect to the database
db.connect(err => {
    if (err) {
        console.error('Error connecting to the database:', err);
        return;
    }
    console.log('Connected to the MySQL database');
}); */

// Helper function to replace '@' with '?' in queries from .env
const prepareQuery = (query) => query.replace(/@/g, '?');

// Function to find user by email and password
const getUser = async (signInEmail, accessCredentials) => {
    try {
        // Usar prepareQuery para evitar SQL Injection
        const query = prepareQuery(process.env.VERIFY_CREDENTIALS);

        console.log("Query a ejecutar:", query);
        console.log("Parámetros:", [signInEmail]);

        const [rows] = await db.query(query, [signInEmail]);

        if (rows.length === 0) {
            throw new Error("Usuario no encontrado");
        }

        const auth = rows[0];

        // Obtener el hash de la contraseña almacenada
        const storedPasswordHash = auth[process.env.CREDENTIALS];

        // Aplicar la misma lógica de hash que se usa en createUser
        const hash = signInEmail + accessCredentials;
        const hashedInputPassword = crypto.createHash("sha256").update(hash).digest("hex");

        console.log("Ingresada (hash):", hashedInputPassword);
        console.log("Almacenada:", storedPasswordHash);

        // Comparar hashes directamente
        if (hashedInputPassword !== storedPasswordHash) {
            throw new Error("Credenciales incorrectas");
        }

        return auth; // Usuario autenticado exitosamente
    } catch (err) {
        throw err;
    }
};


// Function to get the role assigned to the user
const getRoleByUserId = async (authId) => {
    try {
        const query = prepareQuery(process.env.GET_PERMISSION);
        const [rows] = await db.query(query, [authId]);

        if (rows.length === 0) {
            return null; // Usuario sin rol asignado
        }

        return rows[0]; // Devuelve el primer rol encontrado
    } catch (err) {
        console.error("Error en getRoleByUserId:", err);
        throw err; // Lanza el error para ser manejado por la ruta
    }
};


// Función para obtener el username a partir del user_id
const getUsernameById = async (userId) => {
    try {
        const query = process.env.GET_USER;
        const [rows] = await db.query(query, [userId]);

        if (rows.length === 0) {
            throw new Error("Usuario no encontrado");
        }

        return rows[0].username;
    } catch (err) {
        console.error("Error obteniendo el username:", err);
        throw err;
    }
};

// Función para crear un nuevo ticket
const createTicket = async (subject, request, uniqueId) => {
    try {
        // Obtener el username del usuario antes de crear el ticket
        const username = await getUsernameById(uniqueId);

        // Preparar el query de inserción
        const query = process.env.INSERT_TICKET;
        
        // Ejecutar la inserción con el username obtenido
        const [result] = await db.query(query, [subject, request, uniqueId, username]);

        return {
            id: result.insertId,
            subject,
            request,
            user_id: uniqueId,
            username,
            priority: 'Baja',
            status: 'Abierto'
        };
    } catch (err) {
        console.error("Error creando ticket:", err);
        throw new Error("Error creando ticket");
    }
};

// Function to assign a ticket to a user
const assignTicket = async (ticketId, userId) => {
    try {
        const query = prepareQuery(process.env.ASSIGN_TICKET);
        const [result] = await db.query(query, [ticketId, userId]);

        if (result.affectedRows === 0) {
            throw new Error("No se pudo asignar el ticket");
        }

        return { message: "Ticket asignado con éxito" };
    } catch (err) {
        console.error("Error asignando ticket:", err);
        throw new Error("Error asignando ticket");
    }
};

// Function to create a new user and assign a role
const createUserWithRole = async (id, nameOfUser, signInEmail, plainPassword, permission) => {
    const connection = await db.getConnection();  // Obtener una conexión
    try {
        // Iniciar la transacción
        await connection.beginTransaction();

        // Crear un hash de la contraseña usando SHA-256 (sin bcrypt)
        const hash = signInEmail + plainPassword;
        const hashedPassword = crypto.createHash("sha256").update(hash).digest("hex");
        console.log('Hash de la contraseña con SHA-256:', hashedPassword);

        // Insertar usuario con la contraseña hasheada
        const [result] = await connection.query(prepareQuery(process.env.SQL_INSERT_USER), [id, nameOfUser, signInEmail, hashedPassword]);

        const authId = result.insertId;

        // Insertar el rol del usuario
        await connection.query(prepareQuery(process.env.SQL_INSERT_ROLE), [authId, permission]);

        // Confirmar la transacción
        await connection.commit();

        // Retornar éxito
        return { message: "Usuario creado con éxito" };
    } catch (err) {
        // En caso de error, deshacer la transacción
        await connection.rollback();
        throw err;  // Lanza el error para ser manejado fuera de la función
    } finally {
        // Liberar la conexión
        //connection.release();
    }
};



// Función usando promesas para obtener los roles
const getRoles = async () => {
    try {
        const PERMISSION_ID = process.env.PERMISSION_ID;
        const PERMISSION_NAME = process.env.PERMISSION_NAME;

        // Usamos el método de promesas para la consulta
        const [results] = await db.query(prepareQuery(process.env.SQL_GET_ROLES));

        console.log("Raw Results from DB:", results);  // Para depuración

        const mappedResults = results.map(permission => ({
            permissionId: permission[PERMISSION_ID],  // Mapeo dinámico
            permissionName: permission[PERMISSION_NAME]
        }));

        console.log("Mapped Permissions:", mappedResults);  // Para depuración

        return mappedResults;  // Devuelve los resultados
    } catch (error) {
        console.error("Error fetching roles:", error);
        throw error;  // Lanzamos el error para manejarlo más arriba si es necesario
    }
};

 // Function to get a specific ticket by ID and user authorization
 const getTicketById = async (ticketId) => {
    try {
      console.log(`Fetching ticket details for ticket ID: ${ticketId}`);  // Print the ticketId being queried
      
      const query = prepareQuery(process.env.SQL_GET_TICKET_BY_ID);
      console.log(`Prepared SQL query: ${query}`);  // Print the prepared query for debugging
      
      const [rows] = await db.query(query, [ticketId]);
      console.log(`Query result: ${JSON.stringify(rows)}`);  // Print the result of the query
      
      if (rows.length === 0) {
        console.error("Ticket not found or unauthorized access");
        throw new Error("Ticket not found or unauthorized access");
      }
  
      console.log(`Ticket found: ${JSON.stringify(rows[0])}`);  // Print the ticket details found in the database
      return rows[0]; // Return the first ticket found
    } catch (err) {
      console.error("Error fetching ticket by ID:", err);
      throw err; // Re-throw the error for handling in server.js
    }
  };
  

const getTickets = async () => {
    try {
        const REQUEST_PRIORITY = process.env.REQUEST_PRIORITY;
        const REQUEST_TITLE = process.env.REQUEST_TITLE;
        const REQUEST_ORIGIN = process.env.REQUEST_ORIGIN;
        const REQUEST_ID = process.env.REQUEST_ID;

        // Usamos el método de promesas para la consulta
        const [results] = await db.query(prepareQuery(process.env.SQL_GET_TICKETS_ADMIN));

        console.log("Raw Results from DB:", results);  // Para depuración

        const mappedResults = results.map(ticket => ({
              // Mapeo dinámico

            subject: ticket[REQUEST_TITLE],
            urgent: ticket[REQUEST_PRIORITY],
            origin: ticket[REQUEST_ORIGIN],
            id: ticket[REQUEST_ID]
        }));

        console.log("Tickets:", mappedResults);  // Para depuración

        return mappedResults;  // Devuelve los resultados
    } catch (error) {
        console.error("Error fetching tickets:", error);
        throw error;  // Lanzamos el error para manejarlo más arriba si es necesario
    }

  
};

  module.exports = {
    getUser,
    getRoleByUserId,
    createTicket,
    getTickets,
    getTicketById,
    createUserWithRole,
    getRoles,
    assignTicket,
    getTicketById, // ✅ Agregado aquí
};
