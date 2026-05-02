// tanyel-windows.jsx — Window manager + draggable Window component

const { useState, useRef, useEffect, useCallback } = React;

// ─── Window manager hook ───
function useWindowManager() {
  const [windows, setWindows] = useState([]);
  const [zCounter, setZCounter] = useState(10);
  const idCounter = useRef(1);

  const open = useCallback((spec) => {
    setWindows(ws => {
      // If app+key already open, focus it instead
      if (spec.singleton) {
        const existing = ws.find(w => w.app === spec.app && w.key === spec.key);
        if (existing) {
          setZCounter(z => z + 1);
          return ws.map(w => w.id === existing.id
            ? { ...w, z: zCounter + 1, minimized: false }
            : w);
        }
      }
      const id = idCounter.current++;
      const z = zCounter + 1;
      setZCounter(z);
      const w = window.innerWidth, h = window.innerHeight;
      const defaultW = spec.width || 720;
      const defaultH = spec.height || 480;
      // cascade
      const offset = (id % 6) * 28;
      return [...ws, {
        id,
        app: spec.app,
        key: spec.key || null,
        title: spec.title || 'Untitled',
        icon: spec.icon || '◇',
        x: spec.x ?? Math.max(20, (w - defaultW) / 2 + offset - 60),
        y: spec.y ?? Math.max(40, (h - defaultH) / 2 + offset - 80),
        width: defaultW,
        height: defaultH,
        z,
        minimized: false,
        maximized: false,
        prevBounds: null,
        props: spec.props || {},
        appData: spec.appData || null,
      }];
    });
  }, [zCounter]);

  const close = useCallback((id) => {
    setWindows(ws => ws.filter(w => w.id !== id));
  }, []);

  const focus = useCallback((id) => {
    setZCounter(z => {
      const next = z + 1;
      setWindows(ws => ws.map(w => w.id === id ? { ...w, z: next, minimized: false } : w));
      return next;
    });
  }, []);

  const minimize = useCallback((id) => {
    setWindows(ws => ws.map(w => w.id === id ? { ...w, minimized: true } : w));
  }, []);

  const toggleMaximize = useCallback((id) => {
    setWindows(ws => ws.map(w => {
      if (w.id !== id) return w;
      if (w.maximized) {
        return { ...w, maximized: false, ...w.prevBounds, prevBounds: null };
      }
      return {
        ...w,
        maximized: true,
        prevBounds: { x: w.x, y: w.y, width: w.width, height: w.height },
        x: 0, y: 28,
        width: window.innerWidth,
        height: window.innerHeight - 28 - 48,
      };
    }));
  }, []);

  const updateBounds = useCallback((id, patch) => {
    setWindows(ws => ws.map(w => w.id === id ? { ...w, ...patch } : w));
  }, []);

  const setProps = useCallback((id, propsPatch) => {
    setWindows(ws => ws.map(w => w.id === id ? { ...w, props: { ...w.props, ...propsPatch } } : w));
  }, []);

  return { windows, open, close, focus, minimize, toggleMaximize, updateBounds, setProps };
}

// ─── Window component ───
function Win({ w, focused, onFocus, onClose, onMinimize, onMaximize, onMove, onResize, children }) {
  const headerRef = useRef(null);
  const drag = useRef(null);

  useEffect(() => {
    const onMM = (e) => {
      if (!drag.current) return;
      const d = drag.current;
      if (d.kind === 'move') {
        const nx = e.clientX - d.dx;
        const ny = Math.max(28, e.clientY - d.dy);
        onMove(w.id, { x: nx, y: ny });
      } else if (d.kind === 'resize') {
        const nw = Math.max(360, d.startW + (e.clientX - d.startX));
        const nh = Math.max(220, d.startH + (e.clientY - d.startY));
        onResize(w.id, { width: nw, height: nh });
      }
    };
    const onMU = () => { drag.current = null; document.body.style.cursor = ''; document.body.style.userSelect = ''; };
    window.addEventListener('mousemove', onMM);
    window.addEventListener('mouseup', onMU);
    return () => { window.removeEventListener('mousemove', onMM); window.removeEventListener('mouseup', onMU); };
  }, [w.id, onMove, onResize]);

  const startDrag = (e) => {
    if (w.maximized) return;
    if (e.target.closest('.win-ctrl')) return;
    onFocus(w.id);
    const rect = e.currentTarget.parentElement.getBoundingClientRect();
    drag.current = { kind: 'move', dx: e.clientX - rect.left, dy: e.clientY - rect.top };
    document.body.style.cursor = 'grabbing';
    document.body.style.userSelect = 'none';
  };

  const startResize = (e) => {
    e.stopPropagation();
    onFocus(w.id);
    drag.current = { kind: 'resize', startX: e.clientX, startY: e.clientY, startW: w.width, startH: w.height };
    document.body.style.userSelect = 'none';
  };

  if (w.minimized) return null;

  return (
    <div
      className="t-win"
      data-focused={focused ? '1' : '0'}
      style={{
        position: 'absolute',
        left: w.x, top: w.y,
        width: w.width, height: w.height,
        zIndex: w.z,
      }}
      onMouseDown={() => onFocus(w.id)}
    >
      <div className="t-win-header" ref={headerRef} onMouseDown={startDrag} onDoubleClick={() => onMaximize(w.id)}>
        <div className="t-win-ctrls">
          <button className="win-ctrl c-close" onClick={() => onClose(w.id)} aria-label="Close"/>
          <button className="win-ctrl c-min" onClick={() => onMinimize(w.id)} aria-label="Minimize"/>
          <button className="win-ctrl c-max" onClick={() => onMaximize(w.id)} aria-label="Maximize"/>
        </div>
        <div className="t-win-title"><span className="t-win-icon">{w.icon}</span>{w.title}</div>
        <div style={{ width: 60 }}/>
      </div>
      <div className="t-win-body">{children}</div>
      {!w.maximized && <div className="t-win-resize" onMouseDown={startResize}/>}
    </div>
  );
}

window.useWindowManager = useWindowManager;
window.Win = Win;
