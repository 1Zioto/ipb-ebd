<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClassStudent extends Model
{
    protected $fillable = ['class_id', 'person_id', 'enrolled_at', 'unenrolled_at', 'is_active'];

    protected function casts(): array
    {
        return ['enrolled_at' => 'date', 'unenrolled_at' => 'date', 'is_active' => 'boolean'];
    }

    public function classRoom(): BelongsTo { return $this->belongsTo(ClassRoom::class, 'class_id'); }
    public function person(): BelongsTo { return $this->belongsTo(Person::class); }
}
