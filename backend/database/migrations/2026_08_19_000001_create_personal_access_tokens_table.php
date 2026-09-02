
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('personal_access_tokens')) {
            Schema::create('personal_access_tokens', function (Blueprint $table) {
                $table->id();
                $table->string('tokenable_type', 191);
                $table->unsignedBigInteger('tokenable_id');
                $table->index(['tokenable_type', 'tokenable_id']);

                $table->text('name');
                $table->string('token', 64)->unique();
                $table->text('abilities')->nullable();
                $table->timestamp('last_used_at')->nullable();
                $table->timestamp('expires_at')->nullable();
                $table->timestamps();
            });

            return;
        }

        DB::statement("
            ALTER TABLE personal_access_tokens
            MODIFY tokenable_type VARCHAR(191) NOT NULL
        ");

        DB::statement("
            ALTER TABLE personal_access_tokens
            ADD INDEX personal_access_tokens_tokenable_type_tokenable_id_index
            (tokenable_type, tokenable_id)
        ");
    }

    public function down(): void
    {
        Schema::dropIfExists('personal_access_tokens');
    }
};
