// tf-screens-b.jsx — Cohorts list, Cohort detail, Student profile

function CohortListScreen({ platform = 'ios' }) {
  const cohorts = [
    { n: '9-B Algebra', l: 'Daraja II', cnt: 24, att: 94, next: 'Bugun · 09:00', tone: 'var(--sf-primary)' },
    { n: '9-A Algebra', l: 'Daraja II', cnt: 22, att: 91, next: 'Bugun · 10:00', tone: 'var(--sf-primary)' },
    { n: '10-V Geometriya', l: 'Daraja III', cnt: 19, att: 88, next: 'Bugun · 11:30', tone: 'var(--sf-accent)' },
    { n: '11-B Tayyorlov', l: 'DTM', cnt: 13, att: 96, next: 'Bugun · 15:00', tone: 'var(--sf-ink-2)' },
    { n: '8-A Algebra', l: 'Daraja I', cnt: 26, att: 89, next: 'Ertaga · 08:30', tone: 'var(--sf-primary)' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Guruhlar"
        subtitle="4 ta faol · 78 o‘quvchi"
        right={<>{Icons.filter}{Icons.plus}</>} />

      <div style={{ padding: '0 18px 10px', background: 'var(--sf-surface)' }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          background: 'var(--sf-surface-2)', borderRadius: 14, padding: '10px 14px',
        }}>
          {React.cloneElement(Icons.search, { size: 18 })}
          <span style={{ color: 'var(--sf-muted)', fontSize: 14 }}>Guruh yoki o‘quvchini izlash</span>
        </div>
        <div style={{ marginTop: 10, display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 6 }}>
          {['Hammasi', 'Algebra', 'Geometriya', 'Tayyorlov', 'Arxiv'].map((t, i) => (
            <div key={t} style={{
              padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
              whiteSpace: 'nowrap',
              background: i === 0 ? 'var(--sf-ink)' : 'transparent',
              color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: i === 0 ? 'none' : '1px solid var(--sf-border)',
            }}>{t}</div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {cohorts.map((c, i) => (
            <div key={i} className="sf-card" style={{ padding: 16, position: 'relative', overflow: 'hidden' }}>
              <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
                <div style={{
                  width: 52, height: 52, borderRadius: 14, flexShrink: 0,
                  background: c.tone, color: '#FFFCF5',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  position: 'relative', overflow: 'hidden',
                }}>
                  <SfStar size={28} color="#FFFCF5" style={{ opacity: 0.9 }} />
                  <div style={{
                    position: 'absolute', bottom: 0, right: 0, padding: '1px 4px',
                    background: 'rgba(0,0,0,0.18)', fontSize: 9, fontWeight: 700,
                    borderTopLeftRadius: 6,
                  }}>{c.cnt}</div>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 6 }}>
                    <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>{c.n}</div>
                    <span className="sf-chip">{c.l}</span>
                  </div>
                  <div style={{ marginTop: 4, fontSize: 12, color: 'var(--sf-muted)' }}>
                    Keyingi: <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>{c.next}</span>
                  </div>
                  {/* Mini stats */}
                  <div style={{ marginTop: 10, display: 'flex', gap: 14, alignItems: 'center' }}>
                    <div>
                      <span className="sf-mono" style={{ fontSize: 14, fontWeight: 700,
                                                          color: c.att >= 92 ? 'var(--sf-success)' :
                                                                  c.att >= 88 ? 'var(--sf-warn)' :
                                                                  'var(--sf-danger)' }}>{c.att}%</span>
                      <span style={{ fontSize: 10, color: 'var(--sf-muted)', marginLeft: 4,
                                      letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>davomat</span>
                    </div>
                    <div style={{ width: 1, height: 14, background: 'var(--sf-border)' }} />
                    {/* mini bar */}
                    <div style={{ flex: 1, display: 'flex', gap: 2, alignItems: 'flex-end', height: 16 }}>
                      {[60, 80, 92, 78, 88, 96, 84, 91, 87, c.att].map((v, j) => (
                        <div key={j} style={{
                          flex: 1, borderRadius: 2,
                          height: `${v}%`,
                          background: j === 9 ? c.tone : 'var(--sf-surface-3)',
                        }} />
                      ))}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* AI suggestion at bottom */}
        <div className="sf-ai-surface" style={{ marginTop: 14, padding: 14, borderRadius: 16 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>Yoyish</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 13, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              <strong>10-V</strong> guruhida davomat oxirgi 2 haftada 4% tushdi. 3 o‘quvchini ko‘rib chiqing.
            </div>
          </div>
        </div>
      </div>

      <SfTabBar active="cohort" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function CohortDetailScreen({ platform = 'ios' }) {
  const roster = [
    { n: 'Akbarov Akmal', up: 8, down: 0, att: 96, t: 'top' },
    { n: 'Azizova Madina', up: 6, down: 0, att: 98, t: 'top' },
    { n: 'Bakirov Sherzod', up: 2, down: 2, att: 88, t: '' },
    { n: 'Davronova Sevinch', up: 4, down: 0, att: 92, t: '' },
    { n: 'Eshmatov Otabek', up: 1, down: 4, att: 72, t: 'warn' },
    { n: 'Fayzullayev Diyor', up: 5, down: 1, att: 94, t: '' },
    { n: 'G‘aniyev Jasur', up: 3, down: 1, att: 89, t: '' },
    { n: 'Halimova Zilola', up: 7, down: 0, att: 95, t: 'top' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS
        left={<><span style={{ display: 'inline-flex', alignItems: 'center' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}Guruhlar</span></>}
        right={<>{Icons.more}</>}
        title="9-B Algebra"
      />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '8px 18px 100px' }}>
        {/* Hero stats */}
        <div className="sf-card" style={{ padding: 18, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.08 }}>
            <SfStar size={140} color="var(--sf-primary)" />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ display: 'flex', gap: 8 }}>
              <SfPill tone="primary">Algebra · Daraja II</SfPill>
              <SfPill>2025–2026</SfPill>
            </div>
            <div style={{ marginTop: 10, fontSize: 22, fontWeight: 800, letterSpacing: '-0.02em' }}>
              9-B · 24 o‘quvchi
            </div>
            <div style={{ marginTop: 2, fontSize: 13, color: 'var(--sf-muted)' }}>
              Asosiy o‘qituvchi: <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>Nigora Karimova</span> · Xona 304
            </div>

            <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
              {[
                { v: '94', s: '%', l: 'Davomat', c: 'var(--sf-success)' },
                { v: '↑18', s: '', l: 'Up karta', c: '#7A4F0E' },
                { v: '↓4', s: '', l: 'Down karta', c: 'var(--sf-danger)' },
                { v: '12', s: '', l: 'Topshiriq', c: 'var(--sf-ink-2)' },
              ].map((s, i) => (
                <div key={i} style={{ textAlign: 'center', padding: '8px 0',
                                        background: 'var(--sf-surface-2)', borderRadius: 10 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 1 }}>
                    <span className="sf-mono" style={{ fontSize: 18, fontWeight: 700, color: s.c }}>{s.v}</span>
                    <span style={{ fontSize: 10, color: 'var(--sf-muted)', fontWeight: 600 }}>{s.s}</span>
                  </div>
                  <div style={{ marginTop: 2, fontSize: 9, color: 'var(--sf-muted)',
                                  letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 14, display: 'flex', gap: 8 }}>
              <button className="sf-btn sf-btn--primary" style={{ flex: 1, fontSize: 13 }}>
                {React.cloneElement(Icons.check, { size: 16 })} Davomat
              </button>
              <button className="sf-btn sf-btn--soft" style={{ flex: 1, fontSize: 13 }}>
                {React.cloneElement(Icons.chat, { size: 16 })} Xabar
              </button>
              <button className="sf-btn sf-btn--ghost" style={{ width: 42, padding: 0 }}>
                {Icons.more}
              </button>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ marginTop: 16, display: 'flex', gap: 6, padding: 4,
                       background: 'var(--sf-surface-2)', borderRadius: 12 }}>
          {['O‘quvchilar', 'Kartalar', 'Topshiriqlar', 'Jadval'].map((t, i) => (
            <div key={t} style={{
              flex: 1, textAlign: 'center', padding: '8px 4px',
              borderRadius: 8, fontSize: 12, fontWeight: 600,
              background: i === 0 ? 'var(--sf-surface)' : 'transparent',
              color: i === 0 ? 'var(--sf-ink)' : 'var(--sf-muted)',
              boxShadow: i === 0 ? 'var(--sf-shadow-sm)' : 'none',
            }}>{t}</div>
          ))}
        </div>

        {/* Sort row */}
        <div style={{ marginTop: 14, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'center', fontSize: 12, color: 'var(--sf-muted)' }}>
          <span>24 o‘quvchi</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontWeight: 600,
                          color: 'var(--sf-ink-2)' }}>
            Saralash: Familiya {React.cloneElement(Icons.chevD, { size: 12 })}
          </span>
        </div>

        {/* Roster */}
        <div className="sf-card" style={{ marginTop: 8, padding: 0, overflow: 'hidden' }}>
          {roster.map((s, i, arr) => (
            <div key={i} style={{
              display: 'flex', gap: 12, padding: '11px 14px', alignItems: 'center',
              borderBottom: i < arr.length - 1 ? '1px solid var(--sf-border)' : 'none',
            }}>
              <SfAvatar name={s.n} size={36} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{s.n}</span>
                  {s.t === 'top' && <span className="sf-mark" style={{ fontSize: 10, color: 'var(--sf-accent)' }} />}
                  {s.t === 'warn' && <span style={{ width: 6, height: 6, borderRadius: '50%',
                                                      background: 'var(--sf-danger)' }} />}
                </div>
                <div style={{ marginTop: 2, display: 'flex', gap: 8, alignItems: 'center',
                                fontSize: 11, color: 'var(--sf-muted)' }}>
                  <span className="sf-mono" style={{
                    color: s.att >= 92 ? 'var(--sf-success)' :
                            s.att >= 85 ? 'var(--sf-warn)' :
                            'var(--sf-danger)', fontWeight: 600,
                  }}>{s.att}%</span>
                  <span>·</span>
                  <span className="sf-mono" style={{ color: '#7A4F0E', fontWeight: 700 }}>↑{s.up}</span>
                  <span className="sf-mono" style={{ color: s.down > 0 ? 'var(--sf-danger)' : 'var(--sf-muted)',
                                                       fontWeight: 700 }}>↓{s.down}</span>
                </div>
              </div>
              {React.cloneElement(Icons.chevR, { size: 16 })}
            </div>
          ))}
        </div>

        {/* AI insight */}
        <div className="sf-ai-surface" style={{ marginTop: 16, padding: 16, borderRadius: 16 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <SfAiBadge>Sinf hisoboti</SfAiBadge>
              <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>Bu hafta</span>
            </div>
            <div style={{ marginTop: 10, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 17, lineHeight: 1.35 }}>
              “Sinf umuman barqaror. Otabek va Sherzod oxirgi 2 haftada Down karta olgan — qisqa suhbat tavsiya etiladi.”
            </div>
          </div>
        </div>
      </div>

      <SfTabBar active="cohort" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function StudentProfileScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS
        left={<><span style={{ display: 'inline-flex', alignItems: 'center' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}9-B</span></>}
        right={<>{Icons.chat}{Icons.more}</>}
        title="O‘quvchi"
      />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '8px 18px 100px' }}>
        {/* Hero */}
        <div className="sf-card" style={{ padding: 20, position: 'relative', overflow: 'hidden' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <SfAvatar name="Akmal Akbarov" size={64} color="var(--sf-primary)" />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 20, fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
                Akbarov Akmal
              </div>
              <div className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)', marginTop: 2 }}>
                DEMO-2026-00042
              </div>
              <div style={{ marginTop: 6, display: 'flex', gap: 6 }}>
                <SfPill tone="primary">9-B</SfPill>
                <SfPill tone="accent">Yulduz</SfPill>
              </div>
            </div>
          </div>
          {/* Mini stat row */}
          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
            {[
              { v: '↑12', l: 'Up karta', c: '#7A4F0E' },
              { v: '↓1', l: 'Down karta', c: 'var(--sf-danger)' },
              { v: '96', l: 'Davomat %', c: 'var(--sf-success)' },
            ].map((s, i) => (
              <div key={i} style={{ padding: 10, borderRadius: 10,
                                      background: 'var(--sf-surface-2)' }}>
                <div className="sf-mono" style={{ fontSize: 20, fontWeight: 700, color: s.c, lineHeight: 1 }}>{s.v}</div>
                <div style={{ marginTop: 4, fontSize: 10, color: 'var(--sf-muted)',
                                letterSpacing: '0.04em', textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent cards */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 8, padding: '0 4px',
                         display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span>Karta tarixi</span>
            <span style={{ fontSize: 11, color: 'var(--sf-primary)', fontWeight: 600 }}>
              13 ta {React.cloneElement(Icons.chevR, { size: 11 })}
            </span>
          </div>
          <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { d: '19 May · 09:42', t: 'Yulduz karta', r: 'Mustaqil yechim · 3-misol', kind: 'up' },
              { d: '17 May · 10:18', t: 'Aktivlik', r: 'Sinfdoshlariga yordam berdi', kind: 'up' },
              { d: '12 May · 11:30', t: 'Yulduz karta', r: 'Daftar — namunaviy', kind: 'up' },
              { d: '8 May · 09:05', t: 'Ogohlantirish', r: 'Darsda telefon bilan band', kind: 'down' },
              { d: '5 May · 14:22', t: 'Yulduz karta', r: 'Olimpiada · 2-bosqich', kind: 'up' },
            ].map((r, i, a) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '11px 14px',
                borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
              }}>
                <div style={{
                  width: 28, height: 36, borderRadius: 6, flexShrink: 0,
                  background: r.kind === 'up' ? 'linear-gradient(135deg, #F6E0AC, #E9C272)'
                                                : 'linear-gradient(135deg, #F0C9BE, #D88A75)',
                  border: `1px solid ${r.kind === 'up' ? '#C49A3A' : '#A14026'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <SfStar size={12} color={r.kind === 'up' ? '#7A4F0E' : '#5C1A0C'} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700,
                                  color: r.kind === 'up' ? 'var(--sf-ink)' : 'var(--sf-danger)' }}>{r.t}</div>
                  <div style={{ fontSize: 11, color: 'var(--sf-muted)', fontStyle: 'italic' }}>“{r.r}”</div>
                </div>
                <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)',
                                                     whiteSpace: 'nowrap' }}>{r.d}</span>
              </div>
            ))}
          </div>

          <button className="sf-btn sf-btn--soft sf-btn--block" style={{ marginTop: 10 }}>
            {React.cloneElement(Icons.plus, { size: 16 })} Karta berish
          </button>
        </div>

        {/* Guardians */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 8, padding: '0 4px' }}>
            Ota-ona aloqasi
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { n: 'Akbarov Anvar', r: 'Ota · birinchi', p: '+998 90 222 11 33' },
              { n: 'Akbarova Dilnoza', r: 'Ona', p: '+998 91 444 55 66' },
            ].map((g, i) => (
              <div key={i} className="sf-card" style={{ flex: 1, padding: 12 }}>
                <SfAvatar name={g.n} size={32} />
                <div style={{ marginTop: 8, fontSize: 13, fontWeight: 600, lineHeight: 1.2 }}>{g.n}</div>
                <div style={{ marginTop: 2, fontSize: 10, color: 'var(--sf-muted)' }}>{g.r}</div>
                <div className="sf-mono" style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-primary)' }}>{g.p}</div>
              </div>
            ))}
          </div>
        </div>

        {/* AI student summary */}
        <div className="sf-ai-surface" style={{ marginTop: 18, padding: 16, borderRadius: 16 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>O‘quvchi haqida</SfAiBadge>
            <div style={{ marginTop: 10, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 16, lineHeight: 1.4 }}>
              “Akmal — sinfning eng kuchli o‘quvchilaridan. Bu oy 12 ta Up karta oldi. Olimpiada tayyorgarligi tavsiya etiladi.”
            </div>
            <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <span className="sf-chip sf-chip--ai">Qo‘shimcha mashq</span>
              <span className="sf-chip sf-chip--ai">Olimpiada nomzodi</span>
            </div>
          </div>
        </div>

        {/* Finance line */}
        <div className="sf-card" style={{ marginTop: 14, padding: 14, display: 'flex',
                                            alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 12, background: 'var(--sf-success-soft)',
            color: 'var(--sf-success)', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{React.cloneElement(Icons.check, { size: 20, stroke: 2.6 })}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, fontWeight: 700 }}>To‘lov · may oyi</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
              <span className="sf-mono">600 000 so‘m</span> · 7 may, Click
            </div>
          </div>
          <SfPill tone="success">To‘langan</SfPill>
        </div>
      </div>

      <SfTabBar active="cohort" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { CohortListScreen, CohortDetailScreen, StudentProfileScreen });
