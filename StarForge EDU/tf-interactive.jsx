// tf-interactive.jsx — Fully interactive prototype phone
// Single iPhone frame, smooth screen transitions, working tabs and detail nav.
// Reads palette/dark from the canvas-level wrapper (data-palette/data-theme).

function InteractivePhone() {
  // Tab state — switches root view
  const [tab, setTab] = React.useState('home');
  // Overlay stack — sub-screens slid in from right.
  // Each entry: { id, key, state: 'entering'|'live'|'leaving' }
  const [stack, setStack] = React.useState([]);
  const keyRef = React.useRef(0);

  const push = (id) => {
    const key = ++keyRef.current;
    setStack(s => [...s, { id, key, state: 'entering' }]);
    // promote to live next frame so CSS transition fires
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        setStack(s => s.map(x => x.key === key ? { ...x, state: 'live' } : x));
      });
    });
  };

  const pop = () => {
    setStack(s => {
      if (!s.length) return s;
      const top = s[s.length - 1];
      const next = s.slice(0, -1);
      next.push({ ...top, state: 'leaving' });
      return next;
    });
    setTimeout(() => {
      setStack(s => s.filter(x => x.state !== 'leaving'));
    }, 320);
  };

  const switchTab = (t) => {
    if (t === tab) return;
    setStack([]);
    setTab(t);
  };

  return (
    <div className="ip-root">
      <style>{ipStyles}</style>
      <div className="ip-phone">
        {/* Status bar */}
        <div className="ip-status">
          <span>09:42</span>
          <div className="ip-notch" />
          <div className="ip-status-r">
            <span style={{ fontSize: 11 }}>5G</span>
            <span style={{
              display: 'inline-block', width: 22, height: 11, border: '1px solid currentColor',
              borderRadius: 2.5, position: 'relative',
            }}>
              <span style={{ position: 'absolute', inset: 1, width: '70%',
                              background: 'currentColor', borderRadius: 1 }} />
            </span>
          </div>
        </div>

        {/* View viewport */}
        <div className="ip-viewport">
          {/* Root tabs — crossfade */}
          <div key={tab} className="ip-root-view">
            {tab === 'home'   && <Home   push={push} switchTab={switchTab} />}
            {tab === 'cohort' && <Cohort push={push} />}
            {tab === 'tasks'  && <Tasks  push={push} />}
            {tab === 'ai'     && <Ai     push={push} />}
            {tab === 'print'  && <Print  push={push} />}
          </div>
          {/* Overlay stack */}
          {stack.map((s, i) => (
            <div key={s.key} className={`ip-overlay ${s.state}`}>
              <Overlay id={s.id} push={push} pop={pop} switchTab={switchTab} />
            </div>
          ))}
        </div>

        {/* Tab bar */}
        <div className="ip-tabs">
          {[
            { id: 'home',   l: 'Bugun',    icon: Icons.home },
            { id: 'cohort', l: 'Guruhlar', icon: Icons.cohort },
            { id: 'tasks',  l: 'Vazifa',   icon: Icons.check },
            { id: 'ai',     l: 'AI',       icon: Icons.ai },
            { id: 'print',  l: 'Print',    icon: Icons.print },
          ].map(t => (
            <button key={t.id} className="ip-tab" data-on={tab === t.id ? '1' : '0'}
                    onClick={() => switchTab(t.id)}>
              <div className="ip-tab-icon-wrap">
                {tab === t.id && <div className="ip-tab-bg" />}
                <div className="ip-tab-icon">{React.cloneElement(t.icon, { size: 22 })}</div>
              </div>
              <span>{t.l}</span>
            </button>
          ))}
        </div>

        <div className="ip-home-indicator" />
      </div>
    </div>
  );
}

// ─── Overlay router
function Overlay({ id, push, pop, switchTab }) {
  if (id === 'survey-list')  return <SurveyList  pop={pop} push={push} />;
  if (id === 'survey-form')  return <SurveyForm  pop={pop} />;
  if (id === 'cohort-detail') return <CohortDetail pop={pop} push={push} />;
  if (id === 'student')      return <Student     pop={pop} push={push} />;
  if (id === 'give-card')    return <GiveCard    pop={pop} />;
  if (id === 'task-detail')  return <TaskDetail  pop={pop} />;
  if (id === 'ai-chat')      return <AiChat      pop={pop} />;
  if (id === 'new-print')    return <NewPrint    pop={pop} />;
  if (id === 'mgmt-chat')    return <MgmtChat    pop={pop} />;
  if (id === 'profile')      return <Profile     pop={pop} push={push} />;
  if (id === 'attendance')   return <Attendance  pop={pop} />;
  return <div style={{ padding: 20 }}>Topilmadi: {id}</div>;
}

// ════════════════════════════════════════════════════════════════
// SCREENS
// ════════════════════════════════════════════════════════════════

function Home({ push, switchTab }) {
  return (
    <div className="ip-scroll">
      {/* Header */}
      <div className="ip-header">
        <div className="ip-header-row">
          <div onClick={() => push('profile')} style={{ display: 'flex', gap: 10, alignItems: 'center', cursor: 'pointer' }}>
            <SfAvatar name="Nigora Karimova" size={36} color="var(--sf-primary)" />
            <div>
              <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>Seshanba · 19 May</div>
              <div style={{ fontSize: 15, fontWeight: 700 }}>Bugun, Nigora opa</div>
            </div>
          </div>
          <button className="ip-icon-btn" onClick={() => push('mgmt-chat')}>
            {React.cloneElement(Icons.bell, { size: 18 })}
            <span className="ip-dot" />
          </button>
        </div>
      </div>

      <div className="ip-body">
        {/* Survey banner (pulse) */}
        <button className="ip-survey" onClick={() => push('survey-list')}>
          <div className="ip-survey-glow" />
          <span className="ip-pulse-dot" />
          <div style={{ flex: 1, textAlign: 'left' }}>
            <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.08em',
                            textTransform: 'uppercase', color: 'var(--sf-danger)' }}>
              So‘rovnoma · 2 kun 14 soat qoldi
            </div>
            <div style={{ marginTop: 1, fontSize: 13.5, fontWeight: 700 }}>
              Oylik o‘qituvchi qoniqishi
            </div>
            <div style={{ fontSize: 10.5, color: 'var(--sf-ink-2)' }}>33% · davom etish</div>
          </div>
          {React.cloneElement(Icons.arrowR, { size: 14 })}
        </button>

        {/* Next lesson hero */}
        <div className="ip-hero" onClick={() => push('attendance')}>
          <SfStar size={140} color="#FFFCF5" style={{ position: 'absolute', right: -30, top: -30, opacity: 0.18 }} />
          <div style={{ position: 'relative' }}>
            <div style={{ fontSize: 10, letterSpacing: '0.14em', textTransform: 'uppercase',
                            fontWeight: 700, opacity: 0.85 }}>Keyingi · 14 daq</div>
            <div style={{ marginTop: 4, fontSize: 22, fontWeight: 800, letterSpacing: '-0.02em' }}>
              Algebra · 9-B
            </div>
            <div style={{ marginTop: 2, fontSize: 12, opacity: 0.9 }}>09:00 – 09:45 · Xona 304</div>
            <div className="ip-hero-cta">
              {React.cloneElement(Icons.check, { size: 14 })}
              Davomat olish
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="ip-stats">
          {[
            { v: '4', l: 'Dars', sub: '/5' },
            { v: '94', l: 'Davomat', sub: '%', c: 'var(--sf-success)' },
            { v: '↑8↓2', l: 'Kartalar', c: '#7A4F0E' },
          ].map((s, i) => (
            <div key={i} className="ip-stat">
              <span className="sf-mono" style={{ fontSize: 16, fontWeight: 700, color: s.c || 'var(--sf-ink)' }}>{s.v}</span>
              {s.sub && <span style={{ fontSize: 10, color: 'var(--sf-muted)', fontWeight: 600 }}>{s.sub}</span>}
              <div className="ip-stat-l">{s.l}</div>
            </div>
          ))}
        </div>

        {/* AI banner */}
        <button className="ip-ai-banner" onClick={() => switchTab('ai')}>
          <SfAiBadge>Ko‘rib chiqing</SfAiBadge>
          <div className="ip-ai-quote">
            “Otabekka oxirgi haftada 2 ta Down karta berildi. Ota bilan suhbat tavsiya etiladi.”
          </div>
          {React.cloneElement(Icons.arrowR, { size: 14 })}
        </button>

        {/* Recent cards (tappable to give-card) */}
        <div className="ip-section">
          <div className="ip-section-h">
            <h3>So‘nggi kartalar</h3>
            <span>10 ta ›</span>
          </div>
          <div className="ip-cards-strip">
            <div onClick={() => push('give-card')} style={{ cursor: 'pointer' }}>
              <SfCard kind="up" size="sm" recipient="Akbarov A." reason="Mustaqil yechim" issuer="N.K." when="09:42" typeName="Yulduz" />
            </div>
            <div onClick={() => push('give-card')} style={{ cursor: 'pointer' }}>
              <SfCard kind="up" size="sm" recipient="Halimova Z." reason="Aktivlik" issuer="N.K." when="09:38" typeName="Aktivlik" />
            </div>
            <div onClick={() => push('give-card')} style={{ cursor: 'pointer' }}>
              <SfCard kind="down" size="sm" recipient="Eshmatov O." reason="Uy ishi yo‘q" issuer="N.K." when="09:12" typeName="Ogohl." />
            </div>
          </div>
        </div>

        {/* Print queue card */}
        <button className="ip-card-btn" onClick={() => switchTab('print')}>
          <div className="ip-icon-square" style={{ background: 'var(--sf-primary-soft)', color: 'var(--sf-primary)' }}>
            {React.cloneElement(Icons.print, { size: 20 })}
            <div className="ip-badge">2</div>
          </div>
          <div style={{ flex: 1, textAlign: 'left' }}>
            <div style={{ fontSize: 13.5, fontWeight: 700 }}>Print navbati · 2 ta</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
              Kvadrat tenglamalar · <span style={{ color: 'var(--sf-success)', fontWeight: 600 }}>64% tugadi</span>
            </div>
          </div>
          {React.cloneElement(Icons.chevR, { size: 16 })}
        </button>
      </div>
    </div>
  );
}

function Cohort({ push }) {
  const groups = [
    { id: 1, n: '9-B Algebra', l: 'Daraja II', cnt: 24, att: 94, color: 'var(--sf-primary)' },
    { id: 2, n: 'Algebra Mid', l: 'Daraja II', cnt: 21, att: 96, color: 'var(--sf-primary)' },
    { id: 3, n: '10-V Geometriya', l: 'Daraja III', cnt: 19, att: 88, color: 'var(--sf-accent)' },
  ];
  return (
    <div className="ip-scroll">
      <div className="ip-header">
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em' }}>Guruhlar</div>
        <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>3 ta · 58 o‘quvchi · 2 fan</div>
      </div>
      <div className="ip-body">
        {groups.map(g => (
          <button key={g.id} className="ip-card-btn" onClick={() => push('cohort-detail')}>
            <div className="ip-icon-square" style={{ background: g.color, color: '#FFFCF5' }}>
              <SfStar size={20} color="#FFFCF5" />
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>{g.n}</div>
              <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{g.l} · {g.cnt} o‘quvchi</div>
              <div style={{ marginTop: 4, display: 'flex', gap: 10, fontSize: 11 }}>
                <span><span className="sf-mono" style={{
                  color: g.att >= 92 ? 'var(--sf-success)' : 'var(--sf-warn)', fontWeight: 700 }}>{g.att}%</span> davomat</span>
              </div>
            </div>
            {React.cloneElement(Icons.chevR, { size: 16 })}
          </button>
        ))}
      </div>
    </div>
  );
}

function Tasks({ push }) {
  const tasks = [
    { id: 1, t: 'May oyi yakuniy hisoboti', proj: 'Hisobot', projColor: 'var(--sf-primary)', dl: 'Erta · 18:00', urgent: true, mgmt: true, pri: 'P1' },
    { id: 2, t: 'Slaydlarni yangilash', proj: 'Materiallar', projColor: 'var(--sf-accent)', dl: 'Pen · 23:59', pri: 'P2' },
    { id: 3, t: 'AI sifat baholash', proj: 'So‘rovnoma', projColor: 'var(--sf-ai)', dl: '22.05', mgmt: true, pri: 'P2' },
    { id: 4, t: 'Olimpiada tayyorgarligi', proj: 'Tayyorlov', projColor: 'var(--sf-ink-2)', dl: '25.05', mgmt: true, pri: 'P3' },
  ];
  return (
    <div className="ip-scroll">
      <div className="ip-header">
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em' }}>Vazifalar</div>
        <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>3 bugun · 2 boshqaruvdan</div>
      </div>
      <div className="ip-body">
        {tasks.map(t => (
          <button key={t.id} className="ip-task" onClick={() => push('task-detail')}>
            <div className="ip-task-rail" style={{ background: t.urgent ? 'var(--sf-danger)' : t.projColor }} />
            <div style={{ paddingLeft: 8, flex: 1, textAlign: 'left' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                <div className="ip-check" />
                {t.mgmt && <span className="ip-tag ip-tag-dark">BOSHQARUV</span>}
                <span style={{ flex: 1 }} />
                <span className="sf-mono" style={{
                  fontSize: 10, fontWeight: 700,
                  color: t.pri === 'P1' ? 'var(--sf-danger)' : t.pri === 'P2' ? 'var(--sf-warn)' : 'var(--sf-muted)',
                }}>{t.pri}</span>
              </div>
              <div style={{ marginTop: 6, fontSize: 13.5, fontWeight: 600 }}>{t.t}</div>
              <div style={{ marginTop: 6, display: 'flex', gap: 10, alignItems: 'center',
                              fontSize: 11, color: 'var(--sf-muted)' }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <span style={{ width: 8, height: 8, borderRadius: 2, background: t.projColor }} />
                  {t.proj}
                </span>
                <span style={{ flex: 1 }} />
                <span className="sf-mono" style={{
                  color: t.urgent ? 'var(--sf-danger)' : 'var(--sf-ink-2)',
                  fontWeight: t.urgent ? 700 : 500,
                }}>{t.dl}</span>
              </div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function Ai({ push }) {
  const groups = [
    { n: '9-B Algebra', sub: '24 o‘quvchi', preview: '“Bu hafta sinf umuman barqaror. 2 ta o‘quvchi diqqat talab qiladi…”', color: 'var(--sf-primary)' },
    { n: 'Algebra Mid', sub: '21 o‘quvchi', preview: '“Davronova S. va Halimova Z. olimpiada darajasi…”', color: 'var(--sf-primary)' },
    { n: '10-V Geometriya', sub: '19 o‘quvchi', preview: '“Trapetsiya mavzusi yaxshi tushunilgan…”', color: 'var(--sf-accent)' },
  ];
  return (
    <div className="ip-scroll">
      <div className="ip-header">
        <SfAiBadge>Yordamchi</SfAiBadge>
        <div style={{ marginTop: 8, fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em' }}>Suhbat</div>
        <div style={{ marginTop: 2, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                       fontSize: 15, color: 'var(--sf-muted)' }}>guruhlaringiz haqida</div>
      </div>
      <div className="ip-body">
        {groups.map((g, i) => (
          <button key={i} className="ip-card-btn ip-ai-row" onClick={() => push('ai-chat')}>
            <div className="ip-icon-square" style={{ background: g.color, color: '#FFFCF5' }}>
              <SfStar size={20} color="#FFFCF5" />
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>{g.n}</div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>{g.sub}</div>
              <div className="ip-ai-preview">{g.preview}</div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

function Print({ push }) {
  return (
    <div className="ip-scroll">
      <div className="ip-header">
        <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em' }}>Print</div>
        <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>Yunusobod · 3 printer</div>
      </div>
      <div className="ip-body">
        {/* My queue */}
        <div className="ip-section-h"><h3>Mening navbatim</h3><span>2 ta</span></div>
        <div className="ip-card-soft">
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <div className="ip-doc-thumb">
              {React.cloneElement(Icons.doc, { size: 18 })}
              <div className="ip-doc-mult">×24</div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>Kvadrat tenglamalar</div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>HP LaserJet · A4 B/W</div>
            </div>
            <SfPill tone="primary">Chop</SfPill>
          </div>
          <div className="ip-progress">
            <div className="ip-progress-fill" style={{ width: '64%' }} />
          </div>
          <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>Tugaydi · 11:24</div>
        </div>

        {/* Printers */}
        <div className="ip-section-h" style={{ marginTop: 8 }}><h3>Printerlar</h3></div>
        {[
          { n: 'HP LaserJet M404n', loc: 'Lobbi · 1-qavat', st: 'Bo‘sh', stTone: 'success', c: 'var(--sf-success)' },
          { n: 'Xerox WorkCentre', loc: '2-qavat dahliz', st: '2 navbat', stTone: 'accent', c: 'var(--sf-warn)' },
          { n: 'Brother DCP-L', loc: 'Direktor xonasi', st: 'Yopiq', stTone: 'neutral', c: 'var(--sf-muted)' },
        ].map((p, i) => (
          <button key={i} className="ip-card-btn">
            <div className="ip-icon-square" style={{ background: 'var(--sf-surface-2)', color: p.c, position: 'relative' }}>
              {React.cloneElement(Icons.print, { size: 20 })}
              <span style={{ position: 'absolute', bottom: 4, right: 4, width: 8, height: 8,
                              borderRadius: '50%', background: p.c, border: '1.5px solid var(--sf-surface)' }} />
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 13.5, fontWeight: 700 }}>{p.n}</div>
              <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{p.loc}</div>
            </div>
            <SfPill tone={p.stTone}>{p.st}</SfPill>
          </button>
        ))}

        <button className="ip-cta" onClick={() => push('new-print')}>
          {React.cloneElement(Icons.plus, { size: 18 })} Yangi chop etish
        </button>
      </div>
    </div>
  );
}

// ─── Overlay screens (slid in from right) ─────────────────────

function OverlayHeader({ pop, title, right }) {
  return (
    <div className="ip-overlay-hdr">
      <button className="ip-back" onClick={pop}>
        {React.cloneElement(Icons.arrowL, { size: 18 })}
      </button>
      <div className="ip-overlay-title">{title}</div>
      <div className="ip-overlay-right">{right}</div>
    </div>
  );
}

function SurveyList({ pop, push }) {
  return (
    <>
      <OverlayHeader pop={pop} title="So‘rovnomalar" />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body" style={{ paddingTop: 12 }}>
          <button className="ip-survey-big" onClick={() => push('survey-form')}>
            <div className="ip-survey-glow" />
            <div style={{ position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <span className="ip-pulse-dot" />
                  <span style={{ padding: '3px 8px', borderRadius: 4, background: 'var(--sf-ink)',
                                  color: 'var(--sf-bg)', fontSize: 10, fontWeight: 700 }}>⏰ Shoshilinch</span>
                </div>
                <span style={{ fontSize: 11, color: 'var(--sf-danger)', fontWeight: 700 }}>2k 14s</span>
              </div>
              <div style={{ marginTop: 10, fontSize: 17, fontWeight: 700, lineHeight: 1.2 }}>
                Oylik o‘qituvchi qoniqishi
              </div>
              <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-ink-2)' }}>
                Karimova R. · Direktor · 22.05 · 12 savol
              </div>
              <div className="ip-survey-cta">
                4/12 javob berildi
                <span style={{ flex: 1 }} />
                Davom etish {React.cloneElement(Icons.arrowR, { size: 12 })}
              </div>
            </div>
          </button>

          <button className="ip-survey-big" style={{ background: 'var(--sf-surface)',
                                                       border: '1px solid var(--sf-border)',
                                                       boxShadow: 'var(--sf-shadow-sm)' }}>
            <div style={{ position: 'relative' }}>
              <span style={{ padding: '3px 8px', borderRadius: 4, background: 'var(--sf-surface-2)',
                              color: 'var(--sf-muted)', fontSize: 10, fontWeight: 700 }}>YANGI</span>
              <div style={{ marginTop: 10, fontSize: 17, fontWeight: 700, lineHeight: 1.2 }}>
                Karta tizimi · taklif va e‘tirozlar
              </div>
              <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-muted)' }}>
                Ahmedov B. · 26.05 · 8 savol
              </div>
            </div>
          </button>
        </div>
      </div>
    </>
  );
}

function SurveyForm({ pop }) {
  const [val, setVal] = React.useState(8);
  return (
    <>
      <div className="ip-overlay-hdr">
        <button className="ip-back" onClick={pop}>Saqlab chiqish</button>
        <div className="ip-overlay-title">5 / 12</div>
        <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-danger)', fontWeight: 700 }}>2k 14s</span>
      </div>
      <div style={{ padding: '0 18px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 3, paddingBottom: 12 }}>
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={i} style={{ flex: 1, height: 3, borderRadius: 3,
                                    background: i < 5 ? 'var(--sf-primary)' : 'var(--sf-surface-2)' }} />
          ))}
        </div>
      </div>
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body" style={{ paddingTop: 16 }}>
          <div style={{ fontSize: 10.5, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>
            5-savol
          </div>
          <div style={{ marginTop: 8, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                          fontSize: 22, lineHeight: 1.25 }}>
            AI yordamchining tavsiyalari sizning ishingizga qanchalik foydali bo‘ldi?
          </div>
          <div style={{ marginTop: 20, display: 'flex', gap: 4 }}>
            {[1,2,3,4,5,6,7,8,9,10].map(n => (
              <button key={n} onClick={() => setVal(n)} style={{
                flex: 1, height: 32, borderRadius: 8, cursor: 'pointer',
                background: n === val ? 'var(--sf-primary)' : 'var(--sf-surface)',
                color: n === val ? '#FFFCF5' : 'var(--sf-ink-2)',
                border: n === val ? 'none' : '1px solid var(--sf-border)',
                fontFamily: 'var(--sf-font-mono)', fontSize: 12, fontWeight: 700,
                boxShadow: n === val ? '0 4px 12px rgba(184,85,53,0.3)' : 'none',
                transition: 'all 0.15s',
              }}>{n}</button>
            ))}
          </div>
          <div style={{ marginTop: 6, display: 'flex', justifyContent: 'space-between', fontSize: 10, color: 'var(--sf-muted)' }}>
            <span>Foyda yo‘q</span><span>Juda foydali</span>
          </div>
          <div className="ip-anon">
            {React.cloneElement(Icons.shield, { size: 14 })}
            <span><strong>Anonim:</strong> markaz faqat jamlangan natijani ko‘radi.</span>
          </div>
        </div>
      </div>
      <div className="ip-footer">
        <button className="ip-btn-ghost" style={{ width: 50 }}>{React.cloneElement(Icons.arrowL, { size: 16 })}</button>
        <button className="ip-btn-primary" onClick={pop}>
          Keyingisi {React.cloneElement(Icons.arrowR, { size: 16 })}
        </button>
      </div>
    </>
  );
}

function CohortDetail({ pop, push }) {
  const roster = [
    { n: 'Akbarov Akmal', up: 8, down: 0, att: 96, t: 'top' },
    { n: 'Azizova Madina', up: 6, down: 0, att: 98, t: 'top' },
    { n: 'Bakirov Sherzod', up: 2, down: 2, att: 88 },
    { n: 'Eshmatov Otabek', up: 1, down: 4, att: 72, t: 'warn' },
    { n: 'Halimova Zilola', up: 7, down: 0, att: 95, t: 'top' },
  ];
  return (
    <>
      <OverlayHeader pop={pop} title="9-B Algebra" right={Icons.more} />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body" style={{ paddingTop: 8 }}>
          <div className="ip-card-soft" style={{ position: 'relative', overflow: 'hidden' }}>
            <SfStar size={120} color="var(--sf-primary)" style={{ position: 'absolute', right: -30, top: -30, opacity: 0.08 }} />
            <div style={{ position: 'relative', display: 'flex', gap: 14, alignItems: 'baseline' }}>
              <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                              fontSize: 36, color: 'var(--sf-primary)', lineHeight: 1 }}>9-B</span>
              <div>
                <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>Algebra · Daraja II</div>
                <div style={{ fontSize: 14, fontWeight: 700 }}>24 o‘quvchi</div>
              </div>
            </div>
            <div style={{ marginTop: 12, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
              {[
                { v: '94%', l: 'Davomat', c: 'var(--sf-success)' },
                { v: '↑18', l: 'Up', c: '#7A4F0E' },
                { v: '↓4', l: 'Down', c: 'var(--sf-danger)' },
              ].map((s, i) => (
                <div key={i} style={{ background: 'var(--sf-surface-2)', borderRadius: 8,
                                        padding: '6px 0', textAlign: 'center' }}>
                  <div className="sf-mono" style={{ fontSize: 17, fontWeight: 700, color: s.c }}>{s.v}</div>
                  <div style={{ fontSize: 9, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                                  textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="ip-section-h" style={{ marginTop: 12 }}>
            <h3>O‘quvchilar · 5/24</h3>
          </div>
          <div className="ip-card-soft" style={{ padding: 0, overflow: 'hidden' }}>
            {roster.map((s, i, a) => (
              <button key={i} onClick={() => push('student')} style={{
                width: '100%', display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
                borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
                background: 'transparent', border: 'none', cursor: 'pointer',
                fontFamily: 'inherit', textAlign: 'left',
              }}>
                <SfAvatar name={s.n} size={32} />
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span style={{ fontSize: 13, fontWeight: 600 }}>{s.n}</span>
                    {s.t === 'top' && <SfStar size={10} color="var(--sf-accent)" />}
                    {s.t === 'warn' && <span style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--sf-danger)' }} />}
                  </div>
                  <div style={{ fontSize: 10.5, color: 'var(--sf-muted)', display: 'flex', gap: 6 }}>
                    <span className="sf-mono" style={{ color: s.att >= 92 ? 'var(--sf-success)' : 'var(--sf-warn)', fontWeight: 600 }}>{s.att}%</span>
                    <span className="sf-mono" style={{ color: '#7A4F0E', fontWeight: 700 }}>↑{s.up}</span>
                    <span className="sf-mono" style={{ color: s.down > 0 ? 'var(--sf-danger)' : 'var(--sf-muted)', fontWeight: 700 }}>↓{s.down}</span>
                  </div>
                </div>
                {React.cloneElement(Icons.chevR, { size: 14 })}
              </button>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

function Student({ pop, push }) {
  return (
    <>
      <OverlayHeader pop={pop} title="O‘quvchi" right={Icons.more} />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body">
          <div className="ip-card-soft" style={{ padding: 16, position: 'relative', overflow: 'hidden' }}>
            <SfStar size={140} color="var(--sf-primary)" style={{ position: 'absolute', right: -40, top: -40, opacity: 0.08 }} />
            <div style={{ position: 'relative', display: 'flex', gap: 12, alignItems: 'center' }}>
              <SfAvatar name="Akmal Akbarov" size={58} color="var(--sf-primary)" />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.1 }}>
                  Akbarov Akmal
                </div>
                <div className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)', marginTop: 2 }}>
                  DEMO-2026-00042
                </div>
                <div style={{ marginTop: 6, display: 'flex', gap: 4 }}>
                  <SfPill tone="primary">9-B</SfPill>
                  <SfPill tone="accent">Yulduz</SfPill>
                </div>
              </div>
            </div>
            <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
              {[
                { v: '↑12', l: 'Up', c: '#7A4F0E' },
                { v: '↓1', l: 'Down', c: 'var(--sf-danger)' },
                { v: '96%', l: 'Davomat', c: 'var(--sf-success)' },
              ].map((s, i) => (
                <div key={i} style={{ padding: 8, background: 'var(--sf-surface-2)', borderRadius: 8, textAlign: 'center' }}>
                  <div className="sf-mono" style={{ fontSize: 17, fontWeight: 700, color: s.c }}>{s.v}</div>
                  <div style={{ fontSize: 9, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                                  textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
                </div>
              ))}
            </div>
          </div>

          <button className="ip-btn-primary" style={{ marginTop: 12, width: '100%' }}
                  onClick={() => push('give-card')}>
            {React.cloneElement(Icons.plus, { size: 16 })} Karta berish
          </button>

          <div className="ip-section-h" style={{ marginTop: 14 }}>
            <h3>Karta tarixi</h3><span>13 ›</span>
          </div>
          <div className="ip-card-soft" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { d: '19 May · 09:42', t: 'Yulduz karta', r: 'Mustaqil yechim', kind: 'up' },
              { d: '17 May', t: 'Aktivlik', r: 'Sinfdoshlariga yordam', kind: 'up' },
              { d: '8 May', t: 'Ogohlantirish', r: 'Darsda telefon bilan', kind: 'down' },
            ].map((r, i, a) => (
              <div key={i} style={{ display: 'flex', gap: 10, padding: '10px 12px',
                                      borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
                                      alignItems: 'center' }}>
                <div style={{
                  width: 24, height: 32, borderRadius: 5,
                  background: r.kind === 'up' ? 'linear-gradient(135deg, #F6E0AC, #E9C272)'
                                                : 'linear-gradient(135deg, #F0C9BE, #D88A75)',
                  border: `1px solid ${r.kind === 'up' ? '#C49A3A' : '#A14026'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}><SfStar size={10} color={r.kind === 'up' ? '#7A4F0E' : '#5C1A0C'} /></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 12, fontWeight: 700,
                                  color: r.kind === 'up' ? 'var(--sf-ink)' : 'var(--sf-danger)' }}>{r.t}</div>
                  <div style={{ fontSize: 10.5, color: 'var(--sf-muted)', fontStyle: 'italic' }}>“{r.r}”</div>
                </div>
                <span className="sf-mono" style={{ fontSize: 9.5, color: 'var(--sf-muted)' }}>{r.d}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

function GiveCard({ pop }) {
  const [picked, setPicked] = React.useState('star');
  return (
    <>
      <div className="ip-overlay-hdr">
        <button className="ip-back" onClick={pop}>Bekor</button>
        <div className="ip-overlay-title">Karta berish</div>
        <span style={{ width: 50 }} />
      </div>
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body">
          <div className="ip-card-soft" style={{ padding: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
            <SfAvatar name="Akbarov Akmal" size={36} color="var(--sf-primary)" />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>Akbarov Akmal</div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>9-B Algebra</div>
            </div>
          </div>

          <div style={{ marginTop: 14, fontSize: 10.5, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>Karta turi</div>
          <div style={{ marginTop: 8, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            {[
              { id: 'star', n: 'Yulduz', s: 'Asosiy +', kind: 'up' },
              { id: 'active', n: 'Aktivlik', s: 'Darsda', kind: 'up' },
              { id: 'helper', n: 'Yordamchi', s: 'Sinfdosh', kind: 'up' },
              { id: 'warn', n: 'Ogohl.', s: 'Asosiy −', kind: 'down' },
            ].map(t => {
              const isUp = t.kind === 'up';
              const on = picked === t.id;
              return (
                <button key={t.id} onClick={() => setPicked(t.id)} className="ip-type-chip" data-on={on ? '1' : '0'} style={{
                  background: on ? (isUp ? '#F6E0AC' : '#F0C9BE') : 'var(--sf-surface)',
                  border: on ? `1.5px solid ${isUp ? '#C49A3A' : '#A14026'}` : '1px solid var(--sf-border)',
                }}>
                  <div style={{ width: 22, height: 28, borderRadius: 5,
                                  background: isUp ? '#E9C272' : '#D88A75',
                                  border: `1px solid ${isUp ? '#A47B22' : '#A14026'}`,
                                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <SfStar size={10} color={isUp ? '#5C3E08' : '#5C1A0C'} />
                  </div>
                  <div style={{ flex: 1, textAlign: 'left' }}>
                    <div style={{ fontSize: 12, fontWeight: 700, color: on ? (isUp ? '#5C3E08' : '#5C1A0C') : 'var(--sf-ink)' }}>{t.n}</div>
                    <div style={{ fontSize: 9.5, color: on ? (isUp ? '#7A4F0E' : '#9A4628') : 'var(--sf-muted)' }}>{t.s}</div>
                  </div>
                </button>
              );
            })}
          </div>

          <div style={{ marginTop: 14, fontSize: 10.5, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>Sabab</div>
          <div className="ip-card-soft" style={{ padding: 10, marginTop: 6 }}>
            <div style={{ fontSize: 13 }}>Mustaqil yechim · 3-misol</div>
          </div>

          <div style={{ marginTop: 16, fontSize: 10.5, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>Ko‘rinish</div>
          <div style={{ marginTop: 8, display: 'flex', justifyContent: 'center' }}>
            <SfCard kind={picked === 'warn' ? 'down' : 'up'} size="lg"
                    recipient="Akbarov Akmal"
                    reason="Mustaqil yechim · 3-misol"
                    issuer="N. Karimova" when="09:42"
                    typeName={
                      picked === 'star' ? 'Yulduz karta' :
                      picked === 'active' ? 'Aktivlik' :
                      picked === 'helper' ? 'Yordamchi' : 'Ogohlantirish'
                    } />
          </div>
        </div>
      </div>
      <div className="ip-footer">
        <button className="ip-btn-ghost" style={{ width: 50 }}>{React.cloneElement(Icons.print, { size: 16 })}</button>
        <button className="ip-btn-primary" onClick={pop}>Karta berish</button>
      </div>
    </>
  );
}

function TaskDetail({ pop }) {
  return (
    <>
      <OverlayHeader pop={pop} title="Vazifa" right={Icons.more} />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body">
          <div style={{ display: 'flex', gap: 6 }}>
            <SfPill tone="primary">BAJARILMOQDA</SfPill>
            <span className="ip-tag ip-tag-dark">BOSHQARUV</span>
            <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-danger)', fontWeight: 700, marginLeft: 'auto' }}>P1</span>
          </div>
          <h2 style={{ marginTop: 10, fontSize: 22, lineHeight: 1.15, letterSpacing: '-0.025em',
                          marginBottom: 14 }}>
            May oyi yakuniy <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontWeight: 400 }}>hisobotini</span> topshirish
          </h2>
          {[
            { l: 'Loyiha', v: 'Hisobot · oylik' },
            { l: 'Bergan', v: 'Karimova R.' },
            { l: 'Muddat', v: 'Ertaga · 18:00', urgent: true },
            { l: 'Subt', v: '2/4' },
          ].map((p, i) => (
            <div key={i} style={{ display: 'flex', padding: '5px 0', fontSize: 12 }}>
              <span style={{ width: 70, color: 'var(--sf-muted)' }}>{p.l}</span>
              <span style={{ color: p.urgent ? 'var(--sf-danger)' : 'var(--sf-ink-2)',
                              fontWeight: p.urgent ? 700 : 600 }}>{p.v}</span>
            </div>
          ))}

          <div style={{ height: 1, background: 'var(--sf-border)', margin: '14px 0' }} />

          <div style={{ fontSize: 13.5, lineHeight: 1.55 }}>
            Hisobotda quyidagilar bo‘lishi kerak:
          </div>
          <div style={{ marginTop: 10 }}>
            {[
              { t: 'Davomat statistikasi · 3 guruh', done: true },
              { t: 'Up/Down kartalar tahlili', done: true },
              { t: 'AI suhbat asosida tavsiyalar', done: false, current: true },
              { t: 'Yakuniy xulosa · 1 sahifa', done: false },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 4px',
                                       borderRadius: 6,
                                       background: s.current ? 'var(--sf-primary-soft)' : 'transparent' }}>
                <div style={{
                  width: 16, height: 16, borderRadius: 4, flexShrink: 0,
                  background: s.done ? 'var(--sf-success)' : 'transparent',
                  border: s.done ? 'none' : `1.5px solid ${s.current ? 'var(--sf-primary)' : 'var(--sf-border-strong)'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#FFFCF5',
                }}>{s.done && React.cloneElement(Icons.check, { size: 10, stroke: 3.2 })}</div>
                <span style={{ fontSize: 13, color: s.done ? 'var(--sf-muted)' : 'var(--sf-ink)',
                                textDecoration: s.done ? 'line-through' : 'none' }}>{s.t}</span>
              </div>
            ))}
          </div>

          <div className="ip-ai-box">
            <SfAiBadge>Hisobot yordamchi</SfAiBadge>
            <div style={{ marginTop: 6, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                            fontSize: 13.5, lineHeight: 1.35 }}>
              “Sizning 3 guruh ma‘lumotlaringizdan yarim avtomatik hisobot tuzdim.”
            </div>
          </div>
        </div>
      </div>
      <div className="ip-footer">
        <button className="ip-btn-ghost">Qoldirish</button>
        <button className="ip-btn-primary" onClick={pop}>
          {React.cloneElement(Icons.check, { size: 14 })} Tugatish
        </button>
      </div>
    </>
  );
}

function AiChat({ pop }) {
  return (
    <>
      <div className="ip-overlay-hdr">
        <button className="ip-back" onClick={pop}>{React.cloneElement(Icons.arrowL, { size: 16 })}</button>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--sf-primary)',
                          color: '#FFFCF5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <SfStar size={16} color="#FFFCF5" />
          </div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>9-B Algebra</div>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)' }}>24 o‘quvchi</div>
          </div>
        </div>
      </div>
      <div className="ip-scroll" style={{ flex: 1, background: 'var(--sf-bg)', padding: '12px 16px' }}>
        <div className="ip-chat-out">
          9-B kvadrat tenglamalar mavzusida qanday boryapti?
        </div>
        <div className="ip-chat-in-wrap">
          <div className="ip-ai-bubble"><span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontSize: 12, fontWeight: 600 }}>Ai</span></div>
          <div className="ip-chat-in">
            <div><span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic' }}>Umuman barqaror.</span> 24 dan 18 nafari mavzuni o‘zlashtirdi. 4 nafari diskriminantda xato.</div>
            <div className="ip-stats-mini">
              {[{v: '18', c: 'var(--sf-success)'}, {v: '4', c: 'var(--sf-warn)'}, {v: '2', c: 'var(--sf-danger)'}].map((s, i) => (
                <div key={i} style={{ flex: 1, textAlign: 'center' }}>
                  <div className="sf-mono" style={{ fontSize: 20, fontWeight: 700, color: s.c }}>{s.v}</div>
                </div>
              ))}
            </div>
            <div className="ip-stats-bar">
              <div style={{ width: '75%', background: 'var(--sf-success)' }} />
              <div style={{ width: '17%', background: 'var(--sf-warn)' }} />
              <div style={{ width: '8%', background: 'var(--sf-danger)' }} />
            </div>
          </div>
        </div>
        <div className="ip-chat-out" style={{ marginTop: 6 }}>
          Otabek otasiga yoziladigan xabar tayyorla.
        </div>
        <div className="ip-chat-in-wrap" style={{ marginTop: 6 }}>
          <div className="ip-ai-bubble"><span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontSize: 12, fontWeight: 600 }}>Ai</span></div>
          <div className="ip-typing">
            <span /><span /><span />
          </div>
        </div>
      </div>
      <div className="ip-footer" style={{ gap: 8 }}>
        <div className="ip-input">
          9-B haqida savol bering...
          <span className="sf-mono" style={{ fontSize: 9, color: 'var(--sf-muted)', marginLeft: 'auto' }}>~120 token</span>
        </div>
        <button className="ip-icon-btn" style={{ background: 'var(--sf-primary)', color: '#FFFCF5' }}>
          {React.cloneElement(Icons.send, { size: 16 })}
        </button>
      </div>
    </>
  );
}

function NewPrint({ pop }) {
  const [copies, setCopies] = React.useState(24);
  return (
    <>
      <OverlayHeader pop={pop} title="Yangi chop etish" />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body">
          <div className="ip-card-soft" style={{ display: 'flex', alignItems: 'center', gap: 10, padding: 10 }}>
            <div style={{ width: 32, height: 40, borderRadius: 6, background: 'var(--sf-danger)',
                            color: '#FFFCF5', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {React.cloneElement(Icons.pdf, { size: 16 })}
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12.5, fontWeight: 700 }}>Kvadrat tenglama · slayd</div>
              <div className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>PDF · 2.1 MB · 8 bet</div>
            </div>
          </div>

          {/* Page preview */}
          <div style={{ marginTop: 14, background: 'var(--sf-surface-2)', borderRadius: 14,
                          padding: 16, height: 160, display: 'flex',
                          alignItems: 'center', justifyContent: 'center', gap: 8 }}>
            {[1,2,3,4,5].map((p, i) => {
              const focus = i === 2;
              return (
                <div key={p} style={{
                  width: focus ? 90 : 56, height: focus ? 124 : 80,
                  background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
                  borderRadius: focus ? 6 : 4, padding: focus ? 8 : 4,
                  boxShadow: focus ? '0 12px 28px rgba(54,30,14,0.2)' : '0 2px 6px rgba(54,30,14,0.06)',
                  transform: focus ? 'translateY(-4px) scale(1)' :
                                       `rotate(${i === 0 ? -3 : i === 4 ? 3 : 0}deg)`,
                  opacity: focus ? 1 : 0.7,
                  transition: 'all 0.3s cubic-bezier(0.32, 0.72, 0, 1)',
                }}>
                  <div style={{ height: focus ? 4 : 3, width: '80%',
                                  background: 'var(--sf-primary)', borderRadius: 2 }} />
                  <div style={{ marginTop: 4, height: 2, width: '90%', background: 'var(--sf-border-strong)' }} />
                  <div style={{ marginTop: 2, height: 2, width: '70%', background: 'var(--sf-border-strong)' }} />
                  {focus && (
                    <div style={{ marginTop: 6, height: 22, borderRadius: 3, background: 'var(--sf-surface-2)',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                      <span className="sf-mono" style={{ fontSize: 8, color: 'var(--sf-muted)' }}>x² − 5x + 6</span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {/* Settings */}
          <div style={{ marginTop: 12, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            <div className="ip-card-soft" style={{ padding: 10 }}>
              <div style={{ fontSize: 9.5, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                              textTransform: 'uppercase', fontWeight: 600 }}>Nusxa</div>
              <div style={{ marginTop: 4, display: 'flex', alignItems: 'center', gap: 8 }}>
                <button className="ip-stepper" onClick={() => setCopies(Math.max(1, copies - 1))}>−</button>
                <div className="sf-mono" style={{ flex: 1, textAlign: 'center', fontSize: 20, fontWeight: 700 }}>{copies}</div>
                <button className="ip-stepper" data-on="1" onClick={() => setCopies(copies + 1)}>+</button>
              </div>
            </div>
            <div className="ip-card-soft" style={{ padding: 10 }}>
              <div style={{ fontSize: 9.5, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                              textTransform: 'uppercase', fontWeight: 600 }}>Format</div>
              <div style={{ marginTop: 4, display: 'flex', gap: 4 }}>
                {['A4', 'A5', 'A3'].map((s, i) => (
                  <div key={s} style={{
                    flex: 1, padding: '4px 0', textAlign: 'center', borderRadius: 6,
                    fontSize: 11, fontWeight: 700,
                    background: i === 0 ? 'var(--sf-ink)' : 'transparent',
                    color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
                    border: i === 0 ? 'none' : '1px solid var(--sf-border)',
                  }}>{s}</div>
                ))}
              </div>
            </div>
          </div>

          <div style={{ marginTop: 12, padding: 12, borderRadius: 12,
                          background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                          display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 10, opacity: 0.7, letterSpacing: '0.06em',
                              textTransform: 'uppercase', fontWeight: 600 }}>Yakuniy</div>
              <div className="sf-mono" style={{ marginTop: 2, fontSize: 16, fontWeight: 700 }}>{copies} × 8 = {copies * 8} sahifa</div>
            </div>
            <SfStar size={28} color="var(--sf-accent)" />
          </div>
        </div>
      </div>
      <div className="ip-footer">
        <button className="ip-btn-primary" onClick={pop} style={{ width: '100%' }}>
          Navbatga qo‘shish {React.cloneElement(Icons.arrowR, { size: 14 })}
        </button>
      </div>
    </>
  );
}

function MgmtChat({ pop }) {
  return (
    <>
      <div className="ip-overlay-hdr">
        <button className="ip-back" onClick={pop}>{React.cloneElement(Icons.arrowL, { size: 16 })}</button>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
          <SfAvatar name="Karimova Rano" size={30} />
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 4 }}>
              Karimova Rano
              <SfPill tone="primary">Direktor</SfPill>
            </div>
            <div style={{ fontSize: 9.5, color: 'var(--sf-success)' }}>onlayn</div>
          </div>
        </div>
      </div>
      <div className="ip-scroll" style={{ flex: 1, background: 'var(--sf-bg)', padding: 14 }}>
        <div className="ip-chat-in-wrap">
          <SfAvatar name="Karimova Rano" size={24} />
          <div className="ip-chat-in" style={{ background: 'var(--sf-surface)', border: '1px solid var(--sf-border)' }}>
            Salom Nigora opa. May yakuniy hisobotini 23 gacha topshirsangiz bo‘ladimi?
          </div>
        </div>
        <div className="ip-chat-out" style={{ marginTop: 8 }}>
          Albatta. Bugun ertalab Up/Down kartalar va davomatni tahlil qilib, yopiq hisobotni jo‘nataman.
        </div>
        <div className="ip-mgmt-card">
          <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--sf-accent-soft)',
                          color: 'var(--sf-accent-ink)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {React.cloneElement(Icons.flag, { size: 14 })}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Topshiriq · direktordan</div>
            <div style={{ marginTop: 2, fontSize: 12.5, fontWeight: 700 }}>May hisoboti</div>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)' }}>
              Muddat: <span className="sf-mono" style={{ color: 'var(--sf-danger)', fontWeight: 700 }}>23.05 · 18:00</span>
            </div>
          </div>
        </div>
      </div>
      <div className="ip-footer" style={{ gap: 8 }}>
        <div className="ip-input">Direktorga yozish...</div>
        <button className="ip-icon-btn" style={{ background: 'var(--sf-primary)', color: '#FFFCF5' }}>
          {React.cloneElement(Icons.send, { size: 16 })}
        </button>
      </div>
    </>
  );
}

function Profile({ pop, push }) {
  return (
    <>
      <OverlayHeader pop={pop} title="Profil" />
      <div className="ip-scroll" style={{ flex: 1 }}>
        <div className="ip-body">
          <div className="ip-card-soft" style={{ padding: 14, position: 'relative', overflow: 'hidden' }}>
            <SfStar size={120} color="var(--sf-primary)" style={{ position: 'absolute', right: -30, top: -30, opacity: 0.08 }} />
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 12 }}>
              <SfAvatar name="Nigora Karimova" size={54} color="var(--sf-primary)" />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 16, fontWeight: 800, letterSpacing: '-0.02em' }}>Nigora Karimova</div>
                <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>Matematika · Yunusobod</div>
                <div style={{ marginTop: 6, padding: '4px 8px', borderRadius: 999,
                                background: 'var(--sf-success-soft)', color: 'var(--sf-success)',
                                display: 'inline-flex', alignItems: 'center', gap: 5,
                                fontSize: 9.5, fontWeight: 700, letterSpacing: '0.04em',
                                textTransform: 'uppercase' }}>
                  <span className="ip-share-dot" />
                  Profil ulashilmoqda
                </div>
              </div>
            </div>
          </div>

          <button className="ip-card-btn" style={{ marginTop: 12 }} onClick={() => push('mgmt-chat')}>
            <div className="ip-icon-square" style={{ background: 'var(--sf-primary)', color: '#FFFCF5' }}>
              {React.cloneElement(Icons.chat, { size: 18 })}
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>Boshqaruv bilan</div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>Direktor, metodist · 5 ta</div>
            </div>
            <div style={{ minWidth: 18, height: 18, padding: '0 5px', borderRadius: 9,
                            background: 'var(--sf-primary)', color: '#FFFCF5',
                            fontSize: 10, fontWeight: 700,
                            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>3</div>
          </button>

          <div className="ip-section-h" style={{ marginTop: 14 }}><h3>Sozlamalar</h3></div>
          <div className="ip-card-soft" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { l: 'Profilim markaz uchun ko‘rinadi', t: true },
              { l: 'Anonim so‘rovnomalarda ishtirok', t: true },
              { l: 'Karta sozlamalari', v: 'Yulduz / Ogohl.' },
              { l: 'Til', v: 'O‘zbekcha' },
              { l: 'AI limiti', v: '4 320 / 50 000', mono: true },
            ].map((it, i, a) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
                borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
              }}>
                <span style={{ flex: 1, fontSize: 12.5 }}>{it.l}</span>
                {it.v && <span className={it.mono ? 'sf-mono' : ''} style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{it.v}</span>}
                {it.t !== undefined && (
                  <div className="ip-toggle" data-on={it.t ? '1' : '0'}>
                    <div className="ip-toggle-knob" />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}

function Attendance({ pop }) {
  const [marks, setMarks] = React.useState({});
  const students = [
    'Akbarov Akmal', 'Azizova Madina', 'Bakirov Sherzod',
    'Davronova Sevinch', 'Eshmatov Otabek', 'Halimova Zilola',
  ];
  const counts = { present: 0, absent: 0 };
  Object.values(marks).forEach(v => { if (v === 'p') counts.present++; else if (v === 'a') counts.absent++; });
  return (
    <>
      <div className="ip-overlay-hdr">
        <button className="ip-back" onClick={pop}>Bekor</button>
        <div className="ip-overlay-title">9-B · Davomat</div>
        <span style={{ color: 'var(--sf-primary)', fontWeight: 700, fontSize: 13 }}>Saqlash</span>
      </div>
      <div style={{ padding: '8px 16px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          <div className="ip-att-stat" style={{ color: 'var(--sf-success)' }}>
            <span className="sf-mono" style={{ fontSize: 18, fontWeight: 700 }}>{counts.present}</span>
            <span>Bor</span>
          </div>
          <div className="ip-att-stat" style={{ color: 'var(--sf-danger)' }}>
            <span className="sf-mono" style={{ fontSize: 18, fontWeight: 700 }}>{counts.absent}</span>
            <span>Yo‘q</span>
          </div>
          <div className="ip-att-stat">
            <span className="sf-mono" style={{ fontSize: 18, fontWeight: 700 }}>{students.length - counts.present - counts.absent}</span>
            <span>Qoldi</span>
          </div>
        </div>
      </div>
      <div className="ip-scroll" style={{ flex: 1, background: 'var(--sf-bg)', padding: '12px 16px' }}>
        <div style={{ padding: 10, background: 'var(--sf-surface-2)', borderRadius: 10,
                       fontSize: 11, color: 'var(--sf-ink-2)', marginBottom: 10 }}>
          Tugmalarni bosing: <strong style={{ color: 'var(--sf-success)' }}>✓ Bor</strong> · <strong style={{ color: 'var(--sf-danger)' }}>✗ Yo‘q</strong>
        </div>
        {students.map((n, i) => {
          const m = marks[i];
          const bg = m === 'p' ? 'var(--sf-success-soft)' : m === 'a' ? 'var(--sf-danger-soft)' : 'var(--sf-surface)';
          return (
            <div key={i} className="ip-att-row" style={{ background: bg,
                                                            border: m ? '1px solid transparent' : '1px solid var(--sf-border)' }}>
              <SfAvatar name={n} size={32} />
              <span style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{n}</span>
              <button className="ip-att-btn" data-on={m === 'p' ? '1' : '0'} data-kind="p"
                      onClick={() => setMarks({ ...marks, [i]: m === 'p' ? undefined : 'p' })}>
                {React.cloneElement(Icons.check, { size: 16, stroke: 2.6 })}
              </button>
              <button className="ip-att-btn" data-on={m === 'a' ? '1' : '0'} data-kind="a"
                      onClick={() => setMarks({ ...marks, [i]: m === 'a' ? undefined : 'a' })}>
                {React.cloneElement(Icons.x, { size: 16, stroke: 2.6 })}
              </button>
            </div>
          );
        })}
      </div>
    </>
  );
}

// ════════════════════════════════════════════════════════════════
// STYLES — scoped to .ip-root
// ════════════════════════════════════════════════════════════════

const ipStyles = `
.ip-root {
  width: 100%; height: 100%;
  display: flex; align-items: center; justify-content: center;
  padding: 28px 0;
}
.ip-phone {
  width: 400px; height: 850px; position: relative;
  background: var(--sf-bg);
  border-radius: 52px; overflow: hidden;
  box-shadow:
    0 30px 80px rgba(54,30,14,0.22),
    0 8px 24px rgba(54,30,14,0.14),
    0 0 0 11px #161310,
    0 0 0 13px #2A2620;
  display: flex; flex-direction: column;
  font-family: var(--sf-font-ui);
  color: var(--sf-ink);
}
.ip-phone * { box-sizing: border-box; }

/* Status bar */
.ip-status {
  height: 50px; padding: 18px 28px 6px; flex-shrink: 0;
  display: flex; justify-content: space-between; align-items: center;
  font-weight: 600; font-size: 15; position: relative; z-index: 10;
}
.ip-notch {
  position: absolute; left: 50%; top: 12px; transform: translateX(-50%);
  width: 108px; height: 30px; background: #000; border-radius: 100px;
}
.ip-status-r { display: flex; gap: 6px; align-items: center; }

/* View viewport */
.ip-viewport { flex: 1; position: relative; overflow: hidden; }
.ip-root-view {
  position: absolute; inset: 0;
  display: flex; flex-direction: column;
  animation: ipFadeIn 0.18s ease-out;
}
@keyframes ipFadeIn { from { opacity: 0.6; transform: scale(0.985); } to { opacity: 1; transform: scale(1); } }

/* Overlay slide-in from right */
.ip-overlay {
  position: absolute; inset: 0;
  background: var(--sf-bg);
  display: flex; flex-direction: column;
  transition: transform 0.32s cubic-bezier(0.32, 0.72, 0, 1);
  will-change: transform;
}
.ip-overlay.entering { transform: translateX(100%); }
.ip-overlay.live { transform: translateX(0); }
.ip-overlay.leaving { transform: translateX(100%); }

/* Scrolling region */
.ip-scroll {
  flex: 1; overflow-y: auto;
  background: var(--sf-bg);
  display: flex; flex-direction: column;
}
.ip-scroll::-webkit-scrollbar { width: 0; }

/* Headers */
.ip-header {
  padding: 8px 18px 14px;
  background: var(--sf-surface);
  border-bottom: 1px solid var(--sf-border);
}
.ip-header-row {
  display: flex; justify-content: space-between; align-items: center;
}
.ip-body { padding: 14px 16px 24px; }

/* Overlay header */
.ip-overlay-hdr {
  padding: 4px 16px;
  background: var(--sf-surface);
  border-bottom: 1px solid var(--sf-border);
  height: 50px;
  display: flex; align-items: center; gap: 8px;
  flex-shrink: 0;
}
.ip-back {
  background: transparent; border: none; cursor: pointer;
  color: var(--sf-primary); font-weight: 600; font-size: 15px;
  font-family: inherit; padding: 8px 4px;
  display: inline-flex; align-items: center; gap: 4px;
}
.ip-overlay-title { flex: 1; text-align: center; font-size: 14px; font-weight: 700; }
.ip-overlay-right { color: var(--sf-ink-2); width: 50px; text-align: right; display: flex; justify-content: flex-end; }

/* Buttons */
.ip-icon-btn {
  width: 38px; height: 38px; border-radius: 12px;
  background: var(--sf-surface-2); border: none; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  color: var(--sf-ink-2); position: relative;
  font-family: inherit;
}
.ip-icon-btn:hover { background: var(--sf-surface-3); }
.ip-dot {
  position: absolute; top: 7px; right: 9px; width: 8px; height: 8px;
  border-radius: 50%; background: var(--sf-primary);
  border: 2px solid var(--sf-surface-2);
}

.ip-card-btn {
  display: flex; align-items: center; gap: 10px;
  padding: 12px; width: 100%; margin-bottom: 8px;
  background: var(--sf-surface); border: 1px solid var(--sf-border);
  border-radius: 14px; cursor: pointer; font-family: inherit;
  transition: transform 0.1s ease, box-shadow 0.15s;
}
.ip-card-btn:hover { transform: translateY(-1px); box-shadow: var(--sf-shadow-sm); }
.ip-card-btn:active { transform: scale(0.985); }
.ip-card-soft {
  background: var(--sf-surface); border: 1px solid var(--sf-border);
  border-radius: 14px; padding: 14px; margin-bottom: 8px;
}
.ip-icon-square {
  width: 44px; height: 44px; border-radius: 12px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center; position: relative;
}

/* Survey banner */
.ip-survey {
  position: relative; width: 100%;
  background: linear-gradient(135deg, #FCEFD0 0%, #F6E0AC 100%);
  border: 1.5px solid var(--sf-accent);
  border-radius: 14px; padding: 12px; margin-bottom: 12px;
  display: flex; align-items: center; gap: 10px;
  box-shadow: 0 0 0 4px rgba(216,154,46,0.20), 0 8px 24px rgba(216,154,46,0.18);
  cursor: pointer; font-family: inherit;
  transition: transform 0.12s;
}
.ip-survey:active { transform: scale(0.98); }
.ip-survey-glow {
  position: absolute; inset: 0; border-radius: 14px;
  border: 2px solid var(--sf-accent); opacity: 0.4;
  animation: ipPulse 1.8s ease-in-out infinite;
  pointer-events: none;
}
.ip-pulse-dot {
  width: 8px; height: 8px; border-radius: 50%; background: var(--sf-danger);
  animation: ipBlink 1s steps(2) infinite; flex-shrink: 0;
}
.ip-survey-big {
  position: relative; width: 100%; padding: 14px;
  background: linear-gradient(135deg, #FCEFD0 0%, #F6E0AC 100%);
  border: 1.5px solid var(--sf-accent);
  border-radius: 18px; margin-bottom: 10px;
  cursor: pointer; font-family: inherit; text-align: left;
  box-shadow: 0 0 0 4px rgba(216,154,46,0.20), 0 8px 24px rgba(216,154,46,0.18);
  overflow: hidden;
}
.ip-survey-cta {
  margin-top: 10px; padding: 8px 10px; border-radius: 10px;
  background: rgba(255,252,245,0.7);
  display: flex; align-items: center; gap: 4px;
  font-size: 11.5px; color: var(--sf-ink-2); font-weight: 600;
}

@keyframes ipPulse { 0%, 100% { opacity: 0.4; transform: scale(1); } 50% { opacity: 0; transform: scale(1.03); } }
@keyframes ipBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }

/* Hero */
.ip-hero {
  position: relative; width: 100%; cursor: pointer; font-family: inherit;
  border-radius: 18px; padding: 14px; overflow: hidden;
  background: linear-gradient(135deg, var(--sf-primary) 0%, var(--sf-primary-hover) 100%);
  color: #FFFCF5; border: none; margin-bottom: 10px;
  transition: transform 0.12s;
}
.ip-hero:active { transform: scale(0.98); }
.ip-hero-cta {
  margin-top: 10px; padding: 8px 12px;
  background: #FFFCF5; color: var(--sf-primary);
  border-radius: 999px;
  display: inline-flex; align-items: center; gap: 4px;
  font-size: 12px; font-weight: 700;
}

/* Stats */
.ip-stats {
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; margin-bottom: 10px;
}
.ip-stat {
  background: var(--sf-surface); border: 1px solid var(--sf-border);
  border-radius: 12px; padding: 8px 10px;
}
.ip-stat-l {
  margin-top: 4px; font-size: 9.5px; color: var(--sf-muted);
  letterSpacing: 0.04em; text-transform: uppercase; font-weight: 600;
}

/* AI banner */
.ip-ai-banner {
  position: relative; width: 100%; padding: 12px; margin-bottom: 10px;
  background: var(--sf-ai-bg);
  border: 1px solid var(--sf-ai-border); border-radius: 14px;
  display: flex; align-items: center; gap: 10px;
  cursor: pointer; font-family: inherit; text-align: left;
}
.ip-ai-quote {
  flex: 1; font-family: var(--sf-font-display); font-style: italic;
  font-size: 13.5px; line-height: 1.35; color: var(--sf-ink);
}

/* Section header */
.ip-section { margin-bottom: 6px; }
.ip-section-h {
  display: flex; justify-content: space-between; align-items: baseline;
  padding: 8px 4px;
}
.ip-section-h h3 { margin: 0; font-size: 13px; font-weight: 700; letter-spacing: -0.01em; }
.ip-section-h span { font-size: 11px; color: var(--sf-primary); font-weight: 600; }

.ip-cards-strip { display: flex; gap: 8px; overflow-x: auto; padding-bottom: 4px; margin: 0 -16px; padding-left: 16px; padding-right: 16px; }
.ip-cards-strip::-webkit-scrollbar { height: 0; }

/* Tabs */
.ip-tabs {
  display: flex; padding: 8px 4px 18px;
  background: var(--sf-surface); border-top: 1px solid var(--sf-border);
  flex-shrink: 0;
}
.ip-tab {
  flex: 1; background: transparent; border: none; cursor: pointer;
  font-family: inherit; padding: 6px 0;
  display: flex; flex-direction: column; align-items: center; gap: 3px;
  color: var(--sf-muted); font-size: 10px; font-weight: 500;
  transition: color 0.2s;
}
.ip-tab[data-on="1"] { color: var(--sf-primary); font-weight: 700; }
.ip-tab-icon-wrap { position: relative; }
.ip-tab-bg {
  position: absolute; inset: -6px; border-radius: 12px;
  background: var(--sf-primary-soft);
  animation: ipTabIn 0.2s ease-out;
}
.ip-tab-icon { position: relative; }
@keyframes ipTabIn { from { transform: scale(0.4); opacity: 0; } to { transform: scale(1); opacity: 1; } }

.ip-home-indicator {
  position: absolute; bottom: 8px; left: 50%; transform: translateX(-50%);
  width: 134px; height: 5px; border-radius: 3px;
  background: var(--sf-ink); opacity: 0.6; pointer-events: none; z-index: 30;
}

/* Tasks */
.ip-task {
  position: relative; background: var(--sf-surface); border: 1px solid var(--sf-border);
  border-radius: 14px; padding: 12px; margin-bottom: 8px;
  cursor: pointer; font-family: inherit; text-align: left; width: 100%;
  transition: transform 0.1s, box-shadow 0.15s;
}
.ip-task:hover { box-shadow: var(--sf-shadow-sm); }
.ip-task:active { transform: scale(0.985); }
.ip-task-rail {
  position: absolute; left: 0; top: 12px; bottom: 12px; width: 3px; border-radius: 3px;
}
.ip-check {
  width: 16px; height: 16px; border-radius: 4px;
  border: 1.5px solid var(--sf-border-strong); flex-shrink: 0;
}
.ip-tag {
  padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: 700;
  letter-spacing: 0.04em;
}
.ip-tag-dark { background: var(--sf-ink); color: var(--sf-bg); }

/* AI list */
.ip-ai-row .ip-ai-preview {
  margin-top: 6px; padding: 8px; border-radius: 8px;
  background: var(--sf-ai-bg); border: 1px solid var(--sf-ai-border);
  font-size: 11.5px; color: var(--sf-ink-2); font-style: italic; line-height: 1.4;
}

/* Print */
.ip-doc-thumb {
  width: 38px; height: 48px; background: var(--sf-surface-2);
  border: 1px solid var(--sf-border); border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
  position: relative; flex-shrink: 0;
}
.ip-doc-mult {
  position: absolute; bottom: -5px; right: -5px;
  padding: 1px 4px; border-radius: 4px; font-size: 8.5px; font-weight: 700;
  background: var(--sf-ink); color: var(--sf-bg);
  font-family: var(--sf-font-mono);
}
.ip-progress { margin-top: 8px; height: 5px; border-radius: 4px; background: var(--sf-surface-2); overflow: hidden; }
.ip-progress-fill { height: 100%; background: var(--sf-primary); transition: width 0.3s; }
.ip-badge {
  position: absolute; top: -5px; right: -5px;
  min-width: 16px; padding: 0 4px; border-radius: 9px;
  background: var(--sf-primary); color: #FFFCF5;
  font-size: 9px; font-weight: 700;
  display: flex; align-items: center; justify-content: center;
}
.ip-cta {
  width: 100%; padding: 12px; border-radius: 999px; border: none;
  background: var(--sf-primary); color: #FFFCF5;
  font-family: inherit; font-weight: 700; font-size: 14px; cursor: pointer;
  display: flex; align-items: center; justify-content: center; gap: 6px;
  margin-top: 12px; transition: transform 0.1s;
}
.ip-cta:active { transform: scale(0.97); }
.ip-btn-primary {
  flex: 1; padding: 13px; border-radius: 999px; border: none;
  background: var(--sf-primary); color: #FFFCF5;
  font-family: inherit; font-weight: 700; font-size: 14px; cursor: pointer;
  display: flex; align-items: center; justify-content: center; gap: 6px;
  transition: transform 0.1s;
}
.ip-btn-primary:active { transform: scale(0.97); }
.ip-btn-ghost {
  padding: 12px 18px; border-radius: 999px;
  background: var(--sf-surface-2); border: 1px solid var(--sf-border-strong);
  color: var(--sf-ink-2); font-family: inherit; font-weight: 600; font-size: 13px;
  cursor: pointer;
}
.ip-footer {
  padding: 10px 16px; background: var(--sf-surface);
  border-top: 1px solid var(--sf-border);
  display: flex; gap: 8px; align-items: center;
  flex-shrink: 0;
}

/* Chat */
.ip-chat-out {
  align-self: flex-end; max-width: 80%; margin-left: auto;
  padding: 9px 12px; border-radius: 16px 16px 4px 16px;
  background: var(--sf-ink); color: var(--sf-bg);
  font-size: 12.5px; line-height: 1.4; margin-bottom: 6px;
}
.ip-chat-in-wrap { display: flex; gap: 6px; align-items: flex-end; }
.ip-ai-bubble {
  width: 24px; height: 24px; border-radius: 6px; flex-shrink: 0;
  background: var(--sf-ai-bg); border: 1px solid var(--sf-ai-border);
  color: var(--sf-ai);
  display: flex; align-items: center; justify-content: center;
}
.ip-chat-in {
  flex: 1; padding: 10px 12px; border-radius: 4px 16px 16px 16px;
  background: var(--sf-surface); border: 1px solid var(--sf-border);
  font-size: 12.5px; line-height: 1.45;
}
.ip-stats-mini {
  margin-top: 10px; display: flex; padding: 8px;
  background: var(--sf-surface-2); border-radius: 8px;
}
.ip-stats-bar {
  margin-top: 6px; height: 5px; border-radius: 4px;
  background: var(--sf-surface-2); overflow: hidden;
  display: flex;
}
.ip-typing {
  padding: 12px 16px; border-radius: 4px 16px 16px 16px;
  background: var(--sf-surface); border: 1px solid var(--sf-border);
  display: flex; gap: 4px;
}
.ip-typing span {
  width: 6px; height: 6px; border-radius: 50%; background: var(--sf-ai);
  opacity: 0.4;
  animation: ipDot 1.2s infinite ease-in-out;
}
.ip-typing span:nth-child(2) { animation-delay: 0.2s; }
.ip-typing span:nth-child(3) { animation-delay: 0.4s; }
@keyframes ipDot {
  0%, 80%, 100% { opacity: 0.3; transform: translateY(0); }
  40% { opacity: 1; transform: translateY(-3px); }
}
.ip-input {
  flex: 1; background: var(--sf-surface-2); border-radius: 22px;
  padding: 10px 14px; font-size: 12.5px; color: var(--sf-muted);
  display: flex; align-items: center;
}

.ip-mgmt-card {
  margin-top: 10px; padding: 10px; border-radius: 12px;
  background: var(--sf-surface); border: 1px solid var(--sf-accent);
  display: flex; gap: 10px; align-items: flex-start;
}

.ip-type-chip {
  padding: 10px; border-radius: 12px;
  cursor: pointer; font-family: inherit;
  display: flex; align-items: flex-start; gap: 8px;
}

.ip-anon {
  margin-top: 18px; padding: 10px; border-radius: 10px;
  background: var(--sf-surface-2); color: var(--sf-ink-2);
  display: flex; gap: 8px; align-items: center; font-size: 11px;
}

.ip-ai-box {
  margin-top: 16px; padding: 12px; border-radius: 14px;
  background: var(--sf-ai-bg); border: 1px solid var(--sf-ai-border);
}

.ip-share-dot {
  width: 6px; height: 6px; border-radius: 50%; background: var(--sf-success);
  animation: ipBreathe 1.6s ease-in-out infinite;
}
@keyframes ipBreathe { 0%, 100% { opacity: 1; transform: scale(1); } 50% { opacity: 0.4; transform: scale(1.6); } }

.ip-toggle {
  width: 40px; height: 24px; border-radius: 999px;
  background: var(--sf-surface-3);
  padding: 3px;
  transition: background 0.2s;
}
.ip-toggle[data-on="1"] { background: var(--sf-primary); }
.ip-toggle-knob {
  width: 18px; height: 18px; border-radius: 50%; background: #FFFCF5;
  box-shadow: 0 1px 2px rgba(0,0,0,0.2);
  transition: transform 0.2s;
}
.ip-toggle[data-on="1"] .ip-toggle-knob { transform: translateX(16px); }

.ip-stepper {
  width: 30px; height: 30px; border-radius: 8px;
  background: var(--sf-surface-2); border: none; cursor: pointer;
  font-family: inherit; font-weight: 700; font-size: 16px;
  color: var(--sf-ink-2);
}
.ip-stepper[data-on="1"] { background: var(--sf-primary); color: #FFFCF5; }

.ip-att-stat {
  flex: 1; padding: 6px 0; text-align: center;
  background: var(--sf-surface-2); border-radius: 10px;
  display: flex; flex-direction: column;
  color: var(--sf-ink-2);
}
.ip-att-stat span:last-child {
  font-size: 9px; color: var(--sf-muted); letter-spacing: 0.04em;
  text-transform: uppercase; font-weight: 600; margin-top: 2px;
}

.ip-att-row {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 12px; border-radius: 12px; margin-bottom: 4px;
  transition: background 0.2s;
}
.ip-att-btn {
  width: 30px; height: 30px; border-radius: 8px;
  border: 1.5px solid var(--sf-border-strong);
  background: var(--sf-surface);
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; transition: all 0.15s;
  color: var(--sf-muted); font-family: inherit;
}
.ip-att-btn[data-kind="p"] { border-color: var(--sf-success); color: var(--sf-success); }
.ip-att-btn[data-kind="a"] { border-color: var(--sf-danger); color: var(--sf-danger); }
.ip-att-btn[data-on="1"][data-kind="p"] { background: var(--sf-success); color: #FFFCF5; }
.ip-att-btn[data-on="1"][data-kind="a"] { background: var(--sf-danger); color: #FFFCF5; }
.ip-att-btn:active { transform: scale(0.9); }
`;

Object.assign(window, { InteractivePhone });
