<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EbdEvent extends Model
{
    use BelongsToInstitution;

    protected $fillable = [
        'institution_id', 'event_date', 'type', 'status', 'is_auto_generated',
        'superintendent_person_id', 'superintendent_name_snapshot', 'notes', 'created_by',
    ];

    protected function casts(): array
    {
        return ['event_date' => 'date', 'is_auto_generated' => 'boolean'];
    }

    public function sessions(): HasMany { return $this->hasMany(AttendanceSession::class); }
    public function superintendent(): BelongsTo { return $this->belongsTo(Person::class, 'superintendent_person_id'); }
    public function creator(): BelongsTo { return $this->belongsTo(User::class, 'created_by'); }
}
