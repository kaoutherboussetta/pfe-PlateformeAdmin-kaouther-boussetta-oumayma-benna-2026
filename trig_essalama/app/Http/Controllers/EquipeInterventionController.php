<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\AdminAutoritaire;
use App\Models\AdminAutoritaireSession;
use App\Models\EquipeIntervention;
use App\Models\User;
use App\Support\ChatIntervenantReader;
use App\Support\ChatIntervenantThreadStore;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\View\View;
use MongoDB\BSON\ObjectId;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class EquipeInterventionController extends Controller
{
    public function index(Request $request): View|RedirectResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return redirect()->route('login')->with('error', 'Vous devez être connecté pour accéder à cette page.');
        }

        return redirect()->route('dashboard', ['section' => 'equipes']);
    }

    /** Notifications (collection MongoDB chat_intervenant). */
    public function chatIntervenantNotifications(Request $request): JsonResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $limit = (int) $request->query('limit', 12);
        $data = ChatIntervenantReader::notifications($limit);

        return response()->json(array_merge(['success' => true], $data));
    }

    public function chatMessages(Request $request): JsonResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $rk = $this->recipientKeyFromRequest($request);
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $authorKey = $this->resolveChatAuthorKey($request, $this->resolveAuthenticatedUser($request));

        $messages = ChatIntervenantReader::messagesForRecipient($rk, 200, $authorKey);

        return response()->json(['success' => true, 'messages' => $messages]);
    }

    /** Compteurs par destinataire (pastilles « Message » intervenants). */
    public function chatIntervenantRecipientCounts(Request $request): JsonResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        return response()->json([
            'success' => true,
            'counts' => ChatIntervenantReader::alertCountsByRecipientKey(),
        ]);
    }

    public function chatSend(Request $request): JsonResponse
    {
        $user = $this->resolveAuthenticatedUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $data = $request->validate([
            'recipient_type' => ['required', 'string', 'in:module,intervenant'],
            'recipient_id' => ['required', 'string', 'max:128'],
            'intervenant_collection' => ['nullable', 'string', 'in:intervenants,intervenant'],
            'message' => ['required', 'string', 'max:2000'],
            'reply_quote' => ['nullable', 'string', 'max:500'],
            'reply_to_self' => ['nullable', 'boolean'],
        ]);

        $rk = $this->buildRecipientKey(
            $data['recipient_type'],
            trim($data['recipient_id']),
            isset($data['intervenant_collection']) ? trim((string) $data['intervenant_collection']) : ''
        );
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $body = trim($data['message']);
        if ($body === '') {
            return response()->json(['success' => false, 'message' => 'Message vide.'], 422);
        }

        $authorLabel = $this->resolveChatAuthorLabel($user);
        $authorKey = $this->resolveChatAuthorKey($request, $user);

        $replyQuote = trim((string) ($data['reply_quote'] ?? ''));

        try {
            ChatIntervenantThreadStore::insertAdminText(
                $rk,
                $authorLabel,
                $authorKey,
                $body,
                $replyQuote,
                $request->boolean('reply_to_self')
            );
        } catch (\Throwable $e) {
            Log::error('chat_intervenant admin chat send: '.$e->getMessage());

            return response()->json(['success' => false, 'message' => 'Impossible d’enregistrer le message.'], 500);
        }

        return response()->json(['success' => true]);
    }

    public function chatVoiceUpload(Request $request): JsonResponse
    {
        $user = $this->resolveAuthenticatedUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $data = $request->validate([
            'recipient_type' => ['required', 'string', 'in:module,intervenant'],
            'recipient_id' => ['required', 'string', 'max:128'],
            'intervenant_collection' => ['nullable', 'string', 'in:intervenants,intervenant'],
            'audio' => ['required', 'file', 'max:15360'],
        ]);

        $rk = $this->buildRecipientKey(
            $data['recipient_type'],
            trim($data['recipient_id']),
            isset($data['intervenant_collection']) ? trim((string) $data['intervenant_collection']) : ''
        );
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $file = $request->file('audio');
        $ext = strtolower((string) ($file->getClientOriginalExtension() ?: ''));
        if (! in_array($ext, ['webm', 'ogg', 'oga', 'wav', 'mp3', 'mpeg', 'mp4', 'm4a'], true)) {
            $ext = 'webm';
        }
        $name = Str::uuid()->toString().'.'.$ext;

        try {
            $relative = $file->storeAs('private/message_admin_voice', $name, 'local');
        } catch (\Throwable $e) {
            Log::error('message_admin voice store: '.$e->getMessage());

            return response()->json(['success' => false, 'message' => 'Impossible d’enregistrer le fichier audio.'], 500);
        }

        if ($relative === false || $relative === '') {
            return response()->json(['success' => false, 'message' => 'Échec du stockage audio.'], 500);
        }

        $authorLabel = $this->resolveChatAuthorLabel($user);
        $authorKey = $this->resolveChatAuthorKey($request, $user);
        $mime = (string) ($file->getMimeType() ?: $file->getClientMimeType() ?: 'audio/webm');

        try {
            ChatIntervenantThreadStore::insertAdminVoice($rk, $authorLabel, $authorKey, $relative, $mime);
        } catch (\Throwable $e) {
            Storage::disk('local')->delete($relative);
            Log::error('chat_intervenant voice create: '.$e->getMessage());

            return response()->json(['success' => false, 'message' => 'Impossible d’enregistrer le message vocal.'], 500);
        }

        return response()->json(['success' => true]);
    }

    public function chatVoiceStream(Request $request, string $id): BinaryFileResponse|JsonResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return response()->json(['message' => 'Non authentifié.'], 401);
        }

        $oid = ChatIntervenantThreadStore::parseObjectIdFromRouteId($id);
        if ($oid !== null) {
            $row = ChatIntervenantThreadStore::findByObjectId($oid);
            if ($row !== null) {
                $relative = trim((string) ($row['audio_storage_path'] ?? ''));
                if ($relative !== '' && Storage::disk('local')->exists($relative)) {
                    $abs = Storage::disk('local')->path($relative);
                    $mime = (string) ($row['audio_mime'] ?? 'audio/webm');

                    return response()->file($abs, [
                        'Content-Type' => $mime,
                        'Cache-Control' => 'private, max-age=3600',
                    ]);
                }
            }
        }

        abort(404);
    }

    public function chatImageUpload(Request $request): JsonResponse
    {
        $user = $this->resolveAuthenticatedUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $data = $request->validate([
            'recipient_type' => ['required', 'string', 'in:module,intervenant'],
            'recipient_id' => ['required', 'string', 'max:128'],
            'intervenant_collection' => ['nullable', 'string', 'in:intervenants,intervenant'],
            'image' => ['required', 'file', 'mimes:jpeg,png,gif,webp', 'max:10240'],
            'message' => ['nullable', 'string', 'max:2000'],
            'reply_quote' => ['nullable', 'string', 'max:500'],
            'reply_to_self' => ['nullable', 'boolean'],
        ]);

        $rk = $this->buildRecipientKey(
            $data['recipient_type'],
            trim($data['recipient_id']),
            isset($data['intervenant_collection']) ? trim((string) $data['intervenant_collection']) : ''
        );
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $file = $request->file('image');
        $ext = strtolower((string) ($file->getClientOriginalExtension() ?: ''));
        if (! in_array($ext, ['jpg', 'jpeg', 'png', 'gif', 'webp'], true)) {
            $ext = match ($file->getMimeType()) {
                'image/png' => 'png',
                'image/gif' => 'gif',
                'image/webp' => 'webp',
                default => 'jpg',
            };
        }
        if ($ext === 'jpeg') {
            $ext = 'jpg';
        }
        $name = Str::uuid()->toString().'.'.$ext;

        try {
            $relative = $file->storeAs('private/message_admin_image', $name, 'local');
        } catch (\Throwable $e) {
            Log::error('message_admin image store: '.$e->getMessage());

            return response()->json(['success' => false, 'message' => 'Impossible d’enregistrer l’image.'], 500);
        }

        if ($relative === false || $relative === '') {
            return response()->json(['success' => false, 'message' => 'Échec du stockage de l’image.'], 500);
        }

        $authorLabel = $this->resolveChatAuthorLabel($user);
        $authorKey = $this->resolveChatAuthorKey($request, $user);
        $mime = (string) ($file->getMimeType() ?: $file->getClientMimeType() ?: 'image/jpeg');

        $caption = trim((string) ($data['message'] ?? ''));
        $body = $caption !== '' ? $caption : '📷 Photo';
        $replyQuote = trim((string) ($data['reply_quote'] ?? ''));

        try {
            ChatIntervenantThreadStore::insertAdminImage($rk, $authorLabel, $authorKey, $relative, $mime, $body, [
                'reply_quote' => $replyQuote,
                'reply_to_self' => $request->boolean('reply_to_self'),
            ]);
        } catch (\Throwable $e) {
            Storage::disk('local')->delete($relative);
            Log::error('chat_intervenant image create: '.$e->getMessage());

            return response()->json(['success' => false, 'message' => 'Impossible d’enregistrer le message photo.'], 500);
        }

        return response()->json(['success' => true]);
    }

    public function chatImageStream(Request $request, string $id): BinaryFileResponse|JsonResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return response()->json(['message' => 'Non authentifié.'], 401);
        }

        $oid = ChatIntervenantThreadStore::parseObjectIdFromRouteId($id);
        if ($oid !== null) {
            $row = ChatIntervenantThreadStore::findByObjectId($oid);
            if ($row !== null) {
                $relative = trim((string) ($row['image_storage_path'] ?? ''));
                if ($relative !== '' && Storage::disk('local')->exists($relative)) {
                    $abs = Storage::disk('local')->path($relative);
                    $mime = (string) ($row['image_mime'] ?? 'image/jpeg');

                    return response()->file($abs, [
                        'Content-Type' => $mime,
                        'Cache-Control' => 'private, max-age=3600',
                    ]);
                }
            }
        }

        abort(404);
    }

    public function chatMessageUpdate(Request $request, string $id): JsonResponse
    {
        $user = $this->resolveAuthenticatedUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $data = $request->validate([
            'recipient_type' => ['required', 'string', 'in:module,intervenant'],
            'recipient_id' => ['required', 'string', 'max:128'],
            'intervenant_collection' => ['nullable', 'string', 'in:intervenants,intervenant'],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $rk = $this->buildRecipientKey(
            $data['recipient_type'],
            trim($data['recipient_id']),
            isset($data['intervenant_collection']) ? trim((string) $data['intervenant_collection']) : ''
        );
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $body = trim($data['message']);
        if ($body === '') {
            return response()->json(['success' => false, 'message' => 'Message vide.'], 422);
        }

        $authorKey = $this->resolveChatAuthorKey($request, $user);

        $oid = ChatIntervenantThreadStore::parseObjectIdFromRouteId($id);
        if ($oid !== null && ChatIntervenantThreadStore::updateAdminText($oid, $rk, $authorKey, $body)) {
            return response()->json(['success' => true]);
        }

        return response()->json(['success' => false, 'message' => 'Message introuvable ou non modifiable.'], 404);
    }

    public function chatMessageDestroy(Request $request, string $id): JsonResponse
    {
        $user = $this->resolveAuthenticatedUser($request);
        if (! $user) {
            return response()->json(['success' => false, 'message' => 'Non authentifié.'], 401);
        }

        $data = $request->validate([
            'recipient_type' => ['required', 'string', 'in:module,intervenant'],
            'recipient_id' => ['required', 'string', 'max:128'],
            'intervenant_collection' => ['nullable', 'string', 'in:intervenants,intervenant'],
        ]);

        $rk = $this->buildRecipientKey(
            $data['recipient_type'],
            trim($data['recipient_id']),
            isset($data['intervenant_collection']) ? trim((string) $data['intervenant_collection']) : ''
        );
        if ($rk === null) {
            return response()->json(['success' => false, 'message' => 'Destinataire invalide.'], 422);
        }

        $authorKey = $this->resolveChatAuthorKey($request, $user);

        $oid = ChatIntervenantThreadStore::parseObjectIdFromRouteId($id);
        if ($oid !== null) {
            $paths = ChatIntervenantThreadStore::deleteAdminMessage($oid, $rk, $authorKey);
            if ($paths !== null) {
                if ($paths['audio'] !== '') {
                    try {
                        Storage::disk('local')->delete($paths['audio']);
                    } catch (\Throwable $e) {
                        Log::debug('chat_intervenant voice delete: '.$e->getMessage());
                    }
                }
                if ($paths['image'] !== '') {
                    try {
                        Storage::disk('local')->delete($paths['image']);
                    } catch (\Throwable $e) {
                        Log::debug('chat_intervenant image delete: '.$e->getMessage());
                    }
                }

                return response()->json(['success' => true]);
            }
        }

        return response()->json(['success' => false, 'message' => 'Message introuvable ou non supprimable.'], 404);
    }

    private function recipientKeyFromRequest(Request $request): ?string
    {
        $type = $request->query('recipient_type');
        $id = trim((string) $request->query('recipient_id', ''));
        $col = trim((string) $request->query('intervenant_collection', ''));

        return $this->buildRecipientKey(
            is_string($type) ? $type : '',
            $id,
            $col
        );
    }

    private function buildRecipientKey(string $type, string $id, string $collection): ?string
    {
        if ($id === '') {
            return null;
        }
        if ($type === 'module') {
            return 'm:'.$id;
        }
        if ($type === 'intervenant') {
            if (! in_array($collection, ['intervenants', 'intervenant'], true)) {
                return null;
            }

            return 'i:'.$collection.':'.$id;
        }

        return null;
    }

    private function resolveChatAuthorLabel(mixed $user): string
    {
        if (is_object($user)) {
            $email = trim((string) data_get($user, 'email'));
            if ($email !== '') {
                return $email;
            }
            $name = trim((string) (data_get($user, 'name')
                ?: data_get($user, 'full_name')
                ?: (trim((string) data_get($user, 'first_name')).' '.trim((string) data_get($user, 'last_name')))));
            if ($name !== '') {
                return $name;
            }
        }

        $e = trim((string) session('admin_email'));
        if ($e !== '') {
            return $e;
        }

        return trim((string) session('admin_name', 'Administrateur'));
    }

    private function resolveChatAuthorKey(Request $request, mixed $user): string
    {
        $email = strtolower(trim((string) session('admin_email')));
        if ($email !== '') {
            return 'e:'.$email;
        }
        if (is_object($user)) {
            $ue = strtolower(trim((string) data_get($user, 'email')));
            if ($ue !== '') {
                return 'e:'.$ue;
            }
            $id = (string) (data_get($user, 'id') ?? data_get($user, '_id') ?? '');
            if ($id !== '') {
                return 'u:'.$id;
            }
        }

        return 's:'.substr(sha1((string) $request->session()->getId()), 0, 20);
    }

    /** Données vue « Équipes d'intervention » (tableau de bord intégré ou page dédiée). */
    public function embedViewData(Request $request, mixed $user): array
    {
        return [
            'equipes' => EquipeIntervention::query()
                ->orderBy('created_at', 'desc')
                ->limit(300)
                ->get(),
            'intervenants' => $this->loadIntervenantsForEquipesPage(),
            'chatAuthorLabel' => $this->resolveChatAuthorLabel($user),
            'chatAuthorKey' => $this->resolveChatAuthorKey($request, $user),
            'chatMessagesUrl' => route('interface_admin_tech.equipes.chat.messages'),
            'chatMessagesBaseUrl' => url('/interface_admin_tech/equipes/chat/messages'),
            'chatSendUrl' => route('interface_admin_tech.equipes.chat.send'),
            'chatVoiceUploadUrl' => route('interface_admin_tech.equipes.chat.voice.upload'),
            'chatImageUploadUrl' => route('interface_admin_tech.equipes.chat.image.upload'),
            'chatIntervenantCountsUrl' => Route::has('api.chat_intervenant.recipient_counts')
                ? route('api.chat_intervenant.recipient_counts')
                : null,
        ];
    }

    public function store(Request $request): RedirectResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return redirect()->route('login')->with('error', 'Non authentifié.');
        }

        $data = $request->validate([
            'nom' => ['required', 'string', 'max:160'],
            'zone' => ['nullable', 'string', 'max:200'],
            'membres_text' => ['nullable', 'string', 'max:5000'],
        ]);

        $membres = $this->parseMembresLines($data['membres_text'] ?? '');

        EquipeIntervention::create([
            'nom' => trim($data['nom']),
            'zone' => isset($data['zone']) ? trim((string) $data['zone']) : '',
            'disponible' => $request->boolean('disponible'),
            'membres' => $membres,
            'current_problem_id' => null,
        ]);

        return redirect()->route('interface_admin_tech.equipes')->with('success', 'Équipe créée avec succès.');
    }

    public function update(Request $request, string $id): RedirectResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return redirect()->route('login')->with('error', 'Non authentifié.');
        }

        $equipe = EquipeIntervention::find($id);
        if (! $equipe) {
            return redirect()->route('interface_admin_tech.equipes')->with('error', 'Équipe introuvable.');
        }

        $data = $request->validate([
            'nom' => ['required', 'string', 'max:160'],
            'zone' => ['nullable', 'string', 'max:200'],
            'membres_text' => ['nullable', 'string', 'max:5000'],
        ]);

        $equipe->nom = trim($data['nom']);
        $equipe->zone = isset($data['zone']) ? trim((string) $data['zone']) : '';
        $equipe->disponible = $request->boolean('disponible');
        $equipe->membres = $this->parseMembresLines($data['membres_text'] ?? '');
        $equipe->save();

        return redirect()->route('interface_admin_tech.equipes')->with('success', 'Équipe mise à jour.');
    }

    public function destroy(Request $request, string $id): RedirectResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return redirect()->route('login')->with('error', 'Non authentifié.');
        }

        $equipe = EquipeIntervention::find($id);
        if (! $equipe) {
            return redirect()->route('interface_admin_tech.equipes')->with('error', 'Équipe introuvable.');
        }

        $equipe->delete();

        return redirect()->route('interface_admin_tech.equipes')->with('success', 'Équipe supprimée.');
    }

    public function assign(Request $request, string $id): RedirectResponse
    {
        if (! $this->resolveAuthenticatedUser($request)) {
            return redirect()->route('login')->with('error', 'Non authentifié.');
        }

        $equipe = EquipeIntervention::find($id);
        if (! $equipe) {
            return redirect()->route('interface_admin_tech.equipes')->with('error', 'Équipe introuvable.');
        }

        if (! $equipe->isAssignable()) {
            return redirect()->route('interface_admin_tech.equipes')->with('error', 'Équipe indisponible ou déjà affectée à un incident.');
        }

        $data = $request->validate([
            'problem_id' => ['required', 'string', 'max:64'],
            'cost' => ['nullable', 'string', 'max:80'],
        ]);

        $problemId = trim($data['problem_id']);
        $cost = trim((string) ($data['cost'] ?? ''));
        if ($cost === '') {
            $cost = '—';
        }

        $assignRequest = clone $request;
        $assignRequest->merge([
            'team_key' => $equipe->teamKey(),
            'team_label' => $equipe->nom,
            'cost' => $cost,
        ]);

        $response = app(ProblemController::class)->assignTeam($assignRequest, $problemId);
        $payload = json_decode($response->getContent(), true);

        if (! ($payload['success'] ?? false)) {
            return redirect()->route('interface_admin_tech.equipes')->with('error', $payload['message'] ?? 'Échec de l’affectation.');
        }

        $equipe->current_problem_id = $problemId;
        $equipe->save();

        return redirect()->route('interface_admin_tech.equipes')->with('success', 'Équipe affectée à l’incident avec succès.');
    }

    /**
     * @return array<int, array{nom: string}>
     */
    private function parseMembresLines(?string $raw): array
    {
        $raw = trim((string) $raw);
        if ($raw === '') {
            return [];
        }

        $lines = preg_split("/\r\n|\n|\r/", $raw) ?: [];
        $out = [];
        foreach ($lines as $line) {
            $line = trim($line);
            if ($line !== '') {
                $out[] = ['nom' => $line];
            }
        }

        return $out;
    }

    /**
     * Intervenants MongoDB (collections `intervenants` / `intervenant`) pour affichage dans le tableau équipes.
     */
    private function loadIntervenantsForEquipesPage(): Collection
    {
        $maxTotal = 1000;
        $perCollection = 800;
        $merged = collect();

        foreach (['intervenants', 'intervenant'] as $collectionName) {
            if ($merged->count() >= $maxTotal) {
                break;
            }
            try {
                $take = min($perCollection, $maxTotal - $merged->count());
                $batch = DB::connection('mongodb')->table($collectionName)
                    ->orderBy('_id', 'desc')
                    ->limit($take)
                    ->get();
                foreach ($batch as $doc) {
                    $row = $this->mongoDocToFlatArrayForIntervenants($doc);
                    $row['_collection'] = $collectionName;
                    $merged->push($this->normalizeIntervenantRowForEquipesPage($row));
                    if ($merged->count() >= $maxTotal) {
                        break 2;
                    }
                }
            } catch (\Throwable $e) {
                Log::debug('Equipes page intervenants: '.$collectionName.' — '.$e->getMessage());
            }
        }

        $this->appendChatIntervenantParticipants($merged, $maxTotal);

        return $merged;
    }

    /**
     * Ajoute les conversations présentes dans chat_intervenant avec leur intervenantId.
     */
    private function appendChatIntervenantParticipants(Collection $merged, int $maxTotal): void
    {
        $seen = [];
        foreach ($merged as $row) {
            foreach ($this->chatParticipantSeenKeys($row) as $key) {
                $seen[$key] = true;
            }
        }

        try {
            $docs = DB::connection('mongodb')
                ->table('chat_intervenant')
                ->orderBy('_id', 'desc')
                ->limit(1200)
                ->get();
        } catch (\Throwable $e) {
            Log::debug('Equipes page chat_intervenant participants — '.$e->getMessage());

            return;
        }

        foreach ($docs as $doc) {
            if ($merged->count() >= $maxTotal) {
                return;
            }

            $row = ChatIntervenantReader::mongoDocToAssocArray($doc);
            $id = trim((string) (
                data_get($row, 'intervenantId')
                ?: data_get($row, 'intervenant_id')
                ?: data_get($row, 'id_intervenant')
                ?: (
                    strtolower(trim((string) data_get($row, 'recipient_type'))) === 'intervenant'
                        ? data_get($row, 'recipient_id')
                        : ''
                )
            ));
            if ($id === '' || str_starts_with($id, 'sh_')) {
                continue;
            }

            $seenKey = strtolower($id);
            if (isset($seen[$seenKey])) {
                continue;
            }
            $seen[$seenKey] = true;

            $collection = trim((string) (data_get($row, 'intervenant_collection')
                ?: data_get($row, 'collection_cible')
                ?: data_get($row, 'target_collection')
                ?: 'intervenants'));
            if (! in_array($collection, ['intervenants', 'intervenant'], true)) {
                $collection = 'intervenants';
            }

            $fullName = trim((string) (data_get($row, 'intervenantName')
                ?: data_get($row, 'sender_name')
                ?: data_get($row, 'name')
                ?: data_get($row, 'fullName')
                ?: data_get($row, 'full_name')
                ?: ''));
            $parts = preg_split('/\s+/u', $fullName) ?: [];
            $prenom = trim((string) (data_get($row, 'prenom')
                ?: data_get($row, 'first_name')
                ?: ($parts[0] ?? '')));
            $nom = trim((string) (data_get($row, 'nom')
                ?: data_get($row, 'last_name')
                ?: (count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : '')));

            $email = trim((string) (data_get($row, 'email')
                ?: data_get($row, 'mail')
                ?: data_get($row, 'courriel')
                ?: (str_contains($id, '@') ? $id : '')));

            $merged->push([
                'nom' => $nom !== '' ? $nom : '—',
                'prenom' => $prenom !== '' ? $prenom : '—',
                'equipe' => (string) (data_get($row, 'equipe') ?: data_get($row, 'team') ?: 'Conversation chat'),
                'phone' => (string) (data_get($row, 'phone') ?: data_get($row, 'telephone') ?: '—'),
                'zone' => (string) (data_get($row, 'zone') ?: data_get($row, 'adresse') ?: '—'),
                'email' => $email !== '' ? $email : '—',
                'id' => $id,
                'collection' => $collection,
                'chat_recipient_id' => $id,
                'chat_collection' => $collection,
                'raw' => $row,
            ]);
        }
    }

    /**
     * Alias connus d'une fiche intervenant : _id Mongo, email, et clé nom/équipe
     * utilisée par certains messages mobile dans chat_intervenant.
     *
     * @return list<string>
     */
    private function chatParticipantSeenKeys(array $row): array
    {
        $keys = [];
        foreach (['chat_recipient_id', 'id'] as $field) {
            $value = strtolower(trim((string) ($row[$field] ?? '')));
            if ($value !== '' && $value !== '—') {
                $keys[] = $value;
            }
        }

        $email = strtolower(trim((string) ($row['email'] ?? '')));
        if ($email !== '' && $email !== '—') {
            $keys[] = $email;
        }

        $prenom = trim((string) ($row['prenom'] ?? ''));
        $nom = trim((string) ($row['nom'] ?? ''));
        $nameParts = array_values(array_filter([$prenom, $nom], static fn (string $v): bool => $v !== '' && $v !== '—'));
        if ($nameParts !== []) {
            $nameSeg = Str::slug(strtolower(implode(' ', $nameParts)), '_');
            if ($nameSeg !== '') {
                $keys[] = 'name_'.$nameSeg;
                $equipe = trim((string) ($row['equipe'] ?? ''));
                if ($equipe !== '' && $equipe !== '—') {
                    $eqSeg = Str::slug(strtolower($equipe), '_');
                    if ($eqSeg !== '') {
                        $keys[] = 'name_'.$nameSeg.'_('.$eqSeg.')';
                    }
                }
            }
        }

        return array_values(array_unique($keys));
    }

    /**
     * Ligne tableau : nom, prénom, équipe, téléphone, zone, email (collections intervenants).
     *
     * @return array{nom: string, prenom: string, equipe: string, phone: string, zone: string, email: string, id: string, collection: string, chat_recipient_id: string, chat_collection: string, raw: array}
     */
    private function normalizeIntervenantRowForEquipesPage(array $row): array
    {
        $equipe = trim((string) (data_get($row, 'equipe')
            ?: data_get($row, 'team')
            ?: data_get($row, 'team_label')
            ?: data_get($row, 'titre')
            ?: data_get($row, 'libelle')
            ?: ''));

        $prenom = trim((string) (data_get($row, 'first_name')
            ?: data_get($row, 'prenom')
            ?: data_get($row, 'firstname')
            ?: ''));

        $nom = trim((string) (data_get($row, 'last_name')
            ?: data_get($row, 'nom_famille')
            ?: data_get($row, 'family_name')
            ?: ''));

        if ($nom === '') {
            $n = trim((string) data_get($row, 'nom'));
            if ($n !== '' && ($equipe === '' || strcasecmp($n, $equipe) !== 0)) {
                $nom = $n;
            }
        }

        if ($nom === '') {
            $nom = '—';
        }
        if ($prenom === '') {
            $prenom = '—';
        }

        $phone = trim((string) (data_get($row, 'telephone')
            ?: data_get($row, 'phone')
            ?: data_get($row, 'tel')
            ?: data_get($row, 'mobile')
            ?: data_get($row, 'gsm')
            ?: data_get($row, 'numero')
            ?: ''));

        $zone = trim((string) (data_get($row, 'zone')
            ?: data_get($row, 'ville')
            ?: data_get($row, 'quartier')
            ?: data_get($row, 'region')
            ?: data_get($row, 'adresse')
            ?: data_get($row, 'localisation')
            ?: data_get($row, 'address')
            ?: ''));

        $email = trim((string) (data_get($row, 'email')
            ?: data_get($row, 'courriel')
            ?: data_get($row, 'mail')
            ?: ''));
        if ($email === '') {
            $email = '—';
        }

        $id = $this->mongoIdToString(data_get($row, '_id') ?? data_get($row, 'id'));
        $collection = (string) (data_get($row, '_collection') ?? '');

        $logicalChatId = trim((string) (data_get($row, 'intervenantId')
            ?: data_get($row, 'intervenant_id')
            ?: data_get($row, 'logical_id')
            ?: data_get($row, 'slug')
            ?: data_get($row, 'external_id')
            ?: ''));

        $chatCollection = in_array($collection, ['intervenants', 'intervenant'], true)
            ? $collection
            : 'intervenants';

        if ($id !== '' && in_array($collection, ['intervenants', 'intervenant'], true)) {
            $chatRecipientId = $logicalChatId !== '' ? $logicalChatId : $id;
        } else {
            $chatRecipientId = $this->shadowIntervenantRecipientId(
                $chatCollection,
                $nom,
                $prenom,
                $email,
                $phone !== '' ? $phone : '—',
                $zone !== '' ? $zone : '—',
                $equipe !== '' ? $equipe : '—'
            );
        }

        $raw = $row;
        unset($raw['__search']);

        return [
            'nom' => $nom,
            'prenom' => $prenom,
            'equipe' => $equipe !== '' ? $equipe : '—',
            'phone' => $phone !== '' ? $phone : '—',
            'zone' => $zone !== '' ? $zone : '—',
            'email' => $email,
            'id' => $id,
            'collection' => $collection,
            'chat_recipient_id' => $chatRecipientId,
            'chat_collection' => $chatCollection,
            'raw' => $raw,
        ];
    }

    /**
     * Clé stable lorsque _id MongoDB est absent : même logique côté liste et envoi.
     */
    private function shadowIntervenantRecipientId(
        string $collection,
        string $nom,
        string $prenom,
        string $email,
        string $phone,
        string $zone,
        string $equipe
    ): string {
        $payload = strtolower($collection).'|'
            .strtolower($nom).'|'
            .strtolower($prenom).'|'
            .strtolower($email).'|'
            .$phone.'|'
            .strtolower($zone).'|'
            .strtolower($equipe);

        return 'sh_'.substr(hash('sha256', $payload), 0, 40);
    }

    /**
     * @param  mixed  $doc  stdClass|array|BSONDocument
     */
    private function mongoDocToFlatArrayForIntervenants(mixed $doc): array
    {
        $arr = json_decode(json_encode($doc), true);
        if (! is_array($arr)) {
            return [];
        }

        $id = '';
        if (array_key_exists('_id', $arr)) {
            $id = $this->mongoIdToString($arr['_id']);
        }
        if ($id === '' && array_key_exists('id', $arr)) {
            $id = $this->mongoIdToString($arr['id']);
        }
        if ($id === '' && is_object($doc) && isset($doc->_id)) {
            $id = $this->mongoIdToString($doc->_id);
        }
        if ($id === '' && is_object($doc) && isset($doc->id)) {
            $id = $this->mongoIdToString($doc->id);
        }
        $arr['_id'] = $id;

        return $arr;
    }

    private function mongoIdToString(mixed $value): string
    {
        if ($value === null) {
            return '';
        }
        if (is_string($value)) {
            return trim($value);
        }
        if ($value instanceof ObjectId) {
            return (string) $value;
        }
        if (is_array($value) && isset($value['$oid'])) {
            return trim((string) $value['$oid']);
        }
        if (is_object($value) && method_exists($value, '__toString')) {
            return trim((string) $value);
        }

        return '';
    }

    /**
     * Même logique que le tableau de bord (routes/web.php) : admin autoritaire en session,
     * admin technique (User ou guard admin), puis utilisateur web.
     */
    private function resolveAuthenticatedUser(Request $request): mixed
    {
        $user = null;

        if ($request->session()->get('autoritaire_authenticated')) {
            return new AdminAutoritaireSession([
                'id' => (string) ($request->session()->get('admin_id') ?: 'autoritaire_1'),
                'email' => $request->session()->get('admin_email'),
                'name' => $request->session()->get('admin_name', 'Administrateur Autoritaire'),
                'first_name' => $request->session()->get('admin_first_name', config('admin_autoritaire.first_name', 'Admin')),
                'last_name' => $request->session()->get('admin_last_name', config('admin_autoritaire.last_name', 'Autoritaire')),
                'role' => 'autoritaire',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (! $user && $request->session()->get('authenticated_admin_technical') && $request->session()->get('admin_type') === 'technical') {
            return new AdminAutoritaireSession([
                'id' => (string) ($request->session()->get('admin_id') ?: 'technical_1'),
                'email' => $request->session()->get('admin_email'),
                'name' => $request->session()->get('admin_name', 'Administrateur Technique'),
                'first_name' => $request->session()->get('admin_first_name', 'Admin'),
                'last_name' => $request->session()->get('admin_last_name', 'Technique'),
                'role' => 'technical',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (! $user && Auth::guard('admin')->check()) {
            $admin = Auth::guard('admin')->user();
            if ($admin) {
                $isTechnical = false;
                if (method_exists($admin, 'isTechnical')) {
                    $isTechnical = (bool) $admin->isTechnical();
                } elseif (isset($admin->role) && ($admin->role === 'technical' || $admin->role === Admin::ROLE_TECHNICAL)) {
                    $isTechnical = true;
                }
                if ($isTechnical) {
                    $user = $admin;
                }
            }
        }

        if (! $user) {
            $user = Auth::user();
        }

        return $user;
    }
}
