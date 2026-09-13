<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StorePersonRequest;
use App\Http\Requests\UpdatePersonRequest;
use App\Http\Resources\PersonResource;
use App\Models\Person;
use App\Support\Audit;
use Illuminate\Http\Request;

class PersonController extends Controller
{
    public function index(Request $request)
    {
        $this->authorize('viewAny', Person::class);

        $q = Person::query()->with('families:id,name');

        if ($request->filled('search')) {
            $q->where('full_name', 'ilike', '%'.$request->string('search').'%');
        }
        if ($request->has('is_active')) {
            $q->where('is_active', $request->boolean('is_active'));
        }
        if ($request->boolean('can_teach')) {
            $q->where('can_teach', true);
        }
        if ($request->boolean('can_superintend')) {
            $q->where('can_superintend', true);
        }

        $q->orderBy('full_name');

        return PersonResource::collection($q->paginate($request->integer('per_page', 20)));
    }

    public function store(StorePersonRequest $request)
    {
        $person = Person::create($request->validated())->refresh();
        Audit::log('person.created', 'person', $person->id, null, $person->toArray());

        return (new PersonResource($person))->response()->setStatusCode(201);
    }

    public function show(Person $person)
    {
        $this->authorize('view', $person);
        return new PersonResource($person->load('families:id,name'));
    }

    public function update(UpdatePersonRequest $request, Person $person)
    {
        $old = $person->toArray();
        $person->update($request->validated());
        Audit::log('person.updated', 'person', $person->id, $old, $person->toArray());

        return new PersonResource($person);
    }

    public function destroy(Person $person)
    {
        $this->authorize('delete', $person);
        // Soft delete + inativação (preserva histórico).
        $person->update(['is_active' => false]);
        $person->delete();
        Audit::log('person.deleted', 'person', $person->id);

        return response()->json(['message' => 'Pessoa inativada.']);
    }

    public function birthdays(Request $request)
    {
        $this->authorize('viewAny', Person::class);
        $scope = $request->string('scope', 'today');

        $q = Person::active()->whereNotNull('birth_date');

        if ((string) $scope === 'week') {
            // Aniversariantes na semana atual (domingo a sábado), por dia/mês.
            $start = now()->startOfWeek(\Carbon\Carbon::SUNDAY);
            $days = collect(range(0, 6))->map(fn ($i) => $start->copy()->addDays($i));
            $q->where(function ($sub) use ($days) {
                foreach ($days as $d) {
                    $sub->orWhere(function ($x) use ($d) {
                        $x->whereRaw('EXTRACT(MONTH FROM birth_date) = ?', [$d->month])
                          ->whereRaw('EXTRACT(DAY FROM birth_date) = ?', [$d->day]);
                    });
                }
            });
        } else {
            $q->birthdayToday();
        }

        return PersonResource::collection($q->orderByRaw('EXTRACT(MONTH FROM birth_date), EXTRACT(DAY FROM birth_date)')->get());
    }
}
