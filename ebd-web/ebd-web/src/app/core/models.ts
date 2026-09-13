export interface AuthUser {
  id: number;
  name: string;
  username: string;
  email: string | null;
  person_id: number | null;
  institution_id: number | null;
  institution: {
    id: number;
    name: string;
    short_name: string;
    type: string;
  } | null;
  is_active: boolean;
  roles: string[];
  permissions: string[];
  is_programmer: boolean;
}

export interface Institution {
  id: number;
  name: string;
  short_name: string;
  type: string;
  code?: string;
  cnpj?: string | null;
  foundation_date?: string | null;
  organization_date?: string | null;
  status: string;
  parent_institution_id?: number | null;
  parent?: { id: number; name: string; short_name: string; type: string; code?: string } | null;
  zipcode?: string | null;
  street?: string | null;
  number?: string | null;
  complement?: string | null;
  district?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
  phone?: string | null;
  whatsapp?: string | null;
  email?: string | null;
  website?: string | null;
  social_media?: Record<string, string> | null;
  logo?: string | null;
  photo?: string | null;
  fantasy_name?: string | null;
  internal_code?: string | null;
  denominational_code?: string | null;
  share_financials_with_parent?: boolean;
  notes?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface InstitutionTreeNode {
  id: number;
  name: string;
  short_name: string;
  type: string;
  code?: string;
  status: string;
  city?: string | null;
  state?: string | null;
  parent_institution_id?: number | null;
  members_count: number;
  subordinates_count: number;
  children: InstitutionTreeNode[];
  expanded?: boolean;
}

export interface InstitutionBreadcrumb {
  id: number;
  name: string;
  short_name: string;
  type: string;
  code?: string;
}

export interface InstitutionSubordinateSummary {
  id: number;
  name: string;
  short_name: string;
  type: string;
  code?: string;
  status: string;
  city?: string | null;
  state?: string | null;
  members_count: number;
  subordinates_count: number;
  share_financials_with_parent?: boolean;
  revenue_total: number | null;
}

export interface InstitutionLinkRequest {
  id: number;
  requester_institution_id: number;
  target_institution_id: number;
  type: 'vinculo_superior' | 'vinculo_inferior' | 'desvinculo';
  status: 'pendente' | 'aceita' | 'recusada' | 'cancelada';
  requested_by_user_id?: number | null;
  actioned_by_user_id?: number | null;
  reason?: string | null;
  action_notes?: string | null;
  actioned_at?: string | null;
  created_at?: string;
  updated_at?: string;
  requester_institution?: Institution;
  target_institution?: Institution;
  requested_by?: { id: number; name: string };
  actioned_by?: { id: number; name: string };
}

export interface ConsolidatedStats {
  institution_id: number;
  is_consolidated: boolean;
  subordinates_direct_count: number;
  subordinates_total_count: number;
  members: {
    total: number;
    tithers: number;
    teachers: number;
    superintendents: number;
  };
  ebd: {
    classes_count: number;
    students_count: number;
  };
  financial: {
    total_revenue: number;
    coletas_count: number;
  };
}

export interface DrilldownStats {
  parent_institution_id: number;
  metric: string;
  items: {
    institution_id: number;
    name: string;
    short_name?: string;
    type: string;
    value: number;
    has_children?: boolean;
  }[];
}

export interface CultRevenueItem {
  date: string;
  service_meeting: string;
  total_amount: number;
  entries_count: number;
}

export interface LoginResponse {
  token: string;
  user: AuthUser;
}

export interface Person {
  id: number;
  full_name: string;
  birth_date: string | null;
  age: number | null;
  is_active: boolean;
  can_teach: boolean;
  can_superintend: boolean;
  is_tither?: boolean;
  tither_since?: string | null;
  envelope_number?: string | null;
  notes: string | null;
  family?: { id: number; name: string; relationship: FamilyRelationship; is_head: boolean } | null;
  created_at?: string;
  updated_at?: string;
}

export type FamilyRelationship = 'responsavel' | 'conjuge' | 'filho' | 'filha' | 'dependente' | 'outro';

export interface FamilyMember {
  id: number;
  full_name: string;
  birth_date: string | null;
  age: number | null;
  is_active: boolean;
  relationship: FamilyRelationship;
  is_head: boolean;
}

export interface Family {
  id: number;
  institution_id: number;
  name: string;
  phone?: string | null;
  whatsapp?: string | null;
  email?: string | null;
  zipcode?: string | null;
  street?: string | null;
  number?: string | null;
  complement?: string | null;
  district?: string | null;
  city?: string | null;
  state?: string | null;
  notes?: string | null;
  is_active: boolean;
  members_count?: number;
  members?: FamilyMember[];
}

export interface ColetaDizimo {
  id: number;
  date: string;
  description: string | null;
  service_meeting: string | null;
  status: 'Aberta' | 'Em conferência' | 'Fechada' | 'Reaberta para correção' | 'Cancelada';
  created_by: number;
  creator?: { id: number; name: string };
  opened_at: string;
  closed_by?: number | null;
  closer?: { id: number; name: string };
  closed_at?: string | null;
  verified_by?: number | null;
  verifier?: { id: number; name: string };
  verified_at?: string | null;
  entry_count: number;
  total_amount: number;
  unidentified_count: number;
  notes?: string | null;
  lancamentos?: LancamentoDizimo[];
  privacy_notice?: string;
}

export interface LancamentoDizimo {
  id: number;
  coleta_id: number;
  person_id: number | null;
  person?: { id: number; full_name: string; envelope_number?: string | null };
  amount: number;
  contribution_type: string;
  is_unidentified: boolean;
  notes?: string | null;
  created_by: number;
  creator?: { id: number; name: string };
  created_at?: string;
}

export interface AlertaDizimo {
  id: number;
  person_id: number;
  person?: { id: number; full_name: string; envelope_number?: string | null; is_tither?: boolean };
  alert_type: 'queda_relevante' | 'interrupcao_contribuicao' | 'historico_insuficiente';
  start_date: string | null;
  detection_date: string;
  variation_percentage: number | null;
  reference_calculation?: {
    reference_average?: number;
    recent_average?: number;
    threshold_percentage?: number;
    months_evaluated?: string[];
    message?: string;
  };
  status: 'Novo' | 'Em análise' | 'Em acompanhamento' | 'Resolvido' | 'Descartado';
  pastor_id?: number | null;
  pastor?: { id: number; name: string };
  notes?: string | null;
  resolved_at?: string | null;
  acompanhamentos?: AcompanhamentoDizimo[];
}

export interface AcompanhamentoDizimo {
  id: number;
  alerta_id: number | null;
  person_id: number;
  responsible_id: number;
  responsible?: { id: number; name: string };
  date: string;
  type: string;
  notes: string | null;
  next_action?: string | null;
  review_date?: string | null;
  status: string;
  conclusion?: string | null;
}

export interface SolicitacaoDiaconato {
  id: number;
  person_id: number;
  person?: { id: number; full_name: string; envelope_number?: string | null; notes?: string | null; families?: Pick<Family, 'id' | 'name' | 'phone' | 'whatsapp'>[] };
  pastor_id: number;
  pastor?: { id: number; name: string };
  diacono_id?: number | null;
  diacono?: { id: number; name: string };
  pastor_notes: string;
  status: 'Pendente' | 'Em atendimento' | 'Concluído' | 'Cancelado';
  created_at?: string;
}

export interface PastoralDashboardStats {
  people_followed: number;
  active_alerts: number;
  new_alerts: number;
  in_progress_alerts: number;
  resolved_alerts: number;
}

export interface MemberFinancialHistory {
  person: {
    id: number;
    full_name: string;
    envelope_number?: string | null;
    is_tither: boolean;
    tither_since?: string | null;
    notes?: string | null;
  };
  metrics: {
    historical_average: number;
    recent_average: number;
    variation_percentage: number;
    trend: 'Estável' | 'Crescimento' | 'Pequena redução' | 'Queda significativa' | 'Sem contribuição recente' | 'Histórico insuficiente';
    months_recorded: number;
    zero_contribution_months: number;
  };
  chart_data: {
    year: number;
    month: number;
    label: string;
    total_amount: number;
    contribution_count: number;
  }[];
}

export interface TithesSettings {
  tithes_min_history_months: string;
  tithes_consecutive_months: string;
  tithes_drop_percentage: string;
  tithes_no_contribution_months: string;
  tithes_alerts_enabled: string;
  tithes_require_double_check: string;
  tithes_allow_multiple_entries: string;
  tithes_allow_unidentified: string;
}

/** Versão com tipos corretos para uso interno no frontend (a API retorna strings) */
export interface TithesSettingsParsed {
  tithes_min_history_months: number;
  tithes_consecutive_months: number;
  tithes_drop_percentage: number;
  tithes_no_contribution_months: number;
  tithes_alerts_enabled: boolean;
  tithes_require_double_check: boolean;
  tithes_allow_multiple_entries: boolean;
  tithes_allow_unidentified: boolean;
}

export function parseTithesSettings(raw: TithesSettings): TithesSettingsParsed {
  return {
    tithes_min_history_months: Number(raw.tithes_min_history_months),
    tithes_consecutive_months: Number(raw.tithes_consecutive_months),
    tithes_drop_percentage: Number(raw.tithes_drop_percentage),
    tithes_no_contribution_months: Number(raw.tithes_no_contribution_months),
    tithes_alerts_enabled: raw.tithes_alerts_enabled === '1' || raw.tithes_alerts_enabled === 'true',
    tithes_require_double_check: raw.tithes_require_double_check === '1' || raw.tithes_require_double_check === 'true',
    tithes_allow_multiple_entries: raw.tithes_allow_multiple_entries === '1' || raw.tithes_allow_multiple_entries === 'true',
    tithes_allow_unidentified: raw.tithes_allow_unidentified === '1' || raw.tithes_allow_unidentified === 'true',
  };
}

export interface Paginated<T> {
  data: T[];
  meta: { current_page: number; last_page: number; per_page: number; total: number };
  links?: unknown;
}

export interface ClassRoom {
  id: number;
  name: string;
  description: string | null;
  age_range: string | null;
  display_order: number;
  is_active: boolean;
  students_count?: number;
  teachers_count?: number;
}

export interface Enrollment {
  id: number;
  class_id: number;
  person_id: number;
  person_name?: string;
  age?: number | null;
  enrolled_at: string | null;
  unenrolled_at: string | null;
  is_active: boolean;
}

export interface ClassTeacher {
  id: number;
  class_id: number;
  person_id: number;
  person_name?: string;
  is_active: boolean;
}

export interface EbdSession {
  id: number;
  ebd_event_id: number;
  class_id: number;
  class_name: string | null;
  status: string;
  status_reason: string | null;
  teacher_person_id: number | null;
  teacher_name: string | null;
  material_mode: string;
  bibles_total: number | null;
  magazines_total: number | null;
  merged_into_class_id: number | null;
  finalized_at: string | null;
}

export interface EbdEvent {
  id: number;
  event_date: string;
  type: string;
  status: string;
  is_auto_generated: boolean;
  superintendent_person_id: number | null;
  superintendent_name: string | null;
  notes: string | null;
  sessions_count?: number;
  sessions?: EbdSession[];
}

export interface AttendanceRecord {
  id: number;
  person_id: number;
  person_name: string;
  present: boolean;
  brought_bible: boolean | null;
  brought_magazine: boolean | null;
}

export interface CallSummary {
  present: number;
  absent: number;
  total: number;
  bibles: number | null;
  magazines: number | null;
}

export interface AuditLog {
  id: number;
  user_id: number | null;
  user?: { id: number; name: string } | null;
  action: string;
  entity_type: string;
  entity_id: number | null;
  old_values?: Record<string, unknown> | null;
  new_values?: Record<string, unknown> | null;
  ip_address?: string | null;
  created_at: string;
}
