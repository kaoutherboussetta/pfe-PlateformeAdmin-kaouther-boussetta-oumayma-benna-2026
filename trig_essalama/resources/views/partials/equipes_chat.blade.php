<div id="eqChatWidget" class="eq-chat-widget" hidden aria-hidden="true">
    <div class="eq-chat-header">
        <div class="eq-chat-head-left">
            <div class="eq-chat-avatar" id="eqChatAvatar">EQ</div>
            <div style="min-width:0;">
                <div class="eq-chat-title-row">
                    <div class="eq-chat-title" id="eqChatTitle">Équipe</div>
                    <span class="eq-chat-chevron" aria-hidden="true"><i class="fas fa-chevron-down"></i></span>
                </div>
                <div class="eq-chat-sub" id="eqChatSub">
                    <span class="eq-chat-sub-line1" id="eqChatSubLine1">Discussion</span>
                    <span class="eq-chat-sub-line2" id="eqChatSubLine2">Messages enregistrés</span>
                </div>
            </div>
        </div>
        <div class="eq-chat-head-actions">
            <button type="button" id="eqChatMin" title="Réduire" aria-label="Réduire"><i class="fas fa-minus"></i></button>
            <button type="button" id="eqChatClose" title="Fermer" aria-label="Fermer"><i class="fas fa-times"></i></button>
        </div>
    </div>
    <div class="eq-chat-body" id="eqChatMessages"></div>
    <div class="eq-chat-footer">
        <div class="eq-chat-foot-panel">
            <div id="eqChatReplyBar" class="eq-chat-reply-bar" hidden>
                <div class="eq-chat-reply-bar-inner">
                    <div class="eq-chat-reply-accent" aria-hidden="true"></div>
                    <div class="eq-chat-reply-text">
                        <span class="eq-chat-reply-label" id="eqChatReplyLabel">Réponse</span>
                        <span class="eq-chat-reply-snippet" id="eqChatReplySnippet"></span>
                    </div>
                    <button type="button" class="eq-chat-reply-cancel" id="eqChatReplyCancel" title="Annuler la réponse" aria-label="Annuler la réponse"><i class="fas fa-times"></i></button>
                </div>
            </div>
            <div class="eq-chat-foot-tools" id="eqChatFootTools">
                <button type="button" class="eq-chat-tool" id="eqChatMic" title="Enregistrer un message vocal" aria-label="Microphone"><i class="fas fa-microphone"></i></button>
                <button type="button" class="eq-chat-tool" title="Stickers (non disponible)" aria-label="Sticker"><i class="far fa-smile"></i></button>
                <button type="button" class="eq-chat-tool" title="GIF (non disponible)" aria-label="GIF"><span>GIF</span></button>
            </div>
            <div id="eqChatVoiceBar" class="eq-chat-voice-bar" hidden>
                <button type="button" class="eq-chat-voice-cancel" id="eqChatVoiceTrash" title="Annuler l’enregistrement" aria-label="Annuler"><i class="fas fa-times"></i></button>
                <div class="eq-chat-voice-pill">
                    <div class="eq-chat-voice-pill-stop-wrap">
                        <button type="button" class="eq-chat-voice-stop-btn" id="eqChatVoicePause" title="Pause" aria-label="Pause"><i class="fas fa-stop"></i></button>
                    </div>
                    <span class="eq-chat-voice-pill-spacer" aria-hidden="true"></span>
                    <span class="eq-chat-voice-timer-badge" id="eqChatVoiceTimer">0:00</span>
                </div>
                <button type="button" class="eq-chat-voice-send-plain" id="eqChatVoiceSendGreen" title="Envoyer le vocal" aria-label="Envoyer"><i class="fas fa-paper-plane"></i></button>
            </div>
            <div class="eq-chat-foot-input-row" id="eqChatInputRow">
                <button type="button" class="eq-chat-side-plus" id="eqChatSidePlus" title="Ajouter une ou plusieurs photos" aria-label="Ajouter une ou plusieurs photos"><i class="fas fa-plus"></i></button>
                <div class="eq-chat-composer">
                    <div id="eqChatAttachPreview" class="eq-chat-attach-preview" hidden>
                        <button type="button" class="eq-chat-attach-add" id="eqChatAttachAddBtn" title="Ajouter une ou plusieurs photos" aria-label="Ajouter des photos">
                            <span class="eq-chat-attach-add-inner"><i class="fas fa-plus" aria-hidden="true"></i></span>
                        </button>
                        <div id="eqChatAttachThumbs" class="eq-chat-attach-thumbs"></div>
                    </div>
                    <div class="eq-chat-composer-field">
                        <div class="eq-chat-input-wrap">
                            <input type="text" id="eqChatInput" placeholder="Message" maxlength="2000" autocomplete="off" />
                            <button type="button" class="eq-chat-emoji-in" title="Emoji (non disponible)" aria-label="Emoji"><i class="far fa-smile"></i></button>
                        </div>
                    </div>
                </div>
                <button type="button" class="eq-chat-send" id="eqChatSend" title="Envoyer" aria-label="Envoyer"><i class="fas fa-paper-plane"></i></button>
            </div>
            <input type="file" id="eqChatImageInput" accept="image/jpeg,image/jpg,image/png,image/gif,image/webp" multiple hidden />
        </div>
    </div>
</div>

<div id="eqChatCtxMenu" class="eq-chat-ctx" hidden role="menu" aria-label="Actions message">
    <button type="button" class="eq-chat-ctx-item" data-act="copy" role="menuitem"><i class="fas fa-copy" aria-hidden="true"></i> Copier</button>
    <button type="button" class="eq-chat-ctx-item" data-act="reply" role="menuitem"><i class="fas fa-reply" aria-hidden="true"></i> Répondre</button>
    <div class="eq-chat-ctx-sep" aria-hidden="true"></div>
    <button type="button" class="eq-chat-ctx-item eq-chat-ctx-mine" data-act="edit" role="menuitem"><i class="fas fa-pen" aria-hidden="true"></i> Modifier</button>
    <button type="button" class="eq-chat-ctx-item eq-chat-ctx-mine danger" data-act="delete" role="menuitem"><i class="fas fa-trash" aria-hidden="true"></i> Supprimer</button>
</div>

<script>
(function () {
    var CHAT_BADGES_REFRESH_MS = 12000;
    var CHAT_OPEN_THREAD_REFRESH_MS = 5000;
    var messagesUrl = @json($chatMessagesUrl ?? '');
    var chatMessagesBaseUrl = @json($chatMessagesBaseUrl ?? '');
    var sendUrl = @json($chatSendUrl ?? '');
    var voiceUploadUrl = @json($chatVoiceUploadUrl ?? '');
    var imageUploadUrl = @json($chatImageUploadUrl ?? '');
    var chatIntervenantCountsUrl = @json($chatIntervenantCountsUrl ?? '');
    var widget = document.getElementById('eqChatWidget');
    var titleEl = document.getElementById('eqChatTitle');
    var avatarEl = document.getElementById('eqChatAvatar');
    var bodyEl = document.getElementById('eqChatMessages');
    var inputEl = document.getElementById('eqChatInput');
    var sendBtn = document.getElementById('eqChatSend');
    var btnMin = document.getElementById('eqChatMin');
    var btnClose = document.getElementById('eqChatClose');
    var subLine1 = document.getElementById('eqChatSubLine1');
    var subLine2 = document.getElementById('eqChatSubLine2');
    var ctxMenu = document.getElementById('eqChatCtxMenu');
    var ctxState = { msgId: '', body: '', copyText: '', replyFull: '', mine: false, hasVoice: false };
    var replyBar = document.getElementById('eqChatReplyBar');
    var replySnippet = document.getElementById('eqChatReplySnippet');
    var replyLabel = document.getElementById('eqChatReplyLabel');
    var replyCancel = document.getElementById('eqChatReplyCancel');
    var replyDraft = null;
    var state = { type: '', id: '', collection: '', label: '', loading: false };

    var micBtn = document.getElementById('eqChatMic');
    var imageInput = document.getElementById('eqChatImageInput');
    var sidePlusBtn = document.getElementById('eqChatSidePlus');
    var attachPreview = document.getElementById('eqChatAttachPreview');
    var attachThumbs = document.getElementById('eqChatAttachThumbs');
    var attachAddBtn = document.getElementById('eqChatAttachAddBtn');
    var pendingImages = [];
    var MAX_PENDING_IMAGES = 15;
    var mediaStream = null;
    var mediaRecorder = null;
    var recordChunks = [];
    var isRecording = false;
    var voiceCloseDiscard = false;
    var voiceBarEl = document.getElementById('eqChatVoiceBar');
    var voiceInputRow = document.getElementById('eqChatInputRow');
    var voiceTrash = document.getElementById('eqChatVoiceTrash');
    var voicePauseBtn = document.getElementById('eqChatVoicePause');
    var voiceSendGreen = document.getElementById('eqChatVoiceSendGreen');
    var voiceTimerEl = document.getElementById('eqChatVoiceTimer');
    var voiceUiActive = false;
    var voiceTimerInterval = null;
    var recAccumMs = 0;
    var recSegStart = 0;
    var voicePaused = false;

    function clearPendingAttachment() {
        for (var pi = 0; pi < pendingImages.length; pi++) {
            try { URL.revokeObjectURL(pendingImages[pi].objectUrl); } catch (e) {}
        }
        pendingImages = [];
        if (attachThumbs) attachThumbs.innerHTML = '';
        if (attachPreview) attachPreview.hidden = true;
    }

    function renderAttachPreview() {
        if (!attachPreview || !attachThumbs) return;
        if (!pendingImages.length) {
            attachThumbs.innerHTML = '';
            attachPreview.hidden = true;
            return;
        }
        attachPreview.hidden = false;
        attachThumbs.innerHTML = '';
        for (var i = 0; i < pendingImages.length; i++) {
            var item = pendingImages[i];
            var slot = document.createElement('div');
            slot.className = 'eq-chat-attach-thumb-slot';
            var img = document.createElement('img');
            img.className = 'eq-chat-attach-thumb-img';
            img.src = item.objectUrl;
            img.alt = 'Aperçu';
            var rm = document.createElement('button');
            rm.type = 'button';
            rm.className = 'eq-chat-attach-remove';
            rm.setAttribute('data-idx', String(i));
            rm.title = 'Retirer la photo';
            rm.setAttribute('aria-label', 'Retirer la photo');
            rm.innerHTML = '<i class="fas fa-times" aria-hidden="true"></i>';
            slot.appendChild(img);
            slot.appendChild(rm);
            attachThumbs.appendChild(slot);
        }
    }

    function addPendingImageFilesFromList(fileList) {
        if (!fileList || !fileList.length) return;
        var toAdd = [];
        for (var i = 0; i < fileList.length; i++) {
            var f = fileList[i];
            if (f && f.type && f.type.indexOf('image/') === 0) toAdd.push(f);
        }
        if (!toAdd.length) {
            alert('Veuillez choisir des fichiers image (JPEG, PNG, GIF ou WebP).');
            return;
        }
        var room = MAX_PENDING_IMAGES - pendingImages.length;
        if (room <= 0) {
            alert('Maximum ' + MAX_PENDING_IMAGES + ' images à la fois. Envoyez puis ajoutez d’autres photos.');
            return;
        }
        if (toAdd.length > room) {
            toAdd = toAdd.slice(0, room);
            alert('Seules les ' + room + ' premières images ont été ajoutées (limite ' + MAX_PENDING_IMAGES + ').');
        }
        for (var j = 0; j < toAdd.length; j++) {
            pendingImages.push({ file: toAdd[j], objectUrl: URL.createObjectURL(toAdd[j]) });
        }
        renderAttachPreview();
    }

    function clearReplyDraft() {
        replyDraft = null;
        if (replyBar) replyBar.hidden = true;
        if (replySnippet) replySnippet.textContent = '';
    }

    function beginReplyToMessage(fullTextForQuote, originalAuthorIsSelf) {
        var full = (fullTextForQuote || '').trim();
        if (!full) return;
        var oneLine = full.replace(/\s+/g, ' ');
        var snip = oneLine.length > 72 ? oneLine.slice(0, 72) + '…' : oneLine;
        replyDraft = { full: full, snippet: snip, replyToSelf: !!originalAuthorIsSelf };
        if (replySnippet) replySnippet.textContent = snip;
        if (replyLabel) {
            replyLabel.textContent = originalAuthorIsSelf ? 'Réponse à vous-même' : (state.type === 'intervenant' ? 'Réponse à l’intervenant' : 'Réponse à l’équipe');
        }
        if (replyBar) replyBar.hidden = false;
        inputEl.value = '';
        inputEl.focus();
    }

    function parseMessageParts(m) {
        var quote = ((m && m.reply_quote) || '').trim();
        var main = ((m && m.body) || '').trim();
        var replyToSelf = !!(m && m.reply_to_self);
        if (quote) {
            return { quote: quote, main: main, replyToSelf: replyToSelf, legacy: false };
        }
        if (main.indexOf('[Réponse]\n') === 0) {
            var rest = main.slice('[Réponse]\n'.length);
            var sep = '\n\n';
            var ix = rest.indexOf(sep);
            if (ix !== -1) {
                return { quote: rest.slice(0, ix).trim(), main: rest.slice(ix + sep.length).trim(), replyToSelf: false, legacy: true };
            }
        }
        return { quote: '', main: main, replyToSelf: false, legacy: false };
    }

    function replyLabelInBubble(parts) {
        if (!parts.quote) return '';
        if (parts.legacy) return 'Réponse';
        return parts.replyToSelf ? 'Réponse à vous-même' : (state.type === 'intervenant' ? 'Réponse à l’intervenant' : 'Réponse à l’équipe');
    }

    function copyTextForMessage(parts, m) {
        var t = parts.quote ? parts.quote + '\n\n' + parts.main : parts.main;
        if (m && m.audio_url) {
            return (t ? t + '\n' : '') + 'Message vocal — ' + m.audio_url;
        }
        if (m && m.image_url) {
            return (t ? t + '\n' : '') + 'Photo — ' + m.image_url;
        }
        return t;
    }

    function fullTextForReplyActionParts(parts, m) {
        if (m && m.audio_url) return '🎤 Message vocal';
        if (m && m.image_url) return '📷 Photo';
        if (parts.quote) return (parts.quote + (parts.main ? '\n' + parts.main : '')).trim();
        return parts.main;
    }

    function isMediaPlaceholderBody(text) {
        var s = (text || '').trim();
        return s === '🎤 Message vocal' || s === '📷 Photo';
    }

    function hashStringForBars(s) {
        var h = 0;
        var str = String(s || '');
        for (var i = 0; i < str.length; i++) {
            h = ((h << 5) - h) + str.charCodeAt(i);
            h |= 0;
        }
        return Math.abs(h) + 1;
    }

    function buildVoiceMessagePlayer(audioUrl, isMine, msgId) {
        var vw = document.createElement('div');
        vw.className = 'eq-chat-voice-player ' + (isMine ? 'eq-chat-voice-player--mine' : 'eq-chat-voice-player--other');
        var playBtn = document.createElement('button');
        playBtn.type = 'button';
        playBtn.className = 'eq-chat-voice-play';
        playBtn.setAttribute('aria-label', 'Lire le message vocal');
        playBtn.innerHTML = '<i class="fas fa-play" aria-hidden="true"></i>';
        var wave = document.createElement('div');
        wave.className = 'eq-chat-voice-static-wave';
        wave.setAttribute('aria-hidden', 'true');
        var seed = hashStringForBars(msgId || audioUrl);
        var n = 14;
        for (var bi = 0; bi < n; bi++) {
            seed = (seed * 1103515245 + 12345) & 0x7fffffff;
            var pct = 28 + (seed % 72);
            var bar = document.createElement('span');
            bar.className = 'eq-chat-voice-static-bar';
            bar.style.height = pct + '%';
            wave.appendChild(bar);
        }
        var durEl = document.createElement('span');
        durEl.className = 'eq-chat-voice-dur';
        durEl.textContent = '0:00';
        var aud = document.createElement('audio');
        aud.className = 'eq-chat-voice-audio';
        aud.preload = 'metadata';
        aud.src = audioUrl;
        function syncIcon() {
            var ic = playBtn.querySelector('i');
            if (!ic) return;
            ic.className = aud.paused ? 'fas fa-play' : 'fas fa-pause';
        }
        function setDurLabel() {
            var d = aud.duration;
            if (d && isFinite(d)) durEl.textContent = formatVoiceTime(d);
        }
        aud.addEventListener('loadedmetadata', setDurLabel);
        aud.addEventListener('durationchange', setDurLabel);
        aud.addEventListener('play', syncIcon);
        aud.addEventListener('pause', syncIcon);
        aud.addEventListener('ended', function () {
            syncIcon();
            setDurLabel();
        });
        playBtn.addEventListener('click', function (ev) {
            ev.stopPropagation();
            if (aud.paused) {
                var scope = widget ? widget.querySelectorAll('.eq-chat-voice-audio') : document.querySelectorAll('.eq-chat-voice-audio');
                scope.forEach(function (other) {
                    if (other !== aud && !other.paused) other.pause();
                });
                aud.play().catch(function () {});
            } else {
                aud.pause();
            }
        });
        vw.appendChild(playBtn);
        vw.appendChild(wave);
        vw.appendChild(durEl);
        vw.appendChild(aud);
        return vw;
    }

    function fillBubbleContent(bubble, m) {
        var parts = parseMessageParts(m);
        bubble.innerHTML = '';
        if (parts.quote) {
            var head = document.createElement('div');
            head.className = 'eq-chat-reply-in-head';
            var ic = document.createElement('i');
            ic.className = 'fas fa-reply eq-chat-reply-in-icon';
            ic.setAttribute('aria-hidden', 'true');
            var lab = document.createElement('span');
            lab.className = 'eq-chat-reply-in-label';
            lab.textContent = replyLabelInBubble(parts);
            head.appendChild(ic);
            head.appendChild(lab);
            var prev = document.createElement('div');
            prev.className = 'eq-chat-reply-in-preview';
            prev.textContent = parts.quote;
            bubble.appendChild(head);
            bubble.appendChild(prev);
        }
        if (m.audio_url) {
            bubble.appendChild(buildVoiceMessagePlayer(m.audio_url, !!m.mine, m.id));
        }
        if (m.image_url) {
            var iw = document.createElement('div');
            iw.className = 'eq-chat-img-wrap';
            var img = document.createElement('img');
            img.className = 'eq-chat-msg-img';
            img.src = m.image_url;
            img.alt = 'Photo envoyée';
            img.loading = 'lazy';
            img.decoding = 'async';
            img.addEventListener('click', function (e) {
                e.stopPropagation();
                window.open(m.image_url, '_blank', 'noopener,noreferrer');
            });
            iw.appendChild(img);
            bubble.appendChild(iw);
        }
        var showMainText = parts.main && parts.main.trim() && !isMediaPlaceholderBody(parts.main);
        if (showMainText) {
            var mainEl = document.createElement('div');
            mainEl.className = 'eq-chat-reply-in-main';
            mainEl.textContent = parts.main;
            bubble.appendChild(mainEl);
        } else if (!m.audio_url && !m.image_url) {
            var mainEmpty = document.createElement('div');
            mainEmpty.className = 'eq-chat-reply-in-main';
            mainEmpty.textContent = parts.main;
            bubble.appendChild(mainEmpty);
        }
        bubble.addEventListener('contextmenu', function (ev) {
            var hasMedia = !!(m.audio_url || m.image_url);
            var bodyForEdit = hasMedia ? '' : parts.main;
            openCtxMenu(ev, {
                id: m.id,
                body: bodyForEdit,
                copyText: copyTextForMessage(parts, m),
                replyFull: fullTextForReplyActionParts(parts, m),
                mine: !!m.mine,
                hasVoice: hasMedia
            });
        });
        if (m.audio_url && !parts.quote && !showMainText) {
            bubble.classList.add('eq-chat-bubble--voice-only');
        }
        if (m.image_url && !parts.quote && !showMainText) {
            bubble.classList.add('eq-chat-bubble--image-only');
        }
    }

    function hideCtxMenu() {
        if (ctxMenu) ctxMenu.hidden = true;
    }

    function placeCtxMenu(clientX, clientY) {
        if (!ctxMenu) return;
        ctxMenu.hidden = false;
        ctxMenu.style.left = '0px';
        ctxMenu.style.top = '0px';
        var w = ctxMenu.offsetWidth;
        var h = ctxMenu.offsetHeight;
        var x = clientX;
        var y = clientY;
        if (x + w > window.innerWidth - 8) x = Math.max(8, window.innerWidth - w - 8);
        if (y + h > window.innerHeight - 8) y = Math.max(8, window.innerHeight - h - 8);
        ctxMenu.style.left = x + 'px';
        ctxMenu.style.top = y + 'px';
    }

    function openCtxMenu(e, payload) {
        e.preventDefault();
        e.stopPropagation();
        ctxState.msgId = payload.id;
        ctxState.body = payload.body;
        ctxState.copyText = payload.copyText || payload.body;
        ctxState.replyFull = payload.replyFull || payload.body;
        ctxState.mine = payload.mine;
        ctxState.hasVoice = !!payload.hasVoice;
        if (!ctxMenu) return;
        var canEdit = payload.mine && !payload.hasVoice;
        ctxMenu.querySelectorAll('.eq-chat-ctx-mine').forEach(function (el) {
            var isEdit = el.getAttribute('data-act') === 'edit';
            var ok = isEdit ? canEdit : payload.mine;
            el.classList.toggle('is-disabled', !ok);
            el.disabled = !ok;
        });
        placeCtxMenu(e.clientX, e.clientY);
    }

    function csrf() {
        var m = document.querySelector('meta[name="csrf-token"]');
        return m ? m.getAttribute('content') : '';
    }

    function setRecordingUi(on) {
        if (!micBtn) return;
        micBtn.classList.toggle('eq-chat-tool--recording', on);
        micBtn.title = 'Enregistrer un message vocal';
    }

    function enterVoiceUi() {
        voiceUiActive = true;
        if (voiceInputRow) voiceInputRow.hidden = true;
        if (voiceBarEl) voiceBarEl.hidden = false;
        recAccumMs = 0;
        recSegStart = Date.now();
        voicePaused = false;
        if (voiceTimerEl) voiceTimerEl.textContent = '0:00';
        if (voicePauseBtn) {
            var icp = voicePauseBtn.querySelector('i');
            if (icp) icp.className = 'fas fa-stop';
            voicePauseBtn.setAttribute('title', 'Pause');
            voicePauseBtn.setAttribute('aria-label', 'Pause');
        }
        setRecordingUi(true);
    }

    function exitVoiceUi() {
        voiceUiActive = false;
        if (voiceTimerInterval) {
            clearInterval(voiceTimerInterval);
            voiceTimerInterval = null;
        }
        if (voiceInputRow) voiceInputRow.hidden = false;
        if (voiceBarEl) voiceBarEl.hidden = true;
        setRecordingUi(false);
    }

    function formatVoiceTime(totalSec) {
        var sec = Math.max(0, Math.floor(totalSec));
        var m = Math.floor(sec / 60);
        var s = sec % 60;
        return m + ':' + (s < 10 ? '0' : '') + s;
    }

    function formatSentRelativeFr(iso) {
        if (!iso) return '';
        var d = new Date(iso);
        if (isNaN(d.getTime())) return '';
        var diffSec = Math.max(0, Math.floor((Date.now() - d.getTime()) / 1000));
        if (diffSec < 45) return 'à l’instant';
        if (diffSec < 3600) {
            var min = Math.floor(diffSec / 60);
            return 'il y a ' + min + ' min';
        }
        if (diffSec < 86400) {
            var h = Math.floor(diffSec / 3600);
            return 'il y a ' + h + ' h';
        }
        if (diffSec < 172800) return 'hier';
        return d.toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' });
    }

    function getRecElapsedMs() {
        if (voicePaused) return recAccumMs;
        return recAccumMs + (Date.now() - recSegStart);
    }

    function tickVoiceTimer() {
        if (voiceTimerEl) voiceTimerEl.textContent = formatVoiceTime(getRecElapsedMs() / 1000);
    }

    function startVoiceTimer() {
        if (voiceTimerInterval) clearInterval(voiceTimerInterval);
        voiceTimerInterval = setInterval(tickVoiceTimer, 200);
    }

    function toggleVoicePause() {
        if (!mediaRecorder || !voicePauseBtn) return;
        var ic = voicePauseBtn.querySelector('i');
        if (mediaRecorder.state === 'recording') {
            mediaRecorder.pause();
            recAccumMs += Date.now() - recSegStart;
            voicePaused = true;
            if (ic) ic.className = 'fas fa-play';
            voicePauseBtn.setAttribute('title', 'Reprendre');
            voicePauseBtn.setAttribute('aria-label', 'Reprendre');
        } else if (mediaRecorder.state === 'paused') {
            mediaRecorder.resume();
            recSegStart = Date.now();
            voicePaused = false;
            if (ic) ic.className = 'fas fa-stop';
            voicePauseBtn.setAttribute('title', 'Pause');
            voicePauseBtn.setAttribute('aria-label', 'Pause');
        }
    }

    function stopRecorderAndFinish(uploadAfter) {
        if (!mediaRecorder) return;
        voiceCloseDiscard = !uploadAfter;
        if (typeof mediaRecorder.requestData === 'function') {
            try { mediaRecorder.requestData(); } catch (e) {}
        }
        try {
            if (mediaRecorder.state === 'recording' || mediaRecorder.state === 'paused') {
                mediaRecorder.stop();
            }
        } catch (e) {}
    }

    function stopMicStream() {
        if (mediaStream) {
            mediaStream.getTracks().forEach(function (t) { t.stop(); });
            mediaStream = null;
        }
    }

    function discardVoiceRecording() {
        if (!isRecording && !mediaRecorder) return;
        voiceCloseDiscard = true;
        if (mediaRecorder && (mediaRecorder.state === 'recording' || mediaRecorder.state === 'paused')) {
            try { mediaRecorder.stop(); } catch (e) {}
        } else {
            voiceCloseDiscard = false;
            isRecording = false;
            exitVoiceUi();
            stopMicStream();
            recordChunks = [];
            mediaRecorder = null;
        }
    }

    function uploadVoiceBlob(blob) {
        if (!voiceUploadUrl || !state.id) return;
        state.loading = true;
        var fd = new FormData();
        fd.append('recipient_type', state.type);
        fd.append('recipient_id', state.id);
        fd.append('intervenant_collection', state.collection || '');
        fd.append('audio', blob, 'voice.webm');
        fd.append('_token', csrf());
        fetch(voiceUploadUrl, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrf() } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                state.loading = false;
                if (data && data.success) loadMessages();
                else alert((data && data.message) ? data.message : 'Envoi vocal impossible.');
            })
            .catch(function () { state.loading = false; alert('Erreur réseau.'); });
    }

    function uploadPendingImagesBatch(caption) {
        if (!imageUploadUrl || !state.id || !pendingImages.length) return;
        var queue = pendingImages.map(function (x) { return x.file; });
        var cap0 = (caption || '').trim();
        var hadReply = !!(replyDraft && replyDraft.full);
        var rq = '';
        var rts = false;
        if (hadReply) {
            rq = replyDraft.full.length > 500 ? replyDraft.full.slice(0, 500) : replyDraft.full;
            rts = !!replyDraft.replyToSelf;
        }
        state.loading = true;
        if (sendBtn) sendBtn.disabled = true;

        function doOne(ix) {
            if (ix >= queue.length) {
                clearPendingAttachment();
                inputEl.value = '';
                clearReplyDraft();
                loadMessages();
                state.loading = false;
                if (sendBtn) sendBtn.disabled = false;
                return;
            }
            var fd = new FormData();
            fd.append('recipient_type', state.type);
            fd.append('recipient_id', state.id);
            fd.append('intervenant_collection', state.collection || '');
            fd.append('image', queue[ix]);
            if (ix === 0 && cap0) fd.append('message', cap0);
            if (hadReply && ix === 0 && rq) {
                fd.append('reply_quote', rq);
                fd.append('reply_to_self', rts ? '1' : '0');
            }
            fd.append('_token', csrf());
            fetch(imageUploadUrl, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrf() } })
                .then(function (r) { return r.json(); })
                .then(function (data) {
                    if (data && data.success) {
                        doOne(ix + 1);
                    } else {
                        alert((data && data.message) ? data.message : 'Envoi de la photo impossible.');
                        state.loading = false;
                        if (sendBtn) sendBtn.disabled = false;
                    }
                })
                .catch(function () {
                    alert('Erreur réseau.');
                    state.loading = false;
                    if (sendBtn) sendBtn.disabled = false;
                });
        }
        doOne(0);
    }

    function openChatImagePicker() {
        if (!imageUploadUrl || !state.id || state.loading) return;
        if (isRecording) {
            alert('Terminez ou annulez l’enregistrement vocal avant d’ajouter une photo.');
            return;
        }
        if (imageInput) imageInput.click();
    }

    function toggleVoiceRecord() {
        if (!voiceUploadUrl || !state.id || state.loading) return;
        if (isRecording) return;
        if (typeof MediaRecorder === 'undefined') {
            alert('Enregistrement vocal non supporté par ce navigateur.');
            return;
        }
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
            alert('Microphone non disponible (HTTPS requis sur certains navigateurs).');
            return;
        }
        navigator.mediaDevices.getUserMedia({ audio: true }).then(function (stream) {
            mediaStream = stream;
            recordChunks = [];
            var opts = { mimeType: 'audio/webm;codecs=opus' };
            if (!MediaRecorder.isTypeSupported(opts.mimeType)) {
                opts.mimeType = 'audio/webm';
                if (!MediaRecorder.isTypeSupported(opts.mimeType)) {
                    opts = {};
                }
            }
            try {
                mediaRecorder = opts.mimeType ? new MediaRecorder(stream, { mimeType: opts.mimeType }) : new MediaRecorder(stream);
            } catch (err) {
                stopMicStream();
                alert('Impossible de démarrer l’enregistrement.');
                return;
            }
            mediaRecorder.ondataavailable = function (e) {
                if (e.data && e.data.size > 0) recordChunks.push(e.data);
            };
            mediaRecorder.onstop = function () {
                isRecording = false;
                exitVoiceUi();
                stopMicStream();
                var mr = mediaRecorder;
                var mime = (mr && mr.mimeType) ? mr.mimeType : 'audio/webm';
                var blob = new Blob(recordChunks, { type: mime });
                recordChunks = [];
                mediaRecorder = null;
                if (voiceCloseDiscard) {
                    voiceCloseDiscard = false;
                    return;
                }
                if (blob.size < 400) {
                    alert('Enregistrement trop court.');
                    return;
                }
                uploadVoiceBlob(blob);
            };
            enterVoiceUi();
            startVoiceTimer();
            mediaRecorder.start();
            isRecording = true;
        }).catch(function () {
            alert('Accès au microphone refusé ou impossible.');
        });
    }

    function initials(s) {
        var t = (s || '').trim();
        if (!t) return 'EQ';
        var p = t.split(/\s+/).filter(Boolean);
        if (p.length >= 2) return (p[0][0] + p[1][0]).toUpperCase();
        return t.slice(0, 2).toUpperCase();
    }

    function openChat(btn) {
        if (btn.disabled) return;
        discardVoiceRecording();
        state.type = btn.getAttribute('data-type') || '';
        state.id = btn.getAttribute('data-id') || '';
        state.collection = btn.getAttribute('data-collection') || '';
        state.label = btn.getAttribute('data-label') || 'Équipe';
        titleEl.textContent = state.label;
        avatarEl.textContent = initials(state.label);
        if (subLine1 && subLine2) {
            if (state.type === 'intervenant') {
                subLine1.textContent = 'Discussion avec l’intervenant';
                subLine2.textContent = 'Messages enregistrés';
            } else {
                subLine1.textContent = 'Discussion avec l’équipe';
                subLine2.textContent = 'Messages enregistrés';
            }
        }
        widget.hidden = false;
        widget.setAttribute('aria-hidden', 'false');
        widget.classList.remove('eq-chat-widget--min');
        clearReplyDraft();
        clearPendingAttachment();
        loadMessages();
        setTimeout(function () { inputEl.focus(); }, 80);
    }

    function closeChat() {
        discardVoiceRecording();
        clearPendingAttachment();
        widget.hidden = true;
        widget.setAttribute('aria-hidden', 'true');
        widget.classList.remove('eq-chat-widget--min');
        bodyEl.innerHTML = '';
        inputEl.value = '';
        clearReplyDraft();
    }

    function isChatThreadOpen() {
        return !!widget && !widget.hidden && !!state.id;
    }

    function renderMessages(list) {
        bodyEl.innerHTML = '';
        if (!list || !list.length) {
            bodyEl.innerHTML = '<div class="eq-chat-empty">Aucun message pour le moment. Écrivez le premier.</div>';
            return;
        }
        list.forEach(function (m) {
            var wrap = document.createElement('div');
            wrap.className = 'eq-chat-bubble-wrap ' + (m.mine ? 'eq-chat-bubble-wrap--mine' : 'eq-chat-bubble-wrap--other');
            var bubble = document.createElement('div');
            bubble.className = 'eq-chat-bubble ' + (m.mine ? 'eq-chat-bubble--mine' : 'eq-chat-bubble--other');
            fillBubbleContent(bubble, m);
            var meta = document.createElement('div');
            meta.className = 'eq-chat-meta';
            var partsMeta = parseMessageParts(m);
            var voiceOnlyMeta = m.mine && (m.audio_url || m.image_url) && !(partsMeta.main && partsMeta.main.trim() && !isMediaPlaceholderBody(partsMeta.main));
            if (voiceOnlyMeta) {
                meta.classList.add('eq-chat-meta--sent', 'eq-chat-meta--with-receipt');
                var rel = formatSentRelativeFr(m.created_at);
                var receipt = document.createElement('span');
                receipt.className = 'eq-chat-meta-receipt';
                receipt.setAttribute('aria-hidden', 'true');
                receipt.title = (state.label ? 'Destinataire : ' + state.label : 'Destinataire');
                receipt.textContent = initials(state.label || '—');
                var sentTxt = document.createElement('span');
                sentTxt.className = 'eq-chat-meta-sent-text';
                sentTxt.textContent = 'Envoyé' + (rel ? ' ' + rel : '');
                meta.appendChild(receipt);
                meta.appendChild(sentTxt);
            } else {
                meta.textContent = (m.mine ? 'Vous' : (m.author_label || '—')) + (m.created_at ? ' · ' + new Date(m.created_at).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }) : '');
            }
            wrap.appendChild(bubble);
            wrap.appendChild(meta);
            bodyEl.appendChild(wrap);
        });
        bodyEl.scrollTop = bodyEl.scrollHeight;
    }

    function chatRecipientKeyFromButton(btn) {
        if (!btn) return '';
        var type = btn.getAttribute('data-type') || '';
        var id = btn.getAttribute('data-id') || '';
        if (!id) return '';
        if (type === 'module') return 'm:' + id;
        if (type === 'intervenant') {
            var col = btn.getAttribute('data-collection') || 'intervenants';
            return 'i:' + col + ':' + id;
        }
        return '';
    }

    function refreshChatIntervenantBadges() {
        if (!chatIntervenantCountsUrl) return;
        fetch(chatIntervenantCountsUrl, { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data || !data.success || !data.counts) return;
                document.querySelectorAll('.eq-chat-open[data-type="intervenant"], .eq-chat-open[data-type="module"]').forEach(function (btn) {
                    var rk = chatRecipientKeyFromButton(btn);
                    var n = rk && data.counts[rk] != null ? parseInt(data.counts[rk], 10) : 0;
                    if (isNaN(n) || n <= 0) {
                        var old = btn.querySelector('.eq-chat-ci-badge');
                        if (old) old.remove();
                        return;
                    }
                    var badge = btn.querySelector('.eq-chat-ci-badge');
                    if (!badge) {
                        badge = document.createElement('span');
                        badge.className = 'eq-chat-ci-badge';
                        badge.setAttribute('aria-label', 'Nouveaux messages (chat intervenants)');
                        btn.appendChild(badge);
                    }
                    badge.textContent = n > 99 ? '99+' : String(n);
                });
            })
            .catch(function () {});
    }

    function loadMessages() {
        if (!messagesUrl || !state.id) return;
        var q = new URLSearchParams({
            recipient_type: state.type,
            recipient_id: state.id,
            intervenant_collection: state.collection || ''
        });
        state.loading = true;
        fetch(messagesUrl + '?' + q.toString(), { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                state.loading = false;
                if (data && data.success) {
                    renderMessages(data.messages || []);
                } else {
                    var msg = (data && data.message) ? String(data.message) : '';
                    if (msg) {
                        bodyEl.innerHTML = '';
                        var errDiv = document.createElement('div');
                        errDiv.className = 'eq-chat-empty';
                        errDiv.textContent = msg;
                        bodyEl.appendChild(errDiv);
                    } else {
                        renderMessages([]);
                    }
                }
                refreshChatIntervenantBadges();
            })
            .catch(function () { state.loading = false; bodyEl.innerHTML = '<div class="eq-chat-empty">Erreur de chargement.</div>'; });
    }

    function sendMessage() {
        if (!state.id || state.loading) return;
        if (pendingImages.length > 0) {
            if (!imageUploadUrl) return;
            var cap = (inputEl.value || '').trim();
            uploadPendingImagesBatch(cap);
            return;
        }
        if (!sendUrl) return;
        var text = (inputEl.value || '').trim();
        if (!text) return;
        sendBtn.disabled = true;
        var fd = new FormData();
        fd.append('recipient_type', state.type);
        fd.append('recipient_id', state.id);
        fd.append('intervenant_collection', state.collection || '');
        fd.append('message', text);
        if (replyDraft && replyDraft.full) {
            var rq = replyDraft.full.length > 500 ? replyDraft.full.slice(0, 500) : replyDraft.full;
            fd.append('reply_quote', rq);
            fd.append('reply_to_self', replyDraft.replyToSelf ? '1' : '0');
        }
        fd.append('_token', csrf());
        fetch(sendUrl, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrf() } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                sendBtn.disabled = false;
                if (data && data.success) {
                    inputEl.value = '';
                    clearReplyDraft();
                    loadMessages();
                } else {
                    alert((data && data.message) ? data.message : 'Envoi impossible.');
                }
            })
            .catch(function () { sendBtn.disabled = false; alert('Erreur réseau.'); });
    }

    function recipientQueryString() {
        return new URLSearchParams({
            recipient_type: state.type,
            recipient_id: state.id,
            intervenant_collection: state.collection || ''
        }).toString();
    }

    if (ctxMenu) {
        ctxMenu.addEventListener('contextmenu', function (e) { e.preventDefault(); });
        ctxMenu.addEventListener('click', function (e) {
            var btn = e.target.closest('[data-act]');
            if (!btn || btn.disabled || btn.classList.contains('is-disabled')) return;
            e.stopPropagation();
            var act = btn.getAttribute('data-act');
            var id = ctxState.msgId;
            var body = ctxState.body;
            var toCopy = ctxState.copyText || body;
            hideCtxMenu();
            if (act === 'copy') {
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(toCopy).catch(function () {
                        window.prompt('Copier (Ctrl+C puis Entrée) :', toCopy);
                    });
                } else {
                    window.prompt('Copier (Ctrl+C puis Entrée) :', toCopy);
                }
                return;
            }
            if (act === 'reply') {
                beginReplyToMessage(ctxState.replyFull || body, ctxState.mine);
                return;
            }
            if (!chatMessagesBaseUrl || !id) return;
            if (act === 'edit') {
                var next = window.prompt('Modifier le message :', body);
                if (next === null) return;
                next = next.trim();
                if (!next || next === body) return;
                fetch(chatMessagesBaseUrl + '/' + encodeURIComponent(id), {
                    method: 'PUT',
                    credentials: 'same-origin',
                    headers: {
                        'Accept': 'application/json',
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': csrf()
                    },
                    body: JSON.stringify({
                        recipient_type: state.type,
                        recipient_id: state.id,
                        intervenant_collection: state.collection || '',
                        message: next
                    })
                }).then(function (r) { return r.json(); }).then(function (data) {
                    if (data && data.success) loadMessages();
                    else alert((data && data.message) ? data.message : 'Modification impossible.');
                }).catch(function () { alert('Erreur réseau.'); });
                return;
            }
            if (act === 'delete') {
                if (!window.confirm('Supprimer ce message ?')) return;
                fetch(chatMessagesBaseUrl + '/' + encodeURIComponent(id) + '?' + recipientQueryString(), {
                    method: 'DELETE',
                    credentials: 'same-origin',
                    headers: {
                        'Accept': 'application/json',
                        'X-CSRF-TOKEN': csrf()
                    }
                }).then(function (r) { return r.json(); }).then(function (data) {
                    if (data && data.success) loadMessages();
                    else alert((data && data.message) ? data.message : 'Suppression impossible.');
                }).catch(function () { alert('Erreur réseau.'); });
            }
        });
    }

    document.addEventListener('click', hideCtxMenu);
    document.addEventListener('contextmenu', function (e) {
        if (ctxMenu && !ctxMenu.hidden && !ctxMenu.contains(e.target)) hideCtxMenu();
    }, true);
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') hideCtxMenu();
    });
    if (bodyEl) bodyEl.addEventListener('scroll', hideCtxMenu);

    if (replyCancel) replyCancel.addEventListener('click', clearReplyDraft);

    if (micBtn) micBtn.addEventListener('click', function () { toggleVoiceRecord(); });
    if (sidePlusBtn) sidePlusBtn.addEventListener('click', function () { openChatImagePicker(); });
    if (attachAddBtn) attachAddBtn.addEventListener('click', function () { openChatImagePicker(); });
    if (attachPreview) attachPreview.addEventListener('click', function (e) {
        var btn = e.target.closest('.eq-chat-attach-remove');
        if (!btn) return;
        e.preventDefault();
        e.stopPropagation();
        var idx = parseInt(btn.getAttribute('data-idx'), 10);
        if (isNaN(idx) || idx < 0 || idx >= pendingImages.length) return;
        try { URL.revokeObjectURL(pendingImages[idx].objectUrl); } catch (err) {}
        pendingImages.splice(idx, 1);
        renderAttachPreview();
    });
    if (imageInput) imageInput.addEventListener('change', function () {
        var files = imageInput.files;
        imageInput.value = '';
        if (!files || !files.length) return;
        addPendingImageFilesFromList(files);
    });
    if (voiceTrash) voiceTrash.addEventListener('click', function () { discardVoiceRecording(); });
    if (voicePauseBtn) voicePauseBtn.addEventListener('click', function () { toggleVoicePause(); });
    if (voiceSendGreen) voiceSendGreen.addEventListener('click', function () { stopRecorderAndFinish(true); });

    document.querySelectorAll('.eq-chat-open').forEach(function (b) {
        b.addEventListener('click', function () { openChat(b); });
    });
    refreshChatIntervenantBadges();
    setInterval(refreshChatIntervenantBadges, CHAT_BADGES_REFRESH_MS);
    setInterval(function () {
        if (!isChatThreadOpen()) return;
        if (state.loading) return;
        loadMessages();
    }, CHAT_OPEN_THREAD_REFRESH_MS);
    btnClose.addEventListener('click', closeChat);
    btnMin.addEventListener('click', function () { widget.classList.toggle('eq-chat-widget--min'); });
    sendBtn.addEventListener('click', sendMessage);
    inputEl.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });
})();
</script>
