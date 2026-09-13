<?php

namespace App\Traits;

use App\Models\Institution;
use App\Services\InstitutionService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

trait BelongsToInstitution
{
    public function institution(): BelongsTo
    {
        return $this->belongsTo(Institution::class, 'institution_id');
    }

    /** Escopa para somente uma determinada instituição. */
    public function scopeWhereInstitution(Builder $query, int $institutionId): Builder
    {
        return $query->where($this->getTable() . '.institution_id', $institutionId);
    }

    /** Escopa para uma determinada instituição E toda a sua árvore de descendentes. */
    public function scopeWhereInstitutionSubtree(Builder $query, int $rootInstitutionId): Builder
    {
        /** @var InstitutionService $service */
        $service = app(InstitutionService::class);
        $ids = $service->getDescendantIds($rootInstitutionId, true);

        return $query->whereIn($this->getTable() . '.institution_id', $ids);
    }
}
