// tanyel-terminal.jsx — Working terminal for TanyelOS

const { useState: useStateT, useRef: useRefT, useEffect: useEffectT } = React;

function Terminal({ fs, setFs, openFile }) {
  const [lines, setLines] = useStateT(() => [
    { kind: 'sys', text: 'TanyelOS terminal · type `help` for commands' },
    { kind: 'sys', text: '' },
  ]);
  const [cwd, setCwd] = useStateT(['~']);
  const [input, setInput] = useStateT('');
  const [history, setHistory] = useStateT([]);
  const [histIdx, setHistIdx] = useStateT(-1);
  const inputRef = useRefT(null);
  const scrollRef = useRefT(null);

  useEffectT(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [lines]);

  const print = (text, kind = 'out') => {
    const arr = String(text).split('\n');
    setLines(ls => [...ls, ...arr.map(t => ({ kind, text: t }))]);
  };

  const promptStr = () => `tanyel@tanyel-os:${window.TanyelFS.pathToString(cwd)}$ `;

  const run = (rawCmd) => {
    const cmd = rawCmd.trim();
    setLines(ls => [...ls, { kind: 'prompt', text: promptStr() + rawCmd }]);
    if (!cmd) return;
    setHistory(h => [...h, cmd]);

    const parts = cmd.match(/(?:[^\s"]+|"[^"]*")+/g)?.map(p => p.replace(/^"|"$/g, '')) || [];
    const [c, ...args] = parts;
    const { getNode, parsePath, pathToString } = window.TanyelFS;

    switch (c) {
      case 'help':
        print(['Available commands:',
          '  ls [path]            list directory contents',
          '  cd [path]            change directory',
          '  pwd                  print working directory',
          '  cat <file>           print file contents',
          '  mkdir <name>         make a directory',
          '  touch <name>         create empty file',
          '  rm <name>            remove file',
          '  rmdir <name>         remove empty directory',
          '  echo <text>          print text',
          '  clear                clear screen',
          '  neofetch             system info',
          '  whoami               print user',
          '  date                 current date/time',
          '  ps                   list "running" apps',
          '  open <file>          open file in its app',
          '  help                 this message',
        ].join('\n'));
        break;
      case 'pwd':
        print(pathToString(cwd));
        break;
      case 'whoami':
        print('tanyel');
        break;
      case 'date':
        print(new Date().toString());
        break;
      case 'echo':
        print(args.join(' '));
        break;
      case 'clear':
        setLines([]);
        break;
      case 'ls': {
        const target = args[0] ? parsePath(args[0], cwd) : cwd;
        const node = getNode(fs, target);
        if (!node) { print(`ls: ${args[0]}: no such file or directory`, 'err'); break; }
        if (node.type === 'file') { print(node.name); break; }
        const entries = Object.values(node.children).sort((a,b) => {
          if (a.type !== b.type) return a.type === 'dir' ? -1 : 1;
          return a.name.localeCompare(b.name);
        });
        print(entries.map(e => e.type === 'dir' ? e.name + '/' : e.name).join('  ') || '(empty)');
        break;
      }
      case 'cd': {
        if (!args[0] || args[0] === '~') { setCwd(['~']); break; }
        const target = parsePath(args[0], cwd);
        const node = getNode(fs, target);
        if (!node) { print(`cd: ${args[0]}: no such directory`, 'err'); break; }
        if (node.type !== 'dir') { print(`cd: ${args[0]}: not a directory`, 'err'); break; }
        setCwd(target);
        break;
      }
      case 'cat': {
        if (!args[0]) { print('cat: missing file', 'err'); break; }
        const target = parsePath(args[0], cwd);
        const node = getNode(fs, target);
        if (!node) { print(`cat: ${args[0]}: no such file`, 'err'); break; }
        if (node.type === 'dir') { print(`cat: ${args[0]}: is a directory`, 'err'); break; }
        if (node.kind === 'md' || node.kind === 'txt') print(node.content);
        else print(`(binary file — ${node.kind})`);
        break;
      }
      case 'mkdir': {
        if (!args[0]) { print('mkdir: missing name', 'err'); break; }
        const parent = getNode(fs, cwd);
        if (parent.children[args[0]]) { print(`mkdir: ${args[0]}: exists`, 'err'); break; }
        setFs(prev => {
          const copy = JSON.parse(JSON.stringify(prev));
          const p = getNode(copy, cwd);
          p.children[args[0]] = { type: 'dir', name: args[0], children: {} };
          return copy;
        });
        break;
      }
      case 'touch': {
        if (!args[0]) { print('touch: missing name', 'err'); break; }
        setFs(prev => {
          const copy = JSON.parse(JSON.stringify(prev));
          const p = getNode(copy, cwd);
          if (!p.children[args[0]]) {
            p.children[args[0]] = { type: 'file', name: args[0], kind: 'txt', icon: '📄', content: '' };
          }
          return copy;
        });
        break;
      }
      case 'rm': {
        if (!args[0]) { print('rm: missing name', 'err'); break; }
        const p = getNode(fs, cwd);
        if (!p.children[args[0]]) { print(`rm: ${args[0]}: no such file`, 'err'); break; }
        if (p.children[args[0]].type === 'dir') { print(`rm: ${args[0]}: is a directory (use rmdir)`, 'err'); break; }
        setFs(prev => {
          const copy = JSON.parse(JSON.stringify(prev));
          delete getNode(copy, cwd).children[args[0]];
          return copy;
        });
        break;
      }
      case 'rmdir': {
        if (!args[0]) { print('rmdir: missing name', 'err'); break; }
        const p = getNode(fs, cwd);
        const t = p.children[args[0]];
        if (!t) { print(`rmdir: ${args[0]}: no such directory`, 'err'); break; }
        if (t.type !== 'dir') { print(`rmdir: ${args[0]}: not a directory`, 'err'); break; }
        if (Object.keys(t.children).length) { print(`rmdir: ${args[0]}: not empty`, 'err'); break; }
        setFs(prev => {
          const copy = JSON.parse(JSON.stringify(prev));
          delete getNode(copy, cwd).children[args[0]];
          return copy;
        });
        break;
      }
      case 'neofetch': {
        const ascii = [
          '   ▄▄▄▄▄▄▄   ',
          ' ▄█████████▄ ',
          '█████████████',
          '████ TOS ████',
          '█████████████',
          ' ▀█████████▀ ',
          '   ▀▀▀▀▀▀▀   ',
        ];
        const info = [
          'tanyel@tanyel-os',
          '----------------',
          'OS:       TanyelOS 1.0',
          'Host:     web (' + (navigator.userAgent.includes('Chrome') ? 'Chromium' : 'Browser') + ')',
          'Kernel:   react-18.3.1',
          'Shell:    tsh 0.1',
          'Theme:    ' + (document.documentElement.dataset.theme || 'light'),
          'Uptime:   ' + Math.round(performance.now() / 1000) + 's',
        ];
        const out = [];
        const max = Math.max(ascii.length, info.length);
        for (let i = 0; i < max; i++) {
          out.push((ascii[i] || '             ') + '  ' + (info[i] || ''));
        }
        print(out.join('\n'), 'neofetch');
        break;
      }
      case 'ps':
        print(['  PID  APP', '  101  desktop', '  102  taskbar', '  103  terminal', '  104  window-mgr'].join('\n'));
        break;
      case 'open': {
        if (!args[0]) { print('open: missing file', 'err'); break; }
        const target = parsePath(args[0], cwd);
        const node = getNode(fs, target);
        if (!node) { print(`open: ${args[0]}: not found`, 'err'); break; }
        openFile(node, target);
        break;
      }
      default:
        print(`tsh: command not found: ${c}`, 'err');
    }
  };

  const onKey = (e) => {
    if (e.key === 'Enter') {
      run(input);
      setInput('');
      setHistIdx(-1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (history.length === 0) return;
      const idx = histIdx === -1 ? history.length - 1 : Math.max(0, histIdx - 1);
      setHistIdx(idx);
      setInput(history[idx]);
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (histIdx === -1) return;
      const idx = histIdx + 1;
      if (idx >= history.length) { setHistIdx(-1); setInput(''); }
      else { setHistIdx(idx); setInput(history[idx]); }
    } else if (e.key === 'l' && e.ctrlKey) {
      e.preventDefault(); setLines([]);
    }
  };

  return (
    <div className="t-terminal" onClick={() => inputRef.current?.focus()} ref={scrollRef}>
      {lines.map((l, i) => (
        <div key={i} className={`t-line t-line-${l.kind}`}>{l.text || '\u00A0'}</div>
      ))}
      <div className="t-line t-line-input">
        <span className="t-prompt">{promptStr()}</span>
        <input
          ref={inputRef}
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={onKey}
          autoFocus
          spellCheck={false}
        />
      </div>
    </div>
  );
}

window.Terminal = Terminal;
