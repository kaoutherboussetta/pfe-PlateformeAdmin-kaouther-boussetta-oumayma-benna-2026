<!DOCTYPE html>
<html lang="fr" class="trig-app trig-outfit">
<head>
    @include('partials.theme-init')
    <meta charset="UTF-8">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @include('partials.favicon')
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trig-Essalama · Équipes d'intervention</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Outfit:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @include('partials.admin_technique_styles')
        table th.eq-chat-col { letter-spacing: 0.12em; font-size: 10px; font-weight: 700; color: var(--text3); }
        .eq-chat-open {
            position: relative;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            padding: 8px 12px;
            border-radius: 9px;
            border: 1px solid rgba(255, 107, 53, 0.28);
            background: rgba(255, 107, 53, 0.1);
            color: var(--orange);
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
            transition: background 0.2s, border-color 0.2s, transform 0.15s;
        }
        .eq-chat-open:hover:not(:disabled) {
            background: rgba(255, 107, 53, 0.16);
            border-color: var(--border-accent);
            color: var(--orange-dark);
        }
        .eq-chat-open:disabled { opacity: 0.45; cursor: not-allowed; }
        .eq-chat-open--compact {
            padding: 7px 11px;
            font-size: 11px;
            min-width: 40px;
        }
        .eq-chat-ci-badge {
            position: absolute;
            top: -5px;
            right: -6px;
            min-width: 16px;
            height: 16px;
            padding: 0 4px;
            border-radius: 999px;
            background: var(--orange);
            color: #fff;
            font-size: 9px;
            font-weight: 800;
            line-height: 16px;
            text-align: center;
            border: 2px solid var(--bg2, #fff);
            box-sizing: border-box;
            pointer-events: none;
        }
        .eq-chat-widget {
            position: fixed;
            right: 24px;
            bottom: 24px;
            width: min(380px, calc(100vw - 32px));
            max-height: min(540px, calc(100vh - 48px));
            z-index: 9999;
            display: flex;
            flex-direction: column;
            border-radius: 14px;
            overflow: hidden;
            font-family: 'Outfit', system-ui, sans-serif;
            background: var(--bg2);
            color: var(--text);
            border: 1px solid var(--border);
            box-shadow: 0 16px 48px rgba(0, 0, 0, 0.12), 0 0 0 1px rgba(255, 107, 53, 0.06);
        }
        .eq-chat-widget[hidden] { display: none !important; }
        .eq-chat-widget--min .eq-chat-body,
        .eq-chat-widget--min .eq-chat-footer { display: none; }
        .eq-chat-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            padding: 12px 14px;
            background: linear-gradient(135deg, var(--orange) 0%, #C84B1F 100%);
            color: #fff;
            border-bottom: 1px solid rgba(0, 0, 0, 0.08);
            box-shadow: 0 0 20px var(--orange-glow);
        }
        .eq-chat-head-left { display: flex; align-items: center; gap: 10px; min-width: 0; }
        .eq-chat-avatar {
            width: 40px; height: 40px; border-radius: 11px;
            flex-shrink: 0;
            background: linear-gradient(135deg, rgba(255,255,255,0.28), rgba(255,255,255,0.08));
            border: 1px solid rgba(255,255,255,0.35);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 13px;
            color: #fff;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        }
        .eq-chat-title-row { display: flex; align-items: center; gap: 6px; min-width: 0; }
        .eq-chat-title { font-weight: 700; font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; letter-spacing: -0.02em; }
        .eq-chat-chevron { font-size: 10px; opacity: 0.85; flex-shrink: 0; }
        .eq-chat-sub {
            display: flex;
            flex-direction: column;
            gap: 2px;
            margin-top: 2px;
            max-width: 230px;
        }
        .eq-chat-sub-line1 {
            font-size: 11px;
            font-weight: 600;
            line-height: 1.25;
            color: rgba(255, 255, 255, 0.95);
        }
        .eq-chat-sub-line2 {
            font-size: 10px;
            font-weight: 500;
            line-height: 1.25;
            color: rgba(255, 255, 255, 0.78);
        }
        .eq-chat-head-actions { display: flex; gap: 4px; flex-shrink: 0; align-items: center; }
        .eq-chat-head-actions button {
            width: 34px; height: 34px; border-radius: 9px; border: 1px solid rgba(255,255,255,0.22);
            background: rgba(255,255,255,0.12); color: #fff; cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            font-size: 14px;
            transition: background 0.2s, border-color 0.2s;
        }
        .eq-chat-head-actions button:hover {
            background: rgba(255,255,255,0.22);
            border-color: rgba(255,255,255,0.4);
        }
        .eq-chat-body {
            flex: 1;
            min-height: 220px;
            max-height: 360px;
            overflow-y: auto;
            padding: 14px 12px;
            background: var(--bg3);
            display: flex;
            flex-direction: column;
            gap: 12px;
        }
        .eq-chat-body::-webkit-scrollbar { width: 5px; }
        .eq-chat-body::-webkit-scrollbar-thumb { background: rgba(0,0,0,0.12); border-radius: 3px; }
        .eq-chat-bubble-wrap { display: flex; flex-direction: column; max-width: 88%; }
        .eq-chat-bubble-wrap--mine { align-self: flex-end; align-items: flex-end; }
        .eq-chat-bubble-wrap--other { align-self: flex-start; align-items: flex-start; }
        .eq-chat-bubble {
            padding: 10px 14px;
            border-radius: 14px;
            font-size: 14px;
            line-height: 1.45;
            word-break: break-word;
            cursor: context-menu;
            user-select: text;
        }
        .eq-chat-ctx {
            position: fixed;
            z-index: 100020;
            min-width: 188px;
            padding: 6px;
            background: var(--bg2);
            border: 1px solid var(--border);
            border-radius: 10px;
            box-shadow: 0 14px 44px rgba(0, 0, 0, 0.14), 0 0 0 1px rgba(255, 107, 53, 0.06);
            font-family: 'Outfit', sans-serif;
        }
        .eq-chat-ctx[hidden] { display: none !important; }
        .eq-chat-ctx-item {
            display: flex;
            align-items: center;
            gap: 10px;
            width: 100%;
            padding: 9px 12px;
            border: none;
            border-radius: 8px;
            background: transparent;
            color: var(--text);
            font-size: 13px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            text-align: left;
            transition: background 0.15s, color 0.15s;
        }
        .eq-chat-ctx-item i { width: 16px; text-align: center; color: var(--orange); font-size: 13px; }
        .eq-chat-ctx-item:hover { background: rgba(255, 107, 53, 0.1); color: var(--orange-dark); }
        .eq-chat-ctx-item.danger:hover { background: rgba(220, 38, 38, 0.08); color: #b91c1c; }
        .eq-chat-ctx-item.danger:hover i { color: #b91c1c; }
        .eq-chat-ctx-item[disabled], .eq-chat-ctx-item.is-disabled {
            opacity: 0.45;
            cursor: not-allowed;
            pointer-events: none;
        }
        .eq-chat-ctx-sep { height: 1px; margin: 4px 8px; background: var(--border); }
        .eq-chat-bubble--mine {
            background: linear-gradient(135deg, var(--orange), #C84B1F);
            color: #fff;
            border-bottom-right-radius: 5px;
            box-shadow: 0 2px 10px rgba(255, 107, 53, 0.22);
        }
        .eq-chat-bubble--other {
            background: var(--surface);
            color: var(--text);
            border: 1px solid var(--border);
            border-bottom-left-radius: 5px;
        }
        .eq-chat-reply-in-head {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-bottom: 6px;
        }
        .eq-chat-bubble--mine .eq-chat-reply-in-head {
            opacity: 0.95;
        }
        .eq-chat-reply-in-icon {
            font-size: 11px;
            transform: scaleX(-1);
            opacity: 0.85;
        }
        .eq-chat-bubble--mine .eq-chat-reply-in-icon { color: rgba(255, 255, 255, 0.8); }
        .eq-chat-bubble--other .eq-chat-reply-in-icon { color: var(--text3); }
        .eq-chat-reply-in-label {
            font-size: 11px;
            font-weight: 600;
        }
        .eq-chat-bubble--mine .eq-chat-reply-in-label { color: rgba(255, 255, 255, 0.82); }
        .eq-chat-bubble--other .eq-chat-reply-in-label { color: var(--text3); }
        .eq-chat-reply-in-preview {
            padding: 6px 10px 7px;
            border-radius: 10px;
            font-size: 13px;
            line-height: 1.35;
            margin-bottom: 8px;
            display: -webkit-box;
            -webkit-line-clamp: 4;
            -webkit-box-orient: vertical;
            overflow: hidden;
            word-break: break-word;
        }
        .eq-chat-bubble--mine .eq-chat-reply-in-preview {
            background: rgba(255, 255, 255, 0.22);
            border-left: 3px solid rgba(255, 255, 255, 0.55);
            color: rgba(255, 255, 255, 0.96);
        }
        .eq-chat-bubble--other .eq-chat-reply-in-preview {
            background: var(--bg2);
            border-left: 3px solid var(--orange);
            color: var(--text2);
        }
        .eq-chat-reply-in-main {
            font-size: 14px;
            line-height: 1.45;
            word-break: break-word;
        }
        .eq-chat-meta { font-size: 11px; color: var(--text3); margin-top: 4px; padding: 0 4px; }
        .eq-chat-footer {
            display: flex;
            flex-direction: column;
            align-items: stretch;
            gap: 0;
            padding: 0;
            background: var(--bg2);
            border-top: 1px solid var(--border);
        }
        .eq-chat-foot-panel {
            padding: 10px 12px 12px;
            display: flex;
            flex-direction: column;
            gap: 0;
        }
        .eq-chat-reply-bar {
            padding: 0 2px 10px;
        }
        .eq-chat-reply-bar[hidden] { display: none !important; }
        .eq-chat-reply-bar-inner {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 10px;
            border-radius: 10px;
            border: 1px solid rgba(255, 107, 53, 0.35);
            background: var(--bg3);
        }
        .eq-chat-reply-accent {
            width: 3px;
            align-self: stretch;
            min-height: 32px;
            border-radius: 2px;
            background: linear-gradient(180deg, var(--orange), #C84B1F);
            flex-shrink: 0;
        }
        .eq-chat-reply-text {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
            gap: 2px;
        }
        .eq-chat-reply-label {
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            color: var(--orange);
        }
        .eq-chat-reply-snippet {
            font-size: 12px;
            color: var(--text2);
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .eq-chat-reply-cancel {
            width: 32px;
            height: 32px;
            border: none;
            border-radius: 8px;
            background: rgba(0, 0, 0, 0.06);
            color: var(--text2);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            transition: background 0.2s, color 0.2s;
        }
        .eq-chat-reply-cancel:hover {
            background: rgba(255, 107, 53, 0.12);
            color: var(--orange-dark);
        }
        .eq-chat-foot-tools {
            display: flex;
            align-items: center;
            gap: 4px;
            padding: 0 2px 10px;
        }
        .eq-chat-tool {
            width: 36px;
            height: 36px;
            border: none;
            border-radius: 10px;
            background: transparent;
            color: var(--orange);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 17px;
            transition: background 0.2s, color 0.2s, transform 0.15s;
        }
        .eq-chat-tool:hover {
            background: rgba(255, 107, 53, 0.12);
            color: var(--orange-dark);
        }
        .eq-chat-tool--recording {
            background: rgba(255, 107, 53, 0.2) !important;
            color: var(--orange-dark) !important;
            border-radius: 10px;
            box-shadow: inset 0 0 0 1px rgba(255, 107, 53, 0.25);
        }
        .eq-chat-voice-bar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 0 4px 10px;
            margin-top: 0;
            background: transparent;
            border: none;
            box-shadow: none;
        }
        .eq-chat-voice-bar[hidden] { display: none !important; }
        .eq-chat-voice-cancel {
            width: 40px;
            height: 40px;
            border: none;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--orange), #C84B1F);
            color: #fff;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
            box-shadow: 0 2px 10px rgba(255, 107, 53, 0.35);
            transition: transform 0.15s, filter 0.2s;
        }
        .eq-chat-voice-cancel:hover { filter: brightness(1.08); }
        .eq-chat-voice-cancel:active { transform: scale(0.94); }
        .eq-chat-voice-pill {
            flex: 1;
            min-width: 0;
            display: flex;
            align-items: center;
            gap: 0;
            padding: 4px 6px 4px 4px;
            border-radius: 999px;
            background: linear-gradient(135deg, var(--orange), #C84B1F);
            box-shadow: 0 2px 12px rgba(255, 107, 53, 0.28);
        }
        .eq-chat-voice-pill-stop-wrap {
            flex-shrink: 0;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: rgba(0, 0, 0, 0.12);
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .eq-chat-voice-stop-btn {
            width: 34px;
            height: 34px;
            border: none;
            border-radius: 50%;
            background: #fff;
            color: var(--orange);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 11px;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.12);
            transition: transform 0.12s;
        }
        .eq-chat-voice-stop-btn:hover { transform: scale(1.04); }
        .eq-chat-voice-stop-btn:active { transform: scale(0.96); }
        .eq-chat-voice-pill-spacer {
            flex: 1;
            min-width: 8px;
        }
        .eq-chat-voice-timer-badge {
            flex-shrink: 0;
            padding: 8px 14px;
            border-radius: 999px;
            background: #fff;
            color: var(--orange);
            font-size: 14px;
            font-weight: 700;
            font-variant-numeric: tabular-nums;
            line-height: 1;
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
        }
        .eq-chat-voice-send-plain {
            width: 44px;
            height: 44px;
            border: none;
            border-radius: 50%;
            background: transparent;
            color: var(--orange);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 22px;
            flex-shrink: 0;
            transition: transform 0.15s, color 0.2s;
        }
        .eq-chat-voice-send-plain:hover { color: var(--orange-dark); transform: scale(1.06); }
        .eq-chat-voice-send-plain:active { transform: scale(0.94); }
        .eq-chat-voice-send-plain:disabled { opacity: 0.45; cursor: not-allowed; transform: none; }
        .eq-chat-bubble--voice-only {
            padding: 10px 14px 10px 12px;
            border-radius: 20px;
            min-width: 200px;
            max-width: 280px;
        }
        .eq-chat-bubble--image-only {
            padding: 6px;
            border-radius: 16px;
            max-width: min(268px, 86vw);
            overflow: hidden;
        }
        .eq-chat-img-wrap {
            display: block;
            line-height: 0;
        }
        .eq-chat-msg-img {
            display: block;
            max-width: 256px;
            width: 100%;
            height: auto;
            border-radius: 12px;
            cursor: pointer;
        }
        .eq-chat-voice-player {
            position: relative;
            display: flex;
            align-items: center;
            gap: 10px;
            min-width: 0;
        }
        .eq-chat-voice-play {
            width: 36px;
            height: 36px;
            border: none;
            border-radius: 50%;
            flex-shrink: 0;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            transition: transform 0.12s, opacity 0.2s;
        }
        .eq-chat-voice-play:hover { transform: scale(1.05); }
        .eq-chat-voice-play:active { transform: scale(0.95); }
        .eq-chat-voice-player--mine .eq-chat-voice-play {
            background: rgba(255, 255, 255, 0.95);
            color: var(--orange);
        }
        .eq-chat-voice-player--other .eq-chat-voice-play {
            background: rgba(255, 107, 53, 0.15);
            color: var(--orange-dark);
        }
        .eq-chat-voice-static-wave {
            flex: 1;
            min-width: 0;
            height: 28px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 2px;
        }
        .eq-chat-voice-static-bar {
            flex: 1;
            min-width: 2px;
            max-width: 5px;
            border-radius: 2px;
            align-self: center;
            min-height: 4px;
        }
        .eq-chat-voice-player--mine .eq-chat-voice-static-bar {
            background: rgba(255, 255, 255, 0.88);
        }
        .eq-chat-voice-player--other .eq-chat-voice-static-bar {
            background: rgba(255, 107, 53, 0.55);
        }
        .eq-chat-voice-dur {
            flex-shrink: 0;
            font-size: 13px;
            font-weight: 600;
            font-variant-numeric: tabular-nums;
        }
        .eq-chat-voice-player--mine .eq-chat-voice-dur { color: rgba(255, 255, 255, 0.95); }
        .eq-chat-voice-player--other .eq-chat-voice-dur { color: var(--text2); }
        .eq-chat-voice-audio {
            position: absolute;
            width: 0;
            height: 0;
            opacity: 0;
            pointer-events: none;
        }
        .eq-chat-meta--sent {
            color: var(--text3);
            font-size: 11px;
            font-weight: 500;
        }
        .eq-chat-meta--with-receipt {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            gap: 6px;
            flex-wrap: nowrap;
            max-width: 100%;
        }
        .eq-chat-meta-receipt {
            width: 22px;
            height: 22px;
            border-radius: 50%;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 8px;
            font-weight: 800;
            letter-spacing: -0.02em;
            color: var(--orange);
            background: var(--surface);
            border: 1px solid var(--border);
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.06);
        }
        .eq-chat-meta-sent-text {
            white-space: nowrap;
            text-align: right;
        }
        .eq-chat-tool span {
            font-weight: 800;
            font-size: 11px;
            letter-spacing: -0.3px;
            color: inherit;
        }
        .eq-chat-foot-input-row {
            display: flex;
            align-items: flex-end;
            gap: 8px;
        }
        .eq-chat-side-plus {
            width: 42px;
            height: 42px;
            flex-shrink: 0;
            border: none;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--orange), #C84B1F);
            color: #fff;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px;
            box-shadow: 0 3px 12px rgba(255, 107, 53, 0.35);
            transition: transform 0.15s, filter 0.2s;
        }
        .eq-chat-side-plus:hover { filter: brightness(1.06); }
        .eq-chat-side-plus:active { transform: scale(0.94); }
        .eq-chat-side-plus:disabled {
            opacity: 0.45;
            cursor: not-allowed;
            transform: none;
        }
        .eq-chat-composer {
            flex: 1;
            min-width: 0;
            display: flex;
            flex-direction: column;
            gap: 8px;
            padding: 8px 10px 10px;
            border-radius: 20px;
            border: 1px solid var(--border);
            background: var(--bg3);
            box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.06);
        }
        .eq-chat-attach-preview {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 10px;
            min-height: 0;
            padding: 10px 12px;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 14px;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.04);
        }
        .eq-chat-attach-preview[hidden] { display: none !important; }
        .eq-chat-attach-add {
            width: 56px;
            height: 56px;
            flex-shrink: 0;
            border-radius: 12px;
            border: 1px solid rgba(0, 0, 0, 0.08);
            background: #ececee;
            color: var(--orange);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: background 0.2s, border-color 0.2s;
        }
        .eq-chat-attach-add:hover {
            background: #e2e2e6;
            border-color: rgba(255, 107, 53, 0.35);
        }
        .eq-chat-attach-add-inner {
            width: 32px;
            height: 32px;
            border-radius: 8px;
            background: #d4d4d8;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            font-weight: 300;
            color: var(--orange);
        }
        .eq-chat-attach-thumbs {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 10px;
            flex: 1;
            min-width: 0;
        }
        .eq-chat-attach-thumb-slot {
            position: relative;
            width: 56px;
            height: 56px;
            flex-shrink: 0;
            border-radius: 12px;
            overflow: visible;
            border: 1px solid var(--border);
            background: var(--bg3);
        }
        .eq-chat-attach-thumb-img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: block;
            border-radius: 11px;
        }
        .eq-chat-attach-remove {
            position: absolute;
            top: -6px;
            right: -6px;
            width: 22px;
            height: 22px;
            border: 2px solid var(--surface);
            border-radius: 50%;
            background: #fff;
            color: #111;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            padding: 0;
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.15);
            z-index: 1;
        }
        .eq-chat-attach-remove:hover { color: #b91c1c; }
        .eq-chat-composer-field {
            min-width: 0;
        }
        .eq-chat-composer-field .eq-chat-input-wrap {
            flex: 1;
            min-width: 0;
            position: relative;
            display: flex;
            align-items: center;
        }
        .eq-chat-composer-field .eq-chat-input-wrap input {
            width: 100%;
            border-radius: 14px;
            border: none;
            background: rgba(0, 0, 0, 0.06);
            color: var(--text);
            padding: 10px 44px 10px 14px;
            font-size: 15px;
            font-family: inherit;
            transition: background 0.2s, box-shadow 0.2s;
        }
        .eq-chat-composer-field .eq-chat-input-wrap input:focus {
            outline: none;
            background: rgba(0, 0, 0, 0.08);
            box-shadow: 0 0 0 2px rgba(255, 107, 53, 0.22);
        }
        .eq-chat-composer-field .eq-chat-input-wrap input::placeholder { color: var(--text3); opacity: 0.88; }
        .eq-chat-emoji-in {
            position: absolute;
            right: 4px;
            top: 50%;
            transform: translateY(-50%);
            width: 34px;
            height: 34px;
            border: none;
            border-radius: 50%;
            background: transparent;
            color: var(--orange);
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 17px;
            transition: background 0.2s, color 0.2s;
        }
        .eq-chat-emoji-in:hover {
            background: rgba(255, 107, 53, 0.1);
            color: var(--orange-dark);
        }
        .eq-chat-send {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            border: none;
            background: linear-gradient(135deg, var(--orange), #C84B1F);
            color: #fff;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            flex-shrink: 0;
            font-size: 16px;
            box-shadow: 0 4px 16px rgba(255, 107, 53, 0.35);
            transition: transform 0.15s, box-shadow 0.2s, filter 0.2s;
        }
        .eq-chat-send:hover {
            filter: brightness(1.05);
            box-shadow: 0 6px 20px rgba(255, 107, 53, 0.42);
        }
        .eq-chat-send:active { transform: scale(0.96); }
        .eq-chat-send:disabled {
            opacity: .45;
            cursor: not-allowed;
            box-shadow: none;
            filter: none;
        }
        .eq-chat-send.is-disabled {
            opacity: .55;
            box-shadow: 0 2px 8px rgba(255, 107, 53, 0.18);
        }
        .eq-chat-empty { text-align: center; color: var(--text3); font-size: 13px; padding: 28px 12px; line-height: 1.5; }
    </style>
    @include('partials.theme-assets')
</head>
<body>
@include('partials.admin.resolve-header-user', ['headerSourceUser' => $user])
@php
    $headerDisplayName = $headerDisplayName ?? 'Administrateur';
    $headerInitials = $headerInitials ?? 'A';
    $headerAvatarUrl = $headerAvatarUrl ?? null;
    $headerRoleLabel = $headerRoleLabel ?? 'Administrateur';
@endphp
<div class="bg-canvas"></div>
<div class="grid-overlay"></div>

<div class="app">
    @include('partials.admin_technique_sidebar', ['problemesStats' => \App\Support\ProblemesSidebarStats::counts()])

    <div class="main">
        @include('partials.dashboard_topbar', [
            'title' => 'Équipes d\'intervention',
            'titleId' => null,
            'breadcrumb' => 'Trig-Essalama / <span>Équipes</span>',
            'crumbId' => null,
            'chatBellUid' => 'equipes',
        ])

        <div class="content">
            @if(session('success'))
            <div class="alert alert-success"><i class="fas fa-check-circle"></i><span>{{ session('success') }}</span></div>
            @endif
            @if(session('error'))
            <div class="alert alert-error"><i class="fas fa-exclamation-circle"></i><span>{{ session('error') }}</span></div>
            @endif

            <div class="section-header fade-in">
                <h3>Gestion des équipes d'intervention</h3>
            </div>

            <div class="card mb-16">
                <div class="card-head">
                    <div class="card-title-wrap">
                        <div class="card-icon"><i class="fas fa-users-gear"></i></div>
                        <span class="card-title">Équipes & intervenants (MongoDB)</span>
                    </div>
                </div>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Nom</th>
                                <th>Prénom</th>
                                <th>Équipe</th>
                                <th>Téléphone</th>
                                <th>Zone</th>
                                <th>Email</th>
                                <th class="eq-chat-col">MESSAGE</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($equipes ?? [] as $eq)
                                @php $eid = (string) $eq->getKey(); @endphp
                                <tr>
                                    <td><span class="td-name">—</span></td>
                                    <td>—</td>
                                    <td><span class="td-name">{{ $eq->nom }}</span></td>
                                    <td>—</td>
                                    <td>{{ $eq->zone ?: '—' }}</td>
                                    <td><span class="td-email">—</span></td>
                                    <td style="text-align:center;">
                                        <button type="button" class="eq-chat-open eq-chat-open--compact" data-type="module" data-id="{{ $eid }}" data-collection="" data-label="{{ $eq->nom }}" title="Écrire à cette équipe">
                                            <i class="fas fa-comment-dots" aria-hidden="true"></i><span class="eq-chat-open-txt"> Message</span>
                                        </button>
                                    </td>
                                </tr>
                            @endforeach

                            @foreach(($intervenants ?? collect()) as $iv)
                                @php
                                    $ivChatId = (string) ($iv['chat_recipient_id'] ?? $iv['id'] ?? '');
                                    $ivChatCol = (string) ($iv['chat_collection'] ?? $iv['collection'] ?? 'intervenants');
                                    if (! in_array($ivChatCol, ['intervenants', 'intervenant'], true)) {
                                        $ivChatCol = 'intervenants';
                                    }
                                    $ivLabel = trim(($iv['prenom'] ?? '').' '.($iv['nom'] ?? ''));
                                    if ($ivLabel === '' || $ivLabel === '— —') {
                                        $ivLabel = (string) ($iv['equipe'] ?? 'Intervenant');
                                    }
                                @endphp
                                <tr class="intervenant-from-mongo-row">
                                    <td><span class="td-name">{{ $iv['nom'] ?? '—' }}</span></td>
                                    <td>{{ $iv['prenom'] ?? '—' }}</td>
                                    <td>{{ $iv['equipe'] ?? '—' }}</td>
                                    <td>{{ $iv['phone'] ?? '—' }}</td>
                                    <td><span class="td-clip" style="display:block;max-width:260px;">{{ \Illuminate\Support\Str::limit($iv['zone'] ?? '—', 120) }}</span></td>
                                    <td><span class="td-email td-clip" style="display:block;max-width:260px;">{{ $iv['email'] ?? '—' }}</span></td>
                                    <td style="text-align:center;">
                                        <button type="button" class="eq-chat-open eq-chat-open--compact" data-type="intervenant" data-id="{{ $ivChatId }}" data-collection="{{ $ivChatCol }}" data-label="{{ $ivLabel }}" title="Discuter avec cet intervenant">
                                            <i class="fas fa-comment-dots" aria-hidden="true"></i><span class="eq-chat-open-txt"> Message</span>
                                        </button>
                                    </td>
                                </tr>
                            @endforeach

                            @if(($equipes ?? collect())->isEmpty() && ($intervenants ?? collect())->isEmpty())
                                <tr>
                                    <td colspan="7" style="text-align:center;padding:28px;color:var(--text3);">
                                        Aucune donnée : pas d’équipe en base module et aucun document dans les collections <code>intervenants</code> / <code>intervenant</code>.
                                    </td>
                                </tr>
                            @endif
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

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
    var state = { type: '', id: '', collection: '', label: '', isFetching: false, isSubmitting: false };

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

    function isBusySending() {
        return !!state.isSubmitting;
    }

    function refreshSendButtonState() {
        if (!sendBtn) return;
        var hasText = !!((inputEl && inputEl.value ? inputEl.value : '').trim());
        var canSend = !!state.id && !isBusySending() && (hasText || pendingImages.length > 0);
        // Keep the button clickable; validation is handled in sendMessage.
        // This avoids a stuck native disabled state on some browsers.
        sendBtn.disabled = false;
        sendBtn.classList.toggle('is-disabled', !canSend);
        sendBtn.setAttribute('aria-disabled', canSend ? 'false' : 'true');
    }

    function clearPendingAttachment() {
        for (var pi = 0; pi < pendingImages.length; pi++) {
            try { URL.revokeObjectURL(pendingImages[pi].objectUrl); } catch (e) {}
        }
        pendingImages = [];
        if (attachThumbs) attachThumbs.innerHTML = '';
        if (attachPreview) attachPreview.hidden = true;
        refreshSendButtonState();
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
        refreshSendButtonState();
    }

    function clearReplyDraft() {
        replyDraft = null;
        if (replyBar) replyBar.hidden = true;
        if (replySnippet) replySnippet.textContent = '';
        refreshSendButtonState();
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
        if (!voiceUploadUrl || !state.id || isBusySending()) return;
        state.isSubmitting = true;
        refreshSendButtonState();
        var fd = new FormData();
        fd.append('recipient_type', state.type);
        fd.append('recipient_id', state.id);
        fd.append('intervenant_collection', state.collection || '');
        fd.append('audio', blob, 'voice.webm');
        fd.append('_token', csrf());
        fetch(voiceUploadUrl, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrf() } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                state.isSubmitting = false;
                refreshSendButtonState();
                if (data && data.success) loadMessages();
                else alert((data && data.message) ? data.message : 'Envoi vocal impossible.');
            })
            .catch(function () {
                state.isSubmitting = false;
                refreshSendButtonState();
                alert('Erreur réseau.');
            });
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
        if (isBusySending()) return;
        state.isSubmitting = true;
        refreshSendButtonState();

        function doOne(ix) {
            if (ix >= queue.length) {
                clearPendingAttachment();
                inputEl.value = '';
                clearReplyDraft();
                loadMessages();
                state.isSubmitting = false;
                refreshSendButtonState();
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
                        state.isSubmitting = false;
                        refreshSendButtonState();
                    }
                })
                .catch(function () {
                    alert('Erreur réseau.');
                    state.isSubmitting = false;
                    refreshSendButtonState();
                });
        }
        doOne(0);
    }

    function openChatImagePicker() {
        if (!imageUploadUrl || !state.id || isBusySending()) return;
        if (isRecording) {
            alert('Terminez ou annulez l’enregistrement vocal avant d’ajouter une photo.');
            return;
        }
        if (imageInput) imageInput.click();
    }

    function toggleVoiceRecord() {
        if (!voiceUploadUrl || !state.id || isBusySending()) return;
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
        refreshSendButtonState();
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
        refreshSendButtonState();
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
        state.isFetching = true;
        fetch(messagesUrl + '?' + q.toString(), { credentials: 'same-origin', headers: { 'Accept': 'application/json' } })
            .then(function (r) { return r.json(); })
            .then(function (data) {
                state.isFetching = false;
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
            .catch(function () { state.isFetching = false; bodyEl.innerHTML = '<div class="eq-chat-empty">Erreur de chargement.</div>'; });
    }

    function sendMessage() {
        if (!state.id || isBusySending()) return;
        var hasText = !!((inputEl && inputEl.value ? inputEl.value : '').trim());
        var canSendNow = hasText || pendingImages.length > 0;
        if (!canSendNow) {
            if (inputEl) inputEl.focus();
            refreshSendButtonState();
            return;
        }
        if (pendingImages.length > 0) {
            if (!imageUploadUrl) return;
            var cap = (inputEl.value || '').trim();
            uploadPendingImagesBatch(cap);
            return;
        }
        if (!sendUrl) return;
        var text = (inputEl.value || '').trim();
        if (!text) return;
        state.isSubmitting = true;
        refreshSendButtonState();
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
                state.isSubmitting = false;
                refreshSendButtonState();
                if (data && data.success) {
                    inputEl.value = '';
                    clearReplyDraft();
                    loadMessages();
                } else {
                    alert((data && data.message) ? data.message : 'Envoi impossible.');
                }
            })
            .catch(function () {
                state.isSubmitting = false;
                refreshSendButtonState();
                alert('Erreur réseau.');
            });
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
        if (state.isFetching) return;
        loadMessages();
    }, CHAT_OPEN_THREAD_REFRESH_MS);
    btnClose.addEventListener('click', closeChat);
    btnMin.addEventListener('click', function () { widget.classList.toggle('eq-chat-widget--min'); });
    sendBtn.addEventListener('click', sendMessage);
    inputEl.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });
    inputEl.addEventListener('input', refreshSendButtonState);
    refreshSendButtonState();
})();
</script>

@include('partials.theme-toggle')
</body>
</html>

