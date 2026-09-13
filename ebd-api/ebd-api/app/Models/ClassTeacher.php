<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClassTeacher extends Model
{
    protected $fillable = ['class_id', 'person_id', 'is_active'];

    protected function casts(): array { return ['is_active' => 'boolean']; }

    public function classRoom(): BelongsTo { return $this->belongsTo(ClassRoom::class, 'class_id'); }
    public function person(): BelongsTo { return $this->belongsTo(Person::class); }
}
