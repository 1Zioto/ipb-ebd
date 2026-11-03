import '../../core/api_service.dart';

import 'package:flutter/material.dart';

import '../../core/thermal_printer.dart';

import '../../widgets/app_drawer.dart';



class PessoasScreen extends StatefulWidget {

  const PessoasScreen({super.key});



  @override

  State<PessoasScreen> createState() => _PessoasScreenState();

}



class _PessoasScreenState extends State<PessoasScreen> {

  final _searchController = TextEditingController();

  String _searchTerm = '';

  String _selectedFilter = 'Todos'; // 'Todos', 'Comungante', 'Não-Comungante', 'Oficiais'



  bool _isLoading = false;

  List<Map<String, dynamic>> _pessoas = [];



  static final List<Map<String, dynamic>> _defaultPessoas = [

    {

      'id': 10,

      'nome': 'Alice Costa',

      'envelope': '110',

      'tipo': 'Comungante',

      'tel': '(27) 998302-1703',

      'email': 'alice.costa@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Alice Costa',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0104',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 42,

      'nome': 'Amanda Rezende',

      'envelope': '142',

      'tipo': 'Comungante',

      'tel': '(27) 997481-1639',

      'email': 'amanda.rezende@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Amanda Rezende',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0120',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 2,

      'nome': 'Ana Clara Souza',

      'envelope': '102',

      'tipo': 'Comungante',

      'tel': '(27) 996994-6659',

      'email': 'ana.clara.souza@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Ana Clara Souza',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0128',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 58,

      'nome': 'André Luiz Souza',

      'envelope': '158',

      'tipo': 'Comungante',

      'tel': '(27) 998936-9404',

      'email': 'andré.luiz.souza@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família André Luiz Souza',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0167',

      'admissao': '2020-01-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 7,

      'nome': 'Arthur Rodrigues',

      'envelope': '107',

      'tipo': 'Comungante',

      'tel': '(27) 999654-3674',

      'email': 'arthur.rodrigues@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Arthur Rodrigues',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0132',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 12,

      'nome': 'Beatriz Gomes',

      'envelope': '112',

      'tipo': 'Comungante',

      'tel': '(27) 996709-6775',

      'email': 'beatriz.gomes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Beatriz Gomes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0105',

      'admissao': '2024-09-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 69,

      'nome': 'Beatriz Helena Guimarães',

      'envelope': '169',

      'tipo': 'Não-Comungante',

      'tel': '(27) 992325-1441',

      'email': 'beatriz.helena.guimarães@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Beatriz Helena Guimarães',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0156',

      'admissao': '2021-03-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Pedagoga e Professora do Berçário & Maternal',

    },

    {

      'id': 35,

      'nome': 'Benício Moraes',

      'envelope': '135',

      'tipo': 'Comungante',

      'tel': '(27) 997747-2079',

      'email': 'benício.moraes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Benício Moraes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0145',

      'admissao': '2022-05-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 17,

      'nome': 'Bernardo Almeida',

      'envelope': '117',

      'tipo': 'Não-Comungante',

      'tel': '(27) 991711-9241',

      'email': 'bernardo.almeida@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Bernardo Almeida',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0136',

      'admissao': '2025-11-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 45,

      'nome': 'Bruno Tavares',

      'envelope': '145',

      'tipo': 'Comungante',

      'tel': '(27) 992327-8234',

      'email': 'bruno.tavares@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Bruno Tavares',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0150',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 33,

      'nome': 'Caio Batista',

      'envelope': '133',

      'tipo': 'Comungante',

      'tel': '(27) 994040-2337',

      'email': 'caio.batista@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Caio Batista',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0144',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 48,

      'nome': 'Camila Borges',

      'envelope': '148',

      'tipo': 'Comungante',

      'tel': '(27) 993082-1470',

      'email': 'camila.borges@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Camila Borges',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0123',

      'admissao': '2024-09-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 71,

      'nome': 'Camila Siqueira Paiva',

      'envelope': '171',

      'tipo': 'Comungante',

      'tel': '(27) 995785-8200',

      'email': 'camila.siqueira.paiva@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Camila Siqueira Paiva',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0158',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professora da Classe de Juniores',

    },

    {

      'id': 54,

      'nome': 'Carlos Eduardo Lima',

      'envelope': '154',

      'tipo': 'Comungante',

      'tel': '(27) 992773-7010',

      'email': 'carlos.eduardo.lima@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Carlos Eduardo Lima',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0163',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 30,

      'nome': 'Cecília Monteiro',

      'envelope': '130',

      'tipo': 'Comungante',

      'tel': '(27) 992673-6262',

      'email': 'cecília.monteiro@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Cecília Monteiro',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0114',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 61,

      'nome': 'Cristiane Almeida Nunes',

      'envelope': '161',

      'tipo': 'Comungante',

      'tel': '(27) 993913-2017',

      'email': 'cristiane.almeida.nunes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Cristiane Almeida Nunes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0170',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 31,

      'nome': 'Daniel Vieira',

      'envelope': '131',

      'tipo': 'Comungante',

      'tel': '(27) 998638-8680',

      'email': 'daniel.vieira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Daniel Vieira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0143',

      'admissao': '2020-01-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 72,

      'nome': 'Daniela Martins Prado',

      'envelope': '172',

      'tipo': 'Comungante',

      'tel': '(27) 994936-7454',

      'email': 'daniela.martins.prado@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Daniela Martins Prado',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0159',

      'admissao': '2024-09-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professora da Classe de Primários',

    },

    {

      'id': 9,

      'nome': 'Davi Pereira',

      'envelope': '109',

      'tipo': 'Comungante',

      'tel': '(27) 999484-7965',

      'email': 'davi.pereira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Davi Pereira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0133',

      'admissao': '2022-05-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 65,

      'nome': 'Diác. André Luiz Ramos',

      'envelope': '165',

      'tipo': 'Sob Disciplina',

      'tel': '(27) 995748-5170',

      'email': 'diác..andré.luiz.ramos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Diác. André Luiz Ramos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0175',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Superintendência de Apoio e Logística',

    },

    {

      'id': 66,

      'nome': 'Diác. Felipe Mendes Bastos',

      'envelope': '166',

      'tipo': 'Falecido',

      'tel': '(27) 993605-6658',

      'email': 'diác..felipe.mendes.bastos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Diác. Felipe Mendes Bastos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0176',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Superintendência de Apoio e Professor Substituto',

    },

    {

      'id': 1,

      'nome': 'Douglas Zioto',

      'envelope': '101',

      'tipo': 'Não-Comungante',

      'tel': '(27) 994011-1365',

      'email': 'douglas.zioto@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Douglas Zioto',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0101',

      'admissao': '2020-01-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Membro cadastrado no Rol Oficial.',

    },

    {

      'id': 47,

      'nome': 'Eduardo Peixoto',

      'envelope': '147',

      'tipo': 'Não-Comungante',

      'tel': '(27) 991705-7056',

      'email': 'eduardo.peixoto@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Eduardo Peixoto',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0151',

      'admissao': '2022-05-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 32,

      'nome': 'Emanuelly Andrade',

      'envelope': '132',

      'tipo': 'Comungante',

      'tel': '(27) 998638-7137',

      'email': 'emanuelly.andrade@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Emanuelly Andrade',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0115',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 29,

      'nome': 'Enzo Freitas',

      'envelope': '129',

      'tipo': 'Comungante',

      'tel': '(27) 997176-7041',

      'email': 'enzo.freitas@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Enzo Freitas',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0142',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 40,

      'nome': 'Esther Azevedo',

      'envelope': '140',

      'tipo': 'Comungante',

      'tel': '(27) 997278-6226',

      'email': 'esther.azevedo@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Esther Azevedo',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0147',

      'admissao': '2024-09-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 43,

      'nome': 'Felipe Guimarães',

      'envelope': '143',

      'tipo': 'Não-Comungante',

      'tel': '(27) 998232-9463',

      'email': 'felipe.guimarães@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Felipe Guimarães',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0121',

      'admissao': '2022-05-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 55,

      'nome': 'Fernanda Alves Costa',

      'envelope': '155',

      'tipo': 'Comungante',

      'tel': '(27) 994020-9972',

      'email': 'fernanda.alves.costa@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Fernanda Alves Costa',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0164',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 11,

      'nome': 'Gabriel Martins',

      'envelope': '111',

      'tipo': 'Comungante',

      'tel': '(27) 996792-8886',

      'email': 'gabriel.martins@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Gabriel Martins',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0134',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 50,

      'nome': 'Gabriela Miranda',

      'envelope': '150',

      'tipo': 'Comungante',

      'tel': '(27) 998406-1901',

      'email': 'gabriela.miranda@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Gabriela Miranda',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0124',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 25,

      'nome': 'Gustavo Moreira',

      'envelope': '125',

      'tipo': 'Comungante',

      'tel': '(27) 998716-8339',

      'email': 'gustavo.moreira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Gustavo Moreira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0140',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 27,

      'nome': 'Heitor Correia',

      'envelope': '127',

      'tipo': 'Não-Comungante',

      'tel': '(27) 998461-5282',

      'email': 'heitor.correia@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Heitor Correia',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0141',

      'admissao': '2024-09-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 8,

      'nome': 'Helena Alves',

      'envelope': '108',

      'tipo': 'Comungante',

      'tel': '(27) 991873-8910',

      'email': 'helena.alves@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Helena Alves',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0103',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 41,

      'nome': 'Henrique Lopes',

      'envelope': '141',

      'tipo': 'Comungante',

      'tel': '(27) 992959-3247',

      'email': 'henrique.lopes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Henrique Lopes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0148',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 22,

      'nome': 'Isabela Nunes',

      'envelope': '122',

      'tipo': 'Comungante',

      'tel': '(27) 992944-2011',

      'email': 'isabela.nunes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Isabela Nunes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0110',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 73,

      'nome': 'José Fernando Peixoto',

      'envelope': '173',

      'tipo': 'Não-Comungante',

      'tel': '(27) 994533-9030',

      'email': 'josé.fernando.peixoto@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família José Fernando Peixoto',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0171',

      'admissao': '2024-09-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Membro cadastrado no Rol Oficial.',

    },

    {

      'id': 3,

      'nome': 'João Pedro Santos',

      'envelope': '103',

      'tipo': 'Comungante',

      'tel': '(27) 996155-7476',

      'email': 'joão.pedro.santos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família João Pedro Santos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0129',

      'admissao': '2024-09-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 74,

      'nome': 'Juliana Freitas Albuquerque',

      'envelope': '174',

      'tipo': 'Comungante',

      'tel': '(27) 997160-4555',

      'email': 'juliana.freitas.albuquerque@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Juliana Freitas Albuquerque',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0127',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professora da Classe de Adolescentes',

    },

    {

      'id': 57,

      'nome': 'Juliana Martins Rocha',

      'envelope': '157',

      'tipo': 'Não-Comungante',

      'tel': '(27) 994659-6846',

      'email': 'juliana.martins.rocha@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Juliana Martins Rocha',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0166',

      'admissao': '2025-11-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 18,

      'nome': 'Júlia Fernandes',

      'envelope': '118',

      'tipo': 'Comungante',

      'tel': '(27) 992377-4162',

      'email': 'júlia.fernandes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Júlia Fernandes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0108',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 6,

      'nome': 'Laura Ferreira',

      'envelope': '106',

      'tipo': 'Comungante',

      'tel': '(27) 999195-3781',

      'email': 'laura.ferreira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Laura Ferreira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0102',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 44,

      'nome': 'Letícia Cavalcante',

      'envelope': '144',

      'tipo': 'Comungante',

      'tel': '(27) 998953-8923',

      'email': 'letícia.cavalcante@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Letícia Cavalcante',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0149',

      'admissao': '2020-01-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 36,

      'nome': 'Lorena Pinto',

      'envelope': '136',

      'tipo': 'Comungante',

      'tel': '(27) 994878-5064',

      'email': 'lorena.pinto@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Lorena Pinto',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0117',

      'admissao': '2024-09-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 19,

      'nome': 'Lucas Araújo',

      'envelope': '119',

      'tipo': 'Comungante',

      'tel': '(27) 999258-1649',

      'email': 'lucas.araújo@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Lucas Araújo',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0137',

      'admissao': '2020-01-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 68,

      'nome': 'Lucas Gabriel Rocha',

      'envelope': '168',

      'tipo': 'Comungante',

      'tel': '(27) 994776-5225',

      'email': 'lucas.gabriel.rocha@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Lucas Gabriel Rocha',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0155',

      'admissao': '2020-01-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Líder da Mocidade (UMP) e Professor',

    },

    {

      'id': 24,

      'nome': 'Luiza Rocha',

      'envelope': '124',

      'tipo': 'Não-Comungante',

      'tel': '(27) 995910-4479',

      'email': 'luiza.rocha@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Luiza Rocha',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0111',

      'admissao': '2024-09-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 28,

      'nome': 'Lívia Castro',

      'envelope': '128',

      'tipo': 'Comungante',

      'tel': '(27) 999561-3977',

      'email': 'lívia.castro@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Lívia Castro',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0113',

      'admissao': '2020-01-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 16,

      'nome': 'Manuela Barbosa',

      'envelope': '116',

      'tipo': 'Comungante',

      'tel': '(27) 997939-3405',

      'email': 'manuela.barbosa@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Manuela Barbosa',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0107',

      'admissao': '2020-01-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 52,

      'nome': 'Marcos Antônio Silva',

      'envelope': '152',

      'tipo': 'Não-Comungante',

      'tel': '(27) 994207-3035',

      'email': 'marcos.antônio.silva@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Marcos Antônio Silva',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0161',

      'admissao': '2020-01-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 4,

      'nome': 'Maria Eduarda Lima',

      'envelope': '104',

      'tipo': 'Comungante',

      'tel': '(27) 994434-7368',

      'email': 'maria.eduarda.lima@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Maria Eduarda Lima',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0130',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 67,

      'nome': 'Mariana Castro Silveira',

      'envelope': '167',

      'tipo': 'Comungante',

      'tel': '(27) 999039-2678',

      'email': 'mariana.castro.silveira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Mariana Castro Silveira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0154',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professora da Classe de Casais',

    },

    {

      'id': 26,

      'nome': 'Mariana Dias',

      'envelope': '126',

      'tipo': 'Comungante',

      'tel': '(27) 997230-7587',

      'email': 'mariana.dias@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Mariana Dias',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0112',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 21,

      'nome': 'Matheus Cardoso',

      'envelope': '121',

      'tipo': 'Comungante',

      'tel': '(27) 998273-5927',

      'email': 'matheus.cardoso@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Matheus Cardoso',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0138',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 38,

      'nome': 'Melissa Farias',

      'envelope': '138',

      'tipo': 'Comungante',

      'tel': '(27) 992241-1717',

      'email': 'melissa.farias@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Melissa Farias',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0118',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 5,

      'nome': 'Miguel Oliveira',

      'envelope': '105',

      'tipo': 'Não-Comungante',

      'tel': '(27) 999146-5811',

      'email': 'miguel.oliveira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Miguel Oliveira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0131',

      'admissao': '2020-01-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 46,

      'nome': 'Natália Neves',

      'envelope': '146',

      'tipo': 'Comungante',

      'tel': '(27) 999726-5921',

      'email': 'natália.neves@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Natália Neves',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0122',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 37,

      'nome': 'Nicolas Cunha',

      'envelope': '137',

      'tipo': 'Não-Comungante',

      'tel': '(27) 997901-3944',

      'email': 'nicolas.cunha@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Nicolas Cunha',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0146',

      'admissao': '2023-07-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 53,

      'nome': 'Patrícia Oliveira Santos',

      'envelope': '153',

      'tipo': 'Comungante',

      'tel': '(27) 991366-6343',

      'email': 'patrícia.oliveira.santos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Patrícia Oliveira Santos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0162',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 70,

      'nome': 'Paulo Henrique Antunes',

      'envelope': '170',

      'tipo': 'Comungante',

      'tel': '(27) 993951-8236',

      'email': 'paulo.henrique.antunes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Paulo Henrique Antunes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0157',

      'admissao': '2022-05-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor da Classe Bereana (Adultos)',

    },

    {

      'id': 60,

      'nome': 'Paulo Henrique Ribeiro',

      'envelope': '160',

      'tipo': 'Comungante',

      'tel': '(27) 991340-5495',

      'email': 'paulo.henrique.ribeiro@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Paulo Henrique Ribeiro',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0169',

      'admissao': '2022-05-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 15,

      'nome': 'Pedro Henrique Silva',

      'envelope': '115',

      'tipo': 'Não-Comungante',

      'tel': '(27) 992530-2335',

      'email': 'pedro.henrique.silva@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Pedro Henrique Silva',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0126',

      'admissao': '2021-03-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 63,

      'nome': 'Presb. Marcos Vinícius Toledo',

      'envelope': '163',

      'tipo': 'Oficial (Presbítero)',

      'tel': '(27) 999801-5493',

      'email': 'presb..marcos.vinícius.toledo@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Presb. Marcos Vinícius Toledo',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0173',

      'admissao': '2020-01-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Superintendente Geral da EBD',

    },

    {

      'id': 64,

      'nome': 'Presb. Roberto Alencar Fontes',

      'envelope': '164',

      'tipo': 'Oficial (Presbítero)',

      'tel': '(27) 994719-5183',

      'email': 'presb..roberto.alencar.fontes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Presb. Roberto Alencar Fontes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0174',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Superintendente Adjunto e Professor de Adultos',

    },

    {

      'id': 23,

      'nome': 'Rafael Teixeira',

      'envelope': '123',

      'tipo': 'Comungante',

      'tel': '(27) 996492-3419',

      'email': 'rafael.teixeira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Rafael Teixeira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0139',

      'admissao': '2022-05-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 59,

      'nome': 'Renata Ferreira Dias',

      'envelope': '159',

      'tipo': 'Comungante',

      'tel': '(27) 994792-4419',

      'email': 'renata.ferreira.dias@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Renata Ferreira Dias',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0168',

      'admissao': '2021-03-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 76,

      'nome': 'Renata Vasconcelos Lima',

      'envelope': '176',

      'tipo': 'Comungante',

      'tel': '(27) 992830-7806',

      'email': 'renata.vasconcelos.lima@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Renata Vasconcelos Lima',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0125',

      'admissao': '2020-01-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professora Auxiliar dos Primários e Berçário',

    },

    {

      'id': 62,

      'nome': 'Rev. Carlos Eduardo Silveira',

      'envelope': '162',

      'tipo': 'Pastor Titular',

      'tel': '(27) 995790-5418',

      'email': 'rev..carlos.eduardo.silveira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Rev. Carlos Eduardo Silveira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0172',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Pastor Titular da IP Campo Verde',

    },

    {

      'id': 56,

      'nome': 'Ricardo Gomes Pereira',

      'envelope': '156',

      'tipo': 'Comungante',

      'tel': '(27) 996147-6062',

      'email': 'ricardo.gomes.pereira@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Ricardo Gomes Pereira',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0165',

      'admissao': '2024-09-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor fictício para demonstração do sistema.',

    },

    {

      'id': 75,

      'nome': 'Ricardo Morais Fontes',

      'envelope': '175',

      'tipo': 'Comungante',

      'tel': '(27) 991798-3930',

      'email': 'ricardo.morais.fontes@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Ricardo Morais Fontes',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0160',

      'admissao': '2025-11-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Professor da Classe de Mocidade / Jovens',

    },

    {

      'id': 13,

      'nome': 'Samuel Ribeiro',

      'envelope': '113',

      'tipo': 'Comungante',

      'tel': '(27) 998600-2001',

      'email': 'samuel.ribeiro@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Samuel Ribeiro',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0135',

      'admissao': '2024-09-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 20,

      'nome': 'Sophia Melo',

      'envelope': '120',

      'tipo': 'Comungante',

      'tel': '(27) 995696-7886',

      'email': 'sophia.melo@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Sophia Melo',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0109',

      'admissao': '2022-05-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 49,

      'nome': 'Thiago Coelho',

      'envelope': '149',

      'tipo': 'Comungante',

      'tel': '(27) 992495-3445',

      'email': 'thiago.coelho@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Thiago Coelho',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0152',

      'admissao': '2023-07-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 14,

      'nome': 'Valentina Carvalho',

      'envelope': '114',

      'tipo': 'Não-Comungante',

      'tel': '(27) 993136-8816',

      'email': 'valentina.carvalho@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Valentina Carvalho',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0106',

      'admissao': '2025-11-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 51,

      'nome': 'Vinícius Duarte',

      'envelope': '151',

      'tipo': 'Comungante',

      'tel': '(27) 992318-1785',

      'email': 'vinícius.duarte@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Vinícius Duarte',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0153',

      'admissao': '2024-09-10',

      'modoAdmissao': 'transferencia',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 39,

      'nome': 'Vitor Hugo Ramos',

      'envelope': '139',

      'tipo': 'Comungante',

      'tel': '(27) 998891-5689',

      'email': 'vitor.hugo.ramos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Casado(a)',

      'familia': 'Família Vitor Hugo Ramos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0119',

      'admissao': '2020-01-10',

      'modoAdmissao': 'profissao_fe_batismo',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

    {

      'id': 34,

      'nome': 'Yasmin Campos',

      'envelope': '134',

      'tipo': 'Não-Comungante',

      'tel': '(27) 997936-9811',

      'email': 'yasmin.campos@email.com',

      'classe': 'Adultos (Bereia)',

      'aniver': '15/10',

      'nascimento': '1990-01-01',

      'cpf': '000.000.000-00',

      'estadoCivil': 'Solteiro(a)',

      'familia': 'Família Yasmin Campos',

      'parentesco': 'Membro',

      'conjuge': '',

      'filhos': '',

      'endereco': 'Endereço cadastrado no sistema',

      'rol': 'ROL-0116',

      'admissao': '2023-07-10',

      'modoAdmissao': 'batismo_infantil',

      'sociedade': 'Sociedade Interna IPB',

      'observacoes': 'Aluno fictício para demonstração do sistema.',

    },

  ];



  @override

  void initState() {

    super.initState();

    _pessoas = List.from(_defaultPessoas);

    _carregarPessoas();

  }



  Future<void> _carregarPessoas() async {

    setState(() => _isLoading = true);

    try {

      final res = await ApiService.instance.getRolMembros(perPage: 300);

      final list = (res['membros'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

      if (list.isNotEmpty && mounted) {

        setState(() {

          _pessoas = list.map((m) {

            final id = m['id'] ?? 0;

            final fullName = (m['full_name'] ?? m['nome'] ?? '').toString();

            final rollNumber = (m['roll_number'] ?? m['rol'] ?? 'ROL-${id.toString().padLeft(4, '0')}').toString();

            final status = (m['canonical_status'] ?? m['tipo'] ?? 'comungante').toString().toLowerCase();



            String tipoLabel = 'Comungante';

            if (status.contains('nao_comungante') || status.contains('não-comungante')) {

              tipoLabel = 'Não-Comungante';

            } else if (status.contains('pastor') || fullName.toLowerCase().contains('rev.') || fullName.toLowerCase().contains('pastor')) {

              tipoLabel = 'Pastor Titular';

            } else if (status.contains('presb') || fullName.toLowerCase().contains('presb.')) {

              tipoLabel = 'Oficial (Presbítero)';

            } else if (status.contains('diac') || fullName.toLowerCase().contains('diác.')) {

              tipoLabel = 'Oficial (Diácono)';

            } else if (status.contains('disciplina')) {

              tipoLabel = 'Sob Disciplina';

            } else if (status.contains('jurisdicao')) {

              tipoLabel = 'Jurisdição Especial';

            }



            return {

              'id': id,

              'nome': fullName,

              'envelope': m['envelope_number']?.toString() ?? (m['envelope']?.toString() ?? '${100 + (id is int ? id : int.tryParse(id.toString()) ?? 0)}'),

              'tipo': tipoLabel,

              'tel': m['phone']?.toString() ?? m['tel']?.toString() ?? '(81) 98765-4321',

              'email': m['email']?.toString() ?? '${fullName.toLowerCase().replaceAll(' ', '.')}@email.com',

              'classe': m['classe']?.toString() ?? 'Adultos (Bereia)',

              'aniver': m['aniver']?.toString() ?? '15/10',

              'nascimento': m['birth_date']?.toString() ?? m['nascimento']?.toString() ?? '1990-01-01',

              'cpf': m['cpf']?.toString() ?? '000.000.000-00',

              'estadoCivil': m['marital_status']?.toString() ?? m['estadoCivil']?.toString() ?? 'Casado(a)',

              'familia': m['family'] is Map ? (m['family']['name']?.toString() ?? 'Família') : (m['familia']?.toString() ?? 'Família $fullName'),

              'parentesco': m['parentesco']?.toString() ?? 'Membro',

              'conjuge': m['spouse_name']?.toString() ?? m['conjuge']?.toString() ?? '',

              'filhos': m['filhos']?.toString() ?? '',

              'endereco': m['address']?.toString() ?? m['endereco']?.toString() ?? 'Endereço cadastrado no sistema',

              'rol': rollNumber,

              'admissao': m['reception_date']?.toString() ?? m['admissao']?.toString() ?? '01/01/2020',

              'modoAdmissao': m['reception_type']?.toString() ?? m['modoAdmissao']?.toString() ?? 'Profissão de Fé',

              'sociedade': m['sociedade']?.toString() ?? 'Sociedade Interna IPB',

              'observacoes': m['notes']?.toString() ?? m['observacoes']?.toString() ?? 'Membro do Rol Oficial da IPB.',

            };

          }).toList();

          _isLoading = false;

        });

        return;

      }

    } catch (_) {}



    if (mounted) {

      setState(() => _isLoading = false);

    }

  }



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  List<Map<String, dynamic>> get _filteredPessoas {

    var list = _pessoas;



    // Filtro por categoria

    if (_selectedFilter == 'Comungante') {

      list = list.where((p) => p['tipo'].toString().contains('Comungante')).toList();

    } else if (_selectedFilter == 'Não-Comungante') {

      list = list.where((p) => p['tipo'].toString().contains('Não-Comungante')).toList();

    } else if (_selectedFilter == 'Oficiais') {

      list = list.where((p) => p['tipo'].toString().contains('Oficial') || p['tipo'].toString().contains('Pastor')).toList();

    }



    if (_searchTerm.isEmpty) return list;

    final term = _searchTerm.toLowerCase();

    return list.where((p) {

      final nome = p['nome'].toString().toLowerCase();

      final env = p['envelope'].toString();

      final fam = (p['familia'] ?? '').toString().toLowerCase();

      final rol = (p['rol'] ?? '').toString();

      return nome.contains(term) || env.contains(term) || fam.contains(term) || rol.contains(term);

    }).toList();

  }



  // ABRIR MODAL DE VISUALIZAÇÃO COMPLETA (DOSSIÊ DO MEMBRO / FAMÍLIA)

  void _openViewModal(Map<String, dynamic> p) {

    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (ctx) => _buildViewBottomSheet(p),

    );

  }



  // ABRIR FORMULÁRIO DE EDIÇÃO / CADASTRO DE PESSOA

  void _openEditModal(Map<String, dynamic> p) {

    final nomeCtrl = TextEditingController(text: p['nome']);

    final envCtrl = TextEditingController(text: p['envelope']);

    final telCtrl = TextEditingController(text: p['tel']);

    final emailCtrl = TextEditingController(text: p['email'] ?? '');

    final classeCtrl = TextEditingController(text: p['classe']);

    final aniverCtrl = TextEditingController(text: p['aniver']);

    final cpfCtrl = TextEditingController(text: p['cpf'] ?? '');

    final familiaCtrl = TextEditingController(text: p['familia'] ?? '');

    final parentescoCtrl = TextEditingController(text: p['parentesco'] ?? '');

    final conjugeCtrl = TextEditingController(text: p['conjuge'] ?? '');

    final filhosCtrl = TextEditingController(text: p['filhos'] ?? '');

    final enderecoCtrl = TextEditingController(text: p['endereco'] ?? '');

    final rolCtrl = TextEditingController(text: p['rol'] ?? '');

    final obsCtrl = TextEditingController(text: p['observacoes'] ?? '');

    String tipoVal = p['tipo'] ?? 'Comungante';



    showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (ctx) {

        return StatefulBuilder(

          builder: (context, setModalState) {

            return Padding(

              padding: EdgeInsets.only(

                bottom: MediaQuery.of(context).viewInsets.bottom + 16,

                top: 20,

                left: 18,

                right: 18,

              ),

              child: SizedBox(

                height: MediaQuery.of(context).size.height * 0.85,

                child: Column(

                  children: [

                    // Cabeçalho da edição

                    Row(

                      children: [

                        Container(

                          padding: const EdgeInsets.all(8),

                          decoration: BoxDecoration(

                            color: const Color(0xFFECFDF5),

                            borderRadius: BorderRadius.circular(10),

                          ),

                          child: const Icon(Icons.edit_note_rounded, color: Color(0xFF047857), size: 24),

                        ),

                        const SizedBox(width: 12),

                        const Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Text(

                                'Editar Membro & Família',

                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),

                              ),

                              Text(

                                'Atualize os dados eclesiásticos, cadastrais e de parentesco',

                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),

                              ),

                            ],

                          ),

                        ),

                        IconButton(

                          onPressed: () => Navigator.of(context).pop(),

                          icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),

                        ),

                      ],

                    ),

                    const Divider(height: 24),



                    // Formulário scrollável

                    Expanded(

                      child: ListView(

                        children: [

                          _buildSectionBadge('DADOS GERAIS & CONTATO'),

                          const SizedBox(height: 10),

                          _buildFormField(controller: nomeCtrl, label: 'Nome Completo', icon: Icons.person_rounded),

                          const SizedBox(height: 12),

                          Row(

                            children: [

                              Expanded(

                                flex: 2,

                                child: _buildFormField(controller: envCtrl, label: 'Envelope nº', icon: Icons.tag_rounded),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                flex: 2,

                                child: _buildFormField(controller: rolCtrl, label: 'ROL nº', icon: Icons.book_rounded),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                flex: 3,

                                child: _buildFormField(controller: aniverCtrl, label: 'Aniversário', icon: Icons.cake_rounded),

                              ),

                            ],

                          ),

                          const SizedBox(height: 12),

                          Row(

                            children: [

                              Expanded(

                                child: _buildFormField(controller: telCtrl, label: 'Telefone / WhatsApp', icon: Icons.phone_rounded),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                child: _buildFormField(controller: cpfCtrl, label: 'CPF', icon: Icons.badge_rounded),

                              ),

                            ],

                          ),

                          const SizedBox(height: 12),

                          _buildFormField(controller: emailCtrl, label: 'E-mail do Membro', icon: Icons.email_rounded),

                          const SizedBox(height: 12),

                          _buildFormField(controller: enderecoCtrl, label: 'Endereço Residencial', icon: Icons.location_on_rounded),



                          const SizedBox(height: 20),

                          _buildSectionBadge('VÍNCULO FAMILIAR & DOMICÍLIO'),

                          const SizedBox(height: 10),

                          _buildFormField(controller: familiaCtrl, label: 'Nome da Família / Núcleo', icon: Icons.roofing_rounded),

                          const SizedBox(height: 12),

                          Row(

                            children: [

                              Expanded(

                                child: _buildFormField(controller: parentescoCtrl, label: 'Grau / Papel no Lar', icon: Icons.people_rounded),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                child: _buildFormField(controller: conjugeCtrl, label: 'Nome do Cônjuge', icon: Icons.favorite_rounded),

                              ),

                            ],

                          ),

                          const SizedBox(height: 12),

                          _buildFormField(controller: filhosCtrl, label: 'Filhos / Dependentes', icon: Icons.child_care_rounded),



                          const SizedBox(height: 20),

                          _buildSectionBadge('ECLESIÁSTICO & ESCOLA DOMINICAL'),

                          const SizedBox(height: 10),

                          DropdownButtonFormField<String>(

                            initialValue: tipoVal,

                            decoration: InputDecoration(

                              labelText: 'Condição do Membro',

                              prefixIcon: const Icon(Icons.church_rounded, size: 20, color: Color(0xFF047857)),

                              filled: true,

                              fillColor: const Color(0xFFF8FAFC),

                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),

                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),

                            ),

                            items: const [

                              DropdownMenuItem(value: 'Comungante', child: Text('Comungante')),

                              DropdownMenuItem(value: 'Não-Comungante', child: Text('Não-Comungante')),

                              DropdownMenuItem(value: 'Oficial (Diácono)', child: Text('Oficial (Diácono)')),

                              DropdownMenuItem(value: 'Oficial (Presbítero)', child: Text('Oficial (Presbítero)')),

                              DropdownMenuItem(value: 'Comungante (Profª)', child: Text('Comungante (Professora EBD)')),

                              DropdownMenuItem(value: 'Pastor Titular', child: Text('Pastor Titular')),

                            ],

                            onChanged: (val) {

                              if (val != null) setModalState(() => tipoVal = val);

                            },

                          ),

                          const SizedBox(height: 12),

                          _buildFormField(controller: classeCtrl, label: 'Classe da EBD', icon: Icons.menu_book_rounded),

                          const SizedBox(height: 12),

                          _buildFormField(controller: obsCtrl, label: 'Observações Pastorais / Secretaria', icon: Icons.note_alt_rounded, maxLines: 2),

                          const SizedBox(height: 20),

                        ],

                      ),

                    ),



                    // Botões de Ação

                    Padding(

                      padding: const EdgeInsets.only(top: 8),

                      child: Row(

                        children: [

                          Expanded(

                            child: OutlinedButton(

                              onPressed: () => Navigator.of(context).pop(),

                              style: OutlinedButton.styleFrom(

                                padding: const EdgeInsets.symmetric(vertical: 14),

                                side: const BorderSide(color: Color(0xFFCBD5E1)),

                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                              ),

                              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w700)),

                            ),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            flex: 2,

                            child: ElevatedButton.icon(

                              onPressed: () {

                                setState(() {

                                  p['nome'] = nomeCtrl.text.trim();

                                  p['envelope'] = envCtrl.text.trim();

                                  p['tel'] = telCtrl.text.trim();

                                  p['email'] = emailCtrl.text.trim();

                                  p['classe'] = classeCtrl.text.trim();

                                  p['aniver'] = aniverCtrl.text.trim();

                                  p['cpf'] = cpfCtrl.text.trim();

                                  p['familia'] = familiaCtrl.text.trim();

                                  p['parentesco'] = parentescoCtrl.text.trim();

                                  p['conjuge'] = conjugeCtrl.text.trim();

                                  p['filhos'] = filhosCtrl.text.trim();

                                  p['endereco'] = enderecoCtrl.text.trim();

                                  p['rol'] = rolCtrl.text.trim();

                                  p['tipo'] = tipoVal;

                                  p['observacoes'] = obsCtrl.text.trim();

                                });

                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(

                                  SnackBar(

                                    content: Text('Dados de "${p['nome']}" atualizados com sucesso!'),

                                    backgroundColor: const Color(0xFF047857),

                                  ),

                                );

                              },

                              style: ElevatedButton.styleFrom(

                                backgroundColor: const Color(0xFF047857),

                                foregroundColor: Colors.white,

                                padding: const EdgeInsets.symmetric(vertical: 14),

                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                                elevation: 0,

                              ),

                              icon: const Icon(Icons.check_circle_rounded, size: 20),

                              label: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            );

          },

        );

      },

    );

  }



  // BOTTOM SHEET DE VISUALIZAÇÃO DETALHADA DO MEMBRO

  Widget _buildViewBottomSheet(Map<String, dynamic> p) {

    return Container(

      height: MediaQuery.of(context).size.height * 0.88,

      decoration: const BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      child: Column(

        children: [

          // Barra de arrasto

          Center(

            child: Container(

              margin: const EdgeInsets.only(top: 10, bottom: 6),

              width: 40,

              height: 4,

              decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(10)),

            ),

          ),



          // Header do Membro

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

            decoration: const BoxDecoration(

              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),

            ),

            child: Row(

              children: [

                CircleAvatar(

                  radius: 26,

                  backgroundColor: const Color(0xFFECFDF5),

                  child: Text(

                    p['nome'].toString().substring(0, 1),

                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF047857)),

                  ),

                ),

                const SizedBox(width: 14),

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        p['nome'],

                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),

                      ),

                      const SizedBox(height: 2),

                      Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

                            decoration: BoxDecoration(

                              color: const Color(0xFFECFDF5),

                              borderRadius: BorderRadius.circular(6),

                            ),

                            child: Text(

                              p['tipo'],

                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),

                            ),

                          ),

                          const SizedBox(width: 6),

                          Text(

                            'Envelope #${p['envelope']}',

                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),

                          ),

                        ],

                      ),

                    ],

                  ),

                ),

                IconButton(

                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF047857)),

                  tooltip: 'Editar Membro',

                  onPressed: () {

                    Navigator.of(context).pop();

                    _openEditModal(p);

                  },

                ),

                IconButton(

                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),

                  onPressed: () => Navigator.of(context).pop(),

                ),

              ],

            ),

          ),



          // Informações completas em abas ou blocos

          Expanded(

            child: ListView(

              padding: const EdgeInsets.all(18),

              children: [

                // CARD 1: Registros Eclesiásticos (IPB)

                _buildInfoCard(

                  title: 'REGISTROS ECLESIÁSTICOS (IPB)',

                  icon: Icons.verified_user_rounded,

                  iconColor: const Color(0xFF047857),

                  children: [

                    _buildInfoRow('Livro do ROL Oficial:', 'ROL nº ${p['rol'] ?? '000'}'),

                    _buildInfoRow('Condição do Membro:', p['tipo']),

                    _buildInfoRow('Modo de Recepção:', p['modoAdmissao'] ?? 'Profissão de Fé e Batismo'),

                    _buildInfoRow('Data de Admissão:', p['admissao'] ?? 'Não informada'),

                    _buildInfoRow('Sociedade Interna:', p['sociedade'] ?? 'Geral'),

                  ],

                ),

                const SizedBox(height: 14),



                // CARD 2: Vínculo Familiar & Núcleo

                _buildInfoCard(

                  title: 'NÚCLEO FAMILIAR',

                  icon: Icons.roofing_rounded,

                  iconColor: const Color(0xFF2563EB),

                  children: [

                    _buildInfoRow('Família Cadastrada:', p['familia'] ?? 'Não associada', isHighlight: true),

                    _buildInfoRow('Papel no Lar:', p['parentesco'] ?? 'Membro'),

                    if ((p['conjuge'] ?? '').toString().isNotEmpty)

                      _buildInfoRow('Cônjuge:', p['conjuge']),

                    if ((p['filhos'] ?? '').toString().isNotEmpty)

                      _buildInfoRow('Filhos / Dependentes:', p['filhos']),

                    _buildInfoRow('Endereço do Lar:', p['endereco'] ?? 'Não informado'),

                  ],

                ),

                const SizedBox(height: 14),



                // CARD 3: Dados Pessoais & Contato

                _buildInfoCard(

                  title: 'DADOS PESSOAIS & CONTATO',

                  icon: Icons.badge_rounded,

                  iconColor: const Color(0xFF7C3AED),

                  children: [

                    _buildInfoRow('CPF:', p['cpf'] ?? 'Não informado'),

                    _buildInfoRow('Aniversário:', '${p['aniver']} (${p['nascimento'] ?? 'Não informado'})'),

                    _buildInfoRow('Telefone / WhatsApp:', p['tel']),

                    _buildInfoRow('E-mail:', p['email'] ?? 'Não informado'),

                    _buildInfoRow('Estado Civil:', p['estadoCivil'] ?? 'Não informado'),

                  ],

                ),

                const SizedBox(height: 14),



                // CARD 4: Educação Bíblica & EBD

                _buildInfoCard(

                  title: 'ESCOLA BÍBLICA DOMINICAL (EBD)',

                  icon: Icons.menu_book_rounded,

                  iconColor: const Color(0xFFD97706),

                  children: [

                    _buildInfoRow('Classe Atual:', p['classe']),

                    _buildInfoRow('Observações:', p['observacoes'] ?? 'Nenhuma observação cadastrada.'),

                  ],

                ),

                const SizedBox(height: 18),



                // Ações Rápidas (Impressão de Etiqueta e WhatsApp)

                Row(

                  children: [

                    Expanded(

                      child: OutlinedButton.icon(

                        onPressed: () {

                          ThermalPrinterService.instance.printMemberQrLabel(

                            memberName: p['nome'],

                            envelopeNumber: p['envelope'],

                            qrData: 'IPB:${p['envelope']}',

                          );

                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(

                              content: Text('Enviando etiqueta de ${p['nome']} para a POS...'),

                              backgroundColor: const Color(0xFF047857),

                            ),

                          );

                        },

                        style: OutlinedButton.styleFrom(

                          padding: const EdgeInsets.symmetric(vertical: 12),

                          side: const BorderSide(color: Color(0xFF047857)),

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),

                        icon: const Icon(Icons.print_rounded, size: 18, color: Color(0xFF047857)),

                        label: const Text('Imprimir Etiqueta POS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      child: ElevatedButton.icon(

                        onPressed: () {

                          Navigator.of(context).pop();

                          _openEditModal(p);

                        },

                        style: ElevatedButton.styleFrom(

                          backgroundColor: const Color(0xFF047857),

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 12),

                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                          elevation: 0,

                        ),

                        icon: const Icon(Icons.edit_rounded, size: 18),

                        label: const Text('Editar Cadastro', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildSectionBadge(String title) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),

      child: Text(

        title,

        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),

      ),

    );

  }



  Widget _buildFormField({

    required TextEditingController controller,

    required String label,

    required IconData icon,

    int maxLines = 1,

  }) {

    return TextField(

      controller: controller,

      maxLines: maxLines,

      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),

      decoration: InputDecoration(

        labelText: label,

        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),

        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF047857)),

        filled: true,

        fillColor: const Color(0xFFF8FAFC),

        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),

        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),

        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF047857), width: 1.5)),

      ),

    );

  }



  Widget _buildInfoCard({

    required String title,

    required IconData icon,

    required Color iconColor,

    required List<Widget> children,

  }) {

    return Container(

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color: const Color(0xFFF8FAFC),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFE2E8F0)),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Icon(icon, size: 16, color: iconColor),

              const SizedBox(width: 8),

              Text(

                title,

                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 0.5),

              ),

            ],

          ),

          const SizedBox(height: 10),

          ...children,

        ],

      ),

    );

  }



  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 6),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: 140,

            child: Text(

              label,

              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),

            ),

          ),

          Expanded(

            child: Text(

              value,

              style: TextStyle(

                fontSize: 12,

                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,

                color: isHighlight ? const Color(0xFF047857) : const Color(0xFF0F172A),

              ),

            ),

          ),

        ],

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(

        elevation: 0,

        backgroundColor: Colors.white,

        title: Row(

          children: [

            Image.asset(

              'assets/images/ipb-logo.png',

              width: 26,

              height: 26,

              fit: BoxFit.contain,

              errorBuilder: (_, _, _) => const Icon(Icons.church, color: Color(0xFF047857), size: 22),

            ),

            const SizedBox(width: 8),

            const Text(

              'Pessoas & Famílias',

              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),

            ),

          ],

        ),

        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF047857)),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF047857)),
                  tooltip: 'Sincronizar membros',
                  onPressed: _carregarPessoas,
                ),

          IconButton(

            icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF047857)),

            tooltip: 'Cadastrar Pessoa',

            onPressed: () {

              final novaPessoa = {

                'id': _pessoas.length + 1,

                'nome': '',

                'envelope': '${100 + _pessoas.length + 1}',

                'tipo': 'Comungante',

                'tel': '',

                'email': '',

                'classe': 'Jovens (Bereanos)',

                'aniver': '',

                'nascimento': '',

                'cpf': '',

                'estadoCivil': 'Solteiro',

                'familia': '',

                'parentesco': '',

                'conjuge': '',

                'filhos': '',

                'endereco': '',

                'rol': '',

                'admissao': '',

                'modoAdmissao': 'Profissão de Fé',

                'sociedade': '',

                'observacoes': '',

              };

              _openEditModal(novaPessoa);

            },

          ),

        ],

      ),

      drawer: const AppDrawer(currentRoute: 'pessoas'),

      body: Column(

        children: [

          // Barra de Busca

          Container(

            padding: const EdgeInsets.all(14),

            color: Colors.white,

            child: TextField(

              controller: _searchController,

              decoration: InputDecoration(

                hintText: 'Buscar por nome, envelope, rol ou família...',

                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),

                prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF047857)),

                suffixIcon: _searchTerm.isNotEmpty

                    ? IconButton(

                        icon: const Icon(Icons.clear, size: 18),

                        onPressed: () {

                          _searchController.clear();

                          setState(() => _searchTerm = '');

                        },

                      )

                    : null,

                filled: true,

                fillColor: const Color(0xFFF8FAFC),

                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(12),

                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),

                ),

                enabledBorder: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(12),

                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),

                ),

              ),

              onChanged: (val) => setState(() => _searchTerm = val.trim()),

            ),

          ),



          // Pílulas de Filtro Rápido

          Container(

            height: 44,

            color: Colors.white,

            padding: const EdgeInsets.symmetric(horizontal: 14),

            child: ListView(

              scrollDirection: Axis.horizontal,

              children: [

                _buildFilterChip('Todos'),

                const SizedBox(width: 8),

                _buildFilterChip('Comungante'),

                const SizedBox(width: 8),

                _buildFilterChip('Não-Comungante'),

                const SizedBox(width: 8),

                _buildFilterChip('Oficiais'),

              ],

            ),

          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),



          // Totalizador

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Text(

                  '${_filteredPessoas.length} PESSOAS / FAMÍLIAS',

                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),

                ),

                const Row(

                  children: [

                    Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFF047857)),

                    SizedBox(width: 4),

                    Text('Toque para visualizar ou editar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),

                  ],

                ),

              ],

            ),

          ),



          // Lista de Pessoas

          Expanded(

            child: _filteredPessoas.isEmpty

                ? const Center(

                    child: Text(

                      'Nenhuma pessoa encontrada.',

                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),

                    ),

                  )

                : ListView.separated(

                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),

                    itemCount: _filteredPessoas.length,

                    separatorBuilder: (_, _) => const SizedBox(height: 8),

                    itemBuilder: (context, idx) {

                      final p = _filteredPessoas[idx];

                      return _buildPersonCard(p);

                    },

                  ),

          ),

        ],

      ),

    );

  }



  Widget _buildFilterChip(String label) {

    final isSelected = _selectedFilter == label;

    return GestureDetector(

      onTap: () => setState(() => _selectedFilter = label),

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        decoration: BoxDecoration(

          color: isSelected ? const Color(0xFF047857) : const Color(0xFFF1F5F9),

          borderRadius: BorderRadius.circular(20),

        ),

        child: Center(

          child: Text(

            label,

            style: TextStyle(

              fontSize: 11,

              fontWeight: FontWeight.w800,

              color: isSelected ? Colors.white : const Color(0xFF475569),

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildPersonCard(Map<String, dynamic> p) {

    return Container(

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: const Color(0xFFE2E8F0)),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.02),

            blurRadius: 4,

            offset: const Offset(0, 1),

          ),

        ],

      ),

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          borderRadius: BorderRadius.circular(14),

          onTap: () => _openViewModal(p),

          child: Padding(

            padding: const EdgeInsets.all(12),

            child: Row(

              children: [

                // Avatar com inicial

                Container(

                  width: 44,

                  height: 44,

                  decoration: BoxDecoration(

                    color: const Color(0xFFECFDF5),

                    borderRadius: BorderRadius.circular(12),

                    border: Border.all(color: const Color(0xFFA7F3D0)),

                  ),

                  child: Center(

                    child: Text(

                      p['nome'].toString().substring(0, 1),

                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF047857), fontSize: 18),

                    ),

                  ),

                ),

                const SizedBox(width: 12),



                // Dados centrais

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        p['nome'],

                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A)),

                      ),

                      const SizedBox(height: 2),

                      Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),

                            decoration: BoxDecoration(

                              color: const Color(0xFFF1F5F9),

                              borderRadius: BorderRadius.circular(4),

                            ),

                            child: Text(

                              p['tipo'],

                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF047857)),

                            ),

                          ),

                          const SizedBox(width: 6),

                          Expanded(

                            child: Text(

                              p['familia'] ?? 'Família IPB',

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 2),

                      Text(

                        '📞 ${p['tel']} • 🎂 ${p['aniver']}',

                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),

                      ),

                    ],

                  ),

                ),



                // Botão de editar e Envelope

                Column(

                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

                      decoration: BoxDecoration(

                        color: const Color(0xFFF1F5F9),

                        borderRadius: BorderRadius.circular(8),

                      ),

                      child: Text(

                        '#${p['envelope']}',

                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF047857)),

                      ),

                    ),

                    const SizedBox(height: 4),

                    IconButton(

                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),

                      padding: EdgeInsets.zero,

                      constraints: const BoxConstraints(),

                      tooltip: 'Editar',

                      onPressed: () => _openEditModal(p),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

