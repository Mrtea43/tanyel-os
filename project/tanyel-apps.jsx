// tanyel-apps.jsx — App contents (File Explorer, About, Projects, Resume, Contact, Settings, ImageViewer, TextViewer)

const { useState: useStateA, useMemo: useMemoA } = React;

// ─── File Explorer ───
function FileExplorer({ initialPath, fs, openFile, setProps }) {
  const [path, setPathState] = useStateA(initialPath || ['~']);
  const [selected, setSelected] = useStateA(null);

  const setPath = (p) => {
    setPathState(p);
    setSelected(null);
    if (setProps) setProps({ path: p });
  };

  const node = window.TanyelFS.getNode(fs, path);
  const entries = node && node.type === 'dir'
    ? Object.values(node.children).sort((a,b) => {
        if (a.type !== b.type) return a.type === 'dir' ? -1 : 1;
        return a.name.localeCompare(b.name);
      })
    : [];

  const goUp = () => { if (path.length > 1) setPath(path.slice(0, -1)); };
  const onCrumb = (i) => setPath(path.slice(0, i + 1));

  const places = [
    { label: 'Home', path: ['~'], icon: '◖' },
    { label: 'Projects', path: ['~', 'projects'], icon: '📁' },
    { label: 'Pictures', path: ['~', 'pictures'], icon: '🖼' },
    { label: 'Config', path: ['~', '.config'], icon: '⚙' },
  ];

  return (
    <div className="t-files">
      <div className="t-files-toolbar">
        <button className="t-btn" onClick={goUp} disabled={path.length <= 1} title="Up">↑</button>
        <button className="t-btn" onClick={() => path.length > 1 && setPath(path.slice(0, -1))} disabled={path.length <= 1}>‹</button>
        <button className="t-btn" disabled>›</button>
        <div className="t-crumbs">
          {path.map((seg, i) => (
            <span key={i}>
              {i > 0 && <span className="t-crumb-sep">/</span>}
              <button className="t-crumb" onClick={() => onCrumb(i)}>{seg}</button>
            </span>
          ))}
        </div>
      </div>
      <div className="t-files-body">
        <div className="t-sidebar">
          <div className="t-side-h">Places</div>
          {places.map(p => (
            <button
              key={p.label}
              className="t-side-item"
              data-active={JSON.stringify(p.path) === JSON.stringify(path) ? '1' : '0'}
              onClick={() => setPath(p.path)}
            >
              <span className="t-side-icon">{p.icon}</span>{p.label}
            </button>
          ))}
          <div className="t-side-h">Devices</div>
          <div className="t-side-item" data-active="0">
            <span className="t-side-icon">◇</span>TanyelOS
          </div>
        </div>
        <div className="t-grid">
          {entries.length === 0 && <div className="t-empty">This folder is empty.</div>}
          {entries.map(e => (
            <button
              key={e.name}
              className="t-tile"
              data-selected={selected === e.name ? '1' : '0'}
              onClick={() => setSelected(e.name)}
              onDoubleClick={() => {
                if (e.type === 'dir') setPath([...path, e.name]);
                else openFile(e, [...path, e.name]);
              }}
            >
              <div className="t-tile-icon">
                {e.type === 'dir' ? '📁' : (e.icon || '📄')}
              </div>
              <div className="t-tile-name">{e.name}</div>
            </button>
          ))}
        </div>
      </div>
      <div className="t-status">
        <span>{entries.length} item{entries.length === 1 ? '' : 's'}{selected ? ` · 1 selected` : ''}</span>
        <span>{window.TanyelFS.pathToString(path)}</span>
      </div>
    </div>
  );
}

// ─── About / README viewer ───
function MarkdownView({ content }) {
  const html = useMemoA(() => {
    if (!content) return '';
    return content.split('\n').map(line => {
      if (line.startsWith('# ')) return `<h1>${line.slice(2)}</h1>`;
      if (line.startsWith('## ')) return `<h2>${line.slice(3)}</h2>`;
      if (line.startsWith('### ')) return `<h3>${line.slice(4)}</h3>`;
      if (line.startsWith('> ')) return `<blockquote>${line.slice(2)}</blockquote>`;
      if (line.startsWith('- ') || line.startsWith('* ')) return `<li>${line.slice(2).replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')}</li>`;
      if (line.trim() === '') return '<br/>';
      return `<p>${line.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')}</p>`;
    }).join('').replace(/(<li>[\s\S]+?<\/li>)(?!<li>)/g, '<ul>$1</ul>');
  }, [content]);
  return <div className="t-md" dangerouslySetInnerHTML={{ __html: html }}/>;
}

function AboutApp() {
  return (
    <div className="t-about">
      <div className="t-about-hero">
        <div className="t-avatar">T</div>
        <div>
          <div className="t-about-name">Tanyel</div>
          <div className="t-about-tag">Designer · engineer · maker of small tools</div>
        </div>
      </div>
      <MarkdownView content={`# Hello.

I design and build interfaces. I like systems that feel like instruments — quiet by default, expressive on demand.

## Currently
- Designing systems on a small product team
- Tinkering with **TanyelOS** (the thing you're using)
- Picking up rust, slowly

## Previously
- Frontend lead at two small startups
- Studied human-computer interaction

## Things I care about
- Density without clutter
- Keyboard-first interactions
- Boring tooling that just works
- Joke easter eggs hidden in serious software

> "Make the boring parts beautiful and the clever parts invisible."`}/>
    </div>
  );
}

// ─── Projects gallery ───
function ProjectsApp({ fs, openFile }) {
  const projectsNode = window.TanyelFS.getNode(fs, ['~', 'projects']);
  const projects = projectsNode ? Object.values(projectsNode.children) : [];

  return (
    <div className="t-projects">
      <div className="t-projects-h">
        <div className="t-projects-title">Projects</div>
        <div className="t-projects-sub">{projects.length} projects · double-click to open</div>
      </div>
      <div className="t-projects-grid">
        {projects.map(p => {
          const cover = Object.values(p.children).find(c => c.kind === 'image');
          const readme = p.children['readme.md'];
          return (
            <div key={p.name} className="t-proj-card" onDoubleClick={() => readme && openFile(readme, ['~', 'projects', p.name, 'readme.md'])}>
              <div className="t-proj-cover" style={cover ? { background: `linear-gradient(135deg, oklch(70% 0.16 ${cover.content.hue}), oklch(45% 0.18 ${(cover.content.hue + 40) % 360}))` } : {}}>
                <div className="t-proj-cover-label">{p.name}</div>
              </div>
              <div className="t-proj-meta">
                <div className="t-proj-name">{p.name}</div>
                <div className="t-proj-desc">
                  {readme ? readme.content.split('\n').slice(2, 3).join(' ').replace(/[#*]/g, '') : ''}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── Resume ───
function ResumeApp() {
  return (
    <div className="t-resume">
      <header className="t-resume-h">
        <div>
          <h1>Tanyel</h1>
          <div className="t-resume-tag">Designer · Frontend Engineer</div>
        </div>
        <div className="t-resume-contact">
          <div>hello@tanyel.example</div>
          <div>tanyel.example</div>
          <div>github.com/tanyel</div>
        </div>
      </header>

      <section>
        <h3>Experience</h3>
        <div className="t-resume-row">
          <div className="t-resume-when">2024 — now</div>
          <div className="t-resume-what">
            <div className="t-resume-role">Senior Designer · Lattice Labs</div>
            <p>Lead the design system. Built component primitives now used by 6 squads. Shipped a redesign that cut onboarding time in half.</p>
          </div>
        </div>
        <div className="t-resume-row">
          <div className="t-resume-when">2021 — 2024</div>
          <div className="t-resume-what">
            <div className="t-resume-role">Frontend Engineer · Studio Wedge</div>
            <p>Built design tools and prototypes for client work. Shipped two consumer apps from sketch to App Store.</p>
          </div>
        </div>
        <div className="t-resume-row">
          <div className="t-resume-when">2019 — 2021</div>
          <div className="t-resume-what">
            <div className="t-resume-role">Designer · Freelance</div>
            <p>Brand and product work for early-stage companies. Mostly fintech and dev tools.</p>
          </div>
        </div>
      </section>

      <section>
        <h3>Education</h3>
        <div className="t-resume-row">
          <div className="t-resume-when">2017 — 2019</div>
          <div className="t-resume-what">
            <div className="t-resume-role">MSc Human-Computer Interaction</div>
            <p>Thesis: Direct manipulation interfaces for live-coded music.</p>
          </div>
        </div>
      </section>

      <section>
        <h3>Toolkit</h3>
        <div className="t-resume-tags">
          {['TypeScript','React','SwiftUI','CSS','Figma','Rust (learning)','WebAudio','Postgres','Tooling'].map(t => (
            <span key={t} className="t-tag">{t}</span>
          ))}
        </div>
      </section>
    </div>
  );
}

// ─── Contact ───
function ContactApp() {
  const [sent, setSent] = useStateA(false);
  return (
    <div className="t-contact">
      <div className="t-contact-h">
        <h1>Get in touch</h1>
        <p>Send a note, or grab a link below.</p>
      </div>
      <div className="t-contact-row">
        <div className="t-contact-form">
          {!sent ? (
            <form onSubmit={(e) => { e.preventDefault(); setSent(true); }}>
              <label>Name<input type="text" defaultValue=""/></label>
              <label>Email<input type="email" defaultValue=""/></label>
              <label>Message<textarea rows="6" defaultValue=""/></label>
              <button type="submit" className="t-cta">Send</button>
            </form>
          ) : (
            <div className="t-contact-sent">
              <div className="t-contact-checkmark">✓</div>
              <div>Message sent. I'll get back to you.</div>
              <button className="t-btn" onClick={() => setSent(false)}>Send another</button>
            </div>
          )}
        </div>
        <div className="t-contact-side">
          <div className="t-contact-link"><span>Email</span><a href="#">hello@tanyel.example</a></div>
          <div className="t-contact-link"><span>Website</span><a href="#">tanyel.example</a></div>
          <div className="t-contact-link"><span>GitHub</span><a href="#">github.com/tanyel</a></div>
          <div className="t-contact-link"><span>Read</span><a href="#">tanyel.example/notes</a></div>
        </div>
      </div>
    </div>
  );
}

// ─── Image viewer ───
function ImageViewer({ file }) {
  const c = file.content || {};
  return (
    <div className="t-imgview">
      <div
        className="t-imgview-canvas"
        style={{ background: `linear-gradient(135deg, oklch(70% 0.16 ${c.hue || 200}), oklch(45% 0.18 ${((c.hue || 200) + 40) % 360}))` }}
      >
        <div className="t-imgview-placeholder">
          <div className="t-imgview-label">{c.label || file.name}</div>
          <div className="t-imgview-meta">{file.name}</div>
        </div>
      </div>
    </div>
  );
}

// ─── Text/PDF viewer ───
function TextViewer({ file }) {
  if (file.kind === 'pdf') {
    return (
      <div className="t-pdf">
        <div className="t-pdf-page">
          <ResumeApp/>
        </div>
      </div>
    );
  }
  return <div className="t-txt"><MarkdownView content={file.content}/></div>;
}

// ─── Settings ───
function SettingsApp({ tweaks, setTweak }) {
  return (
    <div className="t-settings">
      <div className="t-set-side">
        <div className="t-set-side-item" data-active="1">⌥ Appearance</div>
        <div className="t-set-side-item" data-active="0">⏿ Display</div>
        <div className="t-set-side-item" data-active="0">⌨ Keyboard</div>
        <div className="t-set-side-item" data-active="0">⏻ Power</div>
      </div>
      <div className="t-set-main">
        <h2>Appearance</h2>
        <div className="t-set-group">
          <div className="t-set-row">
            <div>
              <div className="t-set-label">Theme</div>
              <div className="t-set-hint">Light, dark, or follow system.</div>
            </div>
            <div className="t-segmented">
              {['light','dark'].map(v => (
                <button key={v} data-active={tweaks.theme === v ? '1' : '0'} onClick={() => setTweak('theme', v)}>{v}</button>
              ))}
            </div>
          </div>
          <div className="t-set-row">
            <div>
              <div className="t-set-label">Accent color</div>
              <div className="t-set-hint">Used for highlights, focus rings, the dock indicator.</div>
            </div>
            <div className="t-swatches">
              {[
                ['teal',  '195 0.13'],
                ['amber', '60 0.15'],
                ['rose',  '20 0.16'],
                ['violet','290 0.13'],
                ['lime',  '130 0.15'],
              ].map(([name, oklchHC]) => (
                <button
                  key={name}
                  className="t-swatch"
                  data-active={tweaks.accent === name ? '1' : '0'}
                  style={{ background: `oklch(60% ${oklchHC.split(' ')[1]} ${oklchHC.split(' ')[0]})` }}
                  title={name}
                  onClick={() => setTweak('accent', name)}
                />
              ))}
            </div>
          </div>
          <div className="t-set-row">
            <div>
              <div className="t-set-label">Font</div>
              <div className="t-set-hint">Interface typography.</div>
            </div>
            <div className="t-segmented">
              {['Geist','Inter','IBM Plex','JetBrains Mono'].map(v => (
                <button key={v} data-active={tweaks.font === v ? '1' : '0'} onClick={() => setTweak('font', v)}>{v}</button>
              ))}
            </div>
          </div>
        </div>

        <h2 style={{ marginTop: 24 }}>Wallpaper</h2>
        <div className="t-wallpaper-picker">
          {['aurora','dusk','grid','topo','solid'].map(w => (
            <button
              key={w}
              className="t-wp-card"
              data-active={tweaks.wallpaper === w ? '1' : '0'}
              onClick={() => setTweak('wallpaper', w)}
            >
              <div className={`t-wp-thumb t-wp-${w}`}/>
              <div className="t-wp-name">{w}</div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

window.FileExplorer = FileExplorer;
window.AboutApp = AboutApp;
window.ProjectsApp = ProjectsApp;
window.ResumeApp = ResumeApp;
window.ContactApp = ContactApp;
window.ImageViewer = ImageViewer;
window.TextViewer = TextViewer;
window.SettingsApp = SettingsApp;
window.MarkdownView = MarkdownView;
