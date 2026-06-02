// tf-screens-auth.jsx — Login (username + password) + Welcome
// Replaces the phone-OTP flow per latest brief.

function LoginScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ flex: 1, padding: '12px 28px 24px', display: 'flex', flexDirection: 'column',
                     position: 'relative', overflow: 'hidden' }}>
        {/* Decorative tile bg */}
        <div style={{
          position: 'absolute', right: -80, top: -40, opacity: 0.08,
        }}><SfStar size={300} color="var(--sf-primary)" /></div>
        <div style={{
          position: 'absolute', left: -40, bottom: 120, opacity: 0.05,
        }}><SfStar size={200} color="var(--sf-accent)" /></div>

        {/* Wordmark */}
        <div style={{ position: 'relative', marginTop: 18, display: 'flex',
                       alignItems: 'center', gap: 10 }}>
          <SfStar size={28} color="var(--sf-primary)" />
          <div style={{ fontSize: 15, fontWeight: 700, letterSpacing: '-0.02em' }}>
            StarForge<span style={{ color: 'var(--sf-muted)', fontWeight: 500 }}> · EDU</span>
          </div>
          <div style={{ flex: 1 }} />
          <span className="sf-chip">Ustoz</span>
        </div>

        {/* Heading */}
        <div style={{ position: 'relative', marginTop: 64 }}>
          <div style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                          fontSize: 38, lineHeight: 1, color: 'var(--sf-ink)' }}>
            Assalomu
          </div>
          <div style={{ fontSize: 36, fontWeight: 800, letterSpacing: '-0.035em',
                          marginTop: 2, color: 'var(--sf-ink)' }}>
            alaykum.
          </div>
          <div style={{ marginTop: 14, fontSize: 14, color: 'var(--sf-muted)',
                          lineHeight: 1.5, maxWidth: 280 }}>
            Hisobingizga kiring. Login va parol o‘quv markazi ma‘muri tomonidan beriladi.
          </div>
        </div>

        {/* Username */}
        <div style={{ position: 'relative', marginTop: 36 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
            Foydalanuvchi nomi
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
            borderRadius: 14, padding: '14px 16px',
          }}>
            <span style={{ color: 'var(--sf-muted)' }}>{React.cloneElement(Icons.user, { size: 18 })}</span>
            <span className="sf-mono" style={{ fontSize: 16, color: 'var(--sf-ink)', flex: 1 }}>
              nigora.karimova
            </span>
            <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>@demo</span>
          </div>
        </div>

        {/* Password */}
        <div style={{ position: 'relative', marginTop: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between',
                          alignItems: 'baseline', marginBottom: 8 }}>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                            textTransform: 'uppercase', color: 'var(--sf-muted)' }}>
              Parol
            </div>
            <span style={{ fontSize: 11, color: 'var(--sf-primary)', fontWeight: 600 }}>
              Unutdingizmi?
            </span>
          </div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: 'var(--sf-surface)',
            border: '1.5px solid var(--sf-primary)',
            borderRadius: 14, padding: '14px 16px',
            boxShadow: '0 0 0 4px var(--sf-primary-soft)',
          }}>
            <span style={{ color: 'var(--sf-primary)' }}>{React.cloneElement(Icons.shield, { size: 18 })}</span>
            <span style={{ flex: 1, display: 'flex', gap: 4, alignItems: 'center' }}>
              {[1,2,3,4,5,6,7,8].map(i => (
                <span key={i} style={{ width: 8, height: 8, borderRadius: '50%',
                                          background: 'var(--sf-ink)' }} />
              ))}
              <span style={{ width: 2, height: 18, background: 'var(--sf-primary)',
                              marginLeft: 2, animation: 'sfBlink 1.1s steps(2) infinite' }} />
            </span>
            <span style={{ color: 'var(--sf-muted)' }}>{React.cloneElement(Icons.search, { size: 16 })}</span>
          </div>
        </div>

        {/* Remember + center */}
        <div style={{ position: 'relative', marginTop: 18,
                        display: 'flex', alignItems: 'center', gap: 10, fontSize: 13 }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: 'var(--sf-primary)', color: '#FFFCF5',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{React.cloneElement(Icons.check, { size: 14, stroke: 3 })}</div>
          <span style={{ color: 'var(--sf-ink-2)' }}>Bu qurilmada eslab qol</span>
        </div>

        <div style={{ flex: 1 }} />

        {/* Submit */}
        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 54, fontSize: 16, position: 'relative' }}>
          Kirish
          {React.cloneElement(Icons.arrowR, { size: 18 })}
        </button>

        {/* Branch line */}
        <div style={{ position: 'relative', marginTop: 14, padding: 12,
                        borderRadius: 12, background: 'var(--sf-surface-2)',
                        display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: 'var(--sf-primary)', color: '#FFFCF5',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontSize: 16,
          }}>D</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--sf-ink)' }}>Demo Akademiya</div>
            <div className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>
              Yunusobod filiali · demo.starforge.uz
            </div>
          </div>
          {React.cloneElement(Icons.chevR, { size: 16 })}
        </div>

        <div style={{ position: 'relative', marginTop: 12, display: 'flex',
                        justifyContent: 'center', gap: 18,
                        fontSize: 12, color: 'var(--sf-muted)' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            {React.cloneElement(Icons.globe, { size: 14 })} O‘zbekcha
          </span>
          <span>·</span>
          <span>Yordam</span>
        </div>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`@keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }`}</style>
    </SfFrame>
  );
}

// Welcome — after login, before Today.
function WelcomeScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(120% 80% at 50% 0%, var(--sf-accent-soft) 0%, transparent 55%)',
        }} />
        <div className="sf-pattern" style={{ position: 'absolute', inset: 0 }} />

        <div style={{ position: 'relative', padding: '40px 28px 24px',
                       display: 'flex', flexDirection: 'column', height: '100%' }}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginTop: 18 }}>
            <div style={{ position: 'relative' }}>
              <div style={{
                position: 'absolute', inset: -16, borderRadius: '50%',
                background: 'var(--sf-accent-soft)', filter: 'blur(20px)',
              }} />
              <SfAvatar name="Nigora Karimova" size={92} color="var(--sf-primary)" />
            </div>
            <div style={{ marginTop: 16, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 22, color: 'var(--sf-ink-2)' }}>
              Xush kelibsiz,
            </div>
            <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: '-0.025em',
                           color: 'var(--sf-ink)', marginTop: 2 }}>
              Nigora opa
            </div>
            <div style={{ marginTop: 4, fontSize: 12, color: 'var(--sf-muted)' }}>
              Matematika ustozi · Demo Akademiya
            </div>
          </div>

          {/* Branch + subjects */}
          <div className="sf-card" style={{ marginTop: 22, padding: 14, display: 'flex', gap: 12 }}>
            <div style={{
              width: 42, height: 42, borderRadius: 12,
              background: 'var(--sf-primary)', color: '#FFFCF5',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><SfStar size={22} color="#FFFCF5" /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 700 }}>Yunusobod filiali</div>
              <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>
                3 ta guruh · 2 ta fan · 58 o‘quvchi
              </div>
            </div>
            <div style={{ color: 'var(--sf-primary)' }}>{React.cloneElement(Icons.check, { size: 22 })}</div>
          </div>

          <div style={{ marginTop: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <SfPill tone="primary">Algebra</SfPill>
            <SfPill tone="accent">Geometriya</SfPill>
          </div>

          {/* Mini cohort summary */}
          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
            {[
              { v: '3', l: 'Guruh' },
              { v: '58', l: 'O‘quvchi' },
              { v: '12', l: 'Dars / hafta' },
            ].map((s, i) => (
              <div key={i} style={{
                padding: 12, borderRadius: 12, background: 'var(--sf-surface)',
                border: '1px solid var(--sf-border)', textAlign: 'center',
              }}>
                <div className="sf-mono" style={{ fontSize: 22, fontWeight: 700,
                                                   color: 'var(--sf-primary)', lineHeight: 1 }}>{s.v}</div>
                <div style={{ marginTop: 3, fontSize: 10.5, color: 'var(--sf-muted)',
                               letterSpacing: '0.04em', textTransform: 'uppercase' }}>{s.l}</div>
              </div>
            ))}
          </div>

          <div style={{ flex: 1 }} />

          <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 54, fontSize: 16 }}>
            Boshlash
            {React.cloneElement(Icons.arrowR, { size: 18 })}
          </button>
        </div>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { LoginScreen, WelcomeScreen });
