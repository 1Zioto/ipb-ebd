/**
 * Sistema de Impressão Térmica POS & Bluetooth
 * Igreja Presbiteriana do Brasil • Diaconato & Tesouraria
 *
 * Suporta:
 * 1. Bluetooth Low Energy (Web Bluetooth API) - Conexão direta com mini-impressoras POS/BLE
 * 2. RawBT Android Service/Intent - Padrão universal para impressoras Bluetooth Clássicas (SPP 2.0/3.0 / MTP-II / POS-58)
 * 3. Spooler Nativo do Sistema / Navegador (Cupom Térmico 58mm / 80mm com CSS de bobina)
 */

class PosPrinterService {
  constructor() {
    this.STORAGE_KEY = 'ipb_pos_printer_config';
    this.DEFAULT_CONFIG = {
      mode: 'auto',              // 'auto' | 'bluetooth' | 'rawbt' | 'system'
      paperWidth: '58',          // '58' (32 colunas) | '80' (48 colunas)
      copies: 1,                 // 1 ou 2 vias
      autoCut: false,            // Corte de papel / guilhotina
      churchName: 'IGREJA PRESBITERIANA DO BRASIL',
      churchSub: 'Junta Diaconal & Tesouraria',
      footerMsg: 'Deus ama ao que dá com alegria. (2 Co 9:7)',
      autoPrintEnvelope: false,  // Imprimir automaticamente ao registrar envelope
      autoPrintFechamento: true, // Imprimir ao finalizar sessão
      lastDeviceName: ''
    };

    this.config = { ...this.DEFAULT_CONFIG };
    this.bleDevice = null;
    this.bleCharacteristic = null;
    this.isConnecting = false;

    // UUIDs conhecidos de impressoras térmicas Bluetooth (ESC/POS)
    this.BT_SERVICES = [
      '000018f0-0000-1000-8000-00805f9b34fb', // Standard Print
      '0000ffe0-0000-1000-8000-00805f9b34fb', // MTP-II, GOOJPRT, POS-5802
      '49535343-fe7d-4ae5-8fa9-9fafd205e455', // ISSC Transparent
      'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
      '0000ff00-0000-1000-8000-00805f9b34fb',
      '0000fee7-0000-1000-8000-00805f9b34fb'
    ];

    this.BT_CHARACTERISTICS = [
      '00002af1-0000-1000-8000-00805f9b34fb',
      '0000ffe1-0000-1000-8000-00805f9b34fb',
      '49535343-1e4d-4bd9-ba61-23c647249616',
      '49535343-aca3-481c-91ec-d85e28a60318',
      '0000ff02-0000-1000-8000-00805f9b34fb',
      '0000fee8-0000-1000-8000-00805f9b34fb'
    ];

    this.loadConfig();
  }

  loadConfig() {
    try {
      const saved = localStorage.getItem(this.STORAGE_KEY);
      if (saved) {
        this.config = { ...this.DEFAULT_CONFIG, ...JSON.parse(saved) };
      }
    } catch (e) {
      console.warn('Erro ao carregar configurações de impressora:', e);
    }
  }

  saveConfig() {
    try {
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(this.config));
    } catch (e) {
      console.warn('Erro ao salvar configurações de impressora:', e);
    }
  }

  getCols() {
    return this.config.paperWidth === '80' ? 48 : 32;
  }

  isBluetoothSupported() {
    return typeof navigator !== 'undefined' && 'bluetooth' in navigator;
  }

  isConnected() {
    return !!(this.bleDevice && this.bleDevice.gatt && this.bleDevice.gatt.connected && this.bleCharacteristic);
  }

  getDeviceName() {
    if (this.isConnected()) {
      return this.bleDevice.name || 'Impressora Bluetooth Conectada';
    }
    return this.config.lastDeviceName || null;
  }

  /**
   * Conecta à impressora via Web Bluetooth API
   */
  async conectarBluetooth() {
    if (!this.isBluetoothSupported()) {
      throw new Error('Web Bluetooth não é suportado neste navegador. Utilize o modo RawBT ou Spooler do Sistema.');
    }

    this.isConnecting = true;
    try {
      const options = {
        acceptAllDevices: true,
        optionalServices: this.BT_SERVICES
      };

      const device = await navigator.bluetooth.requestDevice(options);
      if (!device) throw new Error('Nenhum dispositivo selecionado.');

      this.bleDevice = device;
      this.config.lastDeviceName = device.name || 'Impressora POS';
      this.saveConfig();

      device.addEventListener('gattserverdisconnected', () => {
        this.bleCharacteristic = null;
        if (typeof onPrinterStatusChange === 'function') {
          onPrinterStatusChange(false);
        }
      });

      const server = await device.gatt.connect();

      // Procurar serviço e característica de escrita
      let characteristicFound = null;
      for (const serviceUuid of this.BT_SERVICES) {
        try {
          const service = await server.getPrimaryService(serviceUuid);
          const characteristics = await service.getCharacteristics();
          for (const char of characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              characteristicFound = char;
              break;
            }
          }
          if (characteristicFound) break;
        } catch (e) {
          // Continua tentando próximo UUID
        }
      }

      // Se não encontrou pelos UUIDs predefinidos, tentar listar todos os serviços
      if (!characteristicFound) {
        try {
          const services = await server.getPrimaryServices();
          for (const service of services) {
            const characteristics = await service.getCharacteristics();
            for (const char of characteristics) {
              if (char.properties.write || char.properties.writeWithoutResponse) {
                characteristicFound = char;
                break;
              }
            }
            if (characteristicFound) break;
          }
        } catch (e) {
          console.warn('Erro ao varrer serviços genéricos:', e);
        }
      }

      if (!characteristicFound) {
        throw new Error('Impressora encontrada, mas não foi possível estabelecer canal de escrita ESC/POS.');
      }

      this.bleCharacteristic = characteristicFound;
      this.isConnecting = false;

      if (typeof onPrinterStatusChange === 'function') {
        onPrinterStatusChange(true);
      }

      return {
        success: true,
        name: device.name || 'Impressora POS'
      };
    } catch (err) {
      this.isConnecting = false;
      this.bleDevice = null;
      this.bleCharacteristic = null;
      throw err;
    }
  }

  async desconectarBluetooth() {
    if (this.bleDevice && this.bleDevice.gatt && this.bleDevice.gatt.connected) {
      await this.bleDevice.gatt.disconnect();
    }
    this.bleDevice = null;
    this.bleCharacteristic = null;
    if (typeof onPrinterStatusChange === 'function') {
      onPrinterStatusChange(false);
    }
  }

  /**
   * Envia dados brutos ESC/POS em pacotes para o BLE
   */
  async enviarBleBytes(uint8Array) {
    if (!this.isConnected()) {
      throw new Error('Impressora Bluetooth não está conectada.');
    }

    const CHUNK_SIZE = 80; // Tamanho ideal para MTU de impressoras térmicas
    const totalLen = uint8Array.length;

    for (let offset = 0; offset < totalLen; offset += CHUNK_SIZE) {
      const chunk = uint8Array.subarray(offset, Math.min(offset + CHUNK_SIZE, totalLen));
      if (this.bleCharacteristic.properties.writeWithoutResponse) {
        await this.bleCharacteristic.writeValueWithoutResponse(chunk);
      } else {
        await this.bleCharacteristic.writeValue(chunk);
      }
      // Pequeno atraso para evitar overflow do buffer da impressora térmica
      await new Promise(r => setTimeout(r, 25));
    }
  }

  /**
   * Converte Uint8Array para Base64
   */
  uint8ToBase64(uint8Array) {
    let binary = '';
    const len = uint8Array.byteLength;
    for (let i = 0; i < len; i++) {
      binary += String.fromCharCode(uint8Array[i]);
    }
    return window.btoa(binary);
  }

  /**
   * Envia dados para o app RawBT via Intent do Android ou link direto
   */
  enviarRawBt(uint8Array) {
    const base64 = this.uint8ToBase64(uint8Array);
    
    // Tentar abrir via Intent específico do RawBT para Android
    const intentUrl = `intent:base64,${base64}#Intent;scheme=rawbt;package=ru.a402d.rawbtprinter;S.browser_fallback_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dru.a402d.rawbtprinter;end;`;
    
    try {
      window.location.href = intentUrl;
      return true;
    } catch (e) {
      // Fallback para URL scheme direto
      try {
        window.location.href = `rawbt:data:application/octet-stream;base64,${base64}`;
        return true;
      } catch (err) {
        throw new Error('Não foi possível comunicar com o RawBT: ' + err.message);
      }
    }
  }

  /**
   * Impressão via spooler do navegador/sistema
   */
  imprimirSistema(htmlContent) {
    const printArea = document.getElementById('thermalReceiptPrintArea');
    if (!printArea) {
      throw new Error('Área de impressão térmica não encontrada no DOM.');
    }

    printArea.innerHTML = htmlContent;
    printArea.className = `thermal-print-page paper-${this.config.paperWidth}mm`;
    
    window.print();
    return true;
  }

  /**
   * Método Mestre de Impressão
   */
  async imprimirDocumento({ escPosBytes, htmlContent, titulo }) {
    const modo = this.config.mode;
    const copias = parseInt(this.config.copies) || 1;

    for (let via = 1; via <= copias; via++) {
      // Se tiver mais de 1 via, adiciona cabeçalho da via
      let bytesParaEnvio = escPosBytes;
      let htmlParaEnvio = htmlContent;

      if (copias > 1) {
        const textoVia = via === 1 ? '--- 1ª VIA (IGREJA) ---' : '--- 2ª VIA (OFERTANTE) ---';
        htmlParaEnvio = `<div style="text-align:center;font-weight:bold;margin-bottom:6px;font-size:10px;">${textoVia}</div>` + htmlContent;
      }

      if (modo === 'bluetooth') {
        if (!this.isConnected()) {
          throw new Error('Impressora Bluetooth não está conectada. Clique em "Conectar Impressora" ou selecione outro modo.');
        }
        await this.enviarBleBytes(bytesParaEnvio);
      } else if (modo === 'rawbt') {
        this.enviarRawBt(bytesParaEnvio);
      } else if (modo === 'system') {
        this.imprimirSistema(htmlParaEnvio);
      } else {
        // MODO AUTO:
        // 1. Se BLE conectado, envia via BLE
        if (this.isConnected()) {
          await this.enviarBleBytes(bytesParaEnvio);
        } else if (/Android/i.test(navigator.userAgent)) {
          // 2. Se estiver em Android, envia via RawBT (suporta qualquer impressora pareada)
          this.enviarRawBt(bytesParaEnvio);
        } else {
          // 3. Fallback: Diálogo nativo do sistema
          this.imprimirSistema(htmlParaEnvio);
        }
      }

      // Pequena pausa entre vias se houver mais de uma
      if (via < copias) {
        await new Promise(r => setTimeout(r, 600));
      }
    }

    return true;
  }

  // ========================================================
  // CONSTRUTOR DE COMANDOS ESC/POS & FORMATADOR DE CUPONS
  // ========================================================

  /**
   * Sanitiza caracteres com acentos para ASCII universal para compatibilidade
   * total com impressoras térmicas ESC/POS sem necessidade de troca de CodePage ROM.
   */
  removerAcentos(texto) {
    if (!texto) return '';
    return texto
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^\x20-\x7E\n\r]/g, ' ');
  }

  /**
   * Alinha duas colunas (Esquerda e Direita) com preenchimento exato
   */
  formatarLinhaDuasColunas(esquerda, direita, largura) {
    const esq = this.removerAcentos(esquerda || '');
    const dir = this.removerAcentos(direita || '');
    const espacosDisponiveis = largura - esq.length - dir.length;

    if (espacosDisponiveis <= 0) {
      // Se não couber na mesma linha, quebra
      return esq + '\n' + ' '.repeat(largura - dir.length) + dir;
    }
    return esq + ' '.repeat(espacosDisponiveis) + dir;
  }

  /**
   * Gera uma linha divisória pontilhada
   */
  formatarDivisoria(largura, char = '-') {
    return char.repeat(largura);
  }

  /**
   * Centraliza texto
   */
  centralizarTexto(texto, largura) {
    const t = this.removerAcentos(texto || '');
    if (t.length >= largura) return t;
    const pad = Math.floor((largura - t.length) / 2);
    return ' '.repeat(pad) + t;
  }

  /**
   * Cria buffer binário ESC/POS para um documento de texto com comandos
   */
  criarEscPosBuffer(comandos) {
    const bytes = [];

    // Reset da impressora
    bytes.push(0x1B, 0x40);

    for (const cmd of comandos) {
      switch (cmd.type) {
        case 'align':
          bytes.push(0x1B, 0x61, cmd.value === 'center' ? 0x01 : (cmd.value === 'right' ? 0x02 : 0x00));
          break;
        case 'bold':
          bytes.push(0x1B, 0x45, cmd.value ? 0x01 : 0x00);
          break;
        case 'double':
          bytes.push(0x1D, 0x21, cmd.value ? 0x11 : 0x00); // 0x11 = dobro de altura e largura
          break;
        case 'text':
          const sanitized = this.removerAcentos(cmd.text);
          for (let i = 0; i < sanitized.length; i++) {
            bytes.push(sanitized.charCodeAt(i));
          }
          break;
        case 'line':
          const lineSanitized = this.removerAcentos(cmd.text || '') + '\n';
          for (let i = 0; i < lineSanitized.length; i++) {
            bytes.push(lineSanitized.charCodeAt(i));
          }
          break;
        case 'feed':
          bytes.push(0x1B, 0x64, cmd.lines || 3);
          break;
        case 'cut':
          if (this.config.autoCut) {
            bytes.push(0x1D, 0x56, 0x41, 0x10); // Corta papel
          }
          break;
      }
    }

    // Avanço final de 3 linhas para sair da guilhotina/picote
    bytes.push(0x1B, 0x64, 0x03);

    return new Uint8Array(bytes);
  }

  // ========================================================
  // MODELOS DE CUPOM
  // ========================================================

  /**
   * 1. Comprovante Individual de Envelope / Oferta
   */
  gerarCupomEnvelope(entry) {
    const cols = this.getCols();
    const dataHora = new Date().toLocaleString('pt-BR');
    const labelDest = {
      dizimo: 'DIZIMO',
      oferta: 'OFERTA GERAL',
      missoes: 'MISSOES',
      construcao: 'CONSTRUCAO'
    }[entry.destinacao] || (entry.destinacao || 'GERAL').toUpperCase();

    const forma = (entry.forma || 'DINHEIRO').toUpperCase();
    const valorFormatado = `R$ ${entry.valor.toFixed(2).replace('.', ',')}`;

    // --- COMANDOS ESC/POS ---
    const cmds = [];
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: this.config.churchName });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.config.churchSub });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });
    
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'COMPROVANTE DE ENTRADA' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });

    cmds.push({ type: 'align', value: 'left' });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Data/Hora:', dataHora, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Reg. ID:', `#${entry.id.toString().slice(-6)}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Destinacao:', labelDest, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Forma Entrada:', forma, cols) });
    
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });
    cmds.push({ type: 'line', text: 'Membro / Dizimista:' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: `  ${entry.membro || 'Nao Identificado'}` });
    cmds.push({ type: 'bold', value: false });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'double', value: true });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: valorFormatado });
    cmds.push({ type: 'double', value: false });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });

    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'line', text: '' });
    cmds.push({ type: 'line', text: '_______________________________' });
    cmds.push({ type: 'line', text: 'Visto Junta Diaconal / Tesouraria' });
    cmds.push({ type: 'line', text: '' });
    cmds.push({ type: 'line', text: this.config.footerMsg });
    cmds.push({ type: 'cut' });

    const escPosBytes = this.criarEscPosBuffer(cmds);

    // --- VERSÃO HTML PARA SISTEMA & PREVIEW ---
    const htmlContent = `
      <div class="thermal-receipt-doc">
        <div class="th-center th-bold th-title">${this.config.churchName}</div>
        <div class="th-center th-muted">${this.config.churchSub}</div>
        <div class="th-divider double"></div>

        <div class="th-center th-bold th-subtitle">COMPROVANTE DE ENTRADA</div>
        <div class="th-divider"></div>

        <div class="th-row"><span>Data/Hora:</span><span>${dataHora}</span></div>
        <div class="th-row"><span>Reg. ID:</span><span>#${entry.id.toString().slice(-6)}</span></div>
        <div class="th-row"><span>Destinação:</span><span class="th-bold">${labelDest}</span></div>
        <div class="th-row"><span>Forma Entrada:</span><span>${forma}</span></div>
        
        <div class="th-divider"></div>
        <div class="th-label">Membro / Dizimista:</div>
        <div class="th-bold th-indent">${entry.membro || 'Não Identificado'}</div>

        <div class="th-divider double"></div>
        <div class="th-center th-big-total th-bold">${valorFormatado}</div>
        <div class="th-divider double"></div>

        <div class="th-sign-box">
          <div class="th-sign-line"></div>
          <div class="th-center th-caption">Visto Junta Diaconal / Tesouraria</div>
        </div>

        <div class="th-center th-footer-msg">${this.config.footerMsg}</div>
      </div>
    `;

    return { escPosBytes, htmlContent, titulo: `Recibo #${entry.id.toString().slice(-6)}` };
  }

  /**
   * 2. Termo de Fechamento & Batimento Canônico da Apuração
   */
  gerarCupomFechamento({ totais, conferente1, conferente2, dataStr, entries }) {
    const cols = this.getCols();
    const dataHora = new Date().toLocaleString('pt-BR');
    const dataApuracao = dataStr || new Date().toLocaleDateString('pt-BR');

    // Totais por categoria
    let totDizimo = 0, totOferta = 0, totMissoes = 0, totConstrucao = 0;
    (entries || []).forEach(e => {
      if (e.destinacao === 'dizimo') totDizimo += e.valor;
      else if (e.destinacao === 'oferta') totOferta += e.valor;
      else if (e.destinacao === 'missoes') totMissoes += e.valor;
      else if (e.destinacao === 'construcao') totConstrucao += e.valor;
    });

    const statusBatimento = Math.abs(totais.diferencaDinheiro) < 0.01 
      ? '100% CONCILIADO (R$ 0,00)' 
      : (totais.diferencaDinheiro > 0 
          ? `+ R$ ${totais.diferencaDinheiro.toFixed(2).replace('.', ',')} (SOBRA/SALVA)` 
          : `- R$ ${Math.abs(totais.diferencaDinheiro).toFixed(2).replace('.', ',')} (DIFERENCA)`);

    // --- COMANDOS ESC/POS ---
    const cmds = [];
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: this.config.churchName });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.config.churchSub });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });

    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'TERMO DE APURACAO DIACONAL' });
    cmds.push({ type: 'line', text: 'DIZIMOS E OFERTAS' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });

    cmds.push({ type: 'align', value: 'left' });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Data Apuracao:', dataApuracao, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Emissao:', dataHora, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Culto / Servico:', 'Culto Dominical', cols) });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'RESUMO FINANCEIRO' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Especie (Contado):', `R$ ${totais.totalFisico.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Envelopes Dinheiro:', `R$ ${totais.totalEnvelopesDinheiro.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Ofertas Salva (Sobra):', `R$ ${totais.diferencaDinheiro.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('PIX / Transf.:', `R$ ${totais.totalPix.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Cartoes (POS):', `R$ ${totais.totalCartao.toFixed(2).replace('.', ',')}`, cols) });
    
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('TOTAL GERAL APURADO:', `R$ ${totais.totalGeral.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });

    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'DESTINACOES' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Dizimos:', `R$ ${totDizimo.toFixed(2).replace('.', ',')}`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Ofertas Gerais:', `R$ ${totOferta.toFixed(2).replace('.', ',')}`, cols) });
    if (totMissoes > 0) cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Missoes:', `R$ ${totMissoes.toFixed(2).replace('.', ',')}`, cols) });
    if (totConstrucao > 0) cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Construcao:', `R$ ${totConstrucao.toFixed(2).replace('.', ',')}`, cols) });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Total de Envelopes:', `${totais.totalEnvelopes} un`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Batimento Salva:', statusBatimento, cols) });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'COMISSAO DE CONFERENCIA' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: '' });
    cmds.push({ type: 'line', text: '_______________________________' });
    cmds.push({ type: 'line', text: `1o: ${conferente1 || 'Diacono / Tesoureiro'}` });
    cmds.push({ type: 'line', text: '' });
    cmds.push({ type: 'line', text: '_______________________________' });
    cmds.push({ type: 'line', text: `2o: ${conferente2 || 'Diacono Verificador'}` });
    cmds.push({ type: 'line', text: '' });
    cmds.push({ type: 'line', text: this.config.footerMsg });
    cmds.push({ type: 'cut' });

    const escPosBytes = this.criarEscPosBuffer(cmds);

    // --- VERSÃO HTML ---
    const htmlContent = `
      <div class="thermal-receipt-doc">
        <div class="th-center th-bold th-title">${this.config.churchName}</div>
        <div class="th-center th-muted">${this.config.churchSub}</div>
        <div class="th-divider double"></div>

        <div class="th-center th-bold th-subtitle">TERMO DE APURAÇÃO DIACONAL</div>
        <div class="th-center th-caption">DÍZIMOS & OFERTAS • IPB</div>
        <div class="th-divider"></div>

        <div class="th-row"><span>Data Apuração:</span><span>${dataApuracao}</span></div>
        <div class="th-row"><span>Emissão:</span><span>${dataHora}</span></div>
        <div class="th-row"><span>Culto / Serviço:</span><span>Culto Dominical</span></div>

        <div class="th-divider"></div>
        <div class="th-section-title">RESUMO FINANCEIRO</div>
        <div class="th-row"><span>Espécie (Contado):</span><span>R$ ${totais.totalFisico.toFixed(2).replace('.', ',')}</span></div>
        <div class="th-row"><span>Envelopes em Dinheiro:</span><span>R$ ${totais.totalEnvelopesDinheiro.toFixed(2).replace('.', ',')}</span></div>
        <div class="th-row"><span>Ofertas Salva (Sobra):</span><span class="th-bold">R$ ${totais.diferencaDinheiro.toFixed(2).replace('.', ',')}</span></div>
        <div class="th-row"><span>PIX / Transferências:</span><span>R$ ${totais.totalPix.toFixed(2).replace('.', ',')}</span></div>
        <div class="th-row"><span>Cartões (POS):</span><span>R$ ${totais.totalCartao.toFixed(2).replace('.', ',')}</span></div>

        <div class="th-divider double"></div>
        <div class="th-row th-bold th-highlight">
          <span>TOTAL GERAL:</span>
          <span>R$ ${totais.totalGeral.toFixed(2).replace('.', ',')}</span>
        </div>
        <div class="th-divider double"></div>

        <div class="th-section-title">DESTINAÇÕES</div>
        <div class="th-row"><span>Dízimos:</span><span>R$ ${totDizimo.toFixed(2).replace('.', ',')}</span></div>
        <div class="th-row"><span>Ofertas Gerais:</span><span>R$ ${totOferta.toFixed(2).replace('.', ',')}</span></div>
        ${totMissoes > 0 ? `<div class="th-row"><span>Missões:</span><span>R$ ${totMissoes.toFixed(2).replace('.', ',')}</span></div>` : ''}
        ${totConstrucao > 0 ? `<div class="th-row"><span>Construção:</span><span>R$ ${totConstrucao.toFixed(2).replace('.', ',')}</span></div>` : ''}

        <div class="th-divider"></div>
        <div class="th-row"><span>Total de Envelopes:</span><span class="th-bold">${totais.totalEnvelopes}</span></div>
        <div class="th-row"><span>Batimento Salva:</span><span class="th-bold">${statusBatimento}</span></div>

        <div class="th-divider"></div>
        <div class="th-center th-bold th-section-title">COMISSÃO CANÔNICA DE CONFERÊNCIA</div>
        <div class="th-sign-box">
          <div class="th-sign-line"></div>
          <div class="th-center th-caption">1º: ${conferente1 || 'Diácono / Tesoureiro'}</div>
        </div>
        <div class="th-sign-box">
          <div class="th-sign-line"></div>
          <div class="th-center th-caption">2º: ${conferente2 || 'Diácono Verificador'}</div>
        </div>

        <div class="th-center th-footer-msg">${this.config.footerMsg}</div>
      </div>
    `;

    return { escPosBytes, htmlContent, titulo: `Termo de Fechamento (${dataApuracao})` };
  }

  /**
   * 3. Cupom de Teste de Comunicação
   */
  gerarCupomTeste() {
    const cols = this.getCols();
    const dataHora = new Date().toLocaleString('pt-BR');

    const cmds = [];
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: this.config.churchName });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.config.churchSub });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });

    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'TESTE DE IMPRESSORA POS' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });

    cmds.push({ type: 'align', value: 'left' });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Data/Hora:', dataHora, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Modo Configurado:', this.config.mode.toUpperCase(), cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Largura Bobina:', `${this.config.paperWidth}mm (${cols} colunas)`, cols) });
    cmds.push({ type: 'line', text: this.formatarLinhaDuasColunas('Status Conexao:', this.isConnected() ? 'BLUETOOTH CONECTADO' : 'PRONTO P/ ENVIO', cols) });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '-') });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'TESTE DE ESTILOS DE TEXTO:' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: '1. Texto Normal: 0123456789' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: '2. Texto em Negrito Ativado' });
    cmds.push({ type: 'bold', value: false });

    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'double', value: true });
    cmds.push({ type: 'line', text: 'TESTE DUPLO' });
    cmds.push({ type: 'double', value: false });

    cmds.push({ type: 'line', text: this.formatarDivisoria(cols, '=') });
    cmds.push({ type: 'align', value: 'center' });
    cmds.push({ type: 'bold', value: true });
    cmds.push({ type: 'line', text: 'SISTEMA OPERACIONAL OK' });
    cmds.push({ type: 'bold', value: false });
    cmds.push({ type: 'line', text: 'IPB Diaconato & Tesouraria' });
    cmds.push({ type: 'cut' });

    const escPosBytes = this.criarEscPosBuffer(cmds);

    const htmlContent = `
      <div class="thermal-receipt-doc">
        <div class="th-center th-bold th-title">${this.config.churchName}</div>
        <div class="th-center th-muted">${this.config.churchSub}</div>
        <div class="th-divider double"></div>

        <div class="th-center th-bold th-subtitle">TESTE DE IMPRESSORA POS</div>
        <div class="th-divider"></div>

        <div class="th-row"><span>Data/Hora:</span><span>${dataHora}</span></div>
        <div class="th-row"><span>Modo:</span><span class="th-bold">${this.config.mode.toUpperCase()}</span></div>
        <div class="th-row"><span>Largura:</span><span>${this.config.paperWidth}mm (${cols} colunas)</span></div>
        <div class="th-row"><span>Status:</span><span class="th-bold">${this.isConnected() ? 'BLUETOOTH CONECTADO' : 'PRONTO'}</span></div>

        <div class="th-divider"></div>
        <div class="th-section-title">TESTE DE ESTILOS:</div>
        <div>1. Texto Normal: 0123456789</div>
        <div class="th-bold">2. Texto em Negrito</div>
        <div class="th-center th-big-total th-bold">TESTE DUPLO</div>

        <div class="th-divider double"></div>
        <div class="th-center th-bold">SISTEMA OPERACIONAL OK</div>
        <div class="th-center th-caption">IPB Diaconato & Tesouraria</div>
      </div>
    `;

    return { escPosBytes, htmlContent, titulo: 'Teste de Impressora POS' };
  }
}

// Instância Global
const posPrinter = new PosPrinterService();
