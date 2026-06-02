// tf-screens-a.jsx — Brand card, Onboarding, Today, Schedule, Lesson, Attendance

// ─────────────────────────────────────────────────────────────
// BRAND IDENTITY CARD — wordmark, type, palette, motif
// ─────────────────────────────────────────────────────────────
function BrandCard() {
  return (
    <div className="sf-app" style={{
      width: '100%', height: '100%', padding: 36, overflow: 'hidden',
      background: 'var(--sf-bg)', position: 'relative',
    }}>
      {/* Big mark */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
        <SfStar size={64} color="var(--sf-primary)" />
        <div>
          <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
                        color: 'var(--sf-muted)', fontWeight: 600 }}>
            Identity · v1
          </div>
          <div style={{ fontFamily: 'var(--sf-font-ui)', fontSize: 38, fontWeight: 800,
                        letterSpacing: '-0.035em', color: 'var(--sf-ink)', lineHeight: 1 }}>
            StarForge<span style={{ color: 'var(--sf-muted)', fontWeight: 500 }}> · EDU</span>
          </div>
          <div style={{ marginTop: 6, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                        fontSize: 19, color: 'var(--sf-ink-2)' }}>
            Maktab uchun zamonaviy platforma.
          </div>
        </div>
      </div>

      <div style={{ marginTop: 28, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
        {/* Type spec */}
        <div className="sf-card" style={{ padding: 20 }}>
          <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
                        color: 'var(--sf-muted)', fontWeight: 600, marginBottom: 12 }}>Type</div>
          <div style={{ fontFamily: 'var(--sf-font-ui)', fontSize: 28, fontWeight: 800,
                        letterSpacing: '-0.03em', lineHeight: 1.05 }}>
            Manrope <span style={{ fontWeight: 400, color: 'var(--sf-muted)' }}>· UI</span>
          </div>
          <div style={{ marginTop: 8, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                        fontSize: 24, color: 'var(--sf-ink-2)' }}>
            Instrument Serif · ifoda
          </div>
          <div style={{ marginTop: 8, fontFamily: 'var(--sf-font-mono)', fontSize: 14,
                        color: 'var(--sf-muted)' }}>
            JetBrains Mono · ↑18 ↓4 · 09:42
          </div>
        </div>

        {/* Palette */}
        <div className="sf-card" style={{ padding: 20 }}>
          <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
                        color: 'var(--sf-muted)', fontWeight: 600, marginBottom: 12 }}>Palette · Saroy</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 6 }}>
            {['var(--sf-ink)', 'var(--sf-primary)', 'var(--sf-accent)', 'var(--sf-surface-2)', 'var(--sf-surface)'].map((c, i) => (
              <div key={i} style={{ height: 56, borderRadius: 10, background: c,
                                    border: '1px solid var(--sf-border)' }} />
            ))}
          </div>
          <div style={{ marginTop: 12, fontSize: 12, color: 'var(--sf-muted)', lineHeight: 1.5 }}>
            Ink · Terracotta · Saffron · Surface 2 · Surface
          </div>
        </div>

        {/* Motif card */}
        <div className="sf-card" style={{ padding: 20, gridColumn: '1 / -1', display: 'flex', gap: 18, alignItems: 'center' }}>
          <div style={{ display: 'flex', gap: 12 }}>
            <SfStar size={48} color="var(--sf-primary)" />
            <SfStar size={48} color="var(--sf-accent)" />
            <SfStar size={48} color="var(--sf-ink)" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase',
                          color: 'var(--sf-muted)', fontWeight: 600 }}>Motif</div>
            <div style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                          fontSize: 22, color: 'var(--sf-ink)', lineHeight: 1.3 }}>
              Sakkiz qirrali yulduz — Markaziy Osiyo geometrik naqshlariga ishora. Modern, soddalashtirilgan.
            </div>
          </div>
        </div>
      </div>

      {/* Decorative tile in corner */}
      <div style={{
        position: 'absolute', right: -60, bottom: -60, width: 260, height: 260,
        opacity: 0.08, pointerEvents: 'none',
      }}>
        <SfStar size={260} color="var(--sf-primary)" />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING — Phone, OTP, Welcome (per-platform inner)
// ─────────────────────────────────────────────────────────────
function OnboardPhone({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ flex: 1, padding: '12px 28px 24px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ marginTop: 24, display: 'flex', alignItems: 'center', gap: 10 }}>
          <SfStar size={28} color="var(--sf-primary)" />
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.02em' }}>
            StarForge<span style={{ color: 'var(--sf-muted)', fontWeight: 500 }}> · EDU</span>
          </div>
        </div>

        <div style={{ marginTop: 56 }}>
          <div style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                        fontSize: 36, lineHeight: 1.05, color: 'var(--sf-ink)' }}>
            Xush kelibsiz,
          </div>
          <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: '-0.03em',
                        marginTop: 2, color: 'var(--sf-ink)' }}>
            ustoz.
          </div>
          <div style={{ marginTop: 16, fontSize: 15, color: 'var(--sf-muted)',
                        lineHeight: 1.5, maxWidth: 280 }}>
            Markazingiz tomonidan berilgan telefon raqami orqali kiring. SMS bilan tasdiqlaymiz.
          </div>
        </div>

        {/* Phone input */}
        <div style={{ marginTop: 40 }}>
          <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.06em',
                        textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 10 }}>
            Telefon raqami
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: 'var(--sf-surface)', border: '1.5px solid var(--sf-primary)',
            borderRadius: 16, padding: '14px 16px',
            boxShadow: '0 0 0 4px var(--sf-primary-soft)',
          }}>
            <span style={{ fontFamily: 'var(--sf-font-mono)', fontSize: 16, color: 'var(--sf-ink-2)' }}>+998</span>
            <span style={{ width: 1, height: 22, background: 'var(--sf-border)' }} />
            <span className="sf-mono" style={{ fontSize: 20, fontWeight: 500,
                                                color: 'var(--sf-ink)', letterSpacing: '0.04em' }}>
              90 123 45 67
            </span>
            <span style={{ flex: 1 }} />
            <div style={{ width: 8, height: 22, background: 'var(--sf-primary)', borderRadius: 2 }} />
          </div>
          <div style={{ marginTop: 10, fontSize: 12, color: 'var(--sf-muted)' }}>
            Operator: <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>Beeline UZ</span>
          </div>
        </div>

        <div style={{ flex: 1 }} />

        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 54, fontSize: 16 }}>
          Tasdiq kodini yuborish
          {React.cloneElement(Icons.arrowR, { size: 18 })}
        </button>

        <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center', gap: 18,
                       fontSize: 12, color: 'var(--sf-muted)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            {React.cloneElement(Icons.globe, { size: 14 })} O‘zbekcha
          </span>
          <span>·</span>
          <span>Yordam kerakmi?</span>
        </div>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function OnboardOtp({ platform = 'ios' }) {
  const digits = ['4', '8', '2', '1', '', ''];
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ padding: '4px 18px 0' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 4 }}>
          <div style={{ color: 'var(--sf-primary)', display: 'inline-flex', alignItems: 'center', gap: 2 }}>
            {React.cloneElement(Icons.arrowL, { size: 18 })}
            <span style={{ fontSize: 16, fontWeight: 600 }}>Orqaga</span>
          </div>
        </div>
      </div>

      <div style={{ padding: '8px 28px 24px', display: 'flex', flexDirection: 'column', flex: 1 }}>
        <div style={{ fontSize: 30, fontWeight: 800, letterSpacing: '-0.03em', lineHeight: 1.1 }}>
          Tasdiq <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontWeight: 400 }}>kodini</span> kiriting
        </div>
        <div style={{ marginTop: 12, fontSize: 14, color: 'var(--sf-muted)', lineHeight: 1.5 }}>
          <span className="sf-mono">+998 90 123 45 67</span> raqamiga 6 xonali kod yubordik.
        </div>

        {/* OTP boxes */}
        <div style={{ marginTop: 36, display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10 }}>
          {digits.map((d, i) => (
            <div key={i} style={{
              height: 60, borderRadius: 14,
              background: d ? 'var(--sf-surface)' : 'var(--sf-surface-2)',
              border: i === 4 ? '2px solid var(--sf-primary)' : '1px solid var(--sf-border)',
              boxShadow: i === 4 ? '0 0 0 4px var(--sf-primary-soft)' : 'none',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'var(--sf-font-mono)', fontSize: 26, fontWeight: 600,
              color: 'var(--sf-ink)',
              position: 'relative',
            }}>
              {d}
              {i === 4 && (
                <div style={{
                  position: 'absolute', width: 2, height: 28, background: 'var(--sf-primary)',
                  animation: 'sfBlink 1.1s steps(2) infinite',
                }} />
              )}
            </div>
          ))}
        </div>

        {/* Resend */}
        <div style={{ marginTop: 24, display: 'flex', alignItems: 'center',
                       justifyContent: 'space-between' }}>
          <span style={{ fontSize: 13, color: 'var(--sf-muted)' }}>
            Yana kod yuborish: <span className="sf-mono" style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>00:42</span>
          </span>
          <span style={{ fontSize: 13, color: 'var(--sf-primary)', fontWeight: 600 }}>SMS o‘rniga qo‘ng‘iroq</span>
        </div>

        {/* AI assist note */}
        <div className="sf-ai-surface" style={{ marginTop: 24, padding: 14, borderRadius: 14,
                                                 display: 'flex', gap: 12, alignItems: 'flex-start',
                                                 position: 'relative' }}>
          <div style={{ width: 32, height: 32, borderRadius: 8, background: 'var(--sf-surface)',
                         border: '1px solid var(--sf-ai-border)',
                         display: 'flex', alignItems: 'center', justifyContent: 'center',
                         color: 'var(--sf-ai)', flexShrink: 0, position: 'relative', zIndex: 1 }}>
            {Icons.shield}
          </div>
          <div style={{ fontSize: 12.5, lineHeight: 1.5, color: 'var(--sf-ink-2)',
                         position: 'relative', zIndex: 1 }}>
            <strong>Xavfsizlik:</strong> StarForge sizning raqamingizni 3-tomonlarga bermaydi. Kod faqat shu qurilmada amal qiladi.
          </div>
        </div>

        <div style={{ flex: 1 }} />

        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 54, fontSize: 16, opacity: 0.5 }}>
          Tasdiqlash
        </button>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`@keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }`}</style>
    </SfFrame>
  );
}

function OnboardWelcome({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Decorative bg */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(120% 80% at 50% 0%, var(--sf-accent-soft) 0%, transparent 55%)',
        }} />
        <div className="sf-pattern" style={{ position: 'absolute', inset: 0 }} />

        <div style={{ position: 'relative', padding: '40px 28px 24px',
                       display: 'flex', flexDirection: 'column', height: '100%' }}>
          {/* Avatar */}
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: 24 }}>
            <div style={{ position: 'relative' }}>
              <div style={{
                position: 'absolute', inset: -16, borderRadius: '50%',
                background: 'var(--sf-accent-soft)', filter: 'blur(20px)',
              }} />
              <SfAvatar name="Nigora Karimova" size={96} color="var(--sf-primary)" />
            </div>
            <div style={{ marginTop: 18, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 26, color: 'var(--sf-ink-2)' }}>
              Assalomu alaykum,
            </div>
            <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em',
                           color: 'var(--sf-ink)', marginTop: 2 }}>
              Nigora opa
            </div>
          </div>

          {/* Tenant card */}
          <div className="sf-card" style={{ marginTop: 28, padding: 18, display: 'flex',
                                              alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 48, height: 48, borderRadius: 12,
              background: 'var(--sf-primary)', color: 'var(--sf-surface)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontSize: 22,
            }}>D</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, color: 'var(--sf-muted)' }}>O‘quv markaz</div>
              <div style={{ fontSize: 16, fontWeight: 700, color: 'var(--sf-ink)' }}>Demo Akademiya</div>
              <div className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>demo.starforge.uz</div>
            </div>
            <div style={{ color: 'var(--sf-primary)' }}>{React.cloneElement(Icons.check, { size: 22 })}</div>
          </div>

          {/* Stats peek */}
          <div style={{ marginTop: 18, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
            {[
              { v: '4', l: 'Guruh' },
              { v: '78', l: 'O‘quvchi' },
              { v: '12', l: 'Dars / hafta' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: 14, borderRadius: 14, background: 'var(--sf-surface)',
                border: '1px solid var(--sf-border)', textAlign: 'center',
              }}>
                <div className="sf-mono" style={{ fontSize: 24, fontWeight: 700,
                                                    color: 'var(--sf-primary)', lineHeight: 1 }}>{s.v}</div>
                <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-muted)',
                               letterSpacing: '0.04em', textTransform: 'uppercase' }}>{s.l}</div>
              </div>
            ))}
          </div>

          <div style={{ flex: 1 }} />

          <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 54, fontSize: 16 }}>
            Boshlash
            {React.cloneElement(Icons.arrowR, { size: 18 })}
          </button>
          <div style={{ marginTop: 12, textAlign: 'center', fontSize: 12, color: 'var(--sf-muted)' }}>
            Bu siz emasmisiz? <span style={{ color: 'var(--sf-primary)', fontWeight: 600 }}>Chiqish</span>
          </div>
        </div>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

// ─────────────────────────────────────────────────────────────
// TODAY DASHBOARD
// ─────────────────────────────────────────────────────────────
function TodayScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}

      {/* Header */}
      <div style={{ padding: platform === 'ios' ? '8px 20px 12px' : '12px 18px 14px',
                     background: 'var(--sf-surface)', borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <SfAvatar name="Nigora Karimova" size={36} color="var(--sf-primary)" />
            <div>
              <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>Seshanba · 19 May</div>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>Bugun, Nigora opa</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <div style={{ position: 'relative', width: 38, height: 38, borderRadius: 12,
                           background: 'var(--sf-surface-2)', display: 'flex', alignItems: 'center',
                           justifyContent: 'center' }}>
              {React.cloneElement(Icons.bell, { size: 20 })}
              <div style={{ position: 'absolute', top: 7, right: 9, width: 8, height: 8,
                             borderRadius: '50%', background: 'var(--sf-primary)',
                             border: '2px solid var(--sf-surface-2)' }} />
            </div>
            <div style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--sf-surface-2)',
                           display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {React.cloneElement(Icons.search, { size: 20 })}
            </div>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', padding: '16px 18px 100px',
                     background: 'var(--sf-bg)' }}>

        {/* SURVEY URGENT BANNER */}
        <div style={{
          position: 'relative', borderRadius: 16, overflow: 'hidden',
          background: 'linear-gradient(135deg, #FCEFD0 0%, #F6E0AC 100%)',
          border: '1.5px solid var(--sf-accent)',
          padding: 14, marginBottom: 14,
          boxShadow: '0 0 0 4px rgba(216,154,46,0.20), 0 8px 24px rgba(216,154,46,0.18)',
        }}>
          <div style={{ position: 'absolute', inset: 0, borderRadius: 16,
                          border: '2px solid var(--sf-accent)', opacity: 0.4,
                          animation: 'sfPulse 1.8s ease-in-out infinite', pointerEvents: 'none' }} />
          <div style={{ position: 'absolute', right: -20, top: -20, opacity: 0.18 }}>
            <SfStar size={100} color="#7A4F0E" />
          </div>
          <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 8, height: 8, borderRadius: '50%', background: 'var(--sf-danger)',
              animation: 'sfBlink 1s steps(2) infinite', flexShrink: 0,
            }} />
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em',
                              textTransform: 'uppercase', color: 'var(--sf-danger)' }}>
                So‘rovnoma · 2 kun 14 soat qoldi
              </div>
              <div style={{ marginTop: 2, fontSize: 14, fontWeight: 700, color: 'var(--sf-ink)' }}>
                Oylik o‘qituvchi qoniqishi
              </div>
              <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-ink-2)' }}>
                12 savol · ~4 daq · 33% tugatildi
              </div>
            </div>
            <button className="sf-btn" style={{ background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                                                  fontSize: 12, padding: '8px 12px' }}>
              Davom {React.cloneElement(Icons.arrowR, { size: 12 })}
            </button>
          </div>
        </div>

        {/* Hero — next lesson */}
        <div style={{
          borderRadius: 22, padding: 18, position: 'relative', overflow: 'hidden',
          background: 'linear-gradient(135deg, var(--sf-primary) 0%, var(--sf-primary-hover) 100%)',
          color: '#FFFCF5',
        }}>
          <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.18 }}>
            <SfStar size={160} color="#FFFCF5" />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <div style={{ fontSize: 11, letterSpacing: '0.14em', textTransform: 'uppercase',
                               fontWeight: 600, opacity: 0.85 }}>Keyingi dars · 14 daqiqa</div>
                <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: '-0.02em',
                               marginTop: 6, lineHeight: 1.1 }}>
                  Algebra · Daraja II
                </div>
                <div style={{ marginTop: 4, fontSize: 14, opacity: 0.9 }}>
                  Guruh <span style={{ fontWeight: 700 }}>9-B</span> · 24 o‘quvchi · 304-xona
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div className="sf-mono" style={{ fontSize: 22, fontWeight: 600 }}>09:00</div>
                <div style={{ fontSize: 11, opacity: 0.85 }}>– 09:45</div>
              </div>
            </div>
            <div style={{ marginTop: 18, display: 'flex', gap: 8 }}>
              <button style={{
                flex: 1, height: 42, borderRadius: 999, border: 'none',
                background: '#FFFCF5', color: 'var(--sf-primary)',
                fontFamily: 'inherit', fontWeight: 700, fontSize: 14,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              }}>{React.cloneElement(Icons.check, { size: 16 })} Davomat olish</button>
              <button style={{
                width: 42, height: 42, borderRadius: 999, border: '1px solid rgba(255,252,245,0.4)',
                background: 'transparent', color: '#FFFCF5',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{React.cloneElement(Icons.more, { size: 18 })}</button>
            </div>
          </div>
        </div>

        {/* Quick stats */}
        <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {[
            { v: '4', l: 'Bugungi dars', sub: '/ 5' },
            { v: '94', l: 'Davomat', sub: '%', tone: 'var(--sf-success)' },
            { v: '↑8 ↓2', l: 'Kartalar', sub: 'bugun', tone: 'var(--sf-accent-ink)', compact: true },
          ].map((s, i) => (
            <div key={i} className="sf-card" style={{ padding: 12 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
                <span className="sf-mono" style={{ fontSize: s.compact ? 16 : 22, fontWeight: 700,
                                                     color: s.tone || 'var(--sf-ink)', lineHeight: 1 }}>{s.v}</span>
                <span style={{ fontSize: 10, color: 'var(--sf-muted)', fontWeight: 600 }}>{s.sub}</span>
              </div>
              <div style={{ marginTop: 6, fontSize: 11, color: 'var(--sf-muted)',
                             letterSpacing: '0.02em', textTransform: 'uppercase', fontWeight: 600 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* AI panel — Hero feature */}
        <div className="sf-ai-surface" style={{ marginTop: 16, padding: 16, borderRadius: 22 }}>
          <div style={{ position: 'relative', zIndex: 1, display: 'flex', justifyContent: 'space-between',
                         alignItems: 'flex-start' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <SfAiBadge>Ko‘rib chiqing</SfAiBadge>
            </div>
            <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>3 dona</span>
          </div>
          <div style={{ position: 'relative', zIndex: 1, marginTop: 10,
                         fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                         fontSize: 19, color: 'var(--sf-ink)', lineHeight: 1.3 }}>
            “Otabekka oxirgi haftada 2 ta Down karta berildi va davomati pasaymoqda. Ota bilan suhbat tavsiya etiladi.”
          </div>
          <div style={{ position: 'relative', zIndex: 1, marginTop: 12, display: 'flex', gap: 8 }}>
            <button className="sf-btn" style={{ background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                                                  fontSize: 13, padding: '8px 14px' }}>
              Tavsiyani ko‘rish {React.cloneElement(Icons.arrowR, { size: 14 })}
            </button>
            <button className="sf-btn sf-btn--ghost" style={{ fontSize: 13, padding: '8px 14px',
                                                                 background: 'rgba(255,252,245,0.5)' }}>
              Keyinroq
            </button>
          </div>
        </div>

        {/* Today schedule list */}
        <div style={{ marginTop: 22, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'baseline', padding: '0 4px' }}>
          <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>
            Bugungi jadval
          </h3>
          <span style={{ fontSize: 12, color: 'var(--sf-primary)', fontWeight: 600 }}>
            Hammasi {React.cloneElement(Icons.chevR, { size: 12 })}
          </span>
        </div>

        <div className="sf-card" style={{ marginTop: 10, padding: 0, overflow: 'hidden' }}>
          {[
            { t: '09:00', d: 'Algebra · 9-B', room: '304', state: 'now', mins: '14m' },
            { t: '10:00', d: 'Algebra · 9-A', room: '304', state: 'next' },
            { t: '11:30', d: 'Geometriya · 10-V', room: '301', state: '' },
            { t: '14:00', d: 'Bo‘sh oraliq', room: 'Tushlik', state: 'gap' },
            { t: '15:00', d: 'Tayyorlov · 11-B', room: '210', state: '' },
          ].map((row, i, arr) => (
            <div key={i} style={{
              display: 'flex', gap: 12, padding: '12px 16px',
              borderBottom: i < arr.length - 1 ? '1px solid var(--sf-border)' : 'none',
              alignItems: 'center',
              background: row.state === 'gap' ? 'var(--sf-surface-2)' : 'transparent',
              opacity: row.state === 'gap' ? 0.75 : 1,
            }}>
              <div className="sf-mono" style={{ width: 46, fontSize: 13, fontWeight: 600,
                                                  color: 'var(--sf-ink-2)' }}>{row.t}</div>
              <div style={{ width: 3, alignSelf: 'stretch', borderRadius: 2,
                             background: row.state === 'now' ? 'var(--sf-primary)' :
                                          row.state === 'gap' ? 'var(--sf-border-strong)' :
                                          'var(--sf-accent)' }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--sf-ink)' }}>{row.d}</div>
                <div style={{ fontSize: 11.5, color: 'var(--sf-muted)' }}>Xona {row.room}</div>
              </div>
              {row.state === 'now' && <SfPill tone="primary">Hozir · {row.mins}</SfPill>}
              {row.state === 'next' && <SfPill tone="accent">Keyingi</SfPill>}
            </div>
          ))}
        </div>

        {/* Recent cards */}
        <div style={{ marginTop: 20, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'baseline', padding: '0 4px' }}>
          <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, letterSpacing: '-0.01em' }}>
            So‘nggi kartalar
          </h3>
          <span style={{ fontSize: 12, color: 'var(--sf-primary)', fontWeight: 600 }}>
            10 ta {React.cloneElement(Icons.chevR, { size: 12 })}
          </span>
        </div>

        <div style={{ marginTop: 10, display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 4 }}>
          <SfCard kind="up" size="md" recipient="Akbarov A." reason="Mustaqil yechim · 3-misol"
                  issuer="N. Karimova" when="09:42" typeName="Yulduz karta" />
          <SfCard kind="up" size="md" recipient="Halimova Z." reason="Aktivlik · sinfdosh yordami"
                  issuer="N. Karimova" when="09:38" typeName="Aktivlik" />
          <SfCard kind="down" size="md" recipient="Eshmatov O." reason="Uy ishi tayyor emas (2-marta)"
                  issuer="N. Karimova" when="09:12" typeName="Ogohlantirish" />
        </div>

        {/* Print preview */}
        <div className="sf-card" style={{ marginTop: 18, padding: 14,
                                            display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: 'var(--sf-primary-soft)', color: 'var(--sf-primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            position: 'relative', flexShrink: 0,
          }}>
            {React.cloneElement(Icons.print, { size: 22 })}
            <div className="sf-mono" style={{
              position: 'absolute', top: -6, right: -6,
              minWidth: 18, padding: '0 5px', borderRadius: 10,
              background: 'var(--sf-primary)', color: '#FFFCF5',
              fontSize: 10, fontWeight: 700,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>2</div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13.5, fontWeight: 700 }}>Print navbatim · 2 ta</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
              Kvadrat tenglamalar · <span style={{ color: 'var(--sf-success)', fontWeight: 600 }}>64% tugadi</span>
            </div>
          </div>
          {React.cloneElement(Icons.chevR, { size: 16 })}
        </div>
      </div>

      <SfTabBar active="home" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`
        @keyframes sfPulse {
          0%, 100% { opacity: 0.40; transform: scale(1); }
          50% { opacity: 0; transform: scale(1.03); }
        }
        @keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }
      `}</style>
    </SfFrame>
  );
}

// ─────────────────────────────────────────────────────────────
// SCHEDULE — week + day
// ─────────────────────────────────────────────────────────────
function ScheduleScreen({ platform = 'ios' }) {
  const days = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
  const hours = ['08', '09', '10', '11', '12', '13', '14', '15'];
  const lessons = [
    { d: 0, s: 1, e: 1.75, label: 'Algebra · 9-B', color: 'var(--sf-primary)', tone: 'soft' },
    { d: 1, s: 1, e: 1.75, label: 'Algebra · 9-A', color: 'var(--sf-primary)' },
    { d: 1, s: 3.5, e: 4.5, label: 'Geom · 10-V', color: 'var(--sf-accent)' },
    { d: 2, s: 2, e: 3,    label: 'Algebra · 9-B', color: 'var(--sf-primary)' },
    { d: 2, s: 6, e: 7,    label: 'Tayyorlov · 11', color: 'var(--sf-ink-2)' },
    { d: 3, s: 0.5, e: 1.5, label: 'Algebra · 9-A', color: 'var(--sf-primary)' },
    { d: 3, s: 3, e: 4,    label: 'Geom · 10-V', color: 'var(--sf-accent)' },
    { d: 4, s: 2, e: 3,    label: 'Algebra · 9-B', color: 'var(--sf-primary)' },
    { d: 5, s: 1, e: 2.5,  label: 'Konsultatsiya', color: 'var(--sf-ink-2)' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ padding: '8px 20px 0', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontSize: 12, color: 'var(--sf-muted)' }}>May 2026</div>
            <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: '-0.02em' }}>
              19-hafta
            </div>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['Kun', 'Hafta', 'Oy'].map((m, i) => (
              <div key={m} style={{
                padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
                background: i === 1 ? 'var(--sf-ink)' : 'transparent',
                color: i === 1 ? 'var(--sf-bg)' : 'var(--sf-muted)',
                border: i === 1 ? 'none' : '1px solid var(--sf-border)',
              }}>{m}</div>
            ))}
          </div>
        </div>
        {/* Day strip */}
        <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4,
                       paddingBottom: 12 }}>
          {days.map((d, i) => {
            const isToday = i === 1;
            return (
              <div key={d} style={{
                padding: '8px 0', borderRadius: 12, textAlign: 'center',
                background: isToday ? 'var(--sf-primary)' : 'transparent',
                color: isToday ? 'var(--sf-bg)' : 'var(--sf-ink-2)',
              }}>
                <div style={{ fontSize: 10, opacity: 0.7, textTransform: 'uppercase',
                               letterSpacing: '0.05em' }}>{d}</div>
                <div style={{ fontSize: 18, fontWeight: 700, marginTop: 2 }}>{18 + i}</div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Week grid */}
      <div style={{ flex: 1, overflow: 'hidden', background: 'var(--sf-bg)',
                     display: 'flex', flexDirection: 'column', borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ flex: 1, display: 'grid',
                       gridTemplateColumns: '32px 1fr', overflow: 'hidden' }}>
          {/* Hours column */}
          <div style={{ paddingTop: 8 }}>
            {hours.map(h => (
              <div key={h} className="sf-mono" style={{
                height: 48, fontSize: 10, color: 'var(--sf-muted)',
                paddingLeft: 4, paddingTop: 2,
              }}>{h}:00</div>
            ))}
          </div>
          {/* Day columns */}
          <div style={{
            position: 'relative',
            display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
            backgroundImage: 'repeating-linear-gradient(to bottom, transparent, transparent 47px, var(--sf-border) 47px, var(--sf-border) 48px)',
            paddingTop: 8,
          }}>
            {[0,1,2,3,4,5,6].map(d => (
              <div key={d} style={{
                borderLeft: '1px solid var(--sf-border)',
                position: 'relative', minHeight: 48 * 8,
              }}>
                {lessons.filter(l => l.d === d).map((l, i) => (
                  <div key={i} style={{
                    position: 'absolute', left: 2, right: 2,
                    top: 4 + l.s * 48, height: (l.e - l.s) * 48 - 4,
                    background: l.color, color: '#FFFCF5',
                    borderRadius: 6, padding: '4px 5px',
                    fontSize: 9, fontWeight: 600, lineHeight: 1.15,
                    overflow: 'hidden',
                  }}>{l.label}</div>
                ))}
              </div>
            ))}
            {/* Now line */}
            <div style={{
              position: 'absolute', top: 8 + 1 * 48 + 24, left: 0, right: 0,
              borderTop: '1.5px solid var(--sf-primary)',
              zIndex: 2,
            }}>
              <div style={{ position: 'absolute', left: -4, top: -5, width: 8, height: 8,
                             borderRadius: '50%', background: 'var(--sf-primary)' }} />
            </div>
          </div>
        </div>
      </div>

      {/* Today list peek */}
      <div style={{ background: 'var(--sf-surface)', padding: '12px 16px 6px',
                     maxHeight: 200, overflow: 'hidden' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
                       marginBottom: 6 }}>
          <div style={{ fontSize: 14, fontWeight: 700 }}>Seshanba · bugun</div>
          <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>5 ta dars</span>
        </div>
        {[
          { t: '09:00', l: 'Algebra · 9-B', s: 'Hozir' },
          { t: '10:00', l: 'Algebra · 9-A', s: 'Keyingi' },
          { t: '11:30', l: 'Geom · 10-V', s: '' },
        ].map((r, i) => (
          <div key={i} style={{ display: 'flex', gap: 10, padding: '8px 0',
                                  borderTop: i ? '1px solid var(--sf-border)' : 'none', alignItems: 'center' }}>
            <span className="sf-mono" style={{ width: 38, fontSize: 12, color: 'var(--sf-muted)' }}>{r.t}</span>
            <span style={{ flex: 1, fontSize: 13, fontWeight: 600 }}>{r.l}</span>
            {r.s && <SfPill tone={r.s === 'Hozir' ? 'primary' : 'accent'}>{r.s}</SfPill>}
          </div>
        ))}
      </div>

      <SfTabBar active="sched" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

// ─────────────────────────────────────────────────────────────
// LESSON DETAIL
// ─────────────────────────────────────────────────────────────
function LessonScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS
        left={<><span style={{ display: 'inline-flex', alignItems: 'center' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}Jadval</span></>}
        right={<>{Icons.more}</>}
        title="Algebra · Daraja II"
      />
      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '8px 18px 100px' }}>
        {/* Hero */}
        <div className="sf-card" style={{ padding: 18, position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', right: -20, top: -20, opacity: 0.08 }}>
            <SfStar size={130} color="var(--sf-primary)" />
          </div>
          <div style={{ position: 'relative' }}>
            <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
              <SfPill tone="primary">Hozir</SfPill>
              <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>L-204</span>
            </div>
            <div style={{ marginTop: 10, fontSize: 24, fontWeight: 800, letterSpacing: '-0.02em',
                           lineHeight: 1.15 }}>
              Algebra · <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontWeight: 400 }}>Daraja II</span>
            </div>
            <div style={{ marginTop: 4, fontSize: 13.5, color: 'var(--sf-muted)' }}>
              Mavzu: <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>Kvadrat tenglamalarni yechish</span>
            </div>
            <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
              {[
                { l: 'Vaqt', v: '09:00 – 09:45', icon: Icons.clock },
                { l: 'Xona', v: '304 · 2-qavat', icon: Icons.pin },
                { l: 'Guruh', v: '9-B · 24 nafar', icon: Icons.cohort },
              ].map((x, i) => (
                <div key={i} style={{ padding: 10, borderRadius: 12,
                                        background: 'var(--sf-surface-2)' }}>
                  <div style={{ color: 'var(--sf-muted)', display: 'flex', alignItems: 'center', gap: 4 }}>
                    {React.cloneElement(x.icon, { size: 12 })}
                    <span style={{ fontSize: 10, letterSpacing: '0.05em',
                                    textTransform: 'uppercase', fontWeight: 600 }}>{x.l}</span>
                  </div>
                  <div style={{ marginTop: 4, fontSize: 12, fontWeight: 700,
                                  color: 'var(--sf-ink)', lineHeight: 1.2 }}>{x.v}</div>
                </div>
              ))}
            </div>
            <div style={{ marginTop: 14, display: 'flex', gap: 8 }}>
              <button className="sf-btn sf-btn--primary" style={{ flex: 1 }}>
                {React.cloneElement(Icons.check, { size: 18 })} Davomatni boshlash
              </button>
              <button className="sf-btn sf-btn--ghost" style={{ width: 46, padding: 0 }}>
                {Icons.edit}
              </button>
            </div>
          </div>
        </div>

        {/* Plan */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 13, fontWeight: 700, letterSpacing: '-0.005em',
                         marginBottom: 8, padding: '0 4px',
                         display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span>Dars rejasi</span>
            <span style={{ fontSize: 11, color: 'var(--sf-muted)', fontWeight: 500 }}>4 bosqich</span>
          </div>
          <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { t: '5 daq', l: 'Salomlashish va davomat', d: true },
              { t: '15 daq', l: 'Yangi mavzu: kvadrat formulasi', d: false },
              { t: '20 daq', l: 'Mashqlar — guruhli ish', d: false },
              { t: '5 daq', l: 'Uy ishi va xulosa', d: false },
            ].map((s, i, arr) => (
              <div key={i} style={{
                display: 'flex', gap: 12, padding: '12px 16px', alignItems: 'center',
                borderBottom: i < arr.length - 1 ? '1px solid var(--sf-border)' : 'none',
              }}>
                <div style={{
                  width: 22, height: 22, borderRadius: 7, flexShrink: 0,
                  background: s.d ? 'var(--sf-success)' : 'transparent',
                  border: s.d ? 'none' : '1.5px solid var(--sf-border-strong)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#FFFCF5',
                }}>{s.d && React.cloneElement(Icons.check, { size: 14, stroke: 3 })}</div>
                <div style={{ flex: 1, fontSize: 14, fontWeight: 600,
                                opacity: s.d ? 0.5 : 1,
                                textDecoration: s.d ? 'line-through' : 'none' }}>{s.l}</div>
                <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{s.t}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Materials */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 13, fontWeight: 700, marginBottom: 8, padding: '0 4px',
                         display: 'flex', justifyContent: 'space-between' }}>
            <span>Materiallar</span>
            <span style={{ color: 'var(--sf-primary)', fontSize: 11, fontWeight: 600 }}>
              + qo‘shish
            </span>
          </div>
          <div style={{ display: 'flex', gap: 8, overflowX: 'auto' }}>
            {[
              { t: 'Kvadrat tenglama.pdf', m: '2.1 MB · 8 bet', i: Icons.pdf, c: 'var(--sf-danger)' },
              { t: 'Mashq · 12 ta', m: 'Interaktiv', i: Icons.doc, c: 'var(--sf-primary)' },
              { t: 'Video tushuntirish', m: '6:42', i: Icons.video, c: 'var(--sf-accent)' },
            ].map((f, i) => (
              <div key={i} className="sf-card" style={{ minWidth: 140, padding: 12 }}>
                <div style={{ width: 34, height: 34, borderRadius: 10,
                                background: f.c, color: '#FFFCF5',
                                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  {React.cloneElement(f.i, { size: 18 })}
                </div>
                <div style={{ marginTop: 8, fontSize: 12.5, fontWeight: 600,
                                lineHeight: 1.2 }}>{f.t}</div>
                <div style={{ marginTop: 2, fontSize: 10, color: 'var(--sf-muted)' }}>{f.m}</div>
              </div>
            ))}
          </div>
        </div>

        {/* AI: lesson assist */}
        <div className="sf-ai-surface" style={{ marginTop: 18, padding: 16, borderRadius: 18 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>Dars yordamchi</SfAiBadge>
            <div style={{ marginTop: 10, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 17, lineHeight: 1.35, color: 'var(--sf-ink)' }}>
              “Bu mavzuda o‘tgan oyda 4 nafar bola qiynalgan. Mashqdan oldin tezkor takrorlashni tavsiya qilaman.”
            </div>
            <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <span className="sf-chip sf-chip--ai">Takrorlash so‘rovi</span>
              <span className="sf-chip sf-chip--ai">Misol · oson</span>
              <span className="sf-chip sf-chip--ai">Vizual yordam</span>
            </div>
          </div>
        </div>
      </div>
      <SfTabBar active="sched" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

// ─────────────────────────────────────────────────────────────
// TAKE ATTENDANCE — the gesture marking UI
// ─────────────────────────────────────────────────────────────
function AttendanceScreen({ platform = 'ios' }) {
  const students = [
    { n: 'Akbarov Akmal', id: 'DEMO-2026-00042', s: 'present' },
    { n: 'Azizova Madina', id: 'DEMO-2026-00043', s: 'present' },
    { n: 'Bakirov Sherzod', id: 'DEMO-2026-00044', s: 'late', m: '8 daq' },
    { n: 'Davronova Sevinch', id: 'DEMO-2026-00045', s: 'present' },
    { n: 'Eshmatov Otabek', id: 'DEMO-2026-00046', s: 'absent', m: 'Kasal' },
    { n: 'Fayzullayev Diyor', id: 'DEMO-2026-00047', s: 'present' },
    { n: 'G‘aniyev Jasur', id: 'DEMO-2026-00048', s: 'present' },
    { n: 'Halimova Zilola', id: 'DEMO-2026-00049', s: 'excused', m: 'Olimpiada' },
    { n: 'Ibragimov Sardor', id: 'DEMO-2026-00050', s: 'present' },
    { n: 'Jo‘rayeva Nilufar', id: 'DEMO-2026-00051', s: 'present' },
    { n: 'Karimov Rustam', id: 'DEMO-2026-00052', s: null },
    { n: 'Latipova Shahnoza', id: 'DEMO-2026-00053', s: null },
  ];

  const colors = {
    present: { bg: 'var(--sf-success-soft)', fg: 'var(--sf-success)', l: 'Bor', dot: 'var(--sf-success)' },
    absent:  { bg: 'var(--sf-danger-soft)',  fg: 'var(--sf-danger)',  l: 'Yo‘q', dot: 'var(--sf-danger)' },
    late:    { bg: 'var(--sf-warn-soft)',    fg: 'var(--sf-warn)',    l: 'Kechikdi', dot: 'var(--sf-warn)' },
    excused: { bg: 'var(--sf-surface-3)',    fg: 'var(--sf-ink-2)',   l: 'Sababli', dot: 'var(--sf-muted)' },
  };

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}

      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px 0',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', color: 'var(--sf-primary)',
                          fontWeight: 600, fontSize: 16 }}>
            {React.cloneElement(Icons.x, { size: 18 })} Bekor
          </span>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>9-B · Algebra</div>
            <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.01em' }}>Davomat</div>
          </div>
          <span style={{ color: 'var(--sf-primary)', fontWeight: 700, fontSize: 15 }}>Saqlash</span>
        </div>

        {/* Summary strip */}
        <div style={{ padding: '14px 0 16px', display: 'grid',
                       gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
          {[
            { v: 8, l: 'Bor', c: 'var(--sf-success)' },
            { v: 1, l: 'Yo‘q', c: 'var(--sf-danger)' },
            { v: 1, l: 'Kech', c: 'var(--sf-warn)' },
            { v: 1, l: 'Sababli', c: 'var(--sf-muted)' },
          ].map((s, i) => (
            <div key={i} style={{ textAlign: 'center', padding: '6px 0',
                                    background: 'var(--sf-surface-2)', borderRadius: 10 }}>
              <div className="sf-mono" style={{ fontSize: 22, fontWeight: 700, color: s.c, lineHeight: 1 }}>{s.v}</div>
              <div style={{ marginTop: 2, fontSize: 10, fontWeight: 600,
                             textTransform: 'uppercase', letterSpacing: '0.04em',
                             color: 'var(--sf-muted)' }}>{s.l}</div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '12px 18px 100px' }}>
        {/* Tip — swipe gesture */}
        <div style={{ display: 'flex', gap: 10, padding: 12, borderRadius: 14,
                       background: 'var(--sf-surface-2)', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ display: 'flex', gap: 4 }}>
            <span style={{ fontSize: 18 }}>👈</span>
          </div>
          <div style={{ fontSize: 12, color: 'var(--sf-ink-2)', lineHeight: 1.35 }}>
            <strong>Maslahat:</strong> chapga suring — yo‘q · o‘ngga suring — bor · uzun bosing — sababli/kech.
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {students.map((stu, i) => {
            const st = stu.s ? colors[stu.s] : null;
            const isSwipe = i === 4; // show one mid-swipe
            return (
              <div key={i} style={{ position: 'relative', overflow: 'hidden', borderRadius: 14 }}>
                {/* swipe action layer (just for visual) */}
                {isSwipe && (
                  <div style={{
                    position: 'absolute', inset: 0,
                    background: 'var(--sf-danger)', borderRadius: 14,
                    display: 'flex', alignItems: 'center', justifyContent: 'flex-end',
                    padding: '0 18px', color: '#FFFCF5', gap: 6,
                  }}>
                    <span style={{ fontWeight: 700, fontSize: 14 }}>Yo‘q</span>
                    {React.cloneElement(Icons.x, { size: 20 })}
                  </div>
                )}
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '10px 14px',
                  background: st ? st.bg : 'var(--sf-surface)',
                  border: `1px solid ${st ? 'transparent' : 'var(--sf-border)'}`,
                  borderRadius: 14,
                  transform: isSwipe ? 'translateX(-72px)' : 'translateX(0)',
                  transition: 'transform 0.2s',
                  position: 'relative',
                }}>
                  <SfAvatar name={stu.n} size={36} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--sf-ink)' }}>{stu.n}</div>
                    <div className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>
                      {stu.id}{stu.m && <span style={{ marginLeft: 6, color: st?.fg, fontWeight: 600 }}>· {stu.m}</span>}
                    </div>
                  </div>
                  {st ? (
                    <span style={{
                      padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 700,
                      background: 'var(--sf-surface)', color: st.fg,
                      display: 'inline-flex', alignItems: 'center', gap: 4,
                    }}>
                      <span style={{ width: 6, height: 6, borderRadius: '50%', background: st.dot }} />
                      {st.l}
                    </span>
                  ) : (
                    <div style={{ display: 'flex', gap: 6 }}>
                      <div style={{
                        width: 32, height: 32, borderRadius: 10,
                        border: '1.5px solid var(--sf-success)',
                        color: 'var(--sf-success)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>{React.cloneElement(Icons.check, { size: 18, stroke: 2.4 })}</div>
                      <div style={{
                        width: 32, height: 32, borderRadius: 10,
                        border: '1.5px solid var(--sf-danger)',
                        color: 'var(--sf-danger)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                      }}>{React.cloneElement(Icons.x, { size: 18, stroke: 2.4 })}</div>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Footer action */}
      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)',
                     display: 'flex', gap: 10, alignItems: 'center' }}>
        <div style={{ flex: 1 }}>
          <div className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
            10 / 12 belgilangan
          </div>
          <div style={{ marginTop: 4, height: 4, borderRadius: 4, background: 'var(--sf-surface-3)',
                          overflow: 'hidden' }}>
            <div style={{ width: '83%', height: '100%', background: 'var(--sf-primary)' }} />
          </div>
        </div>
        <button className="sf-btn sf-btn--primary">Saqlash {React.cloneElement(Icons.arrowR, { size: 16 })}</button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, {
  BrandCard, OnboardPhone, OnboardOtp, OnboardWelcome,
  TodayScreen, ScheduleScreen, LessonScreen, AttendanceScreen,
});
