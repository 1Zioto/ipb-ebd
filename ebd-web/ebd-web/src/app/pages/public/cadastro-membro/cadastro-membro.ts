import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterModule } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { ButtonModule } from 'primeng/button';
import { InputTextModule } from 'primeng/inputtext';
import { TagModule } from 'primeng/tag';
import { ToastModule } from 'primeng/toast';
import { MessageService } from 'primeng/api';
import { environment } from '@/environments/environment';

export interface PublicChurchInfo {
  id: number;
  name: string;
  short_name: string;
  city: string;
  state: string;
  address?: string;
}

@Component({
  selector: 'app-cadastro-membro-publico',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    RouterModule,
    ButtonModule,
    InputTextModule,
    TagModule,
    ToastModule,
  ],
  providers: [MessageService],
  templateUrl: './cadastro-membro.html',
})
export class CadastroMembroPublicoPage implements OnInit {
  private route = inject(ActivatedRoute);
  private http = inject(HttpClient);
  private msg = inject(MessageService);

  slug = '';
  loading = signal<boolean>(true);
  submitting = signal<boolean>(false);
  church = signal<PublicChurchInfo | null>(null);
  errorNotFound = signal<boolean>(false);

  // Estado de sucesso após envio
  registrationSuccess = signal<boolean>(false);
  applicationId = signal<number | null>(null);

  // Formulário de Cadastro do Membro
  form = {
    full_name: '',
    birth_date: '',
    gender: 'M',
    marital_status: 'solteiro',
    cpf: '',
    rg: '',
    email: '',
    phone: '',
    postal_code: '',
    address: '',
    address_number: '',
    address_complement: '',
    neighborhood: '',
    city: '',
    state: '',
    profession: '',
    education: '',
    father_name: '',
    mother_name: '',
    spouse_name: '',
    is_communicant: true,
    ecclesiastical_condition: 'comungante',
    origin_church: '',
    reception_mode: 'profissao_fe_batismo',
    baptism_date: '',
    baptism_church: '',
    profession_of_faith_date: '',
    notes: '',
  };

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      this.slug = params.get('slug') || '5'; // fallback para a igreja sede caso acesse direto
      this.carregarDadosIgreja();
    });
  }

  carregarDadosIgreja(): void {
    this.loading.set(true);
    const url = `${environment.apiUrl}/public/church/${this.slug}/membership-info`;

    this.http.get<{ institution: PublicChurchInfo }>(url).subscribe({
      next: (res) => {
        this.church.set(res.institution);
        if (res.institution.city) this.form.city = res.institution.city;
        if (res.institution.state) this.form.state = res.institution.state;
        this.loading.set(false);
      },
      error: () => {
        this.errorNotFound.set(true);
        this.loading.set(false);
      },
    });
  }

  buscarCep(): void {
    const cepClean = this.form.postal_code.replace(/\D/g, '');
    if (cepClean.length === 8) {
      this.http.get<any>(`https://viacep.com.br/ws/${cepClean}/json/`).subscribe({
        next: (dados) => {
          if (!dados.erro) {
            this.form.address = dados.logradouro || this.form.address;
            this.form.neighborhood = dados.bairro || this.form.neighborhood;
            this.form.city = dados.localidade || this.form.city;
            this.form.state = dados.uf || this.form.state;
          }
        },
      });
    }
  }

  onSubmit(): void {
    if (!this.form.full_name || !this.form.birth_date || !this.form.phone) {
      this.msg.add({
        severity: 'warn',
        summary: 'Campos Obrigatórios',
        detail: 'Por favor, preencha Nome Completo, Data de Nascimento e Telefone.',
      });
      return;
    }

    this.submitting.set(true);
    const url = `${environment.apiUrl}/public/church/${this.slug}/membership-applications`;

    this.http.post<any>(url, this.form).subscribe({
      next: (res) => {
        this.submitting.set(false);
        this.applicationId.set(res.id || null);
        this.registrationSuccess.set(true);
      },
      error: (err) => {
        this.submitting.set(false);
        const errorMsg = err.error?.message || 'Falha ao enviar sua solicitação de cadastro.';
        this.msg.add({
          severity: 'error',
          summary: 'Atenção',
          detail: errorMsg,
        });
      },
    });
  }
}

