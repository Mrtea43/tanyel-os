// tanyel-shell.jsx — Main TanyelOS shell: boot, desktop, taskbar, start menu, context menu

const { useState: useS, useEffect: useE, useRef: useR, useCallback: useCB } = React;
const { useTweaks, TweaksPanel, TweakSection, TweakRadio, TweakSelect, TweakToggle } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "dark",
  "accent": "teal",
  "font": "Geist",
  "wallpaper": "aurora"
}/*EDITMODE-END*/;

const ACCENT_MAP = {
  teal:   { h: 195, c: 0.13 },
  amber:  { h: 60,  c: 0.15 },
  rose:   { h: 20,  c: 0.16 },
  violet: { h: 290, c: 0.13 },
  lime:   { h: 130, c: 0.15 },
};

const FONT_STACKS = {
  'Geist':           "'Geist', 'Inter', system-ui, sans-serif",
  'Inter':           "'Inter', system-ui, sans-serif",
  'IBM Plex':        "'IBM Plex Sans', system-ui, sans-serif",
  'JetBrains Mono':  "'JetBrains Mono', ui-monospace, monospace",
};

// ─── Boot screen ───
function BootScreen({ onDone }) {
  const [progress, setProgress] = useS(0);
  const [status, setStatus] = useS('Initializing kernel…');
  const [logs, setLogs] = useS([]);
  const [fading, setFading] = useS(false);

  useE(() => {
    const steps = [
      { p: 12, s: 'Loading device tree…',          l: { kind: 'ok', t: 'Reached target Basic System.' }, d: 220 },
      { p: 28, s: 'Mounting /home/tanyel…',         l: { kind: 'ok', t: 'Mounted /home/tanyel.' }, d: 260 },
      { p: 44, s: 'Starting tsh shell…',            l: { kind: 'info', t: 'Started tsh shell daemon.' }, d: 280 },
      { p: 62, s: 'Loading window manager…',        l: { kind: 'ok', t: 'Started Window Manager.' }, d: 300 },
      { p: 78, s: 'Reticulating splines…',          l: { kind: 'info', t: 'Reticulated 1,847 splines.' }, d: 280 },
      { p: 92, s: 'Restoring user session…',        l: { kind: 'ok', t: 'Loaded user session for tanyel.' }, d: 280 },
      { p: 100, s: 'Welcome.',                       l: { kind: 'ok', t: 'Reached target Graphical Interface.' }, d: 320 },
    ];
    let i = 0;
    let t;
    const tick = () => {
      if (i >= steps.length) {
        setFading(true);
        setTimeout(onDone, 500);
        return;
      }
      const step = steps[i++];
      setProgress(step.p);
      setStatus(step.s);
      setLogs(ls => [...ls, step.l]);
      t = setTimeout(tick, step.d);
    };
    tick();
    return () => clearTimeout(t);
  }, [onDone]);

  return (
    <div className="t-boot" data-fading={fading ? '1' : '0'}>
      <div className="t-boot-log">
        {logs.map((l, i) => (
          <div key={i}>
            [<span className={l.kind}>{l.kind === 'ok' ? '  OK  ' : ' INFO '}</span>] {l.t}
          </div>
        ))}
      </div>
      <div className="t-boot-logo">T</div>
      <div className="t-boot-name">TanyelOS</div>
      <div className="t-boot-version">version 1.0 · web edition</div>
      <div className="t-boot-bar"><div className="t-boot-bar-fill" style={{ width: progress + '%' }}/></div>
      <div className="t-boot-status">{status}</div>
    </div>
  );
}

// ─── App spec / openers ───
const APPS = {
  about:    { title: 'About — Tanyel',     icon: '◖', width: 640, height: 520 },
  files:    { title: 'Files',              icon: '📁', width: 720, height: 480 },
  terminal: { title: 'Terminal',           icon: '>_', width: 680, height: 420 },
  projects: { title: 'Projects',           icon: '◇', width: 760, height: 540 },
  resume:   { title: 'Resume — resume.pdf',icon: '📕', width: 720, height: 600 },
  contact:  { title: 'Contact',            icon: '✉', width: 700, height: 480 },
  settings: { title: 'Settings',           icon: '⚙', width: 720, height: 540 },
  text:     { title: 'Text',               icon: '📄', width: 600, height: 480 },
  image:    { title: 'Image',              icon: '🖼', width: 640, height: 480 },
};

// ─── Desktop ───
function Desktop({ tweaks, setTweak }) {
  const [fs, setFs] = useS(window.TanyelFS.initialFS);
  const [selectedIcon, setSelectedIcon] = useS(null);
  const [startOpen, setStartOpen] = useS(false);
  const [ctxMenu, setCtxMenu] = useS(null);
  const wm = window.useWindowManager();
  const [now, setNow] = useS(new Date());
  const [selRect, setSelRect] = useS(null);
  const selStart = useR(null);

  useE(() => {
    const t = setInterval(() => setNow(new Date()), 30000);
    return () => clearInterval(t);
  }, []);

  // Desktop icons
  const desktopIcons = [
    { id: 'about',    label: 'About',         icon: '◖', open: () => openApp('about') },
    { id: 'projects', label: 'Projects',      icon: '◇', open: () => openApp('projects') },
    { id: 'files',    label: 'Files',         icon: '📁', open: () => openApp('files') },
    { id: 'resume',   label: 'resume.pdf',    icon: '📕', open: () => openApp('resume') },
    { id: 'terminal', label: 'Terminal',      icon: '>_', open: () => openApp('terminal') },
    { id: 'contact',  label: 'Contact',       icon: '✉', open: () => openApp('contact') },
    { id: 'settings', label: 'Settings',      icon: '⚙', open: () => openApp('settings') },
  ];

  const openApp = (app, props = {}, extra = {}) => {
    const spec = APPS[app] || APPS.text;
    wm.open({
      app,
      title: extra.title || spec.title,
      icon: extra.icon || spec.icon,
      width: spec.width,
      height: spec.height,
      singleton: app !== 'text' && app !== 'image',
      key: extra.key,
      props,
    });
  };

  const openFile = (node, pathArr) => {
    if (node.type === 'dir') {
      openApp('files', { initialPath: pathArr });
      return;
    }
    if (node.kind === 'pdf')   return openApp('resume');
    if (node.kind === 'contact') return openApp('contact');
    if (node.kind === 'image') {
      openApp('image', { file: node }, { title: node.name + ' — Image', icon: '🖼', key: pathArr.join('/') });
      return;
    }
    if (node.kind === 'md' || node.kind === 'txt') {
      openApp('text', { file: node }, { title: node.name, icon: '📄', key: pathArr.join('/') });
      return;
    }
    openApp('text', { file: node }, { title: node.name, icon: '📄', key: pathArr.join('/') });
  };

  // Right-click on desktop background
  const onDesktopContext = (e) => {
    e.preventDefault();
    setCtxMenu({ x: e.clientX, y: e.clientY });
    setStartOpen(false);
  };

  // Click empty space → close menus, deselect
  const onDesktopMouseDown = (e) => {
    if (e.target.closest('.t-win, .t-taskbar, .t-startmenu, .t-ctxmenu, .twk-panel, .t-desk-icon, .t-topbar')) return;
    setCtxMenu(null);
    setStartOpen(false);
    setSelectedIcon(null);
    if (e.button === 0) {
      selStart.current = { x: e.clientX, y: e.clientY };
    }
  };

  useE(() => {
    const onMM = (e) => {
      if (!selStart.current) return;
      const s = selStart.current;
      const x = Math.min(s.x, e.clientX), y = Math.min(s.y, e.clientY);
      const w = Math.abs(s.x - e.clientX), h = Math.abs(s.y - e.clientY);
      if (w > 4 || h > 4) setSelRect({ x, y, w, h });
    };
    const onMU = () => { selStart.current = null; setSelRect(null); };
    window.addEventListener('mousemove', onMM);
    window.addEventListener('mouseup', onMU);
    return () => { window.removeEventListener('mousemove', onMM); window.removeEventListener('mouseup', onMU); };
  }, []);

  const refreshDesktop = () => {
    setSelectedIcon(null);
    document.body.animate([{ filter: 'brightness(1.15)' }, { filter: 'brightness(1)' }], { duration: 220 });
  };

  const cycleWallpaper = () => {
    const wps = ['aurora','dusk','grid','topo','solid'];
    const i = wps.indexOf(tweaks.wallpaper);
    setTweak('wallpaper', wps[(i + 1) % wps.length]);
  };

  const toggleTheme = () => setTweak('theme', tweaks.theme === 'dark' ? 'light' : 'dark');

  const formatTime = (d) => d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
  const formatDate = (d) => d.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' });

  // Render the active app inside a window
  const renderApp = (w) => {
    switch (w.app) {
      case 'files':
        return <window.FileExplorer
          initialPath={w.props.initialPath || ['~']}
          fs={fs}
          openFile={openFile}
          setProps={(patch) => wm.setProps(w.id, patch)}
        />;
      case 'about':    return <window.AboutApp/>;
      case 'projects': return <window.ProjectsApp fs={fs} openFile={openFile}/>;
      case 'resume':   return <window.ResumeApp/>;
      case 'contact':  return <window.ContactApp/>;
      case 'settings': return <window.SettingsApp tweaks={tweaks} setTweak={setTweak}/>;
      case 'terminal': return <window.Terminal fs={fs} setFs={setFs} openFile={openFile}/>;
      case 'text':     return <window.TextViewer file={w.props.file}/>;
      case 'image':    return <window.ImageViewer file={w.props.file}/>;
      default: return <div style={{ padding: 20 }}>Unknown app.</div>;
    }
  };

  // Active focused window (highest z, not minimized)
  const visibleWindows = wm.windows.filter(w => !w.minimized);
  const focusedId = visibleWindows.length
    ? visibleWindows.reduce((a,b) => a.z > b.z ? a : b).id
    : null;

  return (
    <div
      className="t-desktop"
      onContextMenu={onDesktopContext}
      onMouseDown={onDesktopMouseDown}
    >
      <div className={`t-wallpaper t-wp-${tweaks.wallpaper}`}/>

      {/* Top bar */}
      <div className="t-topbar">
        <div className="t-tb-logo"><span className="t-tb-logo-mark"/>TanyelOS</div>
        <div className="t-tb-app">
          {focusedId ? (wm.windows.find(w => w.id === focusedId)?.title || 'Desktop') : 'Desktop'}
        </div>
        <div className="t-tb-menu">File · Edit · View · Help</div>
        <div className="t-tb-right">
          <span className="t-tb-icon">⌘</span>
          <span className="t-tb-icon">📶</span>
          <span className="t-tb-icon">🔋</span>
          <span>{formatTime(now)}</span>
        </div>
      </div>

      {/* Desktop icons */}
      <div className="t-desktop-grid">
        {desktopIcons.map(ic => (
          <button
            key={ic.id}
            className="t-desk-icon"
            data-selected={selectedIcon === ic.id ? '1' : '0'}
            onClick={(e) => { e.stopPropagation(); setSelectedIcon(ic.id); }}
            onDoubleClick={ic.open}
            onContextMenu={(e) => { e.stopPropagation(); e.preventDefault(); setSelectedIcon(ic.id); }}
          >
            <div className="t-desk-icon-glyph">{ic.icon}</div>
            <div className="t-desk-icon-label">{ic.label}</div>
          </button>
        ))}
      </div>

      {/* Selection rectangle */}
      {selRect && <div className="t-selrect" style={{ left: selRect.x, top: selRect.y, width: selRect.w, height: selRect.h }}/>}

      {/* Windows */}
      {wm.windows.map(w => (
        <window.Win
          key={w.id}
          w={w}
          focused={focusedId === w.id}
          onFocus={wm.focus}
          onClose={wm.close}
          onMinimize={wm.minimize}
          onMaximize={wm.toggleMaximize}
          onMove={(id, p) => wm.updateBounds(id, p)}
          onResize={(id, p) => wm.updateBounds(id, p)}
        >
          {renderApp(w)}
        </window.Win>
      ))}

      {/* Start menu */}
      {startOpen && (
        <div className="t-startmenu" onMouseDown={(e) => e.stopPropagation()}>
          <div className="t-sm-search">
            <span>🔍</span>
            <input placeholder="Search apps and files…" autoFocus/>
          </div>
          <div className="t-sm-h">Pinned</div>
          <div className="t-sm-grid">
            {[
              ['about',    '◖', 'About'],
              ['projects', '◇', 'Projects'],
              ['files',    '📁','Files'],
              ['terminal', '>_','Terminal'],
              ['resume',   '📕','Resume'],
              ['contact',  '✉','Contact'],
              ['settings', '⚙','Settings'],
            ].map(([k, g, l]) => (
              <button key={k} className="t-sm-tile" onClick={() => { openApp(k); setStartOpen(false); }}>
                <div className="t-sm-tile-icon">{g}</div>
                <div>{l}</div>
              </button>
            ))}
          </div>
          <div className="t-sm-h">Recent</div>
          <div>
            <div className="t-sm-recent-item" onClick={() => { openFile(window.TanyelFS.getNode(fs, ['~','projects','tanyel-os','readme.md']), ['~','projects','tanyel-os','readme.md']); setStartOpen(false); }}>
              <span>📄</span><span>tanyel-os / readme.md</span>
            </div>
            <div className="t-sm-recent-item" onClick={() => { openApp('resume'); setStartOpen(false); }}>
              <span>📕</span><span>resume.pdf</span>
            </div>
            <div className="t-sm-recent-item" onClick={() => { openApp('terminal'); setStartOpen(false); }}>
              <span>&gt;_</span><span>Terminal session</span>
            </div>
          </div>
          <div className="t-sm-foot">
            <button onClick={() => { openApp('settings'); setStartOpen(false); }}>⚙ Settings</button>
            <button onClick={() => { setStartOpen(false); window.location.reload(); }}>⏻ Restart</button>
          </div>
        </div>
      )}

      {/* Context menu */}
      {ctxMenu && (
        <div className="t-ctxmenu" style={{ left: Math.min(ctxMenu.x, window.innerWidth - 220), top: Math.min(ctxMenu.y, window.innerHeight - 280) }}
             onMouseDown={(e) => e.stopPropagation()}>
          <div className="t-ctx-item" onClick={() => { refreshDesktop(); setCtxMenu(null); }}>
            <span className="t-ctx-icon">↻</span> Refresh<span className="t-ctx-shortcut">F5</span>
          </div>
          <div className="t-ctx-item" onClick={() => { cycleWallpaper(); setCtxMenu(null); }}>
            <span className="t-ctx-icon">🖼</span> Change wallpaper
          </div>
          <div className="t-ctx-item" onClick={() => { toggleTheme(); setCtxMenu(null); }}>
            <span className="t-ctx-icon">◐</span> Toggle theme<span className="t-ctx-shortcut">⌘T</span>
          </div>
          <div className="t-ctx-sep"/>
          <div className="t-ctx-item" onClick={() => { openApp('terminal'); setCtxMenu(null); }}>
            <span className="t-ctx-icon">&gt;_</span> Open terminal here
          </div>
          <div className="t-ctx-item" onClick={() => { openApp('files'); setCtxMenu(null); }}>
            <span className="t-ctx-icon">📁</span> Open files
          </div>
          <div className="t-ctx-sep"/>
          <div className="t-ctx-item" onClick={() => { openApp('settings'); setCtxMenu(null); }}>
            <span className="t-ctx-icon">⚙</span> Display settings…
          </div>
          <div className="t-ctx-item" data-disabled="1">
            <span className="t-ctx-icon">📋</span> Paste<span className="t-ctx-shortcut">⌘V</span>
          </div>
        </div>
      )}

      {/* Taskbar */}
      <div className="t-taskbar" onMouseDown={(e) => e.stopPropagation()}>
        <button
          className="t-tb-start"
          data-open={startOpen ? '1' : '0'}
          onClick={() => { setStartOpen(o => !o); setCtxMenu(null); }}
        >
          <span className="t-tb-start-mark"/>Start
        </button>
        <div className="t-tb-divider"/>
        {wm.windows.map(w => (
          <button
            key={w.id}
            className="t-tb-app"
            data-active={focusedId === w.id ? '1' : '0'}
            data-minimized={w.minimized ? '1' : '0'}
            onClick={() => {
              if (focusedId === w.id) wm.minimize(w.id);
              else wm.focus(w.id);
            }}
            title={w.title}
          >
            <span className="t-win-icon">{w.icon}</span>
            <span className="t-tb-app-title">{w.title}</span>
          </button>
        ))}
        <div className="t-tb-clock">
          <div className="time">{formatTime(now)}</div>
          <div>{formatDate(now)}</div>
        </div>
      </div>
    </div>
  );
}

// ─── Root app ───
function App() {
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [booted, setBooted] = useS(false);

  // Apply tweaks to root
  useE(() => {
    document.documentElement.dataset.theme = tweaks.theme;
    const a = ACCENT_MAP[tweaks.accent] || ACCENT_MAP.teal;
    document.documentElement.style.setProperty('--accent-h', a.h);
    document.documentElement.style.setProperty('--accent-c', a.c);
    document.documentElement.style.setProperty('--font', FONT_STACKS[tweaks.font] || FONT_STACKS.Geist);
  }, [tweaks.theme, tweaks.accent, tweaks.font]);

  return (
    <>
      {!booted && <BootScreen onDone={() => setBooted(true)}/>}
      {booted && <Desktop tweaks={tweaks} setTweak={setTweak}/>}
      {booted && (
        <TweaksPanel title="Tweaks">
          <TweakSection label="Appearance"/>
          <TweakRadio label="Theme" value={tweaks.theme} options={['light','dark']}
                      onChange={(v) => setTweak('theme', v)}/>
          <TweakRadio label="Accent" value={tweaks.accent}
                      options={['teal','amber','rose','violet','lime']}
                      onChange={(v) => setTweak('accent', v)}/>
          <TweakSelect label="Font" value={tweaks.font}
                       options={['Geist','Inter','IBM Plex','JetBrains Mono']}
                       onChange={(v) => setTweak('font', v)}/>
          <TweakSection label="Desktop"/>
          <TweakSelect label="Wallpaper" value={tweaks.wallpaper}
                       options={['aurora','dusk','grid','topo','solid']}
                       onChange={(v) => setTweak('wallpaper', v)}/>
        </TweaksPanel>
      )}
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
