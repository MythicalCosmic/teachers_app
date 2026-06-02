// tf-screens-cards.jsx — Card system (Up Cards / Down Cards)
// Card types are dynamic: education center admin can rename them.
// Defaults in the design: "Yulduz karta" (positive), "Ogohlantirish" (warning).
// Optional sub-types: "Aktivlik", "Yordamchi", "Mas'uliyatsizlik".

function CardsScreen({ platform = 'ios' }) {
  const recent = [
    { st: 'Akbarov Akmal', cohort: '9-B Algebra', type: 'Yulduz karta', kind: 'up', reason: 'Mustaqil yechim · 3-misol', t: '09:42', icon: '⭐' },
    { st: 'Halimova Zilola', cohort: '9-B Algebra', type: 'Aktivlik', kind: 'up', reason: 'Sinfdoshlariga yordam berdi', t: '09:38', icon: '🎯' },
    { st: 'Eshmatov Otabek', cohort: '9-B Algebra', type: 'Ogohlantirish', kind: 'down', reason: 'Uy ishi tayyor emas (2-marta)', t: '09:12', icon: '⚠' },
    { st: 'Davronova Sevinch', cohort: 'Algebra · Mid', type: 'Yulduz karta', kind: 'up', reason: 'Toza daftar', t: 'Dush · 14:20' },
    { st: 'Bakirov Sherzod', cohort: 'Algebra · Mid', type: 'Ogohlantirish', kind: 'down', reason: 'Darsda telefon bilan', t: 'Dush · 11:05' },
    { st: 'Azizova Madina', cohort: '9-B Algebra', type: 'Yulduz karta', kind: 'up', reason: 'Olimpiada · 2-bosqich', t: 'Yak · 18:40' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Kartalar" subtitle="Bu hafta · 14 berildi"
        right={<>{Icons.filter}{Icons.plus}</>} />

      {/* Summary row */}
      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div className="sf-card" style={{ padding: 14, background: 'var(--sf-bg)',
                                            display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 44, height: 56,
            background: 'linear-gradient(135deg, #F6E0AC, #E9C272)',
            border: '1px solid #C49A3A', borderRadius: 8,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transform: 'rotate(-6deg)', flexShrink: 0,
          }}><SfStar size={20} color="#7A4F0E" /></div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', gap: 14, alignItems: 'baseline' }}>
              <div>
                <span className="sf-mono" style={{ fontSize: 22, fontWeight: 700,
                                                     color: '#7A4F0E' }}>↑ 11</span>
                <span style={{ marginLeft: 4, fontSize: 11, color: 'var(--sf-muted)',
                                fontWeight: 600 }}>Up</span>
              </div>
              <div>
                <span className="sf-mono" style={{ fontSize: 22, fontWeight: 700,
                                                     color: 'var(--sf-danger)' }}>↓ 3</span>
                <span style={{ marginLeft: 4, fontSize: 11, color: 'var(--sf-muted)',
                                fontWeight: 600 }}>Down</span>
              </div>
            </div>
            <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-muted)' }}>
              Joriy sozlama: <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>
              Yulduz / Ogohlantirish</span> · markaz tomonidan
            </div>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '12px 18px 100px' }}>
        {/* Filter chips */}
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 12 }}>
          {['Hammasi · 14', 'Up · 11', 'Down · 3', '9-B', 'Algebra Mid'].map((t, i) => (
            <div key={t} style={{
              padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
              whiteSpace: 'nowrap',
              background: i === 0 ? 'var(--sf-ink)' : 'transparent',
              color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: i === 0 ? 'none' : '1px solid var(--sf-border)',
            }}>{t}</div>
          ))}
        </div>

        {/* AI insight */}
        <div className="sf-ai-surface" style={{ padding: 14, borderRadius: 16, marginBottom: 14 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge compact>Tahlil</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 13, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              <strong>Eshmatov Otabek</strong>ga shu oy 2 ta Down karta berildi. Ota-onaga avtomatik xabar yuborish tavsiya etiladi.
            </div>
          </div>
        </div>

        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          So‘nggi faollik
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {recent.map((c, i) => {
            const isUp = c.kind === 'up';
            return (
              <div key={i} className="sf-card" style={{ padding: 12, display: 'flex',
                                                          gap: 12, alignItems: 'flex-start' }}>
                {/* Mini card */}
                <div style={{
                  width: 44, height: 56, borderRadius: 8, flexShrink: 0,
                  background: isUp ? 'linear-gradient(135deg, #F6E0AC, #E9C272)'
                                    : 'linear-gradient(135deg, #F0C9BE, #D88A75)',
                  border: `1px solid ${isUp ? '#C49A3A' : '#A14026'}`,
                  display: 'flex', flexDirection: 'column',
                  alignItems: 'center', justifyContent: 'center',
                  padding: 4, position: 'relative', overflow: 'hidden',
                }}>
                  <SfStar size={18} color={isUp ? '#7A4F0E' : '#5C1A0C'} />
                  <span style={{ fontSize: 9, fontWeight: 800, color: isUp ? '#7A4F0E' : '#5C1A0C',
                                  marginTop: 2 }}>{isUp ? '↑ UP' : '↓ DOWN'}</span>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6 }}>
                    <div style={{ fontSize: 13.5, fontWeight: 700 }}>{c.st}</div>
                    <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)',
                                                         whiteSpace: 'nowrap' }}>{c.t}</span>
                  </div>
                  <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>
                    {c.cohort} · <span style={{ color: isUp ? 'var(--sf-accent-ink)' : 'var(--sf-danger)',
                                                  fontWeight: 600 }}>{c.type}</span>
                  </div>
                  <div style={{ marginTop: 6, padding: 8, borderRadius: 8,
                                  background: 'var(--sf-surface-2)',
                                  fontSize: 12, color: 'var(--sf-ink-2)',
                                  fontStyle: 'italic', lineHeight: 1.4 }}>
                    “{c.reason}”
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* FAB-ish primary action */}
      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)' }}>
        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 50 }}>
          {React.cloneElement(Icons.plus, { size: 18 })}
          Karta berish
        </button>
      </div>

      <SfTabBar active="cohort" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

// Give-card flow — student selected, choose type, write reason.
function GiveCardScreen({ platform = 'ios' }) {
  const types = [
    { id: 'star', n: 'Yulduz karta', s: 'Asosiy musbat', kind: 'up', active: true },
    { id: 'active', n: 'Aktivlik', s: 'Darsda ishtirok', kind: 'up' },
    { id: 'helper', n: 'Yordamchi', s: 'Sinfdosh yordami', kind: 'up' },
    { id: 'tidy', n: 'Toza ish', s: 'Daftar / vazifa', kind: 'up' },
    { id: 'warn', n: 'Ogohlantirish', s: 'Asosiy salbiy', kind: 'down' },
    { id: 'late', n: 'Mas‘uliyatsizlik', s: 'Uy ishi · kechikish', kind: 'down' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ color: 'var(--sf-primary)', fontSize: 16, fontWeight: 600 }}>Bekor</span>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Karta berish</div>
          </div>
          <span style={{ color: 'var(--sf-primary)', fontWeight: 700, fontSize: 15, opacity: 0.5 }}>Saqlash</span>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        {/* Recipient */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Qabul qiluvchi</div>
        <div className="sf-card" style={{ padding: 12, display: 'flex',
                                            alignItems: 'center', gap: 12 }}>
          <SfAvatar name="Akbarov Akmal" size={40} color="var(--sf-primary)" />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Akbarov Akmal</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>9-B Algebra · 14 yosh</div>
          </div>
          <span style={{ fontSize: 12, color: 'var(--sf-primary)', fontWeight: 600 }}>O‘zgartirish</span>
        </div>

        {/* Type picker */}
        <div style={{ marginTop: 18, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'baseline' }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>Karta turi</div>
          <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
            Markaz <span className="sf-mono" style={{ color: 'var(--sf-ink-2)' }}>v2.3</span>
          </span>
        </div>

        <div style={{ marginTop: 8, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {types.map(t => {
            const isUp = t.kind === 'up';
            const on = t.active;
            return (
              <div key={t.id} style={{
                padding: 12, borderRadius: 14,
                background: on ? (isUp ? '#F6E0AC' : '#F0C9BE') : 'var(--sf-surface)',
                border: on ? `1.5px solid ${isUp ? '#C49A3A' : '#A14026'}`
                            : '1px solid var(--sf-border)',
                position: 'relative', display: 'flex', alignItems: 'flex-start', gap: 10,
              }}>
                <div style={{
                  width: 28, height: 36, borderRadius: 6,
                  background: isUp ? '#E9C272' : '#D88A75',
                  border: `1px solid ${isUp ? '#A47B22' : '#A14026'}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}><SfStar size={14} color={isUp ? '#5C3E08' : '#5C1A0C'} /></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, fontWeight: 700,
                                  color: on ? (isUp ? '#5C3E08' : '#5C1A0C') : 'var(--sf-ink)',
                                  lineHeight: 1.15 }}>{t.n}</div>
                  <div style={{ fontSize: 10, color: on ? (isUp ? '#7A4F0E' : '#9A4628') : 'var(--sf-muted)',
                                  marginTop: 2 }}>{t.s}</div>
                </div>
                {on && (
                  <div style={{
                    position: 'absolute', top: 6, right: 6,
                    width: 18, height: 18, borderRadius: '50%',
                    background: isUp ? '#7A4F0E' : '#5C1A0C', color: '#FFFCF5',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>{React.cloneElement(Icons.check, { size: 12, stroke: 3 })}</div>
                )}
              </div>
            );
          })}
        </div>

        {/* Reason */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Sabab · ixtiyoriy
        </div>
        <div className="sf-card" style={{ padding: 14, minHeight: 80 }}>
          <div style={{ fontSize: 14, color: 'var(--sf-ink)', lineHeight: 1.5 }}>
            Mustaqil yechim · 3-misol
            <span style={{ animation: 'sfBlink 1.1s steps(2) infinite',
                            color: 'var(--sf-primary)', marginLeft: 2 }}>|</span>
          </div>
          <div style={{ marginTop: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {['Aktivlik', 'Tezkor javob', 'Toza daftar', 'Yordam'].map(s => (
              <span key={s} className="sf-chip">+ {s}</span>
            ))}
          </div>
        </div>

        {/* AI suggestion */}
        <div className="sf-ai-surface" style={{ marginTop: 14, padding: 14, borderRadius: 14 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge compact>Sabab taklifi</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 12.5, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              Bugungi darsda Akmalning 3-mashqdagi yechimi <strong>algebraik fikrlash</strong> kuchli ekanini ko‘rsatdi.
            </div>
          </div>
        </div>

        {/* Preview */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 10 }}>
          Ko‘rinish
        </div>
        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <SfCard kind="up" size="lg"
                  recipient="Akbarov Akmal" reason="Mustaqil yechim · 3-misol"
                  issuer="N. Karimova" when="19.05 · 09:42" typeName="Yulduz karta" />
        </div>

        {/* Options */}
        <div className="sf-card" style={{ marginTop: 18, padding: 0, overflow: 'hidden' }}>
          {[
            { l: 'Ota-onaga xabar yuborish', toggle: true },
            { l: 'Chop etish (Print)', toggle: false },
            { l: 'Sinf chatida e‘lon qilish', toggle: false },
          ].map((o, i, a) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center',
                                    padding: '12px 14px',
                                    borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none' }}>
              <span style={{ flex: 1, fontSize: 13.5 }}>{o.l}</span>
              <div style={{
                width: 44, height: 26, borderRadius: 999,
                background: o.toggle ? 'var(--sf-primary)' : 'var(--sf-surface-3)',
                padding: 3,
              }}>
                <div style={{ width: 20, height: 20, borderRadius: '50%', background: '#FFFCF5',
                                boxShadow: '0 1px 2px rgba(0,0,0,0.2)',
                                transform: o.toggle ? 'translateX(18px)' : 'translateX(0)',
                                transition: 'transform 0.2s' }} />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Footer */}
      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)',
                     display: 'flex', gap: 8 }}>
        <button className="sf-btn sf-btn--ghost" style={{ width: 50, padding: 0 }}>
          {React.cloneElement(Icons.print, { size: 18 })}
        </button>
        <button className="sf-btn sf-btn--primary" style={{ flex: 1, height: 50 }}>
          Karta berish
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`@keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }`}</style>
    </SfFrame>
  );
}

Object.assign(window, { CardsScreen, GiveCardScreen });
