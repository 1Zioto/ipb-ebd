<?php

namespace App\Models;

use App\Traits\BelongsToInstitution;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassRoom extends Model
{
    use BelongsToInstitution, SoftDeletes;

    protected $table = 'classes';

    protected $fillable = ['institution_id', 'name', 'description', 'age_range', 'display_order', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'display_order' => 'integer'];
    }

    public function students(): HasMany { return $this->hasMany(ClassStudent::class, 'class_id'); }
    public function teachers(): HasMany { return $this->hasMany(ClassTeacher::class, 'class_id'); }
    public function sessions(): HasMany { return $this->hasMany(AttendanceSession::class, 'class_id'); }

    public function scopeActive($q) { return $q->where('is_active', true); }
}
