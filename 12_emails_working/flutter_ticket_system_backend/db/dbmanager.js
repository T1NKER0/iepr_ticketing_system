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

// Function to find user by email and password
const getUserLogin = async (authID) => {
    try {
        // Usar prepareQuery para evitar SQL Injection
        const query = prepareQuery(process.env.GET_LOGIN);
        let flag = false;

        console.log("Query a ejecutar:", query);
        console.log("Parámetros:", [authID]);

        const [rows] = await db.query(query, [authID]);

        if (rows.length === 0) {
            console.log("Es es el primer login");
            flag = true;
        }

        const auth = rows[0];

        return flag; // Usuario autenticado exitosamente
    } catch (err) {
        throw err;
    }
};

// Function to get all users
const getAllAdmins = async () => {
    try {
        // Prepare the SQL query using the one from the .env
        const query = process.env.GET_ALL_ADMINS;

        // Execute the query
        const [rows] = await db.query(query);

        if (rows.length === 0) {
            throw new Error("No users found");
        }

        return rows; // Return all the user records found in the database
    } catch (err) {
        console.error("Error fetching all users:", err);
        throw err; // Re-throw the error for handling in server.js
    }
};

const getMyTickets = async (authId) => {
    try {
        const REQUEST_TITLE = process.env.REQUEST_TITLE;
        const REQUEST_PRIORITY = process.env.REQUEST_PRIORITY;
        const REQUEST_ORIGIN = process.env.REQUEST_ORIGIN;
        const REQUEST_ID = process.env.REQUEST_ID;

        // Prepare the SQL query using the one from the .env
        const query = process.env.GET_MY_TICKETS;

        // Execute the query with the userId parameter
        const [rows] = await db.query(query, [authId]);

        if (rows.length === 0) {
            throw new Error("No tickets found for the specified user");
        }

        // Map the results dynamically using the environment variables
        const mappedResults = rows.map(ticket => ({
            subject: ticket[REQUEST_TITLE],
            urgent: ticket[REQUEST_PRIORITY],
            origin: ticket[REQUEST_ORIGIN],
            id: ticket[REQUEST_ID]
        }));

        console.log("Mapped Tickets:", mappedResults); // For debugging

        return mappedResults; // Return the mapped tickets
    } catch (err) {
        console.error("Error fetching your tickets:", err);
        throw err; // Re-throw the error for handling in server.js
    }
};

// Function to update the priority of a ticket
const updateTicketPriority = async (ticketId, newPriority) => {
    try {
        const query = prepareQuery(process.env.UPDATE_URGENT); // Use the query from .env
        const [result] = await db.query(query, [newPriority, ticketId]);

        if (result.affectedRows === 0) {
            throw new Error("No ticket found or priority not updated");
        }

        console.log(`Priority updated successfully for ticket ID: ${ticketId}`);
        return { message: `Priority updated to ${newPriority} for ticket ID: ${ticketId}` };
    } catch (err) {
        console.error("Error updating ticket priority:", err);
        throw new Error("Error updating ticket priority");
    }
};

// Function to update the priority of a ticket
const updateTicketStatus = async (ticketId, newStatus) => {
    try {
        const query = prepareQuery(process.env.UPDATE_STATE); // Use the query from .env
        const [result] = await db.query(query, [newStatus, ticketId]);

        if (result.affectedRows === 0) {
            throw new Error("No ticket found or priority not updated");
        }

        console.log(`Status updated successfully for ticket ID: ${ticketId}`);
        return { message: `Status updated to ${newStatus} for ticket ID: ${ticketId}` };
    } catch (err) {
        console.error("Error updating ticket status:", err);
        throw new Error("Error updating ticket status");
    }
};



// Function to get all users (from GET_ALL_USERS in .env)
const getAllUsers = async () => {
    try {
        // Prepare the SQL query from the environment variable
        const query = process.env.GET_ALL_USERS;

        // Execute the query
        const [rows] = await db.query(query);

        if (rows.length === 0) {
            throw new Error("No users found");
        }

        return rows; // Return the rows containing all users
    } catch (err) {
        console.error("Error fetching all users:", err);
        throw err; // Re-throw the error to be handled by server.js
    }
};




// Function to get the role assigned to the user
const getRoleByUserId = async (signInEmail) => {
    try {
        const query = prepareQuery(process.env.GET_PERMISSION);
        const [rows] = await db.query(query, [signInEmail]);

        if (rows.length === 0) {
            return null; // Usuario sin rol asignado
        }

        return rows[0]; // Devuelve el primer rol encontrado
    } catch (err) {
        console.error("Error en getRoleByUserId:", err);
        throw err; // Lanza el error para ser manejado por la ruta
    }
};

// Function to delete a user by username
const deleteUserByUsername = async (username) => {
    try {
        const query = prepareQuery(process.env.DELETE_USER);
        const [result] = await db.query(query, [username]);
        return result;
    } catch (err) {
        throw new Error('Error deleting user: ' + err.message);
    }
};

// Function to delete a user by username
const deleteLogin = async (username) => {
    try {
        const query = prepareQuery(process.env.DELETE_LOGIN);
        const [result] = await db.query(query, [username]);
        return result;
    } catch (err) {
        throw new Error('Error deleting user: ' + err.message);
    }
};

const changePassword = async (signInEmail, newPassword) => {
    try {
        const hash = signInEmail + newPassword;
        const hashedPassword = crypto.createHash("sha256").update(hash).digest("hex");

        // Obtener la consulta desde el .env
        const query = process.env.CHANGE_PASSWORD;

        console.log("Query a ejecutar:", query);
        console.log("Valores:", [hashedPassword, signInEmail]);

        // Ejecutar la consulta con los parámetros correctos
        const [result] = await db.query(query, [hashedPassword, signInEmail]);

        return result;
    } catch (err) {
        throw new Error('Error changing password: ' + err.message);
    }
};



// Función para obtener el username a partir del user_id
const getUsernameById = async (email) => {
    try {
        const query = process.env.GET_USER;
        const [rows] = await db.query(query, [email]);

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
const assignTicket = async (requestId, email) => {
    try {
        const query = prepareQuery(process.env.ASSIGN_TICKET);
        const [result] = await db.query(query, [requestId, email]);

        if (result.affectedRows === 0) {
            throw new Error("No se pudo asignar el ticket");
        }

        return { message: "Ticket asignado con éxito" };
    } catch (err) {
        console.error("Error asignando ticket:", err);
        throw new Error("Error asignando ticket");
    }
};

const insertLoginRecord = async (authId) => {
    try {
        // Prepare the SQL query using the one from the .env
        const query = prepareQuery(process.env.INSERT_LOGIN);

        // Execute the query with the INSERT IGNORE statement to avoid duplicate entries
        const [result] = await db.query(query, [authId]);

        // If no rows were inserted, it indicates a duplicate entry was ignored
        if (result.affectedRows === 0) {
            console.log(`Duplicate entry for user ${authId}. Skipping insertion.`);
            return {
                message: `Login record for user ${authId} already exists. Skipped insertion.`,
            };
        }

        return {
            message: `Login record inserted for user ${authId}`,
            insertId: result.insertId, // You can use this if you want to track the record id
        };
    } catch (err) {
        // Handle and log errors
        console.error("Error inserting login record:", err);

        // Throw a specific error with the message to pass to the caller
        if (err.code === 'ER_DUP_ENTRY') {
            return {
                message: `Duplicate entry for user ${authId}. Skipping insertion.`,
            };
        }

        throw new Error("Error inserting login record");
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
        await connection.query(prepareQuery(process.env.SQL_INSERT_ROLE), [signInEmail, permission]);

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

const getTicketNameById = async (ticketId) => {
    try {
        // Preparar la consulta desde .env
        const query = prepareQuery(process.env.GET_TICKET_NAME);
        
        console.log("Ejecutando consulta:", query);
        console.log("Parámetros:", [ticketId]);

        // Ejecutar la consulta con el ticket_id como parámetro
        const [rows] = await db.query(query, [ticketId]);

        if (rows.length === 0) {
            throw new Error("Ticket no encontrado");
        }

        return rows[0].title; // Devolver el nombre del ticket
    } catch (err) {
        console.error("Error obteniendo el nombre del ticket:", err);
        throw err;
    }
};
  module.exports = {
    getUser,
    getAllAdmins,
    getRoleByUserId,
    createTicket,
    getTickets,
    getTicketById,
    createUserWithRole,
    getRoles,
    assignTicket,
    getTicketById, // ✅ Agregado aquí
    insertLoginRecord,
    deleteUserByUsername,
    getAllUsers,
    getMyTickets, 
    updateTicketPriority,
    updateTicketStatus,
    getUserLogin,
    changePassword,
    deleteLogin,
    getTicketNameById
};
