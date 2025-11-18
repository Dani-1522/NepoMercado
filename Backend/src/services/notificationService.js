const axios = require('axios');

class WhatsAppService {
  constructor() {
    this.baseURL = 'https://graph.facebook.com/v18.0';
    this.accessToken = process.env.WHATSAPP_ACCESS_TOKEN;
    this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
    
    // Validar que tenemos la configuración necesaria
    if (!this.accessToken || !this.phoneNumberId) {
      console.warn('⚠️  WhatsApp Cloud API no configurado completamente');
      console.warn('   Configura WHATSAPP_ACCESS_TOKEN y WHATSAPP_PHONE_NUMBER_ID en .env');
    }
  }

  async sendMessage(phone, message) {
    try {
      // Validar configuración
      if (!this.accessToken || !this.phoneNumberId) {
        throw new Error('WhatsApp Cloud API no configurado. Revisa las variables de entorno.');
      }

      // Formatear número de teléfono
      const formattedPhone = this.formatPhoneNumber(phone);
      console.log(`📤 Enviando WhatsApp a: ${formattedPhone}`);
      
      const url = `${this.baseURL}/${this.phoneNumberId}/messages`;
      
      const payload = {
        messaging_product: 'whatsapp',
        to: formattedPhone,
        type: 'text',
        text: {
          body: message
        }
      };

      console.log('🔧 Payload WhatsApp:', JSON.stringify(payload, null, 2));

      const response = await axios.post(url, payload, {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        },
        timeout: 10000 // 10 segundos timeout
      });

      console.log(`✅ WhatsApp enviado exitosamente a ${formattedPhone}`);
      console.log(`   Message ID: ${response.data?.messages?.[0]?.id}`);
      return true;

    } catch (error) {
      console.error('❌ ERROR enviando WhatsApp:');
      
      if (error.response) {
        // Error de la API de Facebook
        console.error('   Status:', error.response.status);
        console.error('   Data:', JSON.stringify(error.response.data, null, 2));
        
        const errorMessage = error.response.data?.error?.message || 'Error desconocido';
        throw new Error(`WhatsApp API Error: ${errorMessage}`);
      } else if (error.request) {
        // Error de red
        console.error('   No se recibió respuesta del servidor');
        throw new Error('Error de conexión con WhatsApp API');
      } else {
        // Error de configuración
        console.error('   Error:', error.message);
        throw error;
      }
    }
  }

  // Formatear número de teléfono
  formatPhoneNumber(phone) {
    try {
      // Eliminar todo excepto números y +
      let cleaned = phone.replace(/[^\d+]/g, '');
      
      // Si no tiene código país, agregar +57 (colombia) por defecto
      if (!cleaned.startsWith('+')) {
        // Asumir que es un número mexicano
        if (cleaned.length === 10) {
          cleaned = '+57' + cleaned;
        } else {
          throw new Error('Formato de teléfono inválido. Use formato: +573014234567');
        }
      }
      
      // Validar longitud mínima
      if (cleaned.length < 10) {
        throw new Error('Número de teléfono demasiado corto');
      }
      
      return cleaned;
    } catch (error) {
      throw new Error(`Error formateando teléfono: ${error.message}`);
    }
  }

  // Método para enviar mensaje de plantilla (para códigos de verificación)
  async sendTemplateMessage(phone, templateName, parameters = []) {
    try {
      const formattedPhone = this.formatPhoneNumber(phone);
      
      const url = `${this.baseURL}/${this.phoneNumberId}/messages`;
      
      const payload = {
        messaging_product: 'whatsapp',
        to: formattedPhone,
        type: 'template',
        template: {
          name: templateName,
          language: {
            code: 'es'
          },
          components: parameters.length > 0 ? [
            {
              type: 'body',
              parameters: parameters.map(param => ({
                type: 'text',
                text: param
              }))
            }
          ] : undefined
        }
      };

      const response = await axios.post(url, payload, {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`✅ Plantilla WhatsApp enviada a ${formattedPhone}`);
      return true;

    } catch (error) {
      console.error('❌ Error enviando plantilla WhatsApp:', error.response?.data || error.message);
      throw error;
    }
  }
}

// Crear instancia única
const whatsappService = new WhatsAppService();

// Servicio de SMS (mantener por compatibilidad)
const sendSMS = async (phone, message) => {
  console.log('📱 SMS SIMULADO:');
  console.log(`   Para: ${phone}`);
  console.log(`   Mensaje: ${message}`);
  return true;
};

module.exports = { 
  sendSMS, 
  sendWhatsApp: whatsappService.sendMessage.bind(whatsappService),
  sendWhatsAppTemplate: whatsappService.sendTemplateMessage.bind(whatsappService)
};