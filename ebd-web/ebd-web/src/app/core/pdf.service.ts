import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class PdfService {
  /**
   * Gera um arquivo PDF real (Blob application/pdf) e o abre imediatamente em uma nova aba.
   * Utiliza html2pdf.js com renderização A4 retrato em escala 2x, preservando todos os estilos solenes.
   */
  async gerarPdfEmNovaAba(elementOrId: string | HTMLElement, filename: string = 'documento-oficial-ipb'): Promise<void> {
    // 1. Abre a nova aba imediatamente para contornar o bloqueador de popups do navegador
    const novaAba = window.open('', '_blank');
    if (novaAba) {
      novaAba.document.write(`
        <!DOCTYPE html>
        <html lang="pt-BR">
          <head>
            <meta charset="utf-8" />
            <title>Gerando PDF Oficial — IPB</title>
            <style>
              body {
                margin: 0;
                padding: 0;
                height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #f8fafc;
                color: #0f172a;
              }
              .box {
                text-align: center;
                background: white;
                padding: 2.5rem 3rem;
                border-radius: 1rem;
                box-shadow: 0 10px 25px -5px rgba(0,0,0,0.06), 0 8px 10px -6px rgba(0,0,0,0.04);
                max-width: 440px;
                border: 1px solid #e2e8f0;
              }
              .spinner {
                width: 46px;
                height: 46px;
                border: 4px solid #e2e8f0;
                border-top-color: #047857;
                border-radius: 50%;
                animation: spin 0.9s linear infinite;
                margin: 0 auto 1.25rem;
              }
              @keyframes spin { to { transform: rotate(360deg); } }
              h2 { font-size: 1.15rem; font-weight: 700; color: #047857; margin: 0 0 0.5rem; text-transform: uppercase; letter-spacing: 0.05em; }
              p { font-size: 0.875rem; color: #64748b; margin: 0; line-height: 1.4; }
            </style>
          </head>
          <body>
            <div class="box">
              <div class="spinner"></div>
              <h2>Igreja Presbiteriana do Brasil</h2>
              <p>Processando e gerando documento PDF em alta resolução...<br/>Aguarde um instante.</p>
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
        novaAba.document.body.innerHTML = '<div style="padding:2rem;text-align:center;font-family:sans-serif;color:#ef4444;">Erro: Documento não encontrado para geração de PDF.</div>';
      }
      return;
    }

    // 3. Clona o elemento em um contêiner isolado A4 com fundo branco para PDF nítido
    const clone = originalElement.cloneNode(true) as HTMLElement;
    clone.style.width = '794px'; // Largura padrão A4 (96 DPI)
    clone.style.maxWidth = '794px';
    clone.style.backgroundColor = '#ffffff';
    clone.style.color = '#000000';
    clone.style.padding = '24px';
    clone.style.boxSizing = 'border-box';
    clone.style.margin = '0 auto';

    // Cria contêiner temporário fora da tela
    const tempContainer = document.createElement('div');
    tempContainer.style.position = 'fixed';
    tempContainer.style.left = '-9999px';
    tempContainer.style.top = '0';
    tempContainer.style.width = '794px';
    tempContainer.style.backgroundColor = '#ffffff';
    tempContainer.style.zIndex = '-9999';
    tempContainer.appendChild(clone);
    document.body.appendChild(tempContainer);

    try {
      const h2pdf = (window as any).html2pdf;
      if (h2pdf) {
        const opt = {
          margin: [8, 8, 8, 8],
          filename: `${filename}.pdf`,
          image: { type: 'jpeg', quality: 0.98 },
          html2canvas: {
            scale: 2,
            useCORS: true,
            logging: false,
            backgroundColor: '#ffffff',
          },
          jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
        };

        const pdfBlob: Blob = await h2pdf().set(opt).from(clone).outputPdf('blob');
        const blobUrl = URL.createObjectURL(pdfBlob);

        if (novaAba && !novaAba.closed) {
          novaAba.location.href = blobUrl;
        } else {
          window.open(blobUrl, '_blank');
        }
      } else {
        // Fallback: exibe documento formatado na nova aba
        if (novaAba && !novaAba.closed) {
          novaAba.document.body.innerHTML = `
            <div style="max-width: 800px; margin: 20px auto; padding: 20px; font-family: sans-serif;">
              <div style="text-align: right; margin-bottom: 20px;">
                <button onclick="window.print()" style="padding: 10px 20px; background: #047857; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;">
                  Salvar / Imprimir PDF
                </button>
              </div>
              ${clone.innerHTML}
            </div>
          `;
          setTimeout(() => novaAba.print(), 400);
        }
      }
    } catch (err) {
      console.error('Erro ao gerar PDF:', err);
      if (novaAba && !novaAba.closed) {
        novaAba.document.body.innerHTML = `
          <div style="max-width: 800px; margin: 20px auto; padding: 20px; font-family: sans-serif;">
            <div style="text-align: right; margin-bottom: 20px;">
              <button onclick="window.print()" style="padding: 10px 20px; background: #047857; color: white; border: none; border-radius: 6px; font-weight: bold; cursor: pointer;">
                Salvar / Imprimir PDF
              </button>
            </div>
            ${clone.innerHTML}
          </div>
        `;
        setTimeout(() => novaAba.print(), 300);
      }
    } finally {
      if (tempContainer.parentNode) {
        tempContainer.parentNode.removeChild(tempContainer);
      }
    }
  }
}
