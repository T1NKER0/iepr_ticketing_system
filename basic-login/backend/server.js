const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
app.use(express.json());

// Conexión a la base de datos
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'Marcos0206',
    database: 'iepr_ticketing_system'
});

db.connect(err => {
    if (err) {
        console.error('Error al conectar a la base de datos:', err);
        return;
    }
    console.log('Conectado a la base de datos MySQL');
});

// Ruta de ejemplo para Login
app.post('/', (req, res) => {
    const { email, password } = req.body;
    db.query(
        'SELECT * FROM users WHERE email = ? AND password = ?',
        [email, password],
        (err, results) => {
            if (err) {
                res.status(500).json({ error: err });
            } else if (results.length > 0) {
                const user = results[0];
                // Genera un token JWT
                const token = jwt.sign(
                    { user_id: user.user_id, email: user.email }, // Payload
                    'your_secret_key', // Tu clave secreta
                    { expiresIn: '1h' } // Expiración del token
                );

                // Envia la respuesta con el token
                res.json({
                    message: 'Login exitoso',
                    token: token, // Devuelve el token
                    user: user,
                });
            } else {
                res.status(401).json({ message: 'Credenciales incorrectas' });
            }
        }
    );
});

app.listen(3000, () => {
    console.log('Servidor ejecutándose en http://localhost:3000');
});
