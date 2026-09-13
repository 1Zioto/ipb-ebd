<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherSchedule extends Model
{
    protected $fillable = ['ebd_event_id', 'class_id', 'scheduled_person_id', 'notes'];

    public function event(): BelongsTo { return $this->belongsTo(EbdEvent::class, 'ebd_event_id'); }
    public function classRoom(): BelongsTo { return $this->belongsTo(ClassRoom::class, 'class_id'); }
    public function person(): BelongsTo { return $this->belongsTo(Person::class, 'scheduled_person_id'); }
}
