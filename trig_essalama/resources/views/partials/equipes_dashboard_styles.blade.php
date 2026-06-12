        /* ── Section Équipes (tableau dashboard) ── */
        .eq-section { margin-bottom: 8px; }
        .eq-section-header p { max-width: 640px; }

        .eq-kpi-strip {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 16px;
            margin-bottom: 22px;
        }
        @media (max-width: 900px) { .eq-kpi-strip { grid-template-columns: 1fr; } }

        .eq-kpi-card {
            display: flex;
            align-items: center;
            gap: 14px;
            padding: 18px 20px;
            border-radius: 16px;
            background: var(--bg3);
            border: 1px solid var(--border);
            box-shadow: 0 8px 24px rgba(0, 0, 0, 0.05);
            transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
        }
        .eq-kpi-card:hover {
            transform: translateY(-2px);
            border-color: rgba(255, 107, 53, 0.28);
            box-shadow: 0 14px 32px rgba(255, 107, 53, 0.1);
        }
        .eq-kpi-icon {
            width: 44px;
            height: 44px;
            border-radius: 13px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 17px;
            flex-shrink: 0;
        }
        .eq-kpi-icon--orange { background: rgba(255, 107, 53, 0.14); color: var(--orange); }
        .eq-kpi-icon--dark { background: rgba(26, 26, 26, 0.08); color: var(--black-soft); }
        .eq-kpi-icon--warm { background: rgba(255, 146, 92, 0.16); color: var(--orange-dark); }
        .eq-kpi-value {
            font-size: 28px;
            font-weight: 800;
            letter-spacing: -0.03em;
            line-height: 1;
            color: var(--text);
        }
        .eq-kpi-label {
            margin: 6px 0 0;
            font-size: 12px;
            color: var(--text2);
            line-height: 1.4;
        }

        .eq-card {
            background: var(--bg3);
            border: 1px solid var(--border);
            border-radius: 18px;
            overflow: hidden;
            box-shadow: 0 10px 36px rgba(0, 0, 0, 0.06);
        }
        .eq-card-head {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 16px;
            flex-wrap: wrap;
            padding: 20px 22px;
            border-bottom: 1px solid var(--border);
            background: linear-gradient(180deg, rgba(255, 107, 53, 0.06) 0%, rgba(255, 255, 255, 0) 100%);
        }
        .eq-card-head-left { display: flex; align-items: flex-start; gap: 14px; min-width: 0; }
        .eq-card-icon {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: rgba(255, 107, 53, 0.12);
            color: var(--orange);
            border: 1px solid rgba(255, 107, 53, 0.28);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            flex-shrink: 0;
        }
        .eq-card-title {
            margin: 0;
            font-size: 16px;
            font-weight: 800;
            color: var(--text);
            letter-spacing: -0.02em;
        }
        .eq-card-sub {
            margin: 4px 0 0;
            font-size: 12px;
            color: var(--text2);
            line-height: 1.45;
        }
        .eq-card-sub code {
            font-size: 11px;
            padding: 1px 6px;
            border-radius: 6px;
            background: rgba(0, 0, 0, 0.04);
            border: 1px solid rgba(0, 0, 0, 0.06);
        }
        .eq-card-tools {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            margin-left: auto;
        }
        .eq-search-wrap { position: relative; min-width: 240px; }
        .eq-search-icon {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text3);
            font-size: 12px;
            pointer-events: none;
        }
        .eq-search-input {
            width: 100%;
            padding: 10px 12px 10px 34px;
            border-radius: 10px;
            border: 1px solid var(--border);
            background: var(--surface);
            color: var(--text);
            font-size: 13px;
            font-family: inherit;
            transition: border-color 0.2s, box-shadow 0.2s;
        }
        .eq-search-input:focus {
            outline: none;
            border-color: rgba(255, 107, 53, 0.45);
            box-shadow: 0 0 0 3px rgba(255, 107, 53, 0.12);
        }
        .eq-search-input::placeholder { color: var(--text3); }
        .eq-count-badge {
            padding: 7px 12px;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 700;
            color: var(--orange-dark);
            background: rgba(255, 107, 53, 0.1);
            border: 1px solid rgba(255, 107, 53, 0.28);
            white-space: nowrap;
        }

        .eq-table-wrap {
            overflow: auto;
            max-height: min(62vh, 560px);
        }
        .eq-table-wrap::-webkit-scrollbar { width: 6px; height: 6px; }
        .eq-table-wrap::-webkit-scrollbar-thumb { background: rgba(0, 0, 0, 0.14); border-radius: 4px; }

        .eq-table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0;
            min-width: 860px;
        }
        .eq-table thead th {
            position: sticky;
            top: 0;
            z-index: 2;
            padding: 12px 16px;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: var(--text3);
            text-align: left;
            background: var(--bg3);
            border-bottom: 2px solid var(--border);
            box-shadow: 0 1px 0 var(--border);
        }
        .eq-table .eq-th-person { min-width: 220px; }
        .eq-table .eq-th-action { width: 130px; text-align: center; }

        .eq-table tbody td {
            padding: 14px 16px;
            font-size: 13px;
            color: var(--text2);
            border-bottom: 1px solid rgba(0, 0, 0, 0.06);
            vertical-align: middle;
        }
        .eq-row { transition: background 0.15s ease; }
        .eq-row:hover { background: rgba(255, 107, 53, 0.045); }
        .eq-row:hover td:first-child { box-shadow: inset 3px 0 0 var(--orange); }
        .eq-row:nth-child(even) { background: rgba(0, 0, 0, 0.015); }
        .eq-row:nth-child(even):hover { background: rgba(255, 107, 53, 0.05); }
        .eq-row:last-child td { border-bottom: none; }

        .eq-person { display: flex; align-items: center; gap: 12px; min-width: 0; }
        .eq-avatar {
            width: 40px;
            height: 40px;
            border-radius: 12px;
            flex-shrink: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            font-weight: 800;
            color: #fff;
            background: linear-gradient(135deg, var(--orange), #C2410C);
            box-shadow: 0 4px 14px rgba(255, 107, 53, 0.28);
        }
        .eq-avatar--team {
            background: linear-gradient(135deg, #1A1A1A, #404040);
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.18);
        }
        .eq-person-meta { min-width: 0; }
        .eq-person-name {
            display: block;
            font-size: 14px;
            font-weight: 700;
            color: var(--text);
            line-height: 1.25;
        }
        .eq-person-sub {
            display: block;
            margin-top: 3px;
            font-size: 11px;
            color: var(--text3);
            line-height: 1.35;
        }
        .eq-tag {
            display: inline-flex;
            align-items: center;
            padding: 2px 8px;
            border-radius: 999px;
            font-size: 10px;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
        }
        .eq-tag--module {
            color: var(--black-soft);
            background: rgba(0, 0, 0, 0.06);
            border: 1px solid rgba(0, 0, 0, 0.1);
        }

        .eq-team-badge {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 12px;
            border-radius: 999px;
            font-size: 12px;
            font-weight: 700;
            color: var(--orange-dark);
            background: rgba(255, 107, 53, 0.1);
            border: 1px solid rgba(255, 107, 53, 0.28);
            white-space: nowrap;
        }
        .eq-team-badge i { font-size: 11px; opacity: 0.9; }

        .eq-contact-stack { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
        .eq-contact-line {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            color: var(--text);
            transition: color 0.15s;
            max-width: 240px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .eq-contact-line i { color: var(--orange); font-size: 11px; flex-shrink: 0; }
        .eq-contact-line:hover { color: var(--orange-dark); }
        .eq-contact-line--email { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-weight: 500; color: var(--text2); }

        .eq-zone-chip {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 11px;
            border-radius: 10px;
            font-size: 12px;
            font-weight: 600;
            color: var(--text);
            background: var(--surface);
            border: 1px solid var(--border);
            max-width: 220px;
        }
        .eq-zone-chip i { color: var(--orange); font-size: 11px; flex-shrink: 0; }

        .eq-zone-gps {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 11px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 600;
            font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
            color: var(--orange-dark);
            background: rgba(255, 107, 53, 0.08);
            border: 1px solid rgba(255, 107, 53, 0.25);
            text-decoration: none;
            max-width: 240px;
            transition: background 0.15s, border-color 0.15s;
        }
        .eq-zone-gps:hover {
            background: rgba(255, 107, 53, 0.14);
            border-color: rgba(255, 107, 53, 0.4);
        }
        .eq-zone-gps span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

        .eq-empty-cell { color: var(--text3); font-size: 12px; font-style: italic; }

        .eq-td-action { text-align: center; }
        .eq-msg-btn {
            position: relative;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 7px;
            padding: 9px 14px;
            border-radius: 999px;
            border: 1px solid rgba(255, 107, 53, 0.35);
            background: linear-gradient(135deg, rgba(255, 107, 53, 0.12), rgba(255, 107, 53, 0.06));
            color: var(--orange-dark);
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            font-family: inherit;
            white-space: nowrap;
            transition: transform 0.15s, box-shadow 0.2s, background 0.2s, border-color 0.2s;
        }
        .eq-msg-btn i { font-size: 13px; }
        .eq-msg-btn:hover:not(:disabled) {
            transform: translateY(-1px);
            background: linear-gradient(135deg, var(--orange), #C2410C);
            border-color: transparent;
            color: #fff;
            box-shadow: 0 8px 22px rgba(255, 107, 53, 0.35);
        }
        .eq-msg-btn:disabled { opacity: 0.45; cursor: not-allowed; }

        .eq-empty-state {
            text-align: center;
            padding: 48px 24px;
            color: var(--text2);
        }
        .eq-empty-state i {
            font-size: 42px;
            color: var(--text3);
            opacity: 0.45;
            margin-bottom: 12px;
        }
        .eq-empty-state p {
            margin: 0 0 6px;
            font-size: 16px;
            font-weight: 700;
            color: var(--text);
        }
        .eq-empty-state span { font-size: 13px; line-height: 1.5; }
        .eq-empty-state code {
            font-size: 11px;
            padding: 1px 6px;
            border-radius: 6px;
            background: rgba(0, 0, 0, 0.04);
        }

        .eq-no-results {
            text-align: center;
            padding: 28px 16px;
            color: var(--text2);
            font-size: 13px;
            border-top: 1px dashed var(--border);
        }
        .eq-no-results i { display: block; font-size: 22px; color: var(--text3); margin-bottom: 8px; }
        .eq-no-results p { margin: 0; font-weight: 600; color: var(--text); }

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
        .eq-chat-empty { text-align: center; color: var(--text3); font-size: 13px; padding: 28px 12px; line-height: 1.5; }

