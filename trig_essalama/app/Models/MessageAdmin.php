<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

/**
 * Messages admin → intervenants / équipes (collection MongoDB « message_admin »).
 */
class MessageAdmin extends Model
{
    protected $connection = 'mongodb';

    protected $database = 'trig_essalama';

    protected $collection = 'message_admin';

    public $timestamps = false;

    protected $fillable = [
        'recipient_key',
        'body',
        'author_label',
        'author_key',
        'created_at',
        'reply_quote',
        'reply_to_self',
        'audio_storage_path',
        'audio_mime',
        'image_storage_path',
        'image_mime',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
            'reply_to_self' => 'boolean',
        ];
    }
}
