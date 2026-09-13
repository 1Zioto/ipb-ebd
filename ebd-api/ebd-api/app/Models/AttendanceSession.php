<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AttendanceSession extends Model
{
    protected $fillable = [
        'ebd_event_id', 'class_id', 'status', 'status_reason',
        'teacher_person_id', 'teacher_name_snapshot', 'class_name_snapshot',
        'material_mode', 'bibles_total', 'magazines_total', 'merged_into_class_id',
        'created_by', 'finalized_by', 'finalized_at', 'updated_by',
    ];

    protected function casts(): array
    {
        return ['finalized_at' => 'datetime', 'bibles_total' => 'integer', 'magazines_total' => 'integer'];
    }

    public function event(): BelongsTo { return $this->belongsTo(EbdEvent::class, 'ebd_event_id'); }
    public function classRoom(): BelongsTo { return $this->belongsTo(ClassRoom::class, 'class_id'); }
    public function teacher(): BelongsTo { return $this->belongsTo(Person::class, 'teacher_person_id'); }
    public function records(): HasMany { return $this->hasMany(AttendanceRecord::class); }
}
