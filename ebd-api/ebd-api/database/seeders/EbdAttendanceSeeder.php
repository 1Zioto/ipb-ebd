<?php

namespace Database\Seeders;

use App\Models\AttendanceRecord;
use App\Models\AttendanceSession;
use App\Models\ClassRoom;
use App\Models\ClassStudent;
use App\Models\Institution;
use App\Models\Person;
use Illuminate\Database\Seeder;

class EbdAttendanceSeeder extends Seeder
{
    public function run(): void
    {
        $institution = Institution::find(5) ?: Institution::first();
        if (!$institution) {
            return;
        }

        $institutionId = $institution->id;

        // 1. Garantir que todas as classes tenham alunos matriculados
        $classes = ClassRoom::where('institution_id', $institutionId)->where('is_active', true)->get();
        $people = Person::where('institution_id', $institutionId)->get();

        if ($classes->isEmpty() || $people->isEmpty()) {
            return;
        }

        // Distribuir pessoas pelas classes se ainda não estiverem matriculadas
        $studentsPool = $people->values();
        $studentIndex = 0;

        foreach ($classes as $class) {
            $existingCount = ClassStudent::where('class_id', $class->id)->count();
            if ($existingCount < 6) {
                // Matricular de 6 a 12 alunos por classe
                $needed = 8 - $existingCount;
                for ($i = 0; $i < $needed; $i++) {
                    $person = $studentsPool[$studentIndex % $studentsPool->count()];
                    $studentIndex++;

                    ClassStudent::firstOrCreate([
                        'class_id' => $class->id,
                        'person_id' => $person->id,
                    ], [
                        'enrolled_at' => '2026-01-10',
                        'is_active' => true,
                    ]);
                }
            }
        }

        // 2. Preencher chamadas para todas as sessões com status 'finalizada' (Setembro e 04/10/2026)
        $sessions = AttendanceSession::where('status', 'finalizada')
            ->whereHas('event', function ($q) use ($institutionId) {
                $q->where('institution_id', $institutionId);
            })
            ->with(['classRoom', 'event'])
            ->get();

        foreach ($sessions as $session) {
            $classId = $session->class_id;
            $classStudents = ClassStudent::where('class_id', $classId)->with('person')->get();

            // Se a classe não tiver alunos diretos, pega 8 pessoas aleatórias da igreja
            if ($classStudents->isEmpty()) {
                $slice = $people->shuffle()->take(8);
            } else {
                $slice = $classStudents->pluck('person');
            }

            $biblesCount = 0;
            $magazinesCount = 0;

            foreach ($slice as $idx => $person) {
                if (!$person) continue;

                // 80% chance de presença (determinado pelo ID da pessoa e da sessão para ser consistente)
                $seedNum = ($session->id * 17 + $person->id * 23) % 100;
                $isPresent = $seedNum < 82; // 82% presença

                $hasBible = $isPresent && ($seedNum % 10 < 8); // 80% das presenças
                $hasMagazine = $isPresent && ($seedNum % 10 < 7); // 70% das presenças

                if ($hasBible) $biblesCount++;
                if ($hasMagazine) $magazinesCount++;

                AttendanceRecord::updateOrCreate([
                    'attendance_session_id' => $session->id,
                    'person_id' => $person->id,
                ], [
                    'person_name_snapshot' => $person->full_name,
                    'present' => $isPresent,
                    'brought_bible' => $hasBible,
                    'brought_magazine' => $hasMagazine,
                ]);
            }

            // Atualiza totais na própria sessão
            $session->update([
                'bibles_total' => $biblesCount,
                'magazines_total' => $magazinesCount,
                'finalized_at' => $session->event?->event_date?->copy()->setTime(11, 30, 0) ?? now(),
            ]);
        }
    }
}
