/**
 * Endpoint Node.js/Express para envío de emails usando SendGrid
 * Este endpoint se ejecuta desde manigrab.app con IP estática
 * 
 * Uso: POST https://manigrab.app/api/send-email
 * 
 * Headers:
 *   Authorization: Bearer [EMAIL_SERVER_SECRET]
 *   Content-Type: application/json
 * 
 * Body:
 * {
 *   "to": "email@ejemplo.com",
 *   "subject": "Asunto del email",
 *   "html": "<html>...</html>",
 *   "text": "Texto plano (opcional)"
 * }
 */

const express = require('express');
const fetch = require('node-fetch'); // o usar axios

const app = express();
app.use(express.json());

// Middleware CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Authorization, Content-Type');
  
  if (req.method === 'OPTIONS') {
    return res.status(204).send();
  }
  next();
});

// Middleware de autenticación
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  const expectedSecret = process.env.EMAIL_SERVER_SECRET;

  if (!expectedSecret) {
    return res.status(500).json({ 
      error: 'Server configuration error: EMAIL_SERVER_SECRET not set' 
    });
  }

  if (token !== expectedSecret) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  next();
};

// Endpoint para enviar email
app.post('/api/send-email', authenticate, async (req, res) => {
  try {
    const { to, subject, html, text } = req.body;

    // Validar campos requeridos
    if (!to || !subject || !html) {
      return res.status(400).json({ 
        error: 'Missing required fields: to, subject, html' 
      });
    }

    // Obtener configuración de SendGrid
    const sendgridApiKey = process.env.SENDGRID_API_KEY;
    const fromEmail = process.env.SENDGRID_FROM_EMAIL || 'hola@em6490.manigrab.app';
    const fromName = process.env.SENDGRID_FROM_NAME || 'ManiGrab';

    if (!sendgridApiKey) {
      return res.status(500).json({ 
        error: 'Server configuration error: SENDGRID_API_KEY not set' 
      });
    }

    // Preparar email para SendGrid
    const emailData = {
      personalizations: [{
        to: [{ email: to }],
        subject: subject
      }],
      from: {
        email: fromEmail,
        name: fromName
      },
      content: [
        {
          type: 'text/html',
          value: html
        }
      ]
    };

    // Agregar texto plano si está disponible
    if (text) {
      emailData.content.push({
        type: 'text/plain',
        value: text
      });
    }

    // Enviar email usando SendGrid
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sendgridApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(emailData)
    });

    const responseText = await response.text();
    let responseData;
    
    try {
      responseData = JSON.parse(responseText);
    } catch (e) {
      responseData = { raw: responseText };
    }

    if (response.ok) {
      return res.status(200).json({
        success: true,
        message: 'Email sent successfully'
      });
    } else {
      return res.status(response.status).json({
        error: 'SendGrid error',
        details: responseData
      });
    }
  } catch (error) {
    console.error('Error sending email:', error);
    return res.status(500).json({
      error: 'Internal server error',
      details: error.message
    });
  }
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Email endpoint server running on port ${PORT}`);
});

module.exports = app;

