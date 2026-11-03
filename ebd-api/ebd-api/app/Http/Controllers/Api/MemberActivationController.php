<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\AuditLog;
use App\Models\Institution;
use App\Models\Person;
use App\Models\Role;
use App\Models\User;
use App\Models\UserDevice;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class MemberActivationController extends Controller
{
    /**
     * Valida os dados cadastrais do membro (CPF e data de nascimento)
     * e gera o token de ativação do primeiro acesso.
     */
    public function verify(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'cpf' => 'required|string',
            'birth_date' => 'required|date',
            'institution_id' => 'nullable|integer',
            'institution_code' => 'nullable|string',
        ]);

        $cpfClean = preg_replace('/\D/', '', $validated['cpf']);
        if (strlen($cpfClean) !== 11) {
            throw ValidationException::withMessages([
                'cpf' => ['O CPF informado deve conter 11 dígitos válidos.'],
            ]);
        }

        $institutionId = $validated['institution_id'] ?? null;
        if (! $institutionId && ! empty($validated['institution_code'])) {
            $institution = Institution::where('code', $validated['institution_code'])->first();
            $institutionId = $institution?->id;
        }

        // Busca registro da pessoa pelo CPF e data de nascimento
        $personQuery = Person::query()
            ->whereRaw("REGEXP_REPLACE(cpf, '\D', '', 'g') = ?", [$cpfClean])
            ->whereDate('birth_date', $validated['birth_date']);

        if ($institutionId) {
            $personQuery->where('institution_id', $institutionId);
        }

        $person = $personQuery->first();

        if (! $person) {
            throw ValidationException::withMessages([
                'cpf' => ['Dados não localizados no Rol de Membros da igreja. Verifique os dados com a secretaria.'],
            ]);
        }

        // Verifica se já existe um usuário com senha cadastrada
        $existingUser = User::where('person_id', $person->id)->first();
        if ($existingUser && ! empty($existingUser->password)) {
            return response()->json([
                'already_activated' => true,
                'message' => 'Esta conta já foi ativada previamente. Acesse a tela de login ou solicite a recuperação de senha.',
            ], 409);
        }

        $activationToken = Str::random(48);
        $confirmationCode = sprintf('%06d', mt_rand(100000, 999999));

        DB::table('member_activation_tokens')->insert([
            'person_id' => $person->id,
            'institution_id' => $person->institution_id,
            'token' => $activationToken,
            'code' => $confirmationCode,
            'expires_at' => Carbon::now()->addMinutes(30),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Mascarar telefone e e-mail para privacidade na resposta
        $maskedEmail = null;
        if ($person->email) {
            $parts = explode('@', $person->email);
            $userPart = substr($parts[0], 0, 2) . str_repeat('*', max(1, strlen($parts[0]) - 2));
            $domainPart = $parts[1] ?? 'ipb.org.br';
            $maskedEmail = "{$userPart}@{$domainPart}";
        }

        $maskedPhone = null;
        if ($person->phone) {
            $cleanPhone = preg_replace('/\D/', '', $person->phone);
            $maskedPhone = substr($cleanPhone, 0, 2) . ' ****-' . substr($cleanPhone, -4);
        }

        return response()->json([
            'message' => 'Membro localizado com sucesso. Defina sua senha para concluir a ativação.',
            'activation_token' => $activationToken,
            'member_name' => $person->full_name,
            'church_name' => $person->institution?->name ?? 'Igreja Presbiteriana do Brasil',
            'masked_email' => $maskedEmail,
            'masked_phone' => $maskedPhone,
        ]);
    }

    /**
     * Conclui a ativação definindo a senha inicial do membro e emitindo a credencial de acesso.
     */
    public function confirm(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'activation_token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
            'device_name' => 'nullable|string|max:120',
            'platform' => 'nullable|string|max:50',
            'client_version' => 'nullable|string|max:30',
        ]);

        $record = DB::table('member_activation_tokens')
            ->where('token', $validated['activation_token'])
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->first();

        if (! $record) {
            throw ValidationException::withMessages([
                'activation_token' => ['Token de ativação expirado ou inválido. Inicie o processo novamente.'],
            ]);
        }

        $person = Person::with('institution')->findOrFail($record->person_id);
        $cleanCpf = preg_replace('/\D/', '', $person->cpf ?? '');
        $username = ! empty($cleanCpf) ? $cleanCpf : Str::slug($person->full_name) . '.' . $person->id;
        $email = $person->email ?: "membro_{$person->id}@concilia.ipb.org.br";

        // Cria ou atualiza o usuário correspondente
        $user = User::firstOrNew(['person_id' => $person->id]);
        $user->name = $person->full_name;
        $user->username = $username;
        $user->email = $email;
        $user->password = Hash::make($validated['password']);
        $user->institution_id = $person->institution_id;
        $user->is_active = true;
        $user->last_login_at = now();
        $user->save();

        // Garante o perfil "membro"
        $membroRole = Role::firstOrCreate(
            ['slug' => 'membro'],
            ['name' => 'Membro da Igreja', 'description' => 'Acesso à Área Pessoal e devocional']
        );
        $user->roles()->syncWithoutDetaching([$membroRole->id]);

        // Marca token como utilizado
        DB::table('member_activation_tokens')
            ->where('id', $record->id)
            ->update(['used_at' => now(), 'updated_at' => now()]);

        $user->load('roles.permissions', 'institution');
        $token = $user->createToken('api')->plainTextToken;

        // Registra dispositivo
        $tokenId = $user->tokens()->latest('id')->first()?->id;
        UserDevice::create([
            'user_id' => $user->id,
            'token_id' => $tokenId,
            'device_name' => $validated['device_name'] ?? 'Dispositivo Móvel',
            'platform' => $validated['platform'] ?? 'android',
            'client_version' => $validated['client_version'] ?? '1.1.3',
            'ip_address' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 255),
            'last_active_at' => now(),
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'auth.member_activated',
            'entity_type' => 'user',
            'entity_id' => $user->id,
            'ip' => $request->ip(),
            'user_agent' => substr((string) $request->userAgent(), 0, 255),
        ]);

        return response()->json([
            'message' => 'Conta ativada com sucesso! Bem-vindo ao Concilia-IPB.',
            'token' => $token,
            'user' => new UserResource($user),
            'active_context' => 'personal',
        ], 201);
    }
}

