<?php

namespace App\Console\Commands;

use App\Models\Person;
use App\Models\Family;
use Illuminate\Console\Command;

class ListarPessoasParaFamiliasCommand extends Command
{
    protected $signature = 'debug:pessoas-familias';

    public function handle(): int
    {
        $pessoas = Person::where('institution_id', 5)->orderBy('id')->get();
        $this->info("Total de pessoas na instituição 5: " . $pessoas->count());

        $familiasExistentes = Family::where('institution_id', 5)->with('members')->get();
        $this->info("Total de famílias existentes: " . $familiasExistentes->count());
        foreach ($familiasExistentes as $f) {
            $this->line("- {$f->name} (Membros: {$f->members->count()})");
            foreach ($f->members as $m) {
                $this->line("    * {$m->full_name} ({$m->pivot->relationship}, chefe=" . ($m->pivot->is_head ? 'sim' : 'não') . ")");
            }
        }

        $this->info("\nLista de todas as pessoas:");
        foreach ($pessoas as $p) {
            $this->line("ID: {$p->id} | {$p->full_name} | Sexo: {$p->gender} | Idade: {$p->age} | Civil: {$p->marital_status} | Conjuge: {$p->spouse_name}");
        }

        return 0;
    }
}
