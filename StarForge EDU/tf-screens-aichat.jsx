// tf-screens-aichat.jsx — AI Chat (group list + chat)
// Teacher picks a group; AI knows the group context. Conversational.

function AIChatListScreen({ platform = 'ios' }) {
  const groups = [
    {
      n: '9-B Algebra', sub: '24 o‘quvchi · Mar/Yos/Ju', t: 'Bugun · 11:34',
      pinned: true,
      preview: '“Bu hafta sinf umuman barqaror. 2 ta o‘quvchi diqqat talab qiladi…”',
      cards: { up: 8, down: 2 }, attend: 94, color: 'var(--sf-primary)',
    },
    {
      n: 'Algebra · Mid', sub: '21 o‘quvchi · Du/Cho/Pa', t: 'Bugun · 09:12',
      preview: '“Davronova Sevinch va Halimova Zilola olimpiada darajasi…”',
      cards: { up: 6, down: 0 }, attend: 96, color: 'var(--sf-primary)',
    },
    {
      n: '10-V Geometriya', sub: '19 o‘quvchi · Du/Pa', t: 'Kecha',
      preview: '“Trapetsiya mavzusi yaxshi tushunilgan. 11-misol uchun ekstra…”',
      cards: { up: 4, down: 1 }, attend: 88, color: 'var(--sf-accent)',
    },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}

      {/* Custom large header */}
      <div style={{
        padding: '8px 18px 16px', background: 'var(--sf-surface)',
        borderBottom: '1px solid var(--sf-border)', position: 'relative', overflow: 'hidden',
      }}>
        <div style={{ position: 'absolute', right: -30, top: -30, opacity: 0.08 }}>
          <SfStar size={140} color="var(--sf-primary)" />
        </div>
        <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between',
                       alignItems: 'flex-start', marginTop: 4 }}>
          <div>
            <SfAiBadge>Yordamchi</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 28, fontWeight: 800, letterSpacing: '-0.025em',
                            lineHeight: 1.05 }}>
              Suhbat
            </div>
            <div style={{ marginTop: 2, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                            fontSize: 16, color: 'var(--sf-muted)' }}>
              guruhlaringiz haqida
            </div>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--sf-surface-2)',
                            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {React.cloneElement(Icons.search, { size: 18 })}
            </div>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        {/* Token meter */}
        <div className="sf-ai-surface" style={{ padding: 12, borderRadius: 14,
                                                  marginBottom: 14, display: 'flex',
                                                  alignItems: 'center', gap: 12 }}>
          <div style={{ position: 'relative', zIndex: 1, flex: 1 }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Markaz limiti · oy</div>
            <div className="sf-mono" style={{ marginTop: 4, fontSize: 14, color: 'var(--sf-ink-2)' }}>
              4 320 / 50 000 <span style={{ color: 'var(--sf-muted)' }}>token</span>
            </div>
            <div style={{ marginTop: 6, height: 4, borderRadius: 4, background: 'rgba(255,252,245,0.5)',
                            overflow: 'hidden' }}>
              <div style={{ width: '8.6%', height: '100%', background: 'var(--sf-ai)' }} />
            </div>
          </div>
        </div>

        {/* Groups */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Mening guruhlarim · 3
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {groups.map((g, i) => (
            <div key={i} className="sf-card" style={{ padding: 14, position: 'relative',
                                                        overflow: 'hidden' }}>
              <div style={{ position: 'absolute', right: -16, top: -16, opacity: 0.06 }}>
                <SfStar size={84} color={g.color} />
              </div>
              <div style={{ position: 'relative', display: 'flex', gap: 12 }}>
                <div style={{
                  width: 44, height: 44, borderRadius: 12, flexShrink: 0,
                  background: g.color, color: '#FFFCF5',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><SfStar size={22} color="#FFFCF5" /></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between',
                                  alignItems: 'baseline', gap: 6 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span style={{ fontSize: 14.5, fontWeight: 700 }}>{g.n}</span>
                      {g.pinned && <span style={{ color: 'var(--sf-accent)' }}>{React.cloneElement(Icons.pin, { size: 12 })}</span>}
                    </div>
                    <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>{g.t}</span>
                  </div>
                  <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>{g.sub}</div>
                  <div style={{ marginTop: 8, padding: 10, borderRadius: 10,
                                  background: 'var(--sf-ai-bg)', border: '1px solid var(--sf-ai-border)' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                      <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                                       fontSize: 12, color: 'var(--sf-ai)', fontWeight: 600 }}>Ai</span>
                      <span style={{ fontSize: 9.5, color: 'var(--sf-muted)',
                                       letterSpacing: '0.04em', textTransform: 'uppercase',
                                       fontWeight: 600 }}>oxirgi xulosa</span>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--sf-ink-2)', lineHeight: 1.4,
                                    fontStyle: 'italic' }}>{g.preview}</div>
                  </div>
                  <div style={{ marginTop: 8, display: 'flex', gap: 12, fontSize: 11, color: 'var(--sf-muted)' }}>
                    <span><span className="sf-mono" style={{ color: '#7A4F0E', fontWeight: 700 }}>↑{g.cards.up}</span> Up</span>
                    <span><span className="sf-mono" style={{ color: 'var(--sf-danger)', fontWeight: 700 }}>↓{g.cards.down}</span> Down</span>
                    <span>Davomat <span className="sf-mono" style={{
                      color: g.attend >= 92 ? 'var(--sf-success)' : 'var(--sf-warn)', fontWeight: 700 }}>{g.attend}%</span></span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Universal AI */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>
          Yoki umumiy savol bering
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            'Ushbu hafta eng yaxshi 5 o‘quvchini ko‘rsat',
            'Ota-onaga jo‘natiladigan haftalik xulosa tuz',
            'Kim oxirgi 2 haftada karta olmadi?',
          ].map((q, i) => (
            <div key={i} style={{
              padding: 12, borderRadius: 12, background: 'var(--sf-surface)',
              border: '1px solid var(--sf-border)',
              display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ color: 'var(--sf-ai)' }}>
                <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                                fontSize: 14, fontWeight: 600 }}>Ai</span>
              </span>
              <span style={{ flex: 1, fontSize: 13, color: 'var(--sf-ink-2)' }}>{q}</span>
              {React.cloneElement(Icons.arrowR, { size: 14 })}
            </div>
          ))}
        </div>
      </div>

      <SfTabBar active="ai" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function AIChatScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}

      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px 10px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ color: 'var(--sf-primary)', display: 'inline-flex' }}>
            {React.cloneElement(Icons.arrowL, { size: 18 })}
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
            <div style={{ width: 36, height: 36, borderRadius: 10, background: 'var(--sf-primary)',
                            color: '#FFFCF5',
                            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <SfStar size={18} color="#FFFCF5" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6 }}>
                9-B Algebra <SfAiBadge compact>guruh</SfAiBadge>
              </div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>
                24 o‘quvchi · sizning ma‘lumotlaringiz asosida
              </div>
            </div>
          </div>
          <div style={{ color: 'var(--sf-ink-2)' }}>{Icons.more}</div>
        </div>

        {/* Suggested prompts */}
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 2 }}>
          {['Haftalik xulosa', 'Kim qiynalmoqda?', 'Up karta nomzodlari', 'Ota-ona uchun xat'].map(p => (
            <div key={p} style={{
              padding: '6px 12px', borderRadius: 999, fontSize: 11.5, fontWeight: 600,
              background: 'var(--sf-ai-bg)', border: '1px solid var(--sf-ai-border)',
              color: 'var(--sf-ai)', whiteSpace: 'nowrap',
            }}>{p}</div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)',
                     padding: '14px 18px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {/* User question */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            maxWidth: '78%', padding: '10px 14px', borderRadius: '18px 18px 4px 18px',
            background: 'var(--sf-ink)', color: 'var(--sf-bg)', fontSize: 13.5, lineHeight: 1.4,
          }}>
            9-B kvadrat tenglamalar mavzusida qanday boryapti?
          </div>
        </div>

        {/* AI response — rich content */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', maxWidth: '90%' }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: 'var(--sf-ai-bg)', border: '1px solid var(--sf-ai-border)',
            color: 'var(--sf-ai)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
            fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
            fontSize: 14, fontWeight: 600,
          }}>Ai</div>
          <div style={{ flex: 1 }}>
            <div style={{
              padding: '12px 14px', borderRadius: '4px 18px 18px 18px',
              background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
              fontSize: 13.5, lineHeight: 1.5, color: 'var(--sf-ink)',
            }}>
              <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                              fontSize: 15 }}>Umuman barqaror.</span> 24 o‘quvchidan 18 nafari mavzuni mustaqil yechmoqda. 4 nafari diskriminant formulasida kichik xatolarga yo‘l qo‘ydi.
            </div>
            {/* Inline stats card */}
            <div className="sf-card" style={{ marginTop: 8, padding: 12,
                                                background: 'var(--sf-surface)' }}>
              <div style={{ display: 'flex', gap: 14 }}>
                {[
                  { v: '18', l: 'O‘zlashtirdi', c: 'var(--sf-success)' },
                  { v: '4', l: 'Qiynalmoqda', c: 'var(--sf-warn)' },
                  { v: '2', l: 'Tushunmagan', c: 'var(--sf-danger)' },
                ].map((s, i) => (
                  <div key={i} style={{ flex: 1 }}>
                    <div className="sf-mono" style={{ fontSize: 22, fontWeight: 700,
                                                        color: s.c, lineHeight: 1 }}>{s.v}</div>
                    <div style={{ marginTop: 4, fontSize: 10, color: 'var(--sf-muted)',
                                    letterSpacing: '0.04em', textTransform: 'uppercase',
                                    fontWeight: 600 }}>{s.l}</div>
                  </div>
                ))}
              </div>
              {/* Mini distribution bar */}
              <div style={{ marginTop: 10, height: 6, borderRadius: 4,
                              background: 'var(--sf-surface-2)', display: 'flex', overflow: 'hidden' }}>
                <div style={{ width: '75%', background: 'var(--sf-success)' }} />
                <div style={{ width: '17%', background: 'var(--sf-warn)' }} />
                <div style={{ width: '8%', background: 'var(--sf-danger)' }} />
              </div>
            </div>

            {/* Students surfaced */}
            <div style={{ marginTop: 8, fontSize: 13.5, lineHeight: 1.5,
                            padding: '0 4px', color: 'var(--sf-ink-2)' }}>
              Diqqat qaratish kerak bo‘lganlar:
            </div>
            <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
              {[
                { n: 'Eshmatov Otabek', r: 'Diskriminant ishorasi · 2 marta xato', tone: 'warn' },
                { n: 'Bakirov Sherzod', r: 'Formulani eslamayotgan', tone: 'warn' },
              ].map((s, i) => (
                <div key={i} style={{ padding: '8px 10px', borderRadius: 10,
                                        background: 'var(--sf-warn-soft)',
                                        display: 'flex', alignItems: 'center', gap: 8 }}>
                  <SfAvatar name={s.n} size={26} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 600, color: 'var(--sf-ink-2)' }}>{s.n}</div>
                    <div style={{ fontSize: 10.5, color: 'var(--sf-warn)' }}>{s.r}</div>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 8, fontSize: 13.5, lineHeight: 1.5,
                            padding: '0 4px', color: 'var(--sf-ink-2)' }}>
              <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic' }}>Tavsiya: </span>
              ertangi darsda 5 daqiqalik takrorlash + Eshmatov va Bakirov bilan qisqa individual ish.
            </div>

            {/* Actions */}
            <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <button className="sf-btn sf-btn--soft" style={{ fontSize: 12, padding: '6px 10px' }}>
                Takrorlash rejasi tuz
              </button>
              <button className="sf-btn sf-btn--soft" style={{ fontSize: 12, padding: '6px 10px' }}>
                Otabekka xabar yoz
              </button>
            </div>
            <div className="sf-mono" style={{ marginTop: 8, fontSize: 9.5, color: 'var(--sf-muted)' }}>
              Sizning davomat va karta ma‘lumotlaringiz · 14 May–19 May
            </div>
          </div>
        </div>

        {/* Follow-up user */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 4 }}>
          <div style={{
            maxWidth: '78%', padding: '10px 14px', borderRadius: '18px 18px 4px 18px',
            background: 'var(--sf-ink)', color: 'var(--sf-bg)', fontSize: 13.5, lineHeight: 1.4,
          }}>
            Otabek otasiga yoziladigan qisqa xabar tayyorlab ber.
          </div>
        </div>

        {/* AI typing */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: 'var(--sf-ai-bg)', border: '1px solid var(--sf-ai-border)',
            color: 'var(--sf-ai)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
            fontSize: 14, fontWeight: 600,
          }}>Ai</div>
          <div style={{
            padding: '12px 14px', borderRadius: '4px 18px 18px 18px',
            background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
            display: 'flex', gap: 4,
          }}>
            {[0, 1, 2].map(i => (
              <span key={i} style={{
                width: 6, height: 6, borderRadius: '50%', background: 'var(--sf-ai)',
                opacity: 0.4,
                animation: `sfDot 1.2s ${i * 0.2}s infinite ease-in-out`,
              }} />
            ))}
          </div>
        </div>
      </div>

      {/* Input */}
      <div style={{ padding: '10px 14px 12px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)',
                     display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          flex: 1, background: 'var(--sf-surface-2)', borderRadius: 22,
          padding: '10px 16px', fontSize: 13, color: 'var(--sf-muted)',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span style={{ flex: 1 }}>9-B haqida savol bering...</span>
          <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>~120 token</span>
        </div>
        <div style={{
          width: 40, height: 40, borderRadius: 12, background: 'var(--sf-primary)',
          color: '#FFFCF5',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{React.cloneElement(Icons.send, { size: 18 })}</div>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`
        @keyframes sfDot {
          0%, 80%, 100% { opacity: 0.3; transform: translateY(0); }
          40% { opacity: 1; transform: translateY(-3px); }
        }
      `}</style>
    </SfFrame>
  );
}

Object.assign(window, { AIChatListScreen, AIChatScreen });
