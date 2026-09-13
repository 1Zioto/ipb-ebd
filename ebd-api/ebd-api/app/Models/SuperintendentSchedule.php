<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SuperintendentSchedule extends Model
{
    protected $fillable = ['ebd_event_id', 'scheduled_person_id', 'notes'];

    public function event(): BelongsTo { return $this->belongsTo(EbdEvent::class, 'ebd_event_id'); }
    public function person(): BelongsTo { return $this->belongsTo(Person::class, 'scheduled_person_id'); }
}
