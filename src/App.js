import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Alert,
  Platform,
} from 'react-native';
import axios from 'axios';
import NetInfo from '@react-native-community/netinfo';

// Porta do servidor Listener rodando no Termux
const CORE_SERVER_PORT = 8080;
// Substitua pelo IP interno do seu Termux (Ex: 192.168.1.100).
// Você pode obter isso rodando 'ip addr show wlan0' ou 'ip a' no Termux.
const TERMUX_IP = '192.168.1.X'; 
const DEPLOY_URL = `http://${TERMUX_IP}:${CORE_SERVER_PORT}/deploy`;

const App = () => {
  const [ipAddress, setIpAddress] = useState(TERMUX_IP);
  const [connectionStatus, setConnectionStatus] = useState('Desconectado');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Checa o status da rede para dar feedback
    const unsubscribe = NetInfo.addEventListener(state => {
      if (state.isConnected) {
        setConnectionStatus('Conectado à Internet');
      } else {
        setConnectionStatus('Verifique a conexão');
      }
    });

    // Função para buscar o IP da rede local
    NetInfo.fetch('wifi').then(state => {
      if (state.details && state.details.ipAddress) {
        // Alerta para configurar IP, se for o placeholder
        if (TERMUX_IP === '192.168.1.X') {
           setIpAddress(state.details.ipAddress.split('.').slice(0, 3).join('.') + '.X');
        }
      }
    });

    return () => unsubscribe();
  }, []);

  const handleDeploy = async () => {
    if (loading) return;

    if (ipAddress.endsWith('.X')) {
      Alert.alert(
        'Atenção!',
        `Por favor, altere a constante TERMUX_IP no código para o IP interno real do seu Termux (Ex: ${ipAddress.replace('.X', '.100')}) antes de compilar.`
      );
      return;
    }

    setLoading(true);

    try {
      // Envia o comando para o servidor Termux/Listener
      const response = await axios.post(DEPLOY_URL, {
        command: 'start_synapse_shade_deployment',
        timestamp: new Date().toISOString(),
      });

      Alert.alert('Sucesso!', `Comando enviado. Status: ${response.data.status}`);
    } catch (error) {
      console.error(error);
      Alert.alert(
        'Falha na Comunicação!',
        `Não foi possível conectar a ${DEPLOY_URL}. 
        Certifique-se de que o Listener (servidor Node.js) está rodando no seu Termux e que o IP está correto.`
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>SynapseShade - Deploy Master</Text>
      
      <Text style={styles.statusText}>
        Status: {connectionStatus} | IP Alvo: {ipAddress.replace(TERMUX_IP.split('.').slice(-1)[0], '...')}
      </Text>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={handleDeploy}
        disabled={loading || ipAddress.endsWith('.X')}>
        <Text style={styles.buttonText}>
          {loading ? 'Enviando...' : '▶ Iniciar Deploy Central'}
        </Text>
      </TouchableOpacity>
      
      <Text style={styles.footer}>
        App v1.0.0. Este comando ativa o script init-alpha-final-v2.1.sh no Termux.
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
    padding: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#00e676', // Cor Neon Verde
    marginBottom: 30,
  },
  statusText: {
    fontSize: 16,
    color: '#ccc',
    marginBottom: 40,
    textAlign: 'center',
  },
  button: {
    backgroundColor: '#00c853', // Verde Brilhante
    paddingVertical: 15,
    paddingHorizontal: 40,
    borderRadius: 8,
    elevation: 3,
  },
  buttonDisabled: {
    backgroundColor: '#00502a',
  },
  buttonText: {
    fontSize: 20,
    color: '#fff',
    fontWeight: 'bold',
  },
  footer: {
    marginTop: 50,
    fontSize: 12,
    color: '#555',
    textAlign: 'center',
  }
});

export default App;
