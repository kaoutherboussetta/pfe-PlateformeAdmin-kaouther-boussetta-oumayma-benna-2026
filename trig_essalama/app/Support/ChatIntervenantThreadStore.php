<?php

namespace App\Support;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use MongoDB\BSON\ObjectId;
use MongoDB\BSON\UTCDateTime;

/**
 * Messages admin du widget « équipes » dans la collection MongoDB {@code chat_intervenant}
 * (même collection que les messages intervenants).
 */
final class ChatIntervenantThreadStore
{
    private const COLLECTION = 'chat_intervenant';

    public static function parseObjectIdFromRouteId(string $id): ?ObjectId
    {
        $id = trim($id);
        if (str_starts_with(strtolower($id), 'ci:')) {
            $id = trim(substr($id, 3));
        }
        if (strlen($id) !== 24 || ! ctype_xdigit($id)) {
            return null;
        }
        try {
            return new ObjectId($id);
        } catch (\Throwable) {
            return null;
        }
    }

    /**
     * @return array<string, mixed>|null
     */
    public static function findByObjectId(ObjectId $oid): ?array
    {
        try {
            $doc = DB::connection('mongodb')->table(self::COLLECTION)->where('_id', $oid)->first();
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant find: '.$e->getMessage());

            return null;
        }
        if ($doc === null) {
            return null;
        }

        return ChatIntervenantReader::mongoDocToAssocArray($doc);
    }

    public static function insertAdminText(
        string $recipientKey,
        string $authorLabel,
        string $authorKey,
        string $body,
        string $replyQuote,
        bool $replyToSelf
    ): ObjectId {
        $oid = new ObjectId;
        $now = new UTCDateTime;
        $doc = array_merge(self::recipientFields($recipientKey), [
            '_id' => $oid,
            'recipient_key' => $recipientKey,
            'senderRole' => 'admin',
            'sender_type' => 'admin',
            'from_admin' => true,
            'text' => $body,
            'message' => $body,
            'author_label' => $authorLabel,
            'author_key' => $authorKey,
            'createdAt' => $now,
            'created_at' => $now,
            'updated_at' => $now,
            'read' => true,
            'lu' => true,
        ]);
        if ($replyQuote !== '') {
            $doc['reply_quote'] = $replyQuote;
            $doc['reply_to_self'] = $replyToSelf;
        }
        DB::connection('mongodb')->table(self::COLLECTION)->insert($doc);

        return $oid;
    }

    public static function insertAdminVoice(
        string $recipientKey,
        string $authorLabel,
        string $authorKey,
        string $relativePath,
        string $mime
    ): ObjectId {
        $oid = new ObjectId;
        $now = new UTCDateTime;
        DB::connection('mongodb')->table(self::COLLECTION)->insert(array_merge(self::recipientFields($recipientKey), [
            '_id' => $oid,
            'recipient_key' => $recipientKey,
            'senderRole' => 'admin',
            'sender_type' => 'admin',
            'from_admin' => true,
            'text' => '🎤 Message vocal',
            'message' => '🎤 Message vocal',
            'author_label' => $authorLabel,
            'author_key' => $authorKey,
            'createdAt' => $now,
            'created_at' => $now,
            'updated_at' => $now,
            'read' => true,
            'lu' => true,
            'audio_storage_path' => $relativePath,
            'audio_mime' => $mime,
        ]));

        return $oid;
    }

    /**
     * @param  array{reply_quote?: string, reply_to_self?: bool}  $reply
     */
    public static function insertAdminImage(
        string $recipientKey,
        string $authorLabel,
        string $authorKey,
        string $relativePath,
        string $mime,
        string $body,
        array $reply
    ): ObjectId {
        $oid = new ObjectId;
        $now = new UTCDateTime;
        $doc = array_merge(self::recipientFields($recipientKey), [
            '_id' => $oid,
            'recipient_key' => $recipientKey,
            'senderRole' => 'admin',
            'sender_type' => 'admin',
            'from_admin' => true,
            'text' => $body,
            'message' => $body,
            'author_label' => $authorLabel,
            'author_key' => $authorKey,
            'createdAt' => $now,
            'created_at' => $now,
            'updated_at' => $now,
            'read' => true,
            'lu' => true,
            'image_storage_path' => $relativePath,
            'image_mime' => $mime,
        ]);
        $rq = trim((string) ($reply['reply_quote'] ?? ''));
        if ($rq !== '') {
            $doc['reply_quote'] = $rq;
            $doc['reply_to_self'] = (bool) ($reply['reply_to_self'] ?? false);
        }
        DB::connection('mongodb')->table(self::COLLECTION)->insert($doc);

        return $oid;
    }

    public static function isAdminAuthoredThreadDoc(array $row): bool
    {
        return ChatIntervenantReader::isLikelyFromAdmin($row);
    }

    public static function updateAdminText(ObjectId $oid, string $recipientKey, string $authorKey, string $body): bool
    {
        $row = self::findByObjectId($oid);
        if ($row === null || ! self::isAdminAuthoredThreadDoc($row)) {
            return false;
        }
        if (trim((string) ($row['recipient_key'] ?? '')) !== $recipientKey) {
            return false;
        }
        if (trim((string) ($row['author_key'] ?? '')) !== $authorKey) {
            return false;
        }
        if (trim((string) ($row['audio_storage_path'] ?? '')) !== '' || trim((string) ($row['image_storage_path'] ?? '')) !== '') {
            return false;
        }
        try {
            DB::connection('mongodb')->table(self::COLLECTION)->where('_id', $oid)->update([
                'text' => $body,
                'message' => $body,
                'updated_at' => new UTCDateTime,
            ]);
        } catch (\Throwable $e) {
            Log::error('chat_intervenant admin update: '.$e->getMessage());

            return false;
        }

        return true;
    }

    /**
     * @return array{audio: string, image: string}|null
     */
    public static function deleteAdminMessage(ObjectId $oid, string $recipientKey, string $authorKey): ?array
    {
        $row = self::findByObjectId($oid);
        if ($row === null || ! self::isAdminAuthoredThreadDoc($row)) {
            return null;
        }
        if (trim((string) ($row['recipient_key'] ?? '')) !== $recipientKey) {
            return null;
        }
        if (trim((string) ($row['author_key'] ?? '')) !== $authorKey) {
            return null;
        }
        $audio = trim((string) ($row['audio_storage_path'] ?? ''));
        $image = trim((string) ($row['image_storage_path'] ?? ''));
        try {
            DB::connection('mongodb')->table(self::COLLECTION)->where('_id', $oid)->delete();
        } catch (\Throwable $e) {
            Log::error('chat_intervenant admin delete: '.$e->getMessage());

            return null;
        }

        return ['audio' => $audio, 'image' => $image];
    }

    /**
     * Champs métier redondants pour que MongoDB reste lisible et compatible
     * avec les requêtes qui ne connaissent pas recipient_key.
     *
     * @return array<string, string>
     */
    private static function recipientFields(string $recipientKey): array
    {
        if (str_starts_with($recipientKey, 'm:')) {
            $id = trim(substr($recipientKey, 2));

            return [
                'recipient_type' => 'module',
                'recipient_id' => $id,
                'module_id' => $id,
                'equipe_id' => $id,
            ];
        }

        if (preg_match('#^i:(intervenants|intervenant):(.+)$#', $recipientKey, $m)) {
            $collection = $m[1];
            $id = trim($m[2]);

            return [
                'recipient_type' => 'intervenant',
                'recipient_id' => $id,
                'intervenant_collection' => $collection,
                'collection_cible' => $collection,
                'intervenant_id' => $id,
                'intervenantId' => $id,
            ];
        }

        return [];
    }
}
