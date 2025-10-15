// scripts/listener.js
const http = require('http');
const { exec } = require('child_process');
const fs = require('fs');

const PORT = 8080;
const LOG_FILE = '/storage/emulated/0/Documents/AlphaOne/SynapseShade/.logs/listener.log';
const MASTER_SCRIPT = '/data/data/com.termux/files/home/init-alpha-final-v2.1.sh';

const log = (message) => {
    const timestamp = new Date().toISOString();
    const fullMessage = `${timestamp} [LISTENER] ${message}\n`;
    fs.appendFileSync(LOG_FILE, fullMessage);
    console.log(fullMessage.trim());
};

const server = http.createServer((req, res) => {
    // Apenas aceita POST em /deploy
    if (req.method === 'POST' && req.url === '/deploy') {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });

        req.on('end', () => {
            try {
                const data = JSON.parse(body);
                log(`Comando recebido: ${data.command}`);

                // 1. Envia resposta imediata para o cliente (App)
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'OK', message: 'Comando aceito. Execução iniciada em segundo plano.' }));

                // 2. Executa o Master Script em segundo plano
                // O comando nohup garante que o script continue rodando mesmo se o listener.js fechar.
                log(`Executando script mestre: ${MASTER_SCRIPT}`);
                
                // Redireciona a saída do script para um log separado
                const script_log = '/storage/emulated/0/Documents/AlphaOne/SynapseShade/.logs/script_exec.log';
                
                exec(`nohup bash ${MASTER_SCRIPT} --silent > ${script_log} 2>&1 &`, (error, stdout, stderr) => {
                    if (error) {
                        log(`Erro de execução do script: ${error.message}`);
                        return;
                    }
                    log(`Script finalizado. Saída em: ${script_log}`);
                });

            } catch (e) {
                log(`Erro ao processar o corpo da requisição: ${e.message}`);
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ status: 'ERROR', message: 'Requisição inválida.' }));
            }
        });
    } else {
        // Resposta para outras rotas
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('SynapseShade Listener Core Rodando.');
    }
});

server.listen(PORT, '0.0.0.0', () => {
    log(`Servidor SynapseShade Listener rodando em http://0.0.0.0:${PORT}`);
    log('Aguardando comando /deploy...');
});

// Captura erros para log
server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
        log(`Erro: Porta ${PORT} já em uso. Feche outro processo e tente novamente.`);
        process.exit(1);
    } else {
        log(`Erro do Servidor: ${e.message}`);
    }
});
