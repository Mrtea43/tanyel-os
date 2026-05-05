// tanyel-fs.jsx — Virtual filesystem for TanyelOS
// Tree of nodes; mutable but lives in memory. Used by Files + Terminal.

const initialFS = {
  type: 'dir',
  name: '~',
  children: {
    'about.md': {
      type: 'file', name: 'about.md', kind: 'md', icon: '📄',
      content: `# About Tanyel

Designer-engineer based on the internet.
I build interfaces that feel like tools, not toys.

## Currently
- Designing systems at a small product team
- Tinkering with TanyelOS (the thing you're using)
- Picking up rust, slowly

## Previously
- Frontend lead at two startups
- Studied HCI

> "Make the boring parts beautiful and the clever parts invisible."
`,
    },
    'resume.pdf': {
      type: 'file', name: 'resume.pdf', kind: 'pdf', icon: '📕',
      content: 'resume',
    },
    'contact.card': {
      type: 'file', name: 'contact.card', kind: 'contact', icon: '✉',
      content: 'contact',
    },
    'projects': {
      type: 'dir', name: 'projects',
      children: {
        'synth-lab': {
          type: 'dir', name: 'synth-lab',
          children: {
            'readme.md': { type: 'file', name: 'readme.md', kind: 'md', icon: '📄',
              content: `# Synth Lab\n\nA browser-based modular synthesizer.\nWebAudio + custom node graph editor.\n\n**Stack:** TypeScript · WebAudio · Canvas\n**Year:** 2024`},
            'hero.png': { type: 'file', name: 'hero.png', kind: 'image', icon: '🖼',
              content: { hue: 200, label: 'synth-lab' } },
            'demo.mp4': { type: 'file', name: 'demo.mp4', kind: 'video', icon: '◐',
              content: 'demo'},
          }
        },
        'tanyel-os': {
          type: 'dir', name: 'tanyel-os',
          children: {
            'readme.md': { type: 'file', name: 'readme.md', kind: 'md', icon: '📄',
              content: `# TanyelOS\n\nA desktop-OS-as-portfolio.\nEverything is a window. The terminal works.\n\n**Stack:** React · CSS\n**Year:** 2026 (you are here)`},
            'screenshot.png': { type: 'file', name: 'screenshot.png', kind: 'image', icon: '🖼',
              content: { hue: 25, label: 'tanyel-os' } },
          }
        },
        'paper-ui': {
          type: 'dir', name: 'paper-ui',
          children: {
            'readme.md': { type: 'file', name: 'readme.md', kind: 'md', icon: '📄',
              content: `# Paper UI\n\nA tiny component library that makes web pages feel handmade.\nLow-fidelity styling for hi-fidelity ideas.\n\n**Stack:** CSS · A pinch of JS\n**Year:** 2023`},
            'cover.png': { type: 'file', name: 'cover.png', kind: 'image', icon: '🖼',
              content: { hue: 80, label: 'paper-ui' } },
          }
        },
        'fieldnotes': {
          type: 'dir', name: 'fieldnotes',
          children: {
            'readme.md': { type: 'file', name: 'readme.md', kind: 'md', icon: '📄',
              content: `# Fieldnotes\n\nA writing app for people who read on the train.\nMarkdown-first. No cloud.\n\n**Stack:** Swift · macOS\n**Year:** 2023`},
            'cover.png': { type: 'file', name: 'cover.png', kind: 'image', icon: '🖼',
              content: { hue: 320, label: 'fieldnotes' } },
          }
        },
      }
    },
    'pictures': {
      type: 'dir', name: 'pictures',
      children: {
        'wallpaper-01.png': { type: 'file', name: 'wallpaper-01.png', kind: 'image', icon: '🖼', content: { hue: 200, label: 'wp-01' } },
        'wallpaper-02.png': { type: 'file', name: 'wallpaper-02.png', kind: 'image', icon: '🖼', content: { hue: 30, label: 'wp-02' } },
      }
    },
    '.config': {
      type: 'dir', name: '.config',
      children: {
        'theme.conf': { type: 'file', name: 'theme.conf', kind: 'txt', icon: '⚙', content: 'theme=auto\naccent=teal\nfont=geist' },
      }
    },
  }
};

// Path helpers — paths are arrays of segments, with '~' as root.
function getNode(fs, pathArr) {
  let node = fs;
  for (const seg of pathArr) {
    if (seg === '~' || seg === '') continue;
    if (node.type !== 'dir' || !node.children[seg]) return null;
    node = node.children[seg];
  }
  return node;
}

function pathToString(pathArr) {
  if (pathArr.length === 0 || (pathArr.length === 1 && pathArr[0] === '~')) return '~';
  return pathArr.join('/');
}

function parsePath(str, cwd) {
  if (!str) return cwd.slice();
  if (str.startsWith('/')) {
    return ['~', ...str.split('/').filter(Boolean)];
  }
  if (str === '~' || str.startsWith('~/') || str === '~') {
    return ['~', ...str.slice(2).split('/').filter(Boolean)];
  }
  let result = cwd.slice();
  for (const seg of str.split('/').filter(Boolean)) {
    if (seg === '.') continue;
    if (seg === '..') { if (result.length > 1) result.pop(); continue; }
    result.push(seg);
  }
  return result;
}

window.TanyelFS = { initialFS, getNode, pathToString, parsePath };
