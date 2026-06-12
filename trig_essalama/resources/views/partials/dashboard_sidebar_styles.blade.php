        /* Sidebar — identique au tableau de bord autoritaire */
        .sidebar {
            width: 72px;
            background: var(--bg2);
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            align-items: center;
            transition: width 0.25s cubic-bezier(0.4,0,0.2,1);
            overflow: hidden;
            position: sticky;
            top: 0;
            height: 100vh;
            flex-shrink: 0;
            z-index: 20;
        }
        .sidebar.expanded { width: 230px; }

        .sb-logo {
            width: 100%;
            display: flex;
            align-items: center;
            gap: 11px;
            padding: 18px 18px 16px;
            border-bottom: 1px solid var(--border);
            overflow: hidden;
            white-space: nowrap;
            min-height: 72px;
        }
        .logo-mark {
            width: 38px; height: 38px;
            border-radius: 10px;
            background: var(--orange);
            display: flex; align-items: center; justify-content: center;
            font-size: 14px; font-weight: 800; color: #fff;
            flex-shrink: 0;
            letter-spacing: 0.5px;
        }
        .logo-text { opacity: 0; transition: opacity 0.18s; pointer-events: none; }
        .sidebar.expanded .logo-text { opacity: 1; }
        .logo-title { font-size: 13px; font-weight: 700; color: var(--text); letter-spacing: 1.5px; text-transform: uppercase; line-height: 1.2; }
        .logo-sub { font-size: 10px; color: var(--text3); letter-spacing: 0.8px; text-transform: uppercase; margin-top: 1px; }

        .sb-toggle {
            width: 100%;
            display: flex; align-items: center; justify-content: center;
            padding: 12px 0;
            cursor: pointer;
            color: var(--text3);
            transition: color 0.15s;
            border-bottom: 1px solid var(--border);
        }
        .sidebar.expanded .sb-toggle { justify-content: flex-end; padding-right: 18px; }
        .sb-toggle:hover { color: var(--text2); }
        .sb-toggle svg { width: 16px; height: 16px; }

        .sb-section { width: 100%; padding: 14px 0 4px; overflow: hidden; }
        .sb-section-label {
            font-size: 9px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase;
            color: var(--text3);
            padding: 0 18px 6px;
            white-space: nowrap;
            opacity: 0; transition: opacity 0.18s;
            height: 0; overflow: hidden;
        }
        .sidebar.expanded .sb-section-label { opacity: 1; height: auto; }

        .sb-item {
            width: 100%;
            display: flex; align-items: center; gap: 11px;
            padding: 11px 0 11px 18px;
            cursor: pointer;
            color: var(--text2);
            font-size: 13px; font-weight: 500;
            white-space: nowrap;
            transition: background 0.15s, color 0.15s;
            position: relative;
            border-left: 3px solid transparent;
            text-decoration: none;
        }
        .sb-item:hover { background: var(--surface); color: var(--text); }
        .sb-item.active { background: rgba(255,107,53,0.1); color: var(--orange); border-left-color: var(--orange); }
        a.sb-item.sb-item--page-link { color: inherit; text-decoration: none; -webkit-tap-highlight-color: transparent; }
        a.sb-item.sb-item--page-link:visited { color: inherit; }
        a.sb-item.sb-item--page-link .sb-item-label,
        a.sb-item.sb-item--page-link svg { pointer-events: none; }
        .sb-item svg { width: 16px; height: 16px; flex-shrink: 0; }
        .sb-item-label { opacity: 0; transition: opacity 0.18s; }
        .sidebar.expanded .sb-item-label { opacity: 1; }
        .sb-badge {
            margin-left: auto; margin-right: 14px;
            background: rgba(255,107,53,0.12); color: var(--orange-dark);
            border: 1px solid rgba(255,107,53,0.35);
            font-size: 10px; font-weight: 700;
            padding: 1px 6px; border-radius: 10px;
            opacity: 0; transition: opacity 0.18s;
        }
        .sidebar.expanded .sb-badge { opacity: 1; }
        .sb-spacer { flex: 1; width: 100%; }
