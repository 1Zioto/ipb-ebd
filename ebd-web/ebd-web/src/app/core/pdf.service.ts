import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class PdfService {
  /**
   * Abre um visualizador oficial de alta fidelidade para o documento em uma nova aba.
   * Renderiza a folha em proporção exata A4 retrato, com moldura eclesiástica solene da IPB,
   * tipografia formal, cabeçalho timbrado com brasão oficial, barra de ferramentas superior
   * e disparo automático do diálogo nativo de impressão/salvar em PDF com qualidade vetorial máxima.
   * Também disponibiliza download direto em arquivo .pdf via html2pdf.
   */
  async gerarPdfEmNovaAba(
    elementOrId: string | HTMLElement,
    filename: string = 'documento-oficial-ipb',
    tituloDocumento: string = 'Documento Oficial — Igreja Presbiteriana do Brasil'
  ): Promise<void> {
    // 1. Abre a nova aba imediatamente para garantir compatibilidade com popups do navegador
    const novaAba = window.open('', '_blank');
    if (novaAba) {
      novaAba.document.write(`
        <!DOCTYPE html>
        <html lang="pt-BR">
          <head>
            <meta charset="utf-8" />
            <title>Carregando Documento Oficial — IPB</title>
            <style>
              body {
                margin: 0;
                padding: 0;
                height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                background-color: #0f172a;
                color: #f8fafc;
              }
              .box {
                text-align: center;
                background: #1e293b;
                padding: 2.5rem 3rem;
                border-radius: 1rem;
                box-shadow: 0 20px 40px rgba(0,0,0,0.4);
                max-width: 440px;
                border: 1px solid #334155;
              }
              .spinner {
                width: 48px;
                height: 48px;
                border: 4px solid #334155;
                border-top-color: #10b981;
                border-radius: 50%;
                animation: spin 0.9s linear infinite;
                margin: 0 auto 1.25rem;
              }
              @keyframes spin { to { transform: rotate(360deg); } }
              h2 { font-size: 1.15rem; font-weight: 700; color: #10b981; margin: 0 0 0.5rem; text-transform: uppercase; letter-spacing: 0.05em; }
              p { font-size: 0.875rem; color: #94a3b8; margin: 0; line-height: 1.4; }
            </style>
          </head>
          <body>
            <div class="box">
              <div class="spinner"></div>
              <h2>Igreja Presbiteriana do Brasil</h2>
              <p>Preparando documento oficial timbrado em alta definição...<br/>Aguarde um instante.</p>
            </div>
          </body>
        </html>
      `);
      novaAba.document.close();
    }

    // 2. Localiza o elemento HTML original
    const originalElement = typeof elementOrId === 'string'
      ? document.getElementById(elementOrId)
      : elementOrId;

    if (!originalElement) {
      if (novaAba) {
        novaAba.document.body.innerHTML = `
          <div style="padding: 3rem; text-align: center; font-family: sans-serif; color: #ef4444; background: #0f172a; height: 100vh;">
            <h2>Documento não localizado</h2>
            <p>O elemento "${typeof elementOrId === 'string' ? elementOrId : 'solicitado'}" não pôde ser encontrado para emissão.</p>
          </div>
        `;
      }
      return;
    }

    // 3. Clona o elemento original e garante caminhos absolutos nas imagens
    const clone = originalElement.cloneNode(true) as HTMLElement;
    const origin = window.location.origin;
    const images = clone.querySelectorAll('img');
    images.forEach((img) => {
      const src = img.getAttribute('src');
      if (src && !src.startsWith('http') && !src.startsWith('data:')) {
        img.src = `${origin}/${src.replace(/^\//, '')}`;
      }
    });

    const htmlConteudo = clone.outerHTML;

    // 4. Monta a página autossuficiente com CSS eclesiástico solene completo
    const paginaCompleta = `
      <!DOCTYPE html>
      <html lang="pt-BR">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>${tituloDocumento}</title>
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700;800;900&family=Inter:wght@300;400;500;600;700;800&family=Merriweather:ital,wght@0,300;0,400;0,700;1,300;1,400&family=JetBrains+Mono:wght@500;700&display=swap" rel="stylesheet">
          <style>
            /* Reset & Tipografia Universal */
            *, *::before, *::after {
              box-sizing: border-box;
            }
            body {
              margin: 0;
              padding: 0;
              background-color: #0f172a;
              color: #0f172a;
              font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              -webkit-font-smoothing: antialiased;
            }

            /* Barra de Ferramentas Superior (PDF Viewer Toolbar) */
            .ipb-pdf-toolbar {
              position: sticky;
              top: 0;
              z-index: 9999;
              background: linear-gradient(180deg, #0b1329 0%, #080d1c 100%);
              border-bottom: 1px solid rgba(255, 255, 255, 0.1);
              padding: 12px 24px;
              display: flex;
              align-items: center;
              justify-content: space-between;
              box-shadow: 0 4px 20px rgba(0, 0, 0, 0.4);
              color: #ffffff;
            }
            .ipb-pdf-toolbar .brand-group {
              display: flex;
              align-items: center;
              gap: 12px;
            }
            .ipb-pdf-toolbar .brand-logo {
              width: 32px;
              height: 32px;
              object-fit: contain;
            }
            .ipb-pdf-toolbar .brand-info h1 {
              font-family: 'Cinzel', serif;
              font-size: 13px;
              font-weight: 700;
              letter-spacing: 0.1em;
              color: #10b981;
              margin: 0;
              text-transform: uppercase;
            }
            .ipb-pdf-toolbar .brand-info p {
              font-size: 11px;
              color: #94a3b8;
              margin: 0;
            }
            .ipb-pdf-toolbar .actions-group {
              display: flex;
              align-items: center;
              gap: 10px;
            }
            .btn-ipb {
              display: inline-flex;
              align-items: center;
              gap: 8px;
              padding: 8px 18px;
              border-radius: 8px;
              font-size: 13px;
              font-weight: 600;
              cursor: pointer;
              border: none;
              transition: all 0.2s ease;
              text-decoration: none;
            }
            .btn-ipb-primary {
              background: #047857;
              color: #ffffff;
              box-shadow: 0 4px 12px rgba(4, 120, 87, 0.35);
            }
            .btn-ipb-primary:hover {
              background: #059669;
              transform: translateY(-1px);
            }
            .btn-ipb-secondary {
              background: #1e293b;
              color: #e2e8f0;
              border: 1px solid #334155;
            }
            .btn-ipb-secondary:hover {
              background: #334155;
              color: #ffffff;
            }
            .btn-ipb-danger {
              background: transparent;
              color: #94a3b8;
              border: 1px solid rgba(255, 255, 255, 0.1);
            }
            .btn-ipb-danger:hover {
              background: rgba(239, 68, 68, 0.15);
              color: #f87171;
              border-color: #ef4444;
            }
            .toolbar-tip {
              font-size: 11px;
              color: #64748b;
              margin-left: 8px;
            }

            /* Área do Visualizador de Documento */
            .ipb-viewport {
              min-height: calc(100vh - 65px);
              padding: 30px 16px 60px 16px;
              display: flex;
              justify-content: center;
              align-items: flex-start;
              background-color: #0f172a;
            }

            /* Folha A4 Nobre */
            .ipb-folha-a4 {
              width: 210mm;
              min-height: 297mm;
              margin: 0 auto;
              background-color: #ffffff;
              color: #0f172a;
              padding: 14mm 16mm;
              box-shadow: 0 25px 60px rgba(0, 0, 0, 0.45), 0 0 0 1px rgba(255, 255, 255, 0.05);
              border-radius: 3px;
              position: relative;
            }

            /* Moldura e Estilos Canônicos Eclesiásticos da IPB */
            .ipb-moldura-solene {
              border: 2.5px solid #064e3b;
              outline: 1px solid #0f766e;
              outline-offset: -5px;
              padding: 18px 20px;
              background-color: #ffffff;
              position: relative;
            }

            .ipb-timbre-header {
              text-align: center;
              padding-bottom: 12px;
              margin-bottom: 12px;
              border-bottom: 2px solid #064e3b;
            }
            .ipb-logo-img {
              max-height: 60px;
              width: auto;
              object-fit: contain;
              margin-bottom: 6px;
              display: block;
              margin-left: auto;
              margin-right: auto;
            }
            .ipb-timbre-nome-ipb {
              font-family: 'Cinzel', Georgia, serif;
              font-size: 13.5px;
              font-weight: 800;
              letter-spacing: 0.18em;
              color: #064e3b;
              text-transform: uppercase;
              margin: 0 0 2px 0;
            }
            .ipb-timbre-nome-igreja {
              font-family: 'Inter', sans-serif;
              font-size: 17px;
              font-weight: 900;
              letter-spacing: -0.01em;
              color: #0f172a;
              text-transform: uppercase;
              margin: 0 0 2px 0;
            }
            .ipb-timbre-jurisdicao {
              font-size: 10.5px;
              font-weight: 500;
              color: #475569;
              margin: 0 0 6px 0;
            }
            .ipb-faixa-chancela {
              display: inline-block;
              background: #064e3b;
              color: #ffffff;
              padding: 4px 16px;
              border-radius: 4px;
              font-family: 'Cinzel', Georgia, serif;
              font-size: 10.5px;
              font-weight: 700;
              letter-spacing: 0.12em;
              text-transform: uppercase;
            }

            /* Seções Eclesiásticas & Tabelas */
            .ipb-secao-titulo {
              font-family: 'Inter', sans-serif;
              font-size: 10px;
              font-weight: 800;
              letter-spacing: 0.1em;
              color: #064e3b;
              text-transform: uppercase;
              margin: 12px 0 6px 0;
              padding-bottom: 3px;
              border-bottom: 1px solid #cbd5e1;
              display: flex;
              align-items: center;
              gap: 6px;
            }
            .ipb-tabela-dados {
              width: 100%;
              border-collapse: collapse;
              margin-bottom: 8px;
              font-size: 11px;
            }
            .ipb-tabela-dados th,
            .ipb-tabela-dados td {
              padding: 5px 8px;
              text-align: left;
              vertical-align: top;
              border-bottom: 1px solid #e2e8f0;
            }
            .ipb-tabela-dados tr:last-child td {
              border-bottom: none;
            }
            .ipb-label {
              font-size: 9px;
              font-weight: 700;
              text-transform: uppercase;
              letter-spacing: 0.05em;
              color: #64748b;
              display: block;
              margin-bottom: 1px;
            }
            .ipb-val {
              font-size: 11px;
              font-weight: 600;
              color: #0f172a;
              display: block;
            }
            .ipb-val-destaque {
              font-size: 12.5px;
              font-weight: 800;
              color: #064e3b;
            }
            .ipb-badge-canonico {
              display: inline-block;
              padding: 2px 7px;
              border-radius: 4px;
              font-size: 9.5px;
              font-weight: 700;
              text-transform: uppercase;
              background-color: #ecfdf5;
              color: #047857;
              border: 1px solid #a7f3d0;
            }

            /* Certidão Solene do Conselho */
            .ipb-certidao-bloco {
              background: #f8fafc;
              border-left: 3px solid #064e3b;
              border-right: 1px solid #e2e8f0;
              border-top: 1px solid #e2e8f0;
              border-bottom: 1px solid #e2e8f0;
              padding: 8px 12px;
              margin: 10px 0;
              border-radius: 0 6px 6px 0;
            }
            .ipb-certidao-texto {
              font-family: 'Merriweather', Georgia, serif;
              font-size: 10px;
              line-height: 1.55;
              color: #1e293b;
              text-align: justify;
              margin: 0;
            }

            /* Autenticidade e Carimbo Digital */
            .ipb-autenticidade-linha {
              display: flex;
              align-items: center;
              justify-content: space-between;
              font-size: 9.5px;
              color: #64748b;
              padding: 5px 0;
              margin-bottom: 12px;
              border-bottom: 1px dashed #cbd5e1;
            }
            .ipb-codigo-auth {
              font-family: 'JetBrains Mono', monospace;
              font-weight: 700;
              color: #064e3b;
              background: #f1f5f9;
              padding: 2px 6px;
              border-radius: 3px;
              letter-spacing: 0.08em;
            }

            /* Assinaturas Canônicas */
            .ipb-grid-assinaturas {
              display: grid;
              grid-template-columns: 1fr 1fr;
              gap: 24px;
              text-align: center;
              margin-top: 20px;
              padding-top: 4px;
            }
            .ipb-linha-assinatura {
              border-top: 1.2px solid #0f172a;
              width: 80%;
              margin: 0 auto 5px auto;
            }
            .ipb-assinante-nome {
              font-size: 11px;
              font-weight: 800;
              color: #0f172a;
              margin: 0 0 1px 0;
              text-transform: uppercase;
            }
            .ipb-assinante-cargo {
              font-size: 9px;
              color: #475569;
              margin: 0;
              font-weight: 500;
            }

            /* Rodapé Solene */
            .ipb-rodape-solene {
              text-align: center;
              font-size: 8px;
              color: #94a3b8;
              margin-top: 14px;
              padding-top: 6px;
              border-top: 1px solid #f1f5f9;
              font-style: italic;
              letter-spacing: 0.05em;
            }

            /* Regras Especiais de Impressão (@media print) */
            @media print {
              @page {
                size: A4 portrait;
                margin: 8mm 10mm;
              }
              body {
                background: #ffffff !important;
                color: #000000 !important;
              }
              .ipb-pdf-toolbar, .no-print {
                display: none !important;
              }
              .ipb-viewport {
                padding: 0 !important;
                background: #ffffff !important;
              }
              .ipb-folha-a4 {
                width: 100% !important;
                min-height: auto !important;
                box-shadow: none !important;
                border-radius: 0 !important;
                padding: 0 !important;
                margin: 0 !important;
              }
              .ipb-moldura-solene {
                border: 2.5px solid #064e3b !important;
                outline: 1px solid #0f766e !important;
                outline-offset: -5px !important;
              }
              * {
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
              }
            }
          </style>
          <script src="${origin}/html2pdf.bundle.min.js"></script>
        </head>
        <body>
          <!-- Barra de Ações Superior (Viewer Toolbar) -->
          <div class="ipb-pdf-toolbar no-print">
            <div class="brand-group">
              <img src="${origin}/ipb-logo.png" alt="IPB" class="brand-logo" onerror="this.style.display='none'" />
              <div class="brand-info">
                <h1>Igreja Presbiteriana do Brasil</h1>
                <p>Secretaria do Conselho • Documento Canônico Oficial</p>
              </div>
            </div>

            <div class="actions-group">
              <button onclick="window.print()" class="btn-ipb btn-ipb-primary" title="Abrir impressão e salvar como PDF">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="6 9 6 2 18 2 18 9"></polyline>
                  <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                  <rect x="6" y="14" width="12" height="8"></rect>
                </svg>
                Imprimir / Salvar em PDF
              </button>

              <button onclick="baixarPdfArquivo()" id="btn-baixar" class="btn-ipb btn-ipb-secondary" title="Gerar e baixar arquivo .pdf direto">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                  <polyline points="7 10 12 15 17 10"></polyline>
                  <line x1="12" y1="15" x2="12" y2="3"></line>
                </svg>
                Baixar PDF (.pdf)
              </button>

              <button onclick="window.close()" class="btn-ipb btn-ipb-danger" title="Fechar visualizador">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
                Fechar
              </button>
            </div>
          </div>

          <!-- Área do Documento A4 -->
          <div class="ipb-viewport">
            <div class="ipb-folha-a4" id="documento-a4-raiz">
              ${htmlConteudo}
            </div>
          </div>

          <script>
            // Função para download direto do PDF via html2pdf
            function baixarPdfArquivo() {
              const btn = document.getElementById('btn-baixar');
              if (btn) btn.innerHTML = 'Gerando PDF...';

              const elem = document.getElementById('documento-a4-raiz');
              const opt = {
                margin: [8, 8, 8, 8],
                filename: '${filename}.pdf',
                image: { type: 'jpeg', quality: 0.98 },
                html2canvas: {
                  scale: 2,
                  useCORS: true,
                  logging: false,
                  backgroundColor: '#ffffff'
                },
                jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
              };

              if (window.html2pdf) {
                window.html2pdf().set(opt).from(elem).save().then(() => {
                  if (btn) btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg> Baixar PDF (.pdf)';
                }).catch(err => {
                  console.error('Erro no html2pdf:', err);
                  alert('Para salvar em alta definição, use o botão "Imprimir / Salvar em PDF" e selecione "Salvar como PDF".');
                  if (btn) btn.innerHTML = 'Baixar PDF (.pdf)';
                });
              } else {
                window.print();
              }
            }

            // Dispara automaticamente o diálogo nativo após carregamento suave
            window.addEventListener('load', () => {
              setTimeout(() => {
                window.print();
              }, 450);
            });
          </script>
        </body>
      </html>
    `;

    // 5. Injeta a página no documento da nova aba
    if (novaAba && !novaAba.closed) {
      novaAba.document.open();
      novaAba.document.write(paginaCompleta);
      novaAba.document.close();
    } else {
      // Caso popups tenham sido bloqueados, abre via blob URL
      const blob = new Blob([paginaCompleta], { type: 'text/html' });
      const url = URL.createObjectURL(blob);
      window.open(url, '_blank');
    }
  }
}
