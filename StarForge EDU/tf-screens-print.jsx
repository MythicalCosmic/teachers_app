// tf-screens-print.jsx — Print queue (printers list + new job)

function PrintScreen({ platform = 'ios' }) {
  const printers = [
    {
      n: 'HP LaserJet · M404n', loc: 'Lobbi · 1-qavat',
      status: 'free', etaT: 'Hozir tayyor', q: 0, color: false, sizes: 'A4', acc: 'var(--sf-success)',
    },
    {
      n: 'Xerox WorkCentre · Pro', loc: '2-qavat dahliz', status: 'busy',
      etaT: '11:34 da bo‘shaydi', q: 2, color: true, sizes: 'A4 · A3 · color', acc: 'var(--sf-warn)',
    },
    {
      n: 'Brother · DCP-L', loc: 'Direktor xonasi',
      status: 'locked', etaT: 'Faqat ma‘muriyat', q: 0, color: false, sizes: 'A4', acc: 'var(--sf-muted)',
    },
  ];

  const myQueue = [
    {
      doc: 'Kvadrat tenglamalar · slayd', src: 'Kutubxona', copies: 24, size: 'A4 · B/W',
      printer: 'HP LaserJet', state: 'now', pct: 64, eta: 'Tugaydi · 11:24',
    },
    {
      doc: 'Yulduz karta · 6 nusxa', src: 'AI generatsiya', copies: 6, size: 'A5 · rang',
      printer: 'Xerox WorkCentre', state: 'queued', pct: 0, eta: 'Boshlanadi · 11:38',
    },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Chop etish" subtitle="Yunusobod filiali · 3 ta printer"
        right={<>{Icons.search}{Icons.plus}</>} />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '4px 18px 100px' }}>

        {/* My queue */}
        <div style={{ display: 'flex', justifyContent: 'space-between',
                       alignItems: 'baseline', padding: '0 4px 8px' }}>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Mening navbatim</div>
          <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>2 ta faol</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {myQueue.map((j, i) => (
            <div key={i} className="sf-card" style={{ padding: 14, position: 'relative',
                                                        overflow: 'hidden' }}>
              <div style={{ display: 'flex', gap: 12 }}>
                <div style={{
                  width: 46, height: 60, background: 'var(--sf-surface-2)',
                  border: '1px solid var(--sf-border)', borderRadius: 8,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, position: 'relative',
                }}>
                  {React.cloneElement(Icons.doc, { size: 22 })}
                  <div className="sf-mono" style={{
                    position: 'absolute', bottom: -6, right: -6,
                    padding: '1px 5px', borderRadius: 4, fontSize: 9, fontWeight: 700,
                    background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                  }}>×{j.copies}</div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 700,
                                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{j.doc}</div>
                    <SfPill tone={j.state === 'now' ? 'primary' : 'accent'}>
                      {j.state === 'now' ? 'Chop bo‘ladi' : 'Navbatda'}
                    </SfPill>
                  </div>
                  <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-muted)' }}>
                    {j.src} · {j.size} · {j.printer}
                  </div>
                  {/* Progress */}
                  <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ flex: 1, height: 6, borderRadius: 4,
                                    background: 'var(--sf-surface-2)', overflow: 'hidden' }}>
                      <div style={{
                        width: `${j.pct}%`, height: '100%',
                        background: j.state === 'now' ? 'var(--sf-primary)' : 'var(--sf-accent)',
                      }} />
                    </div>
                    <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
                      {j.state === 'now' ? `${j.pct}%` : j.eta.split(' · ')[1] || j.eta}
                    </span>
                  </div>
                  <div style={{ marginTop: 4, fontSize: 10.5, color: 'var(--sf-muted)' }}>{j.eta}</div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Printers list */}
        <div style={{ marginTop: 20, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'baseline', padding: '0 4px 8px' }}>
          <div style={{ fontSize: 13, fontWeight: 700 }}>Printerlar</div>
          <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>Filial · 1-qavat</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {printers.map((p, i) => (
            <div key={i} className="sf-card" style={{ padding: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 48, height: 48, borderRadius: 12,
                  background: 'var(--sf-surface-2)', color: p.acc,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  position: 'relative', flexShrink: 0,
                }}>
                  {React.cloneElement(Icons.print, { size: 22 })}
                  <div style={{
                    position: 'absolute', bottom: 4, right: 4,
                    width: 10, height: 10, borderRadius: '50%',
                    background: p.acc, border: '2px solid var(--sf-surface)',
                  }} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{ fontSize: 14, fontWeight: 700 }}>{p.n}</span>
                    {p.color && <SfPill tone="accent">Rangli</SfPill>}
                  </div>
                  <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>
                    {p.loc} · {p.sizes}
                  </div>
                </div>
                <SfPill tone={
                  p.status === 'free' ? 'success' :
                  p.status === 'busy' ? 'accent' : 'neutral'
                }>
                  {p.status === 'free' ? 'Bo‘sh' : p.status === 'busy' ? `${p.q} navbat` : 'Yopiq'}
                </SfPill>
              </div>
              <div style={{
                marginTop: 10, padding: 10, borderRadius: 10,
                background: 'var(--sf-surface-2)',
                display: 'flex', alignItems: 'center', gap: 8,
                fontSize: 11.5, color: 'var(--sf-ink-2)',
              }}>
                {React.cloneElement(Icons.clock, { size: 14, style: { color: p.acc } })}
                <span style={{ flex: 1 }}>{p.etaT}</span>
                {p.status !== 'locked' && (
                  <span style={{ color: 'var(--sf-primary)', fontWeight: 600 }}>
                    Yuborish {React.cloneElement(Icons.arrowR, { size: 12 })}
                  </span>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '10px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)' }}>
        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 50 }}>
          {React.cloneElement(Icons.plus, { size: 18 })} Yangi chop etish
        </button>
      </div>

      <SfTabBar active="print" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function NewPrintJobScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ color: 'var(--sf-primary)', fontSize: 16, fontWeight: 600 }}>Bekor</span>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>2-bosqich · 3</div>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Yangi chop etish</div>
          </div>
          <span style={{ width: 60 }} />
        </div>
        {/* Progress */}
        <div style={{ display: 'flex', gap: 4, paddingBottom: 12 }}>
          {[1,2,3].map(i => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 3,
              background: i <= 2 ? 'var(--sf-primary)' : 'var(--sf-surface-2)',
            }} />
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        {/* Source selector */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Material manbai
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <div style={{
            padding: 14, borderRadius: 14, background: 'var(--sf-primary-soft)',
            border: '1.5px solid var(--sf-primary)',
            display: 'flex', flexDirection: 'column', gap: 6, position: 'relative',
          }}>
            <div style={{ color: 'var(--sf-primary)' }}>{React.cloneElement(Icons.folder, { size: 22 })}</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: 'var(--sf-primary-ink)' }}>Kutubxonadan</div>
            <div style={{ fontSize: 10.5, color: 'var(--sf-primary-ink)', opacity: 0.7 }}>84 fayl</div>
            <div style={{ position: 'absolute', top: 8, right: 8, color: 'var(--sf-primary)' }}>
              {React.cloneElement(Icons.check, { size: 16, stroke: 2.8 })}
            </div>
          </div>
          <div style={{
            padding: 14, borderRadius: 14, background: 'var(--sf-surface)',
            border: '1px solid var(--sf-border)',
            display: 'flex', flexDirection: 'column', gap: 6,
          }}>
            <div style={{ color: 'var(--sf-muted)' }}>{React.cloneElement(Icons.upload, { size: 22 })}</div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>Yuklash</div>
            <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>PDF · DOCX · JPG</div>
          </div>
        </div>

        {/* Selected file */}
        <div className="sf-card" style={{ marginTop: 14, padding: 14,
                                            display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 40, height: 50, borderRadius: 8,
            background: 'var(--sf-danger)', color: '#FFFCF5',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>{React.cloneElement(Icons.pdf, { size: 20 })}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 700 }}>Kvadrat tenglama · slayd</div>
            <div className="sf-mono" style={{ marginTop: 2, fontSize: 10.5, color: 'var(--sf-muted)' }}>
              PDF · 2.1 MB · 8 bet
            </div>
          </div>
          <span style={{ fontSize: 11, color: 'var(--sf-primary)', fontWeight: 600 }}>
            O‘zgartirish
          </span>
        </div>

        {/* Preview — fancy page strip */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 10 }}>
          Ko‘rinish · 8 bet
        </div>
        <div style={{ position: 'relative', height: 220,
                       background: 'var(--sf-surface-2)', borderRadius: 16,
                       padding: 18, overflow: 'hidden' }}>
          <div className="sf-pattern" style={{ position: 'absolute', inset: 0, opacity: 0.5 }} />
          <div style={{ position: 'relative', display: 'flex',
                          alignItems: 'center', justifyContent: 'center',
                          height: '100%', gap: 12 }}>
            {[1,2,3,4,5].map((p, i) => {
              const focus = i === 2;
              return (
                <div key={p} style={{
                  width: focus ? 120 : 76, height: focus ? 168 : 110,
                  background: 'var(--sf-surface)',
                  border: '1px solid var(--sf-border)',
                  borderRadius: focus ? 8 : 6, padding: focus ? 10 : 6,
                  boxShadow: focus ? '0 12px 32px rgba(54,30,14,0.18)' : '0 2px 6px rgba(54,30,14,0.06)',
                  transform: focus ? 'translateY(-4px)' : `translateY(${(i % 2 === 0) ? 8 : 0}px) rotate(${i === 0 ? -3 : i === 4 ? 3 : 0}deg)`,
                  opacity: focus ? 1 : 0.7,
                  position: 'relative', flexShrink: 0,
                }}>
                  <div style={{ height: focus ? 6 : 4, width: '80%',
                                  background: 'var(--sf-primary)', borderRadius: 2 }} />
                  <div style={{ marginTop: focus ? 8 : 5, height: focus ? 3 : 2, width: '92%',
                                  background: 'var(--sf-border-strong)', borderRadius: 1 }} />
                  <div style={{ marginTop: 3, height: focus ? 3 : 2, width: '70%',
                                  background: 'var(--sf-border-strong)', borderRadius: 1 }} />
                  {focus && (
                    <>
                      <div style={{ marginTop: 8, height: 32, borderRadius: 4,
                                      background: 'var(--sf-surface-2)',
                                      display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <span className="sf-mono" style={{ fontSize: 9, color: 'var(--sf-muted)' }}>x² − 5x + 6</span>
                      </div>
                      <div style={{ marginTop: 5, height: 2, width: '90%',
                                      background: 'var(--sf-border-strong)', borderRadius: 1 }} />
                      <div style={{ marginTop: 3, height: 2, width: '75%',
                                      background: 'var(--sf-border-strong)', borderRadius: 1 }} />
                      <div style={{ position: 'absolute', bottom: 6, right: 8,
                                      fontFamily: 'var(--sf-font-mono)', fontSize: 8,
                                      color: 'var(--sf-muted)' }}>3/8</div>
                    </>
                  )}
                </div>
              );
            })}
          </div>
          {/* Dots */}
          <div style={{ position: 'absolute', bottom: 10, left: 0, right: 0,
                          display: 'flex', justifyContent: 'center', gap: 4 }}>
            {[0,1,2,3,4].map(i => (
              <div key={i} style={{
                width: i === 2 ? 16 : 4, height: 4, borderRadius: 2,
                background: i === 2 ? 'var(--sf-primary)' : 'var(--sf-border-strong)',
              }} />
            ))}
          </div>
        </div>

        {/* Settings */}
        <div style={{ marginTop: 18, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <div className="sf-card" style={{ padding: 12 }}>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Nusxa</div>
            <div style={{ marginTop: 4, display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--sf-surface-2)',
                              display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700 }}>−</div>
              <div className="sf-mono" style={{ flex: 1, textAlign: 'center', fontSize: 22, fontWeight: 700 }}>24</div>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'var(--sf-primary)',
                              color: '#FFFCF5',
                              display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700 }}>+</div>
            </div>
          </div>
          <div className="sf-card" style={{ padding: 12 }}>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Format</div>
            <div style={{ marginTop: 4, display: 'flex', gap: 4 }}>
              {['A4', 'A5', 'A3'].map((s, i) => (
                <div key={s} style={{
                  flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 8,
                  fontSize: 12, fontWeight: 700,
                  background: i === 0 ? 'var(--sf-ink)' : 'transparent',
                  color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
                  border: i === 0 ? 'none' : '1px solid var(--sf-border)',
                }}>{s}</div>
              ))}
            </div>
          </div>
        </div>

        <div style={{ marginTop: 8, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <div className="sf-card" style={{ padding: 12 }}>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Rang</div>
            <div style={{ marginTop: 4, display: 'flex', gap: 4 }}>
              <div style={{ flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 8,
                              fontSize: 12, fontWeight: 700, background: 'var(--sf-ink)', color: 'var(--sf-bg)' }}>Qora-oq</div>
              <div style={{ flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 8,
                              fontSize: 12, fontWeight: 600, color: 'var(--sf-muted)',
                              border: '1px solid var(--sf-border)' }}>Rangli</div>
            </div>
          </div>
          <div className="sf-card" style={{ padding: 12 }}>
            <div style={{ fontSize: 10, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Tomon</div>
            <div style={{ marginTop: 4, display: 'flex', gap: 4 }}>
              <div style={{ flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 8,
                              fontSize: 12, fontWeight: 600, color: 'var(--sf-muted)',
                              border: '1px solid var(--sf-border)' }}>1 ↕</div>
              <div style={{ flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 8,
                              fontSize: 12, fontWeight: 700, background: 'var(--sf-ink)', color: 'var(--sf-bg)' }}>2 ↔</div>
            </div>
          </div>
        </div>

        {/* When */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Qachon tayyor bo‘lsin
        </div>
        <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
          {[
            { l: 'Hozir', v: '~3 daqiqada', dot: 'var(--sf-success)', on: false },
            { l: 'Bugun darsdan oldin', v: '08:45 ga', dot: 'var(--sf-accent)', on: true },
            { l: 'Belgilangan vaqt', v: 'Tanlash', dot: 'var(--sf-muted)', on: false },
          ].map((o, i, a) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center',
                                    padding: '12px 14px', gap: 12,
                                    background: o.on ? 'var(--sf-primary-soft)' : 'transparent',
                                    borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none' }}>
              <div style={{
                width: 18, height: 18, borderRadius: '50%',
                border: `2px solid ${o.on ? 'var(--sf-primary)' : 'var(--sf-border-strong)'}`,
                background: o.on ? 'var(--sf-primary)' : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{o.on && <span style={{ width: 6, height: 6, borderRadius: '50%',
                                            background: '#FFFCF5' }} />}</div>
              <span style={{ flex: 1, fontSize: 13.5, fontWeight: o.on ? 700 : 500 }}>{o.l}</span>
              <span style={{ fontSize: 12, color: 'var(--sf-muted)' }}>{o.v}</span>
            </div>
          ))}
        </div>

        {/* Summary */}
        <div style={{
          marginTop: 18, padding: 14, borderRadius: 14,
          background: 'var(--sf-ink)', color: 'var(--sf-bg)',
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, opacity: 0.7,
                            letterSpacing: '0.06em', textTransform: 'uppercase', fontWeight: 600 }}>
              Yakuniy
            </div>
            <div className="sf-mono" style={{ marginTop: 4, fontSize: 18, fontWeight: 700 }}>
              24 × 8 = 192 sahifa
            </div>
            <div style={{ marginTop: 2, fontSize: 11, opacity: 0.7 }}>
              A4 · Qora-oq · 2 tomonlama · HP LaserJet
            </div>
          </div>
          <SfStar size={36} color="var(--sf-accent)" />
        </div>
      </div>

      {/* Footer */}
      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)', display: 'flex', gap: 8 }}>
        <button className="sf-btn sf-btn--soft" style={{ width: 80 }}>Orqaga</button>
        <button className="sf-btn sf-btn--primary" style={{ flex: 1 }}>
          Navbatga qo‘shish {React.cloneElement(Icons.arrowR, { size: 16 })}
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { PrintScreen, NewPrintJobScreen });
