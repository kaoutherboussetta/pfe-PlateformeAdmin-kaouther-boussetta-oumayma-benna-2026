@php
    $chatBellUid = isset($chatBellUid) ? preg_replace('/[^a-z0-9_-]/i', '', (string) $chatBellUid) : 'nav';
    if ($chatBellUid === '') {
        $chatBellUid = 'nav';
    }
    $chatIntervenantNotifyUrl = $chatIntervenantNotifyUrl
        ?? (\Illuminate\Support\Facades\Route::has('api.chat_intervenant.notifications')
            ? route('api.chat_intervenant.notifications')
            : null);
@endphp

@once('chat-intervenant-bell-styles')
<style>
    .tb-chat-bell-wrap { position: relative; flex-shrink: 0; }
    .tb-chat-bell { border: none; cursor: pointer; font: inherit; padding: 0; }
    .tb-chat-bell .dot[hidden] { display: none !important; }
    .tb-chat-bell-count {
        position: absolute;
        top: 1px;
        right: 1px;
        min-width: 15px;
        height: 15px;
        padding: 0 3px;
        border-radius: 999px;
        background: var(--orange);
        color: #fff;
        font-size: 9px;
        font-weight: 800;
        line-height: 15px;
        text-align: center;
        border: 1.5px solid var(--bg2);
        box-sizing: border-box;
    }
    .tb-chat-bell-count[hidden] { display: none !important; }
    .tb-chat-bell-panel {
        position: absolute;
        right: 0;
        top: calc(100% + 8px);
        width: min(320px, calc(100vw - 28px));
        max-height: min(380px, 72vh);
        background: #fff;
        border: 1px solid var(--border);
        border-radius: 12px;
        box-shadow: 0 18px 40px rgba(0,0,0,0.12);
        z-index: 210;
        display: flex;
        flex-direction: column;
        overflow: hidden;
    }
    .tb-chat-bell-panel[hidden] { display: none !important; }
    .tb-chat-bell-head {
        padding: 9px 12px;
        font-size: 11px;
        font-weight: 700;
        color: var(--text3);
        text-transform: uppercase;
        letter-spacing: 0.06em;
        border-bottom: 1px solid var(--border);
        background: rgba(0,0,0,0.02);
    }
    .tb-chat-bell-list { overflow-y: auto; flex: 1; min-height: 0; }
    .tb-chat-bell-item {
        display: block;
        padding: 9px 12px;
        border-bottom: 1px solid var(--border);
        text-decoration: none;
        color: inherit;
    }
    .tb-chat-bell-item:hover { background: var(--surface); }
    .tb-chat-bell-item--new { background: rgba(255, 107, 53, 0.06); }
    .tb-chat-bell-sender { font-size: 12px; font-weight: 700; color: var(--text); }
    .tb-chat-bell-meta { font-size: 10px; color: var(--text3); margin: 2px 0 4px; }
    .tb-chat-bell-preview { font-size: 12px; color: var(--text2); line-height: 1.35; }
    .tb-chat-bell-empty { padding: 16px 12px; font-size: 12px; color: var(--text3); text-align: center; }
    .tb-chat-bell-foot {
        display: block;
        padding: 9px 12px;
        font-size: 12px;
        font-weight: 600;
        color: var(--orange);
        text-align: center;
        border-top: 1px solid var(--border);
        text-decoration: none;
        background: rgba(255, 107, 53, 0.04);
    }
    .tb-chat-bell-foot:hover { background: rgba(255, 107, 53, 0.1); }
    @keyframes tbChatBellBlink { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
    .tb-icon.tb-chat-bell .dot {
        position: absolute; top: 6px; right: 6px;
        width: 6px; height: 6px; border-radius: 50%;
        background: var(--orange); border: 1.5px solid var(--bg2);
        animation: tbChatBellBlink 2s infinite;
    }
</style>
@endonce

@if($chatIntervenantNotifyUrl)
<div class="tb-chat-bell-wrap" data-chat-bell-uid="{{ $chatBellUid }}">
    <button type="button" class="tb-icon tb-chat-bell" id="chat-bell-{{ $chatBellUid }}-btn" data-url="{{ $chatIntervenantNotifyUrl }}" title="Messages des intervenants vers l’administration" aria-expanded="false" aria-haspopup="true">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <span class="dot" id="chat-bell-{{ $chatBellUid }}-dot" hidden></span>
        <span class="tb-chat-bell-count" id="chat-bell-{{ $chatBellUid }}-count" hidden>0</span>
    </button>
    <div class="tb-chat-bell-panel" id="chat-bell-{{ $chatBellUid }}-panel" hidden role="region" aria-label="Messages des intervenants">
        <div class="tb-chat-bell-head">Messages → administration</div>
        <div class="tb-chat-bell-list" id="chat-bell-{{ $chatBellUid }}-list"></div>
        <a href="{{ url('/interface_admin_tech/equipes') }}" class="tb-chat-bell-foot">Ouvrir équipes →</a>
    </div>
</div>
@else
<div class="tb-icon" title="Notifications" aria-hidden="true">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
        <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
        <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
    </svg>
    <span class="dot"></span>
</div>
@endif

@once('chat-intervenant-bell-doc')
<script>
(function () {
    var BELL_REFRESH_MS = 12000;
    function closeAnyChatBellPanel(uid) {
        var p = document.getElementById('chat-bell-' + uid + '-panel');
        var b = document.getElementById('chat-bell-' + uid + '-btn');
        if (p) p.hidden = true;
        if (b) b.setAttribute('aria-expanded', 'false');
    }
    function closeAllChatBellPanels() {
        document.querySelectorAll('.tb-chat-bell-wrap[data-chat-bell-uid]').forEach(function (w) {
            var uid = w.getAttribute('data-chat-bell-uid');
            if (uid) closeAnyChatBellPanel(uid);
        });
    }
    document.addEventListener('click', function (event) {
        document.querySelectorAll('.tb-chat-bell-wrap').forEach(function (w) {
            if (w.contains(event.target)) return;
            var uid = w.getAttribute('data-chat-bell-uid');
            if (uid) closeAnyChatBellPanel(uid);
        });
    });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape') closeAllChatBellPanels();
    });
})();
</script>
@endonce

@if($chatIntervenantNotifyUrl)
<script>
(function () {
    var uid = @json($chatBellUid);
    var btn = document.getElementById('chat-bell-' + uid + '-btn');
    var list = document.getElementById('chat-bell-' + uid + '-list');
    var dot = document.getElementById('chat-bell-' + uid + '-dot');
    var cnt = document.getElementById('chat-bell-' + uid + '-count');
    if (!btn || !list || !dot || !cnt) return;
    var url = btn.getAttribute('data-url');
    if (!url) return;

    function closeProfileMenus() {
        if (typeof closeTechProfileMenu === 'function') closeTechProfileMenu();
        if (typeof closeProfileMenu === 'function') closeProfileMenu();
    }
    function togglePanel(ev) {
        if (ev) ev.stopPropagation();
        closeProfileMenus();
        var p = document.getElementById('chat-bell-' + uid + '-panel');
        if (!p) return;
        var open = p.hidden;
        p.hidden = !open;
        btn.setAttribute('aria-expanded', open ? 'true' : 'false');
        if (open && typeof window.refreshTechChatBell === 'function') window.refreshTechChatBell();
    }

    function esc(s) {
        var d = document.createElement('div');
        d.textContent = s;
        return d.innerHTML;
    }
    function fmt(iso) {
        if (!iso) return '';
        try {
            var t = new Date(iso);
            if (isNaN(t.getTime())) return '';
            return t.toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' });
        } catch (e) { return ''; }
    }

    function doRefresh() {
        fetch(url + '?limit=12', { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (d) {
                if (!d || !d.success) {
                    dot.hidden = true;
                    cnt.hidden = true;
                    return;
                }
                var alertN = parseInt(d.alert, 10) || 0;
                if (alertN > 0) {
                    cnt.hidden = false;
                    cnt.textContent = alertN > 99 ? '99+' : String(alertN);
                    dot.hidden = true;
                } else {
                    cnt.hidden = true;
                    dot.hidden = true;
                }
                var items = d.items || [];
                var equipesUrl = @json(url('/interface_admin_tech/equipes'));
                if (!items.length) {
                    list.innerHTML = '<div class="tb-chat-bell-empty">Aucun message dans la collection pour l’instant.</div>';
                    return;
                }
                list.innerHTML = items.map(function (it) {
                    var cls = 'tb-chat-bell-item' + (it.unread ? ' tb-chat-bell-item--new' : '');
                    var m = fmt(it.created_at);
                    return '<a class="' + cls + '" href="' + equipesUrl + '">' +
                        '<div class="tb-chat-bell-sender">' + esc(it.sender || 'Intervenant') + '</div>' +
                        (m ? '<div class="tb-chat-bell-meta">' + esc(m) + '</div>' : '') +
                        '<div class="tb-chat-bell-preview">' + esc(it.preview || '') + '</div></a>';
                }).join('');
            })
            .catch(function () { dot.hidden = true; cnt.hidden = true; });
    }

    window.__chatBellRefreshers = window.__chatBellRefreshers || {};
    window.__chatBellRefreshers[uid] = doRefresh;
    window.refreshTechChatBell = function () {
        Object.keys(window.__chatBellRefreshers || {}).forEach(function (k) {
            if (typeof window.__chatBellRefreshers[k] === 'function') window.__chatBellRefreshers[k]();
        });
    };

    btn.addEventListener('click', togglePanel);
    doRefresh();
    setInterval(doRefresh, BELL_REFRESH_MS);
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'visible') doRefresh();
    });
    window.addEventListener('focus', doRefresh);
})();
</script>
@endif
