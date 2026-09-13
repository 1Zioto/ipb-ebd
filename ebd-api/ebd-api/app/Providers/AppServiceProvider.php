<?php

namespace App\Providers;

use App\Database\Connectors\NeonPostgresConnector;
use App\Models\Person;
use App\Models\Family;
use App\Policies\PersonPolicy;
use App\Policies\FamilyPolicy;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind('db.connector.pgsql', fn () => new NeonPostgresConnector);
    }

    public function boot(): void
    {
        // Programador tem acesso técnico total.
        Gate::before(function ($user, $ability) {
            return $user->isProgrammer() ? true : null;
        });

        Gate::policy(Person::class, PersonPolicy::class);
        Gate::policy(Family::class, FamilyPolicy::class);
    }
}
