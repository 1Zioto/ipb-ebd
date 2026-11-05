<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChurchEvent;
use App\Models\ChurchEventRegistration;
use App\Models\Person;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PublicEventController extends Controller
{
    /** Exibir dados públicos do evento pelo slug */
    public function showBySlug(string $slug): JsonResponse
    {
        $event = ChurchEvent::with('institution:id,name,city,state')
            ->where('slug', $slug)
            ->firstOrFail();

        // Verificar disponibilidade de vagas
        $confirmedCount = $event->registrations()->where('status', 'confirmed')->count();
        $isFull = $event->max_capacity ? ($confirmedCount >= $event->max_capacity) : false;
        $remainingSpots = $event->max_capacity ? max(0, $event->max_capacity - $confirmedCount) : null;

        // Verificar período de inscrições
        $now = now();
        $isRegistrationOpen = true;
        if ($event->registration_starts_at && $now->lt($event->registration_starts_at)) {
            $isRegistrationOpen = false;
        }
        if ($event->registration_ends_at && $now->gt($event->registration_ends_at)) {
            $isRegistrationOpen = false;
        }
        if ($event->status !== 'published') {
            $isRegistrationOpen = false;
        }

        return response()->json([
            'event' => [
                'id' => $event->id,
                'title' => $event->title,
                'slug' => $event->slug,
                'theme' => $event->theme,
                'description' => $event->description,
                'event_type' => $event->event_type,
                'target_audience' => $event->target_audience,
                'location_name' => $event->location_name,
                'location_address' => $event->location_address,
                'location_maps_url' => $event->location_maps_url,
                'departure_meeting_point' => $event->departure_meeting_point,
                'departure_time' => $event->departure_time,
                'starts_at' => $event->starts_at,
                'ends_at' => $event->ends_at,
                'registration_starts_at' => $event->registration_starts_at,
                'registration_ends_at' => $event->registration_ends_at,
                'is_paid' => $event->is_paid,
                'price' => (float) $event->price,
                'pix_key' => $event->pix_key,
                'pix_key_type' => $event->pix_key_type,
                'pix_receiver_name' => $event->pix_receiver_name,
                'instructions' => $event->instructions,
                'contact_phone' => $event->contact_phone,
                'contact_email' => $event->contact_email,
                'require_medical_info' => $event->require_medical_info,
                'allow_non_members' => $event->allow_non_members,
                'status' => $event->status,
                'institution' => $event->institution,
            ],
            'availability' => [
                'is_open' => $isRegistrationOpen,
                'is_full' => $isFull,
                'total_registered' => $confirmedCount,
                'max_capacity' => $event->max_capacity,
                'remaining_spots' => $remainingSpots,
            ],
        ]);
    }

    /** Submeter inscrição pública */
    public function register(Request $request, string $slug): JsonResponse
    {
        $event = ChurchEvent::where('slug', $slug)->firstOrFail();

        // Validar status do evento
        if ($event->status !== 'published') {
            return response()->json(['message' => 'As inscrições para este evento não estão abertas.'], 422);
        }

        // Validar capacidade
        $confirmedCount = $event->registrations()->where('status', 'confirmed')->count();
        if ($event->max_capacity && $confirmedCount >= $event->max_capacity) {
            return response()->json(['message' => 'Desculpe, as vagas para este evento foram esgotadas.'], 422);
        }

        $validated = $request->validate([
            'full_name' => 'required|string|max:150',
            'phone' => 'required|string|max:30',
            'email' => 'nullable|email|max:100',
            'cpf' => 'nullable|string|max:20',
            'birth_date' => 'nullable|date',
            'gender' => 'nullable|string|in:M,F',
            'is_member' => 'boolean',
            'church_name' => 'nullable|string|max:150',
            'is_minor' => 'boolean',
            'guardian_name' => 'nullable|string|max:150',
            'guardian_phone' => 'nullable|string|max:30',
            'dietary_restrictions' => 'nullable|string|max:255',
            'medical_notes' => 'nullable|string',
            'emergency_contact_name' => 'nullable|string|max:150',
            'emergency_contact_phone' => 'nullable|string|max:30',
            'notes' => 'nullable|string|max:500',
        ]);

        // Se menor de idade, exigir nome e telefone do responsável
        if (!empty($validated['is_minor']) && (empty($validated['guardian_name']) || empty($validated['guardian_phone']))) {
            return response()->json([
                'message' => 'Para participantes menores de idade, o nome e WhatsApp do responsável são obrigatórios.',
            ], 422);
        }

        // Tentar vincular automaticamente a um membro existente pelo CPF ou Telefone na mesma instituição
        $personId = null;
        if (!empty($validated['cpf'])) {
            $cleanCpf = preg_replace('/\D/', '', $validated['cpf']);
            $person = Person::where('institution_id', $event->institution_id)
                ->whereRaw("regexp_replace(cpf, '\D', '', 'g') = ?", [$cleanCpf])
                ->first();
            if ($person) {
                $personId = $person->id;
            }
        }
        if (!$personId && !empty($validated['phone'])) {
            $cleanPhone = preg_replace('/\D/', '', $validated['phone']);
            $person = Person::where('institution_id', $event->institution_id)
                ->whereRaw("regexp_replace(phone, '\D', '', 'g') LIKE ?", ["%{$cleanPhone}%"])
                ->first();
            if ($person) {
                $personId = $person->id;
            }
        }

        // Gerar código único de inscrição (ex: EVT-8X92K)
        $regCode = 'EVT-' . strtoupper(Str::random(6));

        $paymentStatus = $event->is_paid ? 'pending' : 'free';
        $paymentAmount = $event->is_paid ? $event->price : 0.00;

        $registration = ChurchEventRegistration::create([
            'church_event_id' => $event->id,
            'person_id' => $personId,
            'registration_code' => $regCode,
            'full_name' => trim($validated['full_name']),
            'phone' => trim($validated['phone']),
            'email' => $validated['email'] ?? null,
            'cpf' => $validated['cpf'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'gender' => $validated['gender'] ?? null,
            'is_member' => $validated['is_member'] ?? true,
            'church_name' => $validated['church_name'] ?? null,
            'is_minor' => $validated['is_minor'] ?? false,
            'guardian_name' => $validated['guardian_name'] ?? null,
            'guardian_phone' => $validated['guardian_phone'] ?? null,
            'dietary_restrictions' => $validated['dietary_restrictions'] ?? null,
            'medical_notes' => $validated['medical_notes'] ?? null,
            'emergency_contact_name' => $validated['emergency_contact_name'] ?? null,
            'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? null,
            'payment_status' => $paymentStatus,
            'payment_amount' => $paymentAmount,
            'checked_in' => false,
            'status' => 'confirmed',
            'notes' => $validated['notes'] ?? null,
        ]);

        return response()->json([
            'message' => 'Inscrição realizada com sucesso!',
            'registration_code' => $registration->registration_code,
            'payment_status' => $registration->payment_status,
            'payment_amount' => (float) $registration->payment_amount,
            'pix_key' => $event->pix_key,
            'pix_key_type' => $event->pix_key_type,
            'pix_receiver_name' => $event->pix_receiver_name,
            'event_title' => $event->title,
            'starts_at' => $event->starts_at,
            'location_name' => $event->location_name,
            'location_address' => $event->location_address,
        ], 201);
    }
}

