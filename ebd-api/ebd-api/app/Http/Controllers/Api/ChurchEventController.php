<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChurchEvent;
use App\Models\ChurchEventRegistration;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ChurchEventController extends Controller
{
    /** Listar eventos da instituição com métricas agregadas */
    public function index(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;

        $query = ChurchEvent::query()->where('institution_id', $institutionId);

        if ($request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        if ($request->filled('search')) {
            $s = $request->query('search');
            $query->where(function ($q) use ($s) {
                $q->where('title', 'ilike', "%{$s}%")
                    ->orWhere('theme', 'ilike', "%{$s}%")
                    ->orWhere('location_name', 'ilike', "%{$s}%");
            });
        }

        $events = $query->withCount([
            'registrations as total_registrations',
            'registrations as confirmed_registrations' => function ($q) {
                $q->where('status', 'confirmed');
            },
            'registrations as pending_payments' => function ($q) {
                $q->where('payment_status', 'pending');
            },
            'registrations as confirmed_payments' => function ($q) {
                $q->where('payment_status', 'confirmed');
            },
            'registrations as checked_in_count' => function ($q) {
                $q->where('checked_in', true);
            },
        ])
        ->orderBy('starts_at', 'desc')
        ->paginate((int) $request->query('per_page', 15));

        return response()->json($events);
    }

    /** Exibir detalhes completos de um evento com seus inscritos */
    public function show(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($id);

        $registrationsQuery = $event->registrations();

        if ($request->filled('search')) {
            $s = $request->query('search');
            $registrationsQuery->where(function ($q) use ($s) {
                $q->where('full_name', 'ilike', "%{$s}%")
                    ->orWhere('phone', 'ilike', "%{$s}%")
                    ->orWhere('registration_code', 'ilike', "%{$s}%")
                    ->orWhere('cpf', 'ilike', "%{$s}%");
            });
        }

        if ($request->filled('payment_status')) {
            $registrationsQuery->where('payment_status', $request->query('payment_status'));
        }

        if ($request->filled('checked_in')) {
            $registrationsQuery->where('checked_in', filter_var($request->query('checked_in'), FILTER_VALIDATE_BOOLEAN));
        }

        $registrations = $registrationsQuery->orderBy('created_at', 'desc')->get();

        $stats = [
            'total' => $event->registrations()->count(),
            'confirmed' => $event->registrations()->where('status', 'confirmed')->count(),
            'pending_payment' => $event->registrations()->where('payment_status', 'pending')->count(),
            'confirmed_payment' => $event->registrations()->where('payment_status', 'confirmed')->count(),
            'checked_in' => $event->registrations()->where('checked_in', true)->count(),
            'total_collected' => (float) $event->registrations()->where('payment_status', 'confirmed')->sum('payment_amount'),
            'capacity' => $event->max_capacity,
            'remaining_capacity' => $event->max_capacity ? max(0, $event->max_capacity - $event->registrations()->where('status', 'confirmed')->count()) : null,
        ];

        return response()->json([
            'event' => $event,
            'stats' => $stats,
            'registrations' => $registrations,
        ]);
    }

    /** Criar novo evento */
    public function store(Request $request): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;

        $validated = $request->validate([
            'title' => 'required|string|max:150',
            'theme' => 'nullable|string|max:200',
            'description' => 'nullable|string',
            'event_type' => 'nullable|string|max:60',
            'target_audience' => 'nullable|string|max:60',
            'location_name' => 'nullable|string|max:150',
            'location_address' => 'nullable|string|max:250',
            'location_maps_url' => 'nullable|string|max:1000',
            'departure_meeting_point' => 'nullable|string|max:150',
            'departure_time' => 'nullable|string|max:50',
            'starts_at' => 'required|date',
            'ends_at' => 'nullable|date|after_or_equal:starts_at',
            'registration_starts_at' => 'nullable|date',
            'registration_ends_at' => 'nullable|date',
            'max_capacity' => 'nullable|integer|min:1',
            'is_paid' => 'boolean',
            'price' => 'nullable|numeric|min:0',
            'pix_key' => 'nullable|string|max:150',
            'pix_key_type' => 'nullable|string|max:40',
            'pix_receiver_name' => 'nullable|string|max:150',
            'instructions' => 'nullable|string',
            'contact_phone' => 'nullable|string|max:40',
            'contact_email' => 'nullable|email|max:100',
            'require_medical_info' => 'boolean',
            'allow_non_members' => 'boolean',
            'status' => 'nullable|string|in:draft,published,closed,cancelled',
        ]);

        // Gerar slug amigável e único
        $baseSlug = Str::slug($validated['title']);
        $uniqueSuffix = substr(md5(uniqid((string) mt_rand(), true)), 0, 6);
        $slug = $baseSlug ? "{$baseSlug}-{$uniqueSuffix}" : "evento-{$uniqueSuffix}";

        $event = ChurchEvent::create([
            ...$validated,
            'institution_id' => $institutionId,
            'created_by_user_id' => $request->user()->id,
            'slug' => $slug,
            'is_paid' => $validated['is_paid'] ?? false,
            'price' => $validated['price'] ?? 0.00,
            'status' => $validated['status'] ?? 'published',
            'require_medical_info' => $validated['require_medical_info'] ?? true,
            'allow_non_members' => $validated['allow_non_members'] ?? true,
        ]);

        return response()->json($event, 201);
    }

    /** Atualizar evento existente */
    public function update(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:150',
            'theme' => 'nullable|string|max:200',
            'description' => 'nullable|string',
            'event_type' => 'nullable|string|max:60',
            'target_audience' => 'nullable|string|max:60',
            'location_name' => 'nullable|string|max:150',
            'location_address' => 'nullable|string|max:250',
            'location_maps_url' => 'nullable|string|max:1000',
            'departure_meeting_point' => 'nullable|string|max:150',
            'departure_time' => 'nullable|string|max:50',
            'starts_at' => 'sometimes|required|date',
            'ends_at' => 'nullable|date',
            'registration_starts_at' => 'nullable|date',
            'registration_ends_at' => 'nullable|date',
            'max_capacity' => 'nullable|integer|min:1',
            'is_paid' => 'boolean',
            'price' => 'nullable|numeric|min:0',
            'pix_key' => 'nullable|string|max:150',
            'pix_key_type' => 'nullable|string|max:40',
            'pix_receiver_name' => 'nullable|string|max:150',
            'instructions' => 'nullable|string',
            'contact_phone' => 'nullable|string|max:40',
            'contact_email' => 'nullable|email|max:100',
            'require_medical_info' => 'boolean',
            'allow_non_members' => 'boolean',
            'status' => 'nullable|string|in:draft,published,closed,cancelled',
        ]);

        $event->update($validated);

        return response()->json($event);
    }

    /** Excluir evento */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($id);
        $event->delete();

        return response()->json(['message' => 'Evento excluído com sucesso.']);
    }

    /** Atualizar status, pagamento ou presença de uma inscrição */
    public function updateRegistration(Request $request, int $eventId, int $regId): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($eventId);
        $registration = $event->registrations()->findOrFail($regId);

        $validated = $request->validate([
            'payment_status' => 'nullable|string|in:free,pending,confirmed,rejected',
            'payment_amount' => 'nullable|numeric|min:0',
            'payment_notes' => 'nullable|string',
            'checked_in' => 'nullable|boolean',
            'status' => 'nullable|string|in:confirmed,cancelled,waitlist',
            'notes' => 'nullable|string',
        ]);

        if (array_key_exists('checked_in', $validated)) {
            $registration->checked_in = $validated['checked_in'];
            $registration->checked_in_at = $validated['checked_in'] ? now() : null;
        }

        if (isset($validated['payment_status'])) {
            $registration->payment_status = $validated['payment_status'];
        }

        if (isset($validated['payment_amount'])) {
            $registration->payment_amount = $validated['payment_amount'];
        }

        if (array_key_exists('payment_notes', $validated)) {
            $registration->payment_notes = $validated['payment_notes'];
        }

        if (isset($validated['status'])) {
            $registration->status = $validated['status'];
        }

        if (array_key_exists('notes', $validated)) {
            $registration->notes = $validated['notes'];
        }

        $registration->save();

        return response()->json($registration);
    }

    /** Remover uma inscrição */
    public function destroyRegistration(Request $request, int $eventId, int $regId): JsonResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($eventId);
        $registration = $event->registrations()->findOrFail($regId);
        $registration->delete();

        return response()->json(['message' => 'Inscrição removida com sucesso.']);
    }

    /** Exportar lista de inscritos em formato CSV formatado para retiros */
    public function exportCsv(Request $request, int $id): StreamedResponse
    {
        $institutionId = $request->user()->institution_id ?: 5;
        $event = ChurchEvent::where('institution_id', $institutionId)->findOrFail($id);
        $registrations = $event->registrations()->orderBy('full_name')->get();

        $filename = 'inscritos_' . Str::slug($event->title) . '_' . date('Y-m-d') . '.csv';

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ];

        return response()->stream(function () use ($registrations) {
            $output = fopen('php://output', 'w');
            // BOM para compatibilidade com Microsoft Excel
            fprintf($output, chr(0xEF).chr(0xBB).chr(0xBF));

            fputcsv($output, [
                'Código',
                'Nome Completo',
                'Telefone/WhatsApp',
                'E-mail',
                'CPF',
                'Data Nasc.',
                'Gênero',
                'É Membro?',
                'Igreja / Denominação',
                'Menor?',
                'Nome Responsável',
                'Tel. Responsável',
                'Restrições Alimentares',
                'Observações Médicas',
                'Contato Emergência',
                'Tel. Emergência',
                'Status Pagamento',
                'Valor Pago',
                'Check-in (Presente)',
                'Status Inscrição',
                'Data Inscrição',
            ], ';');

            foreach ($registrations as $r) {
                fputcsv($output, [
                    $r->registration_code,
                    $r->full_name,
                    $r->phone,
                    $r->email ?? '',
                    $r->cpf ?? '',
                    $r->birth_date ? $r->birth_date->format('d/m/Y') : '',
                    $r->gender ?? '',
                    $r->is_member ? 'Sim' : 'Não',
                    $r->church_name ?? '',
                    $r->is_minor ? 'Sim' : 'Não',
                    $r->guardian_name ?? '',
                    $r->guardian_phone ?? '',
                    $r->dietary_restrictions ?? '',
                    $r->medical_notes ?? '',
                    $r->emergency_contact_name ?? '',
                    $r->emergency_contact_phone ?? '',
                    $r->payment_status,
                    number_format($r->payment_amount, 2, ',', '.'),
                    $r->checked_in ? 'Sim' : 'Não',
                    $r->status,
                    $r->created_at ? $r->created_at->format('d/m/Y H:i') : '',
                ], ';');
            }

            fclose($output);
        }, 200, $headers);
    }
}

