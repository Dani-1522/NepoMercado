const axios = require('axios');

// Servicio para enviar notificaciones por WhatsApp Cloud API
class WhatsAppService {
  constructor() {
    this.baseURL = 'https://graph.facebook.com/v18.0';
    this.accessToken = process.env.WHATSAPP_ACCESS_TOKEN;
    this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
  }

  async sendMessage(phone, message) {
    try {
      // Validar configuración
      if (!this.accessToken || !this.phoneNumberId) {
        console.log('💬 WHATSAPP CLOUD API - Configuración faltante:');
        console.log('   ⚠️  Configura WHATSAPP_ACCESS_TOKEN y WHATSAPP_PHONE_NUMBER_ID en .env');
        console.log(`   Mensaje simulado para ${phone}: ${message}`);
        return true;
      }

      // Formatear número (eliminar caracteres no numéricos y agregar código país)
      const formattedPhone = this.formatPhoneNumber(phone);
      
      const url = `${this.baseURL}/${this.phoneNumberId}/messages`;
      
      const payload = {
        messaging_product: 'whatsapp',
        to: formattedPhone,
        type: 'text',
        text: {
          body: message
        }
      };

      const response = await axios.post(url, payload, {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`💬 WhatsApp enviado a ${formattedPhone}`);
      console.log(`   Message ID: ${response.data.messages[0].id}`);
      return true;

    } catch (error) {
      console.error('❌ Error enviando WhatsApp:', error.response?.data || error.message);
      
      // En desarrollo, simular éxito
      if (process.env.NODE_ENV === 'development') {
        console.log('💬 WHATSAPP SIMULADO (modo desarrollo):');
        console.log(`   Para: ${phone}`);
        console.log(`   Mensaje: ${message}`);
        return true;
      }
      
      throw new Error(`Error enviando WhatsApp: ${error.response?.data?.error?.message || error.message}`);
    }
  }

  // Formatear número de teléfono
  formatPhoneNumber(phone) {
    // Eliminar todo excepto números y +
    let cleaned = phone.replace(/[^\d+]/g, '');
    
    // Si no tiene código país, agregar +52 (México) por defecto
    if (!cleaned.startsWith('+')) {
      cleaned = '+52' + cleaned;
    }
    
    return cleaned;
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
          components: parameters.length > 0 ? [{
            type: 'body',
            parameters: parameters
          }] : undefined
        }
      };

      const response = await axios.post(url, payload, {
        headers: {
          'Authorization': `Bearer ${this.accessToken}`,
          'Content-Type': 'application/json'
        }
      });

      console.log(`💬 Plantilla WhatsApp enviada a ${formattedPhone}`);
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