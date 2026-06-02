// tf-screens-surveys.jsx — Surveys deployed by admins

function SurveysScreen({ platform = 'ios' }) {
  const pending = [
    {
      t: 'Oylik o‘qituvchi qoniqishi',
      issuer: 'Karimova R. · Direktor',
      deadline: '22.05 · 23:59',
      remaining: '2 kun 14 soat',
      questions: 12, est: '~4 daqiqa',
      progress: 33, // already answered
      urgent: true,
    },
    {
      t: 'Karta tizimi · taklif va e‘tirozlar',
      issuer: 'Ahmedov B. · O‘quv ishlari',
      deadline: '26.05 · 18:00',
      remaining: '6 kun',
      questions: 8, est: '~3 daqiqa',
      progress: 0,
    },
  ];
  const past = [
    { t: 'Aprel · iss-prosess', issuer: 'Direktor', score: 'Topshirildi', d: '30.04' },
    { t: 'Yangi platforma qulayligi', issuer: 'Markaz', score: 'Topshirildi', d: '15.04' },
    { t: 'AI tavsiyalarining sifati', issuer: 'Metodist', score: 'O‘tkazib yuborilgan', skipped: true, d: '01.04' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="So‘rovnomalar"
        subtitle="Markaz tomonidan yuboriladi · anonim"
        right={<>{Icons.filter}</>} />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '4px 18px 100px' }}>
        {/* PENDING — bright */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 10,
                       display: 'flex', justifyContent: 'space-between' }}>
          <span>Topshirish kutmoqda</span>
          <span style={{ color: 'var(--sf-danger)', fontWeight: 700 }}>· 2 ta</span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {pending.map((s, i) => (
            <div key={i} style={{
              position: 'relative', borderRadius: 18, overflow: 'hidden',
              background: s.urgent ?
                'linear-gradient(135deg, #FCEFD0 0%, #F6E0AC 100%)' :
                'var(--sf-surface)',
              border: s.urgent ? '1.5px solid var(--sf-accent)' : '1px solid var(--sf-border)',
              padding: 16,
              boxShadow: s.urgent ?
                '0 0 0 4px rgba(216,154,46,0.25), 0 8px 24px rgba(216,154,46,0.18)' :
                'var(--sf-shadow-sm)',
            }}>
              {/* Pulse halo */}
              {s.urgent && (
                <>
                  <div style={{
                    position: 'absolute', inset: 0, borderRadius: 18,
                    border: '2px solid var(--sf-accent)', opacity: 0.45,
                    animation: 'sfPulse 1.8s ease-in-out infinite',
                    pointerEvents: 'none',
                  }} />
                  <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.18 }}>
                    <SfStar size={120} color="#7A4F0E" />
                  </div>
                </>
              )}

              <div style={{ position: 'relative', display: 'flex',
                              justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  {s.urgent && (
                    <span style={{
                      width: 8, height: 8, borderRadius: '50%', background: 'var(--sf-danger)',
                      animation: 'sfBlink 1s steps(2) infinite',
                    }} />
                  )}
                  <span className="sf-chip" style={{
                    background: s.urgent ? 'var(--sf-ink)' : 'var(--sf-surface-2)',
                    color: s.urgent ? 'var(--sf-bg)' : 'var(--sf-ink-2)',
                    border: 'none',
                  }}>{s.urgent ? '⏰ Shoshilinch' : 'Yangi'}</span>
                </div>
                <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
                  <span className="sf-mono" style={{ fontWeight: 700,
                    color: s.urgent ? 'var(--sf-danger)' : 'var(--sf-ink-2)' }}>{s.remaining}</span> qoldi
                </span>
              </div>

              <div style={{ position: 'relative', marginTop: 10, fontSize: 17, fontWeight: 700,
                              letterSpacing: '-0.01em', lineHeight: 1.2 }}>
                {s.t}
              </div>
              <div style={{ position: 'relative', marginTop: 4, fontSize: 12, color: 'var(--sf-ink-2)' }}>
                {s.issuer} · <span className="sf-mono">{s.deadline}</span>
              </div>

              <div style={{ position: 'relative', marginTop: 12, padding: 10, borderRadius: 10,
                              background: 'rgba(255,252,245,0.6)', backdropFilter: 'blur(4px)',
                              display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{ flex: 1 }}>
                  <div className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-ink-2)' }}>
                    <strong>{s.questions}</strong> savol · {s.est}
                  </div>
                  {s.progress > 0 && (
                    <div style={{ marginTop: 6, height: 4, borderRadius: 4,
                                    background: 'var(--sf-surface-3)', overflow: 'hidden' }}>
                      <div style={{ width: `${s.progress}%`, height: '100%',
                                      background: 'var(--sf-accent)' }} />
                    </div>
                  )}
                </div>
                <button className="sf-btn" style={{
                  background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                  fontSize: 13, padding: '8px 14px',
                }}>
                  {s.progress > 0 ? 'Davom etish' : 'Boshlash'} {React.cloneElement(Icons.arrowR, { size: 12 })}
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* PAST */}
        <div style={{ marginTop: 24, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Tarix
        </div>
        <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
          {past.map((p, i, a) => (
            <div key={i} style={{
              padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
              borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: p.skipped ? 'var(--sf-surface-2)' : 'var(--sf-success-soft)',
                color: p.skipped ? 'var(--sf-muted)' : 'var(--sf-success)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>{p.skipped ? React.cloneElement(Icons.x, { size: 18 }) :
                              React.cloneElement(Icons.check, { size: 18, stroke: 2.6 })}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13.5, fontWeight: 600 }}>{p.t}</div>
                <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{p.issuer} · {p.score}</div>
              </div>
              <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>{p.d}</span>
            </div>
          ))}
        </div>

        {/* Privacy strip */}
        <div className="sf-ai-surface" style={{ marginTop: 20, padding: 14, borderRadius: 14 }}>
          <div style={{ position: 'relative', zIndex: 1, display: 'flex', gap: 10, alignItems: 'flex-start' }}>
            <div style={{
              width: 32, height: 32, borderRadius: 8, background: 'var(--sf-surface)',
              border: '1px solid var(--sf-ai-border)', color: 'var(--sf-ai)',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>{React.cloneElement(Icons.shield, { size: 16 })}</div>
            <div style={{ fontSize: 12.5, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              <strong>Anonimlik:</strong> Sizning javoblaringiz markazda jamlanadi, lekin ismingiz ko‘rsatilmaydi. Profil ulashish sozlamasi orqali boshqarasiz.
            </div>
          </div>
        </div>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`
        @keyframes sfPulse {
          0%, 100% { opacity: 0.45; transform: scale(1); }
          50% { opacity: 0.0; transform: scale(1.03); }
        }
        @keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }
      `}</style>
    </SfFrame>
  );
}

function SurveyFormScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ color: 'var(--sf-primary)', fontSize: 16, fontWeight: 600 }}>Saqlab chiqish</span>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>4 / 12 savol</div>
          </div>
          <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-danger)', fontWeight: 700 }}>2 kun 14s</span>
        </div>
        <div style={{ display: 'flex', gap: 3, paddingBottom: 12 }}>
          {Array.from({ length: 12 }).map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 3,
              background: i < 4 ? 'var(--sf-primary)' : 'var(--sf-surface-2)',
            }} />
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 22px 100px' }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)' }}>
          5-savol · 12
        </div>
        <div style={{ marginTop: 10, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                       fontSize: 24, lineHeight: 1.25, color: 'var(--sf-ink)' }}>
          AI yordamchining tavsiyalari sizning ishingizga qanchalik foydali bo‘ldi?
        </div>
        <div style={{ marginTop: 6, fontSize: 12, color: 'var(--sf-muted)' }}>
          1 = umuman foyda yo‘q · 10 = juda foydali
        </div>

        {/* Rating scale */}
        <div style={{ marginTop: 20 }}>
          <div style={{ display: 'flex', gap: 4, justifyContent: 'space-between' }}>
            {[1,2,3,4,5,6,7,8,9,10].map(n => {
              const on = n === 8;
              return (
                <div key={n} style={{
                  flex: 1, aspectRatio: '1', maxWidth: 32,
                  borderRadius: 8,
                  background: on ? 'var(--sf-primary)' : 'var(--sf-surface)',
                  color: on ? '#FFFCF5' : 'var(--sf-ink-2)',
                  border: on ? 'none' : '1px solid var(--sf-border)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--sf-font-mono)', fontSize: 13, fontWeight: 700,
                  boxShadow: on ? '0 4px 12px rgba(184,85,53,0.3)' : 'none',
                }}>{n}</div>
              );
            })}
          </div>
          <div style={{ marginTop: 6, display: 'flex', justifyContent: 'space-between',
                          fontSize: 10, color: 'var(--sf-muted)' }}>
            <span>Foyda yo‘q</span><span>Juda foydali</span>
          </div>
        </div>

        {/* Optional text */}
        <div style={{ marginTop: 22, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Izoh · ixtiyoriy
        </div>
        <div className="sf-card" style={{ padding: 14, minHeight: 100 }}>
          <div style={{ fontSize: 13.5, color: 'var(--sf-ink)', lineHeight: 1.5 }}>
            Karta sabab takliflari juda yaxshi — daftarda yozib o‘tirishimni qisqartirdi. Faqat ba‘zan
            <span style={{ animation: 'sfBlink 1.1s steps(2) infinite',
                            color: 'var(--sf-primary)', marginLeft: 2 }}>|</span>
          </div>
        </div>

        {/* Anonymity note */}
        <div style={{
          marginTop: 18, padding: 12, borderRadius: 12, background: 'var(--sf-surface-2)',
          display: 'flex', gap: 10, alignItems: 'center', fontSize: 11.5, color: 'var(--sf-ink-2)',
        }}>
          <span style={{ color: 'var(--sf-success)' }}>{React.cloneElement(Icons.shield, { size: 16 })}</span>
          <span style={{ flex: 1 }}>
            Bu so‘rovnoma <strong>anonim</strong>. Markaz faqat jamlangan natijani ko‘radi.
          </span>
        </div>
      </div>

      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)', display: 'flex', gap: 8 }}>
        <button className="sf-btn sf-btn--ghost" style={{ width: 50, padding: 0 }}>
          {React.cloneElement(Icons.arrowL, { size: 18 })}
        </button>
        <button className="sf-btn sf-btn--primary" style={{ flex: 1 }}>
          Keyingisi {React.cloneElement(Icons.arrowR, { size: 16 })}
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`@keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }`}</style>
    </SfFrame>
  );
}

Object.assign(window, { SurveysScreen, SurveyFormScreen });
