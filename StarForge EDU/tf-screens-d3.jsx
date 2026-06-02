// tf-screens-d3.jsx — Notifications inbox, Profile / Settings

function NotificationsScreen({ platform = 'ios' }) {
  const groups = [
    {
      label: 'Bugun',
      items: [
        { tone: 'ai', icon: 'AI', title: 'AI tavsiyasi', body: '9-B uchun ertangi darsda kvadrat tenglamalarni qisqa qaytarish tavsiya etiladi.', t: '08:42' },
        { tone: 'primary', icon: Icons.check, title: 'Davomat saqlandi', body: 'Algebra Mid · 21/22 belgilandi.', t: '10:05' },
        { tone: 'success', icon: Icons.print, title: 'Print tayyor', body: 'Kvadrat tenglamalar · 24 nusxa · HP LaserJet · lobbi', t: '11:24' },
        { tone: 'accent', icon: Icons.chat, title: 'Ota-onadan xabar', body: 'Akbarova D. (Akmal ona) sizga yozdi · 9-B', t: '11:14' },
        { tone: 'warn', icon: Icons.flag, title: 'Eshmatov Otabek · 3-Down karta', body: '9-B Algebra · ota-onaga avtomatik xabar yuborildi.', t: '11:42' },
      ]
    },
    {
      label: 'Kecha',
      items: [
        { tone: 'success', icon: Icons.print, title: 'Print tugadi', body: 'Yulduz karta · 12 nusxa · A5 rangli · Xerox WC Pro', t: 'Du · 16:50' },
        { tone: 'ai', icon: 'AI', title: 'Suhbat · 10-V', body: '“Trapetsiya mavzusi yaxshi tushunilgan. 11-misol uchun ekstra…”', t: 'Du · 15:20' },
        { tone: 'primary', icon: Icons.chat, title: 'O‘quvchidan savol', body: 'Halimova Zilola sizga yozdi · uy ishi', t: 'Du · 14:08' },
        { tone: 'neutral', icon: Icons.upload, title: 'Haftalik hisobot', body: '14 May – 19 May · yuklab olishga tayyor.', t: 'Du · 09:00' },
      ]
    },
  ];

  const toneColors = {
    ai:      { bg: 'var(--sf-ai-bg)', fg: 'var(--sf-ai)', border: 'var(--sf-ai-border)' },
    primary: { bg: 'var(--sf-primary-soft)', fg: 'var(--sf-primary-ink)', border: 'transparent' },
    accent:  { bg: 'var(--sf-accent-soft)', fg: 'var(--sf-accent-ink)', border: 'transparent' },
    success: { bg: 'var(--sf-success-soft)', fg: 'var(--sf-success)', border: 'transparent' },
    warn:    { bg: 'var(--sf-warn-soft)', fg: 'var(--sf-warn)', border: 'transparent' },
    neutral: { bg: 'var(--sf-surface-2)', fg: 'var(--sf-ink-2)', border: 'transparent' },
  };

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Bildirishnomalar"
        subtitle="9 ta · 4 ta yangi"
        right={<>{Icons.filter}{Icons.check}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { l: 'Hammasi', n: 9, act: true },
            { l: 'AI', n: 2 },
            { l: 'Print', n: 2 },
            { l: 'Xabar', n: 2 },
            { l: 'Markaz', n: 1 },
          ].map((t, i) => (
            <div key={t.l} style={{
              flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 10,
              fontSize: 11, fontWeight: 600,
              background: t.act ? 'var(--sf-ink)' : 'transparent',
              color: t.act ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: t.act ? 'none' : '1px solid var(--sf-border)',
            }}>
              {t.l} · {t.n}
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 0 100px' }}>
        {groups.map((g, gi) => (
          <div key={gi} style={{ marginBottom: 10 }}>
            <div style={{ padding: '6px 18px', fontSize: 11, fontWeight: 600,
                            letterSpacing: '0.06em', textTransform: 'uppercase',
                            color: 'var(--sf-muted)' }}>{g.label}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8, padding: '0 18px' }}>
              {g.items.map((it, i) => {
                const c = toneColors[it.tone];
                return (
                  <div key={i} className="sf-card" style={{ padding: 14,
                                                              display: 'flex', gap: 12 }}>
                    <div style={{
                      width: 38, height: 38, borderRadius: 11, flexShrink: 0,
                      background: c.bg, color: c.fg,
                      border: `1px solid ${c.border}`,
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontFamily: it.icon === 'AI' ? 'var(--sf-font-display)' : 'inherit',
                      fontStyle: it.icon === 'AI' ? 'italic' : 'normal',
                      fontSize: it.icon === 'AI' ? 18 : 0,
                      fontWeight: 600,
                    }}>
                      {it.icon === 'AI' ? 'Ai' : React.cloneElement(it.icon, { size: 18 })}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between',
                                      alignItems: 'baseline', gap: 8 }}>
                        <span style={{ fontSize: 13.5, fontWeight: 700 }}>{it.title}</span>
                        <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)',
                                                             whiteSpace: 'nowrap' }}>{it.t}</span>
                      </div>
                      <div style={{ marginTop: 3, fontSize: 12.5, color: 'var(--sf-muted)',
                                      lineHeight: 1.45 }}>{it.body}</div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function SettingsScreen({ platform = 'ios' }) {
  const sections = [
    {
      h: 'Hisob',
      items: [
        { l: 'Shaxsiy ma‘lumotlar', i: Icons.user, v: 'Nigora Karimova' },
        { l: 'Foydalanuvchi nomi', i: Icons.shield, v: 'nigora.karimova', mono: true },
        { l: 'Parolni o‘zgartirish', i: Icons.edit },
        { l: 'Til', i: Icons.globe, v: 'O‘zbekcha' },
      ]
    },
    {
      h: 'Maxfiylik · Profil ulashish',
      items: [
        { l: 'Profilim markaz uchun ko‘rinadi', toggle: true, share: true },
        { l: 'Ismsiz so‘rovnomalarda ishtirok', toggle: true },
        { l: 'AI sizning ma‘lumotlaringizdan o‘rganadi', toggle: false },
      ]
    },
    {
      h: 'Bildirishnomalar',
      items: [
        { l: 'Push xabarlar', toggle: true },
        { l: 'Dars boshlanishi · 15 daq oldin', toggle: true },
        { l: 'Print tugaganda', toggle: true },
        { l: 'AI tavsiyalari', toggle: true },
        { l: 'Sokin soatlar · 22:00–07:00', v: 'Yoniq' },
      ]
    },
    {
      h: 'AI yordamchi',
      items: [
        { l: 'Guruh haqida suhbat', toggle: true },
        { l: 'Karta sabab taklifi', toggle: true },
        { l: 'Ota-ona javob taklifi', toggle: false },
        { l: 'Markaz limiti', v: '4 320 / 50 000 token', mono: true },
      ]
    },
    {
      h: 'Markaz',
      items: [
        { l: 'Demo Akademiya', i: Icons.shield, v: 'Yunusobod filiali' },
        { l: 'Karta sozlamalari', i: Icons.brand, v: 'Yulduz / Ogohlantirish' },
        { l: 'Qurilmalar', i: Icons.print, v: '2 ta' },
        { l: 'Maxfiylik va shartlar', i: Icons.shield },
      ]
    },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Profil" subtitle="" right={<>{Icons.settings}</>} />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '0 18px 100px' }}>
        <style>{`
          @keyframes sfPulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.4; transform: scale(1.5); }
          }
        `}</style>
        {/* Profile card */}
        <div className="sf-card" style={{ padding: 18, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.08 }}>
            <SfStar size={140} color="var(--sf-primary)" />
          </div>
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 14 }}>
            <SfAvatar name="Nigora Karimova" size={64} color="var(--sf-primary)" />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 800, letterSpacing: '-0.02em' }}>
                Nigora Karimova
              </div>
              <div style={{ marginTop: 2, fontSize: 12, color: 'var(--sf-muted)' }}>
                Matematika ustozi · Yunusobod filiali
              </div>
              <div style={{ marginTop: 6, display: 'flex', gap: 4 }}>
                <SfPill tone="primary">9-B</SfPill>
                <SfPill tone="primary">Alg Mid</SfPill>
                <SfPill tone="accent">10-V</SfPill>
              </div>
              <div style={{ marginTop: 8, padding: '6px 10px', borderRadius: 999,
                              background: 'var(--sf-success-soft)', color: 'var(--sf-success)',
                              display: 'inline-flex', alignItems: 'center', gap: 6,
                              fontSize: 10.5, fontWeight: 700, letterSpacing: '0.04em',
                              textTransform: 'uppercase' }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%',
                                background: 'var(--sf-success)',
                                animation: 'sfPulse 1.6s ease-in-out infinite' }} />
                Profil ulashilmoqda
              </div>
            </div>
          </div>
          <div style={{ position: 'relative', marginTop: 16, display: 'grid',
                          gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
            {[
              { v: '3', l: 'Guruh' },
              { v: '58', l: 'O‘quvchi' },
              { v: '12', l: 'Dars/hafta' },
            ].map((s, i) => (
              <div key={i} style={{ textAlign: 'center', padding: 10,
                                      background: 'var(--sf-surface-2)', borderRadius: 10 }}>
                <div className="sf-mono" style={{ fontSize: 18, fontWeight: 700,
                                                    color: 'var(--sf-ink)', lineHeight: 1 }}>{s.v}</div>
                <div style={{ marginTop: 4, fontSize: 10, color: 'var(--sf-muted)',
                                letterSpacing: '0.04em', textTransform: 'uppercase',
                                fontWeight: 600 }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>

        {sections.map((sec, si) => (
          <div key={si} style={{ marginTop: 20 }}>
            <div style={{ padding: '0 4px 8px', fontSize: 11, fontWeight: 600,
                            letterSpacing: '0.06em', textTransform: 'uppercase',
                            color: 'var(--sf-muted)' }}>{sec.h}</div>
            <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
              {sec.items.map((it, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '12px 14px',
                  borderBottom: i < sec.items.length - 1 ? '1px solid var(--sf-border)' : 'none',
                }}>
                  {it.i && (
                    <div style={{
                      width: 32, height: 32, borderRadius: 9,
                      background: 'var(--sf-surface-2)', color: 'var(--sf-ink-2)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      flexShrink: 0,
                    }}>{React.cloneElement(it.i, { size: 16 })}</div>
                  )}
                  <span style={{ flex: 1, fontSize: 13.5, color: 'var(--sf-ink)' }}>{it.l}</span>
                  {it.v && (
                    <span className={it.mono ? 'sf-mono' : ''}
                          style={{ fontSize: 12, color: 'var(--sf-muted)' }}>{it.v}</span>
                  )}
                  {it.toggle !== undefined && (
                    <div style={{
                      width: 44, height: 26, borderRadius: 999,
                      background: it.toggle ? 'var(--sf-primary)' : 'var(--sf-surface-3)',
                      padding: 3, transition: 'background 0.2s',
                    }}>
                      <div style={{
                        width: 20, height: 20, borderRadius: '50%',
                        background: '#FFFCF5',
                        boxShadow: '0 1px 2px rgba(0,0,0,0.2)',
                        transform: it.toggle ? 'translateX(18px)' : 'translateX(0)',
                        transition: 'transform 0.2s',
                      }} />
                    </div>
                  )}
                  {!it.toggle && it.v === undefined && it.l !== 'Maxfiylik va shartlar' && (
                    React.cloneElement(Icons.chevR, { size: 16 })
                  )}
                  {it.l === 'Maxfiylik va shartlar' && (
                    React.cloneElement(Icons.chevR, { size: 16 })
                  )}
                </div>
              ))}
            </div>
          </div>
        ))}

        {/* Logout */}
        <button className="sf-btn sf-btn--ghost sf-btn--block" style={{
          marginTop: 22, height: 50, color: 'var(--sf-danger)',
          borderColor: 'var(--sf-border)',
        }}>
          {React.cloneElement(Icons.logout, { size: 18 })}
          Chiqish
        </button>

        <div style={{ marginTop: 14, textAlign: 'center' }}>
          <SfWordmark size={12} />
          <div style={{ marginTop: 4, fontSize: 10, color: 'var(--sf-muted)', fontFamily: 'var(--sf-font-mono)' }}>
            v1.0.0 · build 2026.05.19
          </div>
        </div>
      </div>

      <SfTabBar active="me" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { NotificationsScreen, SettingsScreen });
