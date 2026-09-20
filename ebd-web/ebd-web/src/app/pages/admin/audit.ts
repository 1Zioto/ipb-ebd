import { CommonModule } from '@angular/common';
import { Component, OnInit, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ButtonModule } from 'primeng/button';
import { TableModule } from 'primeng/table';
import { InputTextModule } from 'primeng/inputtext';
import { MessageModule } from 'primeng/message';
import { EbdService } from '../../core/ebd.service';
@Component({selector:'app-audit',standalone:true,imports:[CommonModule,FormsModule,ButtonModule,TableModule,InputTextModule,MessageModule],templateUrl:'./audit.html'})
export class AuditPage implements OnInit { private svc=inject(EbdService); logs=signal<any[]>([]);loading=signal(false);error=signal<string|null>(null);action='';entity='';ngOnInit(){this.load();}load(){this.loading.set(true);this.svc.getAuditLogs({action:this.action,entity:this.entity}).subscribe({next:r=>{this.logs.set(r.data);this.loading.set(false);},error:e=>{this.error.set(e.error?.message??'Falha ao carregar auditoria.');this.loading.set(false);}});}}
