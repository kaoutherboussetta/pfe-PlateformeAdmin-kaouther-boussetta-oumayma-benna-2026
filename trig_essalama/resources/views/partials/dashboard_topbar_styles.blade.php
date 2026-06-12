        /* ── TOPBAR (identique tableau de bord autoritaire) ── */
        .topbar {
            height: 60px;
            background: rgba(255,255,255,0.97);
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 20px;
            gap: 16px;
            position: sticky;
            top: 0;
            z-index: 50;
            flex-shrink: 0;
            overflow: visible;
        }

        .tb-page-info {
            min-width: 0;
            flex: 1;
            padding-right: 12px;
            flex-shrink: 1;
        }
        .tb-page-title { font-size: 14px; font-weight: 700; color: var(--text); line-height: 1.2; }
        .tb-breadcrumb { font-size: 11px; color: var(--text3); margin-top: 2px; }
        .tb-breadcrumb span { color: var(--orange); }

        .tb-right { display: flex; align-items: center; gap: 6px; flex-shrink: 0; overflow: visible; position: relative; z-index: 60; }

        .tb-icon {
            width: 34px; height: 34px; border-radius: 8px;
            background: transparent; border: 1px solid transparent;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; color: var(--text2);
            transition: background 0.15s, color 0.15s, border-color 0.15s;
            position: relative; flex-shrink: 0;
        }
        .tb-icon:hover { background: var(--surface2); color: var(--text); border-color: var(--border); }
        .tb-icon svg { width: 15px; height: 15px; }
        .tb-icon .dot {
            position: absolute; top: 6px; right: 6px;
            width: 6px; height: 6px; border-radius: 50%;
            background: var(--orange); border: 1.5px solid var(--bg2);
            animation: blink 2s infinite;
        }

        .tb-profile {
            display: flex; align-items: center; gap: 8px;
            padding: 4px 8px 4px 4px;
            border-radius: 10px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: background 0.15s, border-color 0.15s;
        }
        .tb-profile:hover { background: var(--surface2); border-color: var(--border); }
        .profile-av {
            position: relative;
            width: 30px; height: 30px; border-radius: 8px;
            background: var(--orange);
            display: flex; align-items: center; justify-content: center;
            font-size: 12px; font-weight: 700; color: #fff;
            overflow: hidden;
            flex-shrink: 0;
        }
        .profile-av-img {
            position: absolute;
            inset: 0;
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        .profile-av.has-image .profile-av-img { display: block; }
        .profile-av.has-image .profile-av-letter { display: none; }
        .profile-av-letter { position: relative; z-index: 0; line-height: 1; }
        .profile-name { font-size: 12px; font-weight: 600; color: var(--text); text-transform: lowercase; }
        .profile-role { font-size: 10px; color: var(--text2); margin-top: 1px; }
        .profile-chevron { width: 12px; height: 12px; color: var(--text3); }
        .tb-profile-wrap { position: relative; }
        .tb-profile-menu {
            position: absolute;
            right: 0;
            top: calc(100% + 8px);
            min-width: 240px;
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 12px;
            box-shadow: 0 18px 40px rgba(0,0,0,0.12);
            overflow: hidden;
            display: none;
            z-index: 200;
        }
        .tb-profile-menu.show { display: block; }
        .tb-profile-head {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 14px;
            border-bottom: 1px solid var(--border);
        }
        .tb-profile-head .profile-av { width: 34px; height: 34px; font-size: 13px; }
        .tb-profile-item {
            width: 100%;
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 14px;
            color: var(--text2);
            background: transparent;
            border: none;
            text-decoration: none;
            font-size: 14px;
            text-align: left;
            cursor: pointer;
            border-bottom: 1px solid var(--border);
            box-sizing: border-box;
        }
        .tb-profile-item:last-child { border-bottom: none; }
        .tb-profile-item:hover { background: var(--surface); color: var(--text); }
        .tb-profile-item.logout { color: var(--text); }
        .tb-profile-item.logout:hover { background: rgba(255,107,53,0.1); color: var(--orange-dark); }
        .tb-profile-item svg { width: 16px; height: 16px; flex-shrink: 0; }

        @media (max-width: 900px) {
            .topbar { padding: 0 16px; }
            .tb-profile .profile-name,
            .tb-profile .profile-role,
            .tb-profile .profile-chevron { display: none; }
            .tb-profile { padding: 4px; }
        }
