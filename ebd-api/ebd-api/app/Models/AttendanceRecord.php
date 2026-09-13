<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceRecord extends Model
{
    protected $fillable = [
        'attendance_session_id', 'person_id', 'person_name_snapshot',
        'present', 'brought_bible', 'brought_magazine',
    ];

    protected function casts(): array
    {
        return ['present' => 'boolean', 'brought_bible' => 'boolean', 'brought_magazine' => 'boolean'];
    }

    public function session(): BelongsTo { return $this->belongsTo(AttendanceSession::class, 'attendance_session_id'); }
    public function person(): BelongsTo { return $this->belongsTo(Person::class); }
}
