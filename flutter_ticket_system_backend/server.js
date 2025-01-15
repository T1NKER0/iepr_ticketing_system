require('dotenv').config(); // Importar y configurar dotenv
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

// Clave secreta para firmar el token JWT
const JWT_SECRET = process.env.JWT_SECRET;

// Conexión a la base de datos usando variables de entorno
const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
});

db.connect(err => {
    if (err) {
        console.error('Error al conectar a la base de datos:', err);
        return;
    }
    console.log('Conectado a la base de datos MySQL');
});

// Ruta de inicio de sesión
app.post('/', (req, res) => {
    const { email, password } = req.body;

    // Buscar al usuario por correo y contraseña
    db.query(
        'SELECT * FROM users WHERE email = ? AND password = ?',
        [email, password],
        (err, userResults) => {
            if (err) {
                console.error('Error al consultar usuario:', err);
                return res.status(500).json({ error: 'Error en el servidor' });
            }

            if (userResults.length === 0) {
                console.log('Credenciales incorrectas para:', email);
                return res.status(401).json({ message: 'Credenciales incorrectas' });
            }

            const userId = userResults[0].user_id;
            console.log('Usuario encontrado:', userResults[0]);

            // Buscar el rol asociado en user_roles
            db.query(
                'SELECT role_id FROM user_roles WHERE user_id = ?',
                [userId],
                (err, roleResults) => {
                    if (err) {
                        console.error('Error al consultar roles:', err);
                        return res.status(500).json({ error: 'Error en el servidor' });
                    }

                    if (roleResults.length === 0) {
                        console.log('Rol no asignado para el usuario:', userId);
                        return res.status(400).json({ message: 'El usuario no tiene roles asignados' });
                    }

                    const roleId = roleResults[0].role_id;
                    console.log(`Rol encontrado para el usuario ${userId}:`, roleId);

                    // Mapeo de roles
                    const roles = { 1: '1' }; // Mapa de roles
                    const role = roles[roleId] || 'unknown';

                    console.log(`Rol mapeado para el usuario ${userId}:`, role);

                    // Generar el token JWT
                    const token = jwt.sign(
                        { userId, role }, // Datos del usuario a incluir en el token
                        JWT_SECRET,       // Clave secreta
                        { expiresIn: '1h' } // Expiración del token
                    );

                    // Respuesta final con el token y los datos del usuario
                    return res.json({
                        message: 'Login exitoso',
                        user: {
                            user_id: userResults[0].user_id,
                            username: userResults[0].username,
                            name: userResults[0].name,
                            email: userResults[0].email,
                        },
                        role: role,
                        token: token, // Incluir el token en la respuesta
                    });
                }
            );
        }
    );
});

// Iniciar el servidor
const PORT = process.env.PORT || 3000; // Usar puerto de las variables de entorno o por defecto 3000
app.listen(PORT, () => {
    console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
