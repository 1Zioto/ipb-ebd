<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SettingSeeder extends Seeder
{
    public function run(): void
    {
        $defaults = [
            'ebd_default_weekday' => 0,          // 0 = domingo
            'timezone' => 'America/Sao_Paulo',
            'locale' => 'pt-BR',
            'week_starts_on' => 0,               // semana começa no domingo
            'event_types' => ['regular', 'especial', 'evento', 'outro'],
            'default_material_mode' => 'individual',
        ];

        foreach ($defaults as $key => $value) {
            Setting::firstOrCreate(['key' => $key], ['value' => $value]);
        }
    }
}
