<?php

namespace App\Support;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use MongoDB\BSON\ObjectId;

/**
 * Notifications à partir de la collection MongoDB « chat_intervenant ».
 */
final class ChatIntervenantReader
{
    private const COLLECTION = 'chat_intervenant';

    /**
     * @return array{unread:int, alert:int, items: list<array{id:string, preview:string, sender:string, created_at:?string, unread:bool}>, error:?string}
     */
    public static function notifications(int $itemLimit = 15): array
    {
        $scanLimit = 400;
        $itemLimit = max(1, min(40, $itemLimit));
        $defaults = ['unread' => 0, 'alert' => 0, 'items' => [], 'error' => null];

        try {
            $raw = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->orderBy('_id', 'desc')
                ->limit($scanLimit)
                ->get();
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant: '.$e->getMessage());

            return array_merge($defaults, ['error' => 'collection_indisponible']);
        }

        $unread = 0;
        $alert = 0;
        $items = [];
        foreach ($raw as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            if (self::isLikelyFromAdmin($row)) {
                continue;
            }
            $id = self::idToString($row);
            if ($id === '') {
                continue;
            }
            $u = self::isExplicitlyUnread($row);
            $read = self::isExplicitlyRead($row);

            if ($u) {
                $unread++;
            }
            // Pastille / alerte : message intervenant non explicitement lu (toute date), ou marqué non lu.
            if ($u || ! $read) {
                $alert++;
            }

            if (count($items) < $itemLimit) {
                $items[] = [
                    'id' => $id,
                    'preview' => self::previewText($row),
                    'sender' => self::senderLabel($row),
                    'created_at' => self::createdAtIso($row),
                    'unread' => $u,
                ];
            }
        }

        return [
            'unread' => $unread,
            'alert' => $alert,
            'items' => $items,
            'error' => null,
        ];
    }

    /**
     * Normalise un document Mongo (BSONDocument, stdClass, etc.) en tableau associatif avec les vraies clés string.
     *
     * @return array<string, mixed>
     */
    public static function mongoDocToAssocArray(mixed $doc): array
    {
        if (is_array($doc)) {
            return $doc;
        }
        try {
            $json = json_encode($doc);
            if ($json === false || $json === 'null') {
                return [];
            }
            $decoded = json_decode($json, true);
        } catch (\Throwable) {
            return [];
        }

        return is_array($decoded) ? $decoded : [];
    }

    private static function idToString(mixed $doc): string
    {
        $row = self::mongoDocToAssocArray($doc);
        $id = $row['_id'] ?? $row['id'] ?? null;
        if ($id === null) {
            return '';
        }
        if (is_array($id) && isset($id['$oid'])) {
            return (string) $id['$oid'];
        }
        if (is_object($id) && method_exists($id, '__toString')) {
            return (string) $id;
        }

        return trim((string) $id);
    }

    public static function isLikelyFromAdmin(mixed $doc): bool
    {
        $row = self::mongoDocToAssocArray($doc);
        $senderRole = strtolower(trim((string) ($row['senderRole'] ?? '')));
        if ($senderRole === 'intervenant' || $senderRole === 'mobile' || $senderRole === 'citoyen' || $senderRole === 'user') {
            return false;
        }
        if (in_array($senderRole, ['admin', 'administrateur', 'staff', 'backoffice'], true)) {
            return true;
        }
        foreach (['from_admin', 'is_admin', 'admin_message', 'fromAdmin'] as $k) {
            if (! array_key_exists($k, $row)) {
                continue;
            }
            $v = $row[$k];
            if ($v === true || $v === 1 || $v === '1' || strtolower((string) $v) === 'true') {
                return true;
            }
        }
        $st = strtolower((string) ($row['sender_type'] ?? $row['type_emetteur'] ?? ''));
        // Ne pas utiliser « technique » seul : beaucoup d’apps l’emploient pour l’intervenant / terrain.
        if ($st !== '' && str_contains($st, 'admin')) {
            return true;
        }
        foreach (['from', 'direction', 'source', 'emetteur'] as $k) {
            $from = strtolower(trim((string) ($row[$k] ?? '')));
            if ($from === '') {
                continue;
            }
            if (in_array($from, ['admin', 'admin_tech', 'admin_technique', 'administrateur', 'backoffice'], true)) {
                return true;
            }
        }

        return false;
    }

    private static function isExplicitlyRead(array $row): bool
    {
        foreach (['read', 'is_read', 'lu', 'seen', 'vue', 'opened', 'read_by_admin', 'admin_lu'] as $k) {
            if (! array_key_exists($k, $row)) {
                continue;
            }
            $v = $row[$k];
            if (is_bool($v) && $v) {
                return true;
            }
            $s = strtolower(trim((string) $v));
            if (in_array($s, ['1', 'true', 'yes', 'lu', 'read', 'oui'], true)) {
                return true;
            }
        }
        foreach (['read_at', 'readAt', 'lu_at', 'seen_at'] as $k) {
            if (! empty($row[$k])) {
                return true;
            }
        }

        return false;
    }

    private static function isExplicitlyUnread(array $row): bool
    {
        $seen = false;
        foreach (['read', 'is_read', 'lu', 'seen', 'vue', 'opened', 'read_by_admin', 'admin_lu'] as $k) {
            if (! array_key_exists($k, $row)) {
                continue;
            }
            $seen = true;
            $v = $row[$k];
            if (is_bool($v)) {
                return ! $v;
            }
            $s = strtolower(trim((string) $v));
            if (in_array($s, ['1', 'true', 'yes', 'lu', 'read', 'oui'], true)) {
                return false;
            }
            if (in_array($s, ['0', 'false', 'no', 'non'], true)) {
                return true;
            }
        }
        if (! $seen) {
            return false;
        }

        return ! self::isExplicitlyRead($row);
    }

    private static function createdAtIso(array $row): ?string
    {
        $raw = $row['created_at'] ?? $row['createdAt'] ?? $row['date'] ?? $row['timestamp'] ?? $row['sent_at'] ?? null;
        try {
            if ($raw instanceof \MongoDB\BSON\UTCDateTime) {
                return Carbon::instance($raw->toDateTime())->toIso8601String();
            }
            if ($raw instanceof \DateTimeInterface) {
                return Carbon::instance($raw)->toIso8601String();
            }
            if (is_array($raw) && isset($raw['$date'])) {
                $date = $raw['$date'];
                if (is_array($date) && isset($date['$numberLong'])) {
                    return Carbon::createFromTimestampMs((int) $date['$numberLong'])->toIso8601String();
                }
                if (is_numeric($date)) {
                    return Carbon::createFromTimestampMs((int) $date)->toIso8601String();
                }
                if (is_string($date) && trim($date) !== '') {
                    return Carbon::parse($date)->toIso8601String();
                }
            }
            if ($raw !== null && $raw !== '') {
                return Carbon::parse((string) $raw)->toIso8601String();
            }
        } catch (\Throwable $e) {
            // ignore
        }

        return null;
    }

    private static function previewText(array $row): string
    {
        $text = '';
        foreach (['text', 'message', 'body', 'content', 'message_text', 'contenu'] as $k) {
            $v = $row[$k] ?? null;
            if (is_string($v) && trim($v) !== '') {
                $text = $v;
                break;
            }
        }
        if ($text === '') {
            foreach (['content.text', 'data.message', 'payload.message', 'payload.body'] as $path) {
                $v = data_get($row, $path);
                if (is_string($v) && trim($v) !== '') {
                    $text = $v;
                    break;
                }
            }
        }
        $text = strip_tags($text);
        $text = preg_replace('/\s+/u', ' ', $text) ?? $text;
        $text = trim($text);

        return $text === '' ? '(Message sans texte)' : (mb_strlen($text) > 100 ? mb_substr($text, 0, 97).'…' : $text);
    }

    private static function senderLabel(array $row): string
    {
        $inName = trim((string) ($row['intervenantName'] ?? $row['intervenant_name'] ?? ''));
        if ($inName !== '') {
            return $inName;
        }
        $nom = trim((string) ($row['nom'] ?? $row['last_name'] ?? $row['lastname'] ?? ''));
        $pre = trim((string) ($row['prenom'] ?? $row['first_name'] ?? $row['firstname'] ?? ''));
        if ($nom !== '' || $pre !== '') {
            return trim($pre.' '.$nom) ?: 'Intervenant';
        }
        foreach (['sender_name', 'expediteur', 'intervenant_nom', 'name', 'fullName', 'full_name'] as $k) {
            $v = $row[$k] ?? null;
            if (is_string($v) && trim($v) !== '') {
                return trim($v);
            }
        }

        return 'Intervenant';
    }

    /**
     * Clé destinataire (même format que {@see EquipeInterventionController::buildRecipientKey()} : i:… ou m:…).
     */
    public static function recipientKeyFromRow(array $row): ?string
    {
        $direct = trim((string) ($row['recipient_key'] ?? $row['recipientKey'] ?? $row['dest_recipient_key'] ?? ''));
        if ($direct !== '') {
            return $direct;
        }

        $t = strtolower(trim((string) ($row['recipient_type'] ?? $row['recipientType'] ?? $row['type_dest'] ?? $row['dest_type'] ?? '')));

        $moduleId = trim((string) ($row['module_id'] ?? $row['equipe_id'] ?? $row['team_id'] ?? $row['recipient_id'] ?? $row['recipientId'] ?? $row['dest_id'] ?? ''));
        if ($moduleId === '') {
            $moduleId = self::scalarMongoIdToString($row['recipient_id'] ?? null);
        }
        if ($moduleId !== '' && in_array($t, ['module', 'equipe', 'equipe_module', 'team', 'équipe'], true)) {
            return 'm:'.$moduleId;
        }

        $id = self::scalarMongoIdToString($row['intervenant_id'] ?? $row['intervenantId'] ?? $row['id_intervenant'] ?? $row['recipient_id'] ?? $row['recipientId'] ?? $row['dest_id'] ?? $row['user_id'] ?? $row['userId'] ?? null);
        if ($id === '') {
            return null;
        }

        $col = strtolower(trim((string) ($row['intervenant_collection'] ?? $row['collection_cible'] ?? $row['target_collection'] ?? '')));
        if ($col === '') {
            $col = strtolower(trim((string) ($row['collection'] ?? '')));
        }
        if ($col === '' || ! in_array($col, ['intervenants', 'intervenant'], true)) {
            $col = 'intervenants';
        }

        if (in_array($t, ['module', 'equipe', 'equipe_module', 'team', 'équipe'], true)) {
            return null;
        }

        return 'i:'.$col.':'.$id;
    }

    /**
     * Champs souvent utilisés par l’app mobile pour l’expéditeur / le destinataire métier (hors {@code recipient_key}).
     *
     * @return list<string>
     */
    private static function participantChatIdFields(): array
    {
        return [
            'intervenantId', 'intervenant_id', 'id_intervenant',
            'senderId', 'sender_id', 'from_id', 'author_id', 'authorId',
            'userId', 'user_id', 'member_id', 'participant_id',
            'dest_intervenant_id', 'intervenant_dest',
            'module_id', 'equipe_id', 'team_id',
        ];
    }

    private static function scalarMongoIdToString(mixed $value): string
    {
        if ($value === null) {
            return '';
        }
        if (is_string($value)) {
            return trim($value);
        }
        if (is_array($value) && isset($value['$oid'])) {
            return trim((string) $value['$oid']);
        }
        if (is_object($value) && method_exists($value, '__toString')) {
            return trim((string) $value);
        }

        return trim((string) $value);
    }

    /**
     * Toutes les clés destinataires possibles pour ce document (rapprochement avec les boutons « Message »).
     *
     * @return list<string>
     */
    public static function recipientKeysForRow(mixed $doc): array
    {
        $row = self::mongoDocToAssocArray($doc);
        $out = [];
        foreach (['recipient_key', 'recipientKey', 'dest_recipient_key'] as $k) {
            $v = trim((string) ($row[$k] ?? ''));
            if ($v !== '') {
                $out[] = $v;
            }
        }
        $built = self::recipientKeyFromRow($row);
        if ($built !== null && ! in_array($built, $out, true)) {
            $out[] = $built;
        }
        $seenIds = [];
        $sources = [
            $row['intervenant_id'] ?? null,
            $row['intervenantId'] ?? null,
            $row['id_intervenant'] ?? null,
            $row['user_id'] ?? null,
            $row['userId'] ?? null,
        ];
        $recipientType = strtolower(trim((string) ($row['recipient_type'] ?? $row['recipientType'] ?? $row['type_dest'] ?? $row['dest_type'] ?? '')));
        if (in_array($recipientType, ['intervenant', 'intervenants', 'user', 'citoyen', 'mobile'], true)) {
            $sources[] = $row['recipient_id'] ?? null;
            $sources[] = $row['recipientId'] ?? null;
            $sources[] = $row['dest_id'] ?? null;
        }
        foreach (['senderId', 'sender_id', 'from_id', 'author_id', 'authorId', 'member_id', 'participant_id'] as $sf) {
            if (array_key_exists($sf, $row)) {
                $sources[] = $row[$sf];
            }
        }
        foreach ($sources as $src) {
            $id = self::scalarMongoIdToString($src);
            if ($id === '' || isset($seenIds[$id])) {
                continue;
            }
            $seenIds[$id] = true;
            foreach (['intervenants', 'intervenant'] as $c) {
                $k = 'i:'.$c.':'.$id;
                if (! in_array($k, $out, true)) {
                    $out[] = $k;
                }
            }
        }

        return array_values(array_unique($out));
    }

    public static function rowMatchesRecipient(string $recipientKey, mixed $doc): bool
    {
        $row = self::mongoDocToAssocArray($doc);
        if ($recipientKey === '') {
            return false;
        }
        if (str_starts_with($recipientKey, 'm:')) {
            $want = self::parseModuleRecipientId($recipientKey);
            foreach (self::recipientKeysForRow($row) as $rk) {
                if ($rk === $recipientKey) {
                    return true;
                }
                if (str_starts_with($rk, 'm:')) {
                    $have = self::parseModuleRecipientId($rk);
                    if ($have !== '' && self::idEqualsString($have, $want)) {
                        return true;
                    }
                }
            }

            return false;
        }
        if (! str_starts_with($recipientKey, 'i:')) {
            return false;
        }
        $want = self::parseIntervenantRecipientKey($recipientKey);
        foreach (self::recipientKeysForRow($row) as $rk) {
            if ($rk === $recipientKey) {
                return true;
            }
            if (! str_starts_with($rk, 'i:')) {
                continue;
            }
            $have = self::parseIntervenantRecipientKey($rk);
            if ($have !== null && $want !== null && self::idEqualsString($have['id'], $want['id'])) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return array{col: string, id: string}|null
     */
    private static function parseIntervenantRecipientKey(string $key): ?array
    {
        if (! preg_match('#^i:(intervenants|intervenant):(.+)$#', $key, $m)) {
            return null;
        }

        return ['col' => $m[1], 'id' => $m[2]];
    }

    private static function idEqualsString(string $a, string $b): bool
    {
        if ($a === $b) {
            return true;
        }
        $a = trim($a);
        $b = trim($b);
        if (strlen($a) === 24 && strlen($b) === 24 && ctype_xdigit($a) && ctype_xdigit($b)) {
            return strcasecmp($a, $b) === 0;
        }

        return strcasecmp($a, $b) === 0;
    }

    private static function parseModuleRecipientId(string $recipientKey): string
    {
        if (! str_starts_with($recipientKey, 'm:')) {
            return '';
        }

        return trim(substr($recipientKey, 2));
    }

    /**
     * Le bouton « Message » utilise souvent l’_id Mongo de la fiche ; les messages mobile utilisent souvent le champ {@code intervenantId} logique.
     *
     * @return list<string>
     */
    public static function expandedRecipientKeysForIntervenantButton(string $recipientKey): array
    {
        if (str_starts_with($recipientKey, 'm:')) {
            return [$recipientKey];
        }
        $keys = [$recipientKey];
        $parsed = self::parseIntervenantRecipientKey($recipientKey);
        if ($parsed === null) {
            return array_values(array_unique(array_filter($keys)));
        }
        $idPart = $parsed['id'];
        $isHex24 = strlen($idPart) === 24 && ctype_xdigit($idPart);

        if ($isHex24) {
            $preferredCol = $parsed['col'];
            $altCol = $preferredCol === 'intervenants' ? 'intervenant' : 'intervenants';
            foreach ([$preferredCol, $altCol] as $tbl) {
                if (! in_array($tbl, ['intervenants', 'intervenant'], true)) {
                    continue;
                }
                try {
                    $doc = DB::connection('mongodb')->table($tbl)->where('_id', new ObjectId($idPart))->first();
                } catch (\Throwable) {
                    continue;
                }
                if ($doc === null) {
                    continue;
                }
                $row = self::mongoDocToAssocArray($doc);
                foreach (['intervenantId', 'intervenant_id', 'logical_id', 'slug', 'external_id'] as $fld) {
                    $logical = trim((string) data_get($row, $fld));
                    if ($logical === '' || self::idEqualsString($logical, $idPart)) {
                        continue;
                    }
                    foreach (['intervenants', 'intervenant'] as $c) {
                        $k = 'i:'.$c.':'.$logical;
                        if (! in_array($k, $keys, true)) {
                            $keys[] = $k;
                        }
                    }
                }
                $keys = self::appendEmailKeysFromIntervenantProfile($keys, $row);
                $keys = self::appendShadowKeyFromIntervenantProfile($keys, $preferredCol, $row);
                $guess = self::guessIntervenantChatKeyFromFiche($row);
                if ($guess !== '') {
                    foreach (['intervenants', 'intervenant'] as $c) {
                        $gk = 'i:'.$c.':'.$guess;
                        if (! in_array($gk, $keys, true)) {
                            $keys[] = $gk;
                        }
                    }
                }

                break;
            }

            return array_values(array_unique(array_filter($keys)));
        }

        // Id « logique » sur le bouton : retrouver la fiche pour ajouter les clés i:* basées sur l’_id Mongo (souvent seul dans chat_intervenant).
        $preferredCol = $parsed['col'];
        $altCol = $preferredCol === 'intervenants' ? 'intervenant' : 'intervenants';
        foreach ([$preferredCol, $altCol] as $tbl) {
            if (! in_array($tbl, ['intervenants', 'intervenant'], true)) {
                continue;
            }
            try {
                $doc = DB::connection('mongodb')->table($tbl)
                    ->where(function ($q) use ($idPart) {
                        $q->where('intervenantId', $idPart)
                            ->orWhere('intervenant_id', $idPart)
                            ->orWhere('slug', $idPart)
                            ->orWhere('external_id', $idPart)
                            ->orWhere('logical_id', $idPart)
                            ->orWhere('email', $idPart)
                            ->orWhere('mail', $idPart)
                            ->orWhere('courriel', $idPart);
                    })
                    ->first();
            } catch (\Throwable) {
                continue;
            }
            if ($doc === null) {
                continue;
            }
            $row = self::mongoDocToAssocArray($doc);
            $mid = self::scalarMongoIdToString($row['_id'] ?? $row['id'] ?? null);
            if ($mid !== '' && strlen($mid) === 24 && ctype_xdigit($mid)) {
                foreach (['intervenants', 'intervenant'] as $c) {
                    $k = 'i:'.$c.':'.$mid;
                    if (! in_array($k, $keys, true)) {
                        $keys[] = $k;
                    }
                }
            }
            foreach (['intervenantId', 'intervenant_id', 'logical_id', 'slug', 'external_id'] as $fld) {
                $logical = trim((string) data_get($row, $fld));
                if ($logical === '' || ($mid !== '' && self::idEqualsString($logical, $mid))) {
                    continue;
                }
                foreach (['intervenants', 'intervenant'] as $c) {
                    $k = 'i:'.$c.':'.$logical;
                    if (! in_array($k, $keys, true)) {
                        $keys[] = $k;
                    }
                }
            }
            $keys = self::appendEmailKeysFromIntervenantProfile($keys, $row);
            $keys = self::appendShadowKeyFromIntervenantProfile($keys, $preferredCol, $row);
            $guess = self::guessIntervenantChatKeyFromFiche($row);
            if ($guess !== '' && ! self::idEqualsString($guess, $idPart)) {
                foreach (['intervenants', 'intervenant'] as $c) {
                    $gk = 'i:'.$c.':'.$guess;
                    if (! in_array($gk, $keys, true)) {
                        $keys[] = $gk;
                    }
                }
            }

            break;
        }

        return array_values(array_unique(array_filter($keys)));
    }

    /**
     * Heuristique alignée sur les clés type « name_prenom_nom_(equipe_x) » utilisées par certaines apps mobiles.
     */
    private static function guessIntervenantChatKeyFromFiche(array $row): string
    {
        $pre = trim((string) (data_get($row, 'prenom') ?: data_get($row, 'first_name') ?: data_get($row, 'firstname') ?: ''));
        $nom = trim((string) (data_get($row, 'nom') ?: data_get($row, 'last_name') ?: data_get($row, 'lastname') ?: ''));
        $equipe = trim((string) (data_get($row, 'equipe') ?: data_get($row, 'team') ?: data_get($row, 'team_label') ?: ''));
        if ($pre === '' && $nom === '') {
            return '';
        }
        $parts = array_filter([$pre, $nom], static fn (string $s): bool => $s !== '');
        $joined = strtolower(implode(' ', $parts));
        $nameSeg = Str::slug($joined, '_');
        if ($nameSeg === '') {
            return '';
        }
        if ($equipe === '' || $equipe === '—') {
            return 'name_'.$nameSeg;
        }
        $eqSeg = Str::slug(strtolower($equipe), '_');
        if ($eqSeg === '') {
            return 'name_'.$nameSeg;
        }

        return 'name_'.$nameSeg.'_('.$eqSeg.')';
    }

    /**
     * Ajoute les clés {@code i:*:email} présents sur la fiche (souvent le même compte que {@code intervenantId} slug).
     *
     * @param  list<string>  $keys
     * @return list<string>
     */
    private static function appendEmailKeysFromIntervenantProfile(array $keys, array $row): array
    {
        foreach (['email', 'mail', 'courriel'] as $ef) {
            $em = trim((string) data_get($row, $ef));
            if ($em === '' || ! str_contains($em, '@')) {
                continue;
            }
            foreach (['intervenants', 'intervenant'] as $c) {
                $k = 'i:'.$c.':'.$em;
                if (! in_array($k, $keys, true)) {
                    $keys[] = $k;
                }
            }
        }

        return $keys;
    }

    /**
     * Ancienne clé utilisée quand le tableau ne voyait pas l'_id MongoDB.
     * Elle permet de garder l'historique déjà envoyé en sh_... visible.
     *
     * @param  list<string>  $keys
     * @return list<string>
     */
    private static function appendShadowKeyFromIntervenantProfile(array $keys, string $preferredCollection, array $row): array
    {
        $collection = in_array($preferredCollection, ['intervenants', 'intervenant'], true)
            ? $preferredCollection
            : 'intervenants';

        $nom = trim((string) (data_get($row, 'last_name')
            ?: data_get($row, 'nom_famille')
            ?: data_get($row, 'family_name')
            ?: data_get($row, 'nom')
            ?: '—'));
        $prenom = trim((string) (data_get($row, 'first_name')
            ?: data_get($row, 'prenom')
            ?: data_get($row, 'firstname')
            ?: '—'));
        $email = trim((string) (data_get($row, 'email')
            ?: data_get($row, 'courriel')
            ?: data_get($row, 'mail')
            ?: '—'));
        $phone = trim((string) (data_get($row, 'telephone')
            ?: data_get($row, 'phone')
            ?: data_get($row, 'tel')
            ?: data_get($row, 'mobile')
            ?: data_get($row, 'gsm')
            ?: data_get($row, 'numero')
            ?: '—'));
        $zone = trim((string) (data_get($row, 'zone')
            ?: data_get($row, 'ville')
            ?: data_get($row, 'quartier')
            ?: data_get($row, 'region')
            ?: data_get($row, 'adresse')
            ?: data_get($row, 'localisation')
            ?: data_get($row, 'address')
            ?: '—'));
        $equipe = trim((string) (data_get($row, 'equipe')
            ?: data_get($row, 'team')
            ?: data_get($row, 'team_label')
            ?: data_get($row, 'titre')
            ?: data_get($row, 'libelle')
            ?: '—'));

        $payload = strtolower($collection).'|'
            .strtolower($nom).'|'
            .strtolower($prenom).'|'
            .strtolower($email).'|'
            .$phone.'|'
            .strtolower($zone).'|'
            .strtolower($equipe);
        $shadow = 'sh_'.substr(hash('sha256', $payload), 0, 40);

        foreach (['intervenants', 'intervenant'] as $c) {
            $key = 'i:'.$c.':'.$shadow;
            if (! in_array($key, $keys, true)) {
                $keys[] = $key;
            }
        }

        return $keys;
    }

    private static function rowMatchesAnyRecipient(array $keys, mixed $doc): bool
    {
        $row = self::mongoDocToAssocArray($doc);
        foreach ($keys as $rk) {
            if (self::rowMatchesRecipient($rk, $row)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @param  array<string, mixed>  $row
     * @param  list<string>  $idCandidates
     */
    private static function rowParticipantMatchesIdCandidates(array $row, array $idCandidates): bool
    {
        if ($idCandidates === []) {
            return false;
        }
        foreach (['intervenantId', 'intervenant_id', 'id_intervenant', 'senderId', 'sender_id', 'userId', 'user_id', 'module_id', 'equipe_id', 'team_id', 'recipient_id', 'recipientId', 'dest_id'] as $f) {
            $v = trim((string) ($row[$f] ?? ''));
            if ($v === '') {
                continue;
            }
            foreach ($idCandidates as $cid) {
                if ($cid !== '' && self::idEqualsString($v, $cid)) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Pastilles sur le bouton avec _id Mongo : recopier le compteur des clés basées sur intervenantId logique.
     *
     * @param  array<string, int>  $counts
     */
    private static function spreadAlertCountsToMongoProfileKeys(array &$counts): void
    {
        $logicalIds = [];
        foreach (array_keys($counts) as $rk) {
            $p = self::parseIntervenantRecipientKey($rk);
            if ($p === null) {
                continue;
            }
            $idPart = $p['id'];
            if (strlen($idPart) === 24 && ctype_xdigit($idPart)) {
                continue;
            }
            $logicalIds[$idPart] = true;
        }
        if ($logicalIds === []) {
            return;
        }

        foreach (['intervenants', 'intervenant'] as $tbl) {
            try {
                $docs = DB::connection('mongodb')->table($tbl)->orderBy('_id', 'desc')->limit(1500)->get();
            } catch (\Throwable) {
                continue;
            }
            foreach ($docs as $doc) {
                $row = self::mongoDocToAssocArray($doc);
                $mongoIdStr = self::idToString($row);
                if ($mongoIdStr === '') {
                    continue;
                }
                $logical = trim((string) data_get($row, 'intervenantId')
                    ?: data_get($row, 'intervenant_id')
                    ?: data_get($row, 'slug')
                    ?: data_get($row, 'external_id')
                    ?: '');
                $guess = self::guessIntervenantChatKeyFromFiche($row);
                $matchedSlug = null;
                foreach (array_keys($logicalIds) as $slug) {
                    if ($slug === $logical || $slug === $guess) {
                        $matchedSlug = $slug;
                        break;
                    }
                }
                if ($matchedSlug === null) {
                    continue;
                }
                if ($mongoIdStr === $matchedSlug) {
                    continue;
                }
                $nLogical = max(
                    (int) ($counts['i:intervenants:'.$matchedSlug] ?? 0),
                    (int) ($counts['i:intervenant:'.$matchedSlug] ?? 0)
                );
                if ($nLogical <= 0) {
                    continue;
                }
                foreach (['intervenants', 'intervenant'] as $c) {
                    $mk = 'i:'.$c.':'.$mongoIdStr;
                    $counts[$mk] = max((int) ($counts[$mk] ?? 0), $nLogical);
                }
            }
        }
    }

    /**
     * Compteurs « à traiter » (non lu ou pas explicitement lu) par clé destinataire, pour pastilles sur le tableau.
     *
     * @return array<string, int>
     */
    public static function alertCountsByRecipientKey(int $scanLimit = 2000): array
    {
        $scanLimit = max(100, min(5000, $scanLimit));
        $counts = [];

        try {
            $raw = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->orderBy('_id', 'desc')
                ->limit($scanLimit)
                ->get();
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant alertCountsByRecipientKey: '.$e->getMessage());

            return [];
        }

        foreach ($raw as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            if (self::isLikelyFromAdmin($row)) {
                continue;
            }
            $u = self::isExplicitlyUnread($row);
            $read = self::isExplicitlyRead($row);
            if (! ($u || ! $read)) {
                continue;
            }
            foreach (self::recipientKeysForRow($row) as $rk) {
                if (! str_starts_with($rk, 'i:') && ! str_starts_with($rk, 'm:')) {
                    continue;
                }
                $counts[$rk] = ($counts[$rk] ?? 0) + 1;
            }
        }

        self::spreadAlertCountsToMongoProfileKeys($counts);
        self::spreadAlertCountsUsingChatIntervenantAliases($counts);

        return $counts;
    }

    /**
     * Identifiants à croiser avec les champs du document (en plus de {@code recipient_key}).
     *
     * @param  list<string>  $expandedKeys
     * @return list<string>
     */
    private static function distinctIdCandidatesForChatLookup(string $recipientKey, array $expandedKeys): array
    {
        $c = [];
        foreach ($expandedKeys as $k) {
            if (! str_starts_with($k, 'i:')) {
                continue;
            }
            $p = self::parseIntervenantRecipientKey($k);
            if ($p === null) {
                continue;
            }
            $id = trim($p['id']);
            if ($id !== '') {
                $c[$id] = true;
            }
        }
        if (str_starts_with($recipientKey, 'm:')) {
            $m = self::parseModuleRecipientId($recipientKey);
            if ($m !== '') {
                $c[$m] = true;
            }
        }

        return array_keys($c);
    }

    /**
     * Même personne peut avoir plusieurs {@code intervenantId} dans {@code chat_intervenant} (slug, e-mail, etc.) avec le même {@code intervenantName}.
     * On complète les clés {@code i:…} pour que filtrage et requêtes voient toute la conversation.
     *
     * @param  list<string>  $keys
     * @return list<string>
     */
    private static function mergeIntervenantChatKeysWithNameAliases(array $keys): array
    {
        $candidates = [];
        foreach ($keys as $k) {
            if (! str_starts_with($k, 'i:')) {
                continue;
            }
            $p = self::parseIntervenantRecipientKey($k);
            if ($p === null) {
                continue;
            }
            $id = trim($p['id']);
            if ($id !== '') {
                $candidates[$id] = true;
            }
        }
        if ($candidates === []) {
            return array_values(array_unique($keys));
        }
        $candList = array_keys($candidates);

        try {
            $nameProbe = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->whereIn('intervenantId', $candList)
                ->orderBy('_id', 'desc')
                ->limit(500)
                ->get(['intervenantName', 'intervenantId']);
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant mergeIntervenantChatKeysWithNameAliases probe: '.$e->getMessage());

            return array_values(array_unique($keys));
        }

        $names = [];
        foreach ($nameProbe as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            $n = trim((string) ($row['intervenantName'] ?? ''));
            if ($n !== '') {
                $names[$n] = true;
            }
        }
        if ($names === []) {
            return array_values(array_unique($keys));
        }
        $nameList = array_keys($names);

        try {
            $siblings = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->whereIn('intervenantName', $nameList)
                ->orderBy('_id', 'desc')
                ->limit(3000)
                ->get(['intervenantId']);
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant mergeIntervenantChatKeysWithNameAliases siblings: '.$e->getMessage());

            return array_values(array_unique($keys));
        }

        $merged = $keys;
        foreach ($siblings as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            $iid = trim((string) ($row['intervenantId'] ?? ''));
            if ($iid === '') {
                continue;
            }
            foreach (['intervenants', 'intervenant'] as $c) {
                $ik = 'i:'.$c.':'.$iid;
                if (! in_array($ik, $merged, true)) {
                    $merged[] = $ik;
                }
            }
        }

        return array_values(array_unique($merged));
    }

    /**
     * Même compteur pour toutes les clés {@code i:} alias d’un même intervenant (slug vs e-mail dans {@code chat_intervenant}).
     *
     * @param  array<string, int>  $counts
     */
    private static function spreadAlertCountsUsingChatIntervenantAliases(array &$counts): void
    {
        $rkList = array_keys($counts);
        foreach ($rkList as $rk) {
            if (! str_starts_with($rk, 'i:')) {
                continue;
            }
            $group = self::mergeIntervenantChatKeysWithNameAliases([$rk]);
            if (count($group) <= 1) {
                continue;
            }
            $max = 0;
            foreach ($group as $gk) {
                $max = max($max, (int) ($counts[$gk] ?? 0));
            }
            foreach ($group as $gk) {
                $counts[$gk] = $max;
            }
        }
    }

    /**
     * Messages intervenant (collection chat_intervenant) pour une discussion donnée, format widget équipes.
     *
     * @return list<array<string, mixed>>
     */
    public static function messagesForRecipient(string $recipientKey, int $limit = 200, ?string $threadViewerAuthorKey = null): array
    {
        if ($recipientKey === '' || (! str_starts_with($recipientKey, 'i:') && ! str_starts_with($recipientKey, 'm:'))) {
            return [];
        }
        $limit = max(1, min(300, $limit));
        $keys = str_starts_with($recipientKey, 'm:')
            ? [$recipientKey]
            : self::mergeIntervenantChatKeysWithNameAliases(self::expandedRecipientKeysForIntervenantButton($recipientKey));
        if (str_starts_with($recipientKey, 'i:')) {
            $moduleAliasKey = self::moduleAliasRecipientKeyFromIntervenantRecipient($recipientKey);
            if ($moduleAliasKey !== null && ! in_array($moduleAliasKey, $keys, true)) {
                $keys[] = $moduleAliasKey;
            }
        }

        $byCiId = [];

        $fetchCap = min(2000, max(400, $limit * 5));

        try {
            $viaKey = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->whereIn('recipient_key', $keys)
                ->orderBy('_id', 'asc')
                ->limit($fetchCap)
                ->get();
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant messagesForRecipient whereIn: '.$e->getMessage());
            $viaKey = collect();
        }

        foreach ($viaKey as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            $mid = self::idToString($row);
            if ($mid === '') {
                continue;
            }
            $byCiId['ci:'.$mid] = self::rowToWidgetMessage($row, $mid, $threadViewerAuthorKey);
        }

        $idCandidates = self::distinctIdCandidatesForChatLookup($recipientKey, $keys);
        if ($idCandidates !== []) {
            $fields = self::participantChatIdFields();
            try {
                $viaParticipant = DB::connection('mongodb')
                    ->table(self::COLLECTION)
                    ->where(function ($w) use ($keys, $idCandidates, $fields) {
                        $w->whereIn('recipient_key', $keys);
                        foreach ($idCandidates as $cid) {
                            foreach ($fields as $field) {
                                $w->orWhere($field, $cid);
                            }
                        }
                    })
                    ->orderBy('_id', 'asc')
                    ->limit($fetchCap)
                    ->get();
            } catch (\Throwable $e) {
                Log::debug('chat_intervenant messagesForRecipient participant query: '.$e->getMessage());
                $viaParticipant = collect();
            }
            foreach ($viaParticipant as $doc) {
                $row = self::mongoDocToAssocArray($doc);
                if (! self::rowMatchesAnyRecipient($keys, $row) && ! self::rowParticipantMatchesIdCandidates($row, $idCandidates)) {
                    continue;
                }
                $mid = self::idToString($row);
                if ($mid === '') {
                    continue;
                }
                $ck = 'ci:'.$mid;
                if (! isset($byCiId[$ck])) {
                    $byCiId[$ck] = self::rowToWidgetMessage($row, $mid, $threadViewerAuthorKey);
                }
            }
        }

        $scanLimit = 25000;

        try {
            $raw = DB::connection('mongodb')
                ->table(self::COLLECTION)
                ->orderBy('_id', 'desc')
                ->limit($scanLimit)
                ->get();
        } catch (\Throwable $e) {
            Log::debug('chat_intervenant messagesForRecipient: '.$e->getMessage());

            return array_values($byCiId);
        }

        foreach ($raw as $doc) {
            $row = self::mongoDocToAssocArray($doc);
            if (! self::rowMatchesAnyRecipient($keys, $row) && ! self::rowParticipantMatchesIdCandidates($row, $idCandidates)) {
                continue;
            }
            $mid = self::idToString($row);
            if ($mid === '') {
                continue;
            }
            $ck = 'ci:'.$mid;
            if (! isset($byCiId[$ck])) {
                $byCiId[$ck] = self::rowToWidgetMessage($row, $mid, $threadViewerAuthorKey);
            }
        }

        $buf = array_values($byCiId);
        usort($buf, function (array $a, array $b): int {
            $ta = (int) ($a['_sort_ts'] ?? 0);
            $tb = (int) ($b['_sort_ts'] ?? 0);
            if ($ta === $tb) {
                return strcmp((string) ($a['id'] ?? ''), (string) ($b['id'] ?? ''));
            }

            return $ta <=> $tb;
        });

        if (count($buf) > $limit) {
            $buf = array_slice($buf, -$limit);
        }

        return $buf;
    }

    private static function moduleAliasRecipientKeyFromIntervenantRecipient(string $recipientKey): ?string
    {
        $parsed = self::parseIntervenantRecipientKey($recipientKey);
        if ($parsed === null) {
            return null;
        }
        $id = trim((string) ($parsed['id'] ?? ''));
        if ($id === '') {
            return null;
        }
        // Les IDs hex Mongo/e-mails ne sont pas des clés module.
        if ((strlen($id) === 24 && ctype_xdigit($id)) || str_contains($id, '@')) {
            return null;
        }
        // Accepter les slugs courts utilisés comme clé d’équipe (ex: eq3).
        if (! preg_match('/^[a-z0-9._()\-]{1,64}$/i', $id)) {
            return null;
        }

        return 'm:'.$id;
    }

    /**
     * @return array<string, mixed>
     */
    private static function rowToWidgetMessage(array $row, string $mongoId, ?string $threadViewerAuthorKey = null): array
    {
        $isAdmin = self::isLikelyFromAdmin($row);
        $author = $isAdmin
            ? trim((string) ($row['author_label'] ?? $row['authorLabel'] ?? ''))
            : self::senderLabel($row);
        if ($author === '' && $isAdmin) {
            $author = 'Administration';
        }

        $ci = 'ci:'.$mongoId;
        $audioPath = trim((string) ($row['audio_storage_path'] ?? ''));
        $imagePath = trim((string) ($row['image_storage_path'] ?? ''));

        $audioUrl = $audioPath !== ''
            ? route('interface_admin_tech.equipes.chat.voice.stream', ['id' => $ci])
            : self::firstHttpUrl($row, ['audio_url', 'voice_url', 'url_audio', 'audio_public_url', 'voice_public_url']);
        $imageUrl = $imagePath !== ''
            ? route('interface_admin_tech.equipes.chat.image.stream', ['id' => $ci])
            : self::firstHttpUrl($row, ['image_url', 'photo_url', 'picture_url', 'image_public_url', 'photo_public_url']);

        $ak = trim((string) ($row['author_key'] ?? $row['authorKey'] ?? ''));
        $mine = $threadViewerAuthorKey !== null && $isAdmin && $ak !== '' && $ak === trim($threadViewerAuthorKey);
        $sortTs = self::normalizedSortTimestampForRow($row, $mongoId);

        return [
            'id' => $ci,
            'body' => self::bodyTextFull($row),
            'author_label' => $author,
            'created_at' => self::createdAtIso($row) ?? '',
            '_sort_ts' => $sortTs,
            'mine' => $mine,
            'reply_quote' => trim((string) ($row['reply_quote'] ?? '')),
            'reply_to_self' => (bool) ($row['reply_to_self'] ?? false),
            'audio_url' => $audioUrl,
            'image_url' => $imageUrl,
            'from_chat_intervenant' => true,
        ];
    }

    private static function normalizedSortTimestampForRow(array $row, string $mongoId): int
    {
        $fromDate = 0;
        $iso = self::createdAtIso($row);
        if ($iso !== null && $iso !== '') {
            $fromDate = (int) (strtotime($iso) ?: 0);
        }

        $fromObjectId = 0;
        try {
            if (strlen($mongoId) === 24 && ctype_xdigit($mongoId)) {
                $fromObjectId = (int) (new ObjectId($mongoId))->getTimestamp();
            }
        } catch (\Throwable) {
            $fromObjectId = 0;
        }

        if ($fromDate <= 0) {
            return $fromObjectId;
        }
        if ($fromObjectId <= 0) {
            return $fromDate;
        }

        // Si les deux horodatages diffèrent beaucoup (décalage fuseau/format), garder le plus récent.
        if (abs($fromDate - $fromObjectId) > (6 * 3600)) {
            return max($fromDate, $fromObjectId);
        }

        return $fromDate;
    }

    private static function bodyTextFull(array $row): string
    {
        $text = '';
        foreach (['text', 'message', 'body', 'content', 'message_text', 'contenu'] as $k) {
            $v = $row[$k] ?? null;
            if (is_string($v) && trim($v) !== '') {
                $text = $v;
                break;
            }
        }
        if ($text === '') {
            foreach (['content.text', 'data.message', 'payload.message', 'payload.body'] as $path) {
                $v = data_get($row, $path);
                if (is_string($v) && trim($v) !== '') {
                    $text = $v;
                    break;
                }
            }
        }
        $text = strip_tags($text);
        $text = preg_replace('/\s+/u', ' ', $text) ?? $text;
        $text = trim($text);
        if ($text === '') {
            return '';
        }
        if (mb_strlen($text) > 8000) {
            return mb_substr($text, 0, 7997).'…';
        }

        return $text;
    }

    /**
     * @param  list<string>  $keys
     */
    private static function firstHttpUrl(array $row, array $keys): ?string
    {
        foreach ($keys as $k) {
            $v = $row[$k] ?? null;
            if (! is_string($v)) {
                continue;
            }
            $v = trim($v);
            if ($v === '') {
                continue;
            }
            if (str_starts_with(strtolower($v), 'http://') || str_starts_with(strtolower($v), 'https://')) {
                return $v;
            }
        }

        return null;
    }
}
