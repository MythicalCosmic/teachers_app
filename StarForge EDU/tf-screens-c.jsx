// tf-screens-c.jsx — Assignments list, Create assignment, Grade w/ AI, Gradebook

function AssignmentsScreen({ platform = 'ios' }) {
  const items = [
    { t: 'Kvadrat tenglamalar', c: '9-B Algebra', d: 'Ertaga · 23:59', sub: '24/24', state: 'review', cnt: 7, ai: true },
    { t: 'Funksiyalar grafigi', c: '9-A Algebra', d: 'Pen · 23:59', sub: '18/22', state: 'open' },
    { t: 'Yozma ish · Geometriya', c: '10-V', d: 'Ju · 18:00', sub: '12/19', state: 'open', ai: true },
    { t: 'Olimpiada mashqlari', c: '11-B Tayyorlov', d: '20 May · 23:59', sub: '13/13', state: 'graded' },
    { t: 'Matematik induktsiya', c: '11-B Tayyorlov', d: 'Yopildi · 12 May', sub: '13/13', state: 'closed' },
  ];

  const stateChip = {
    review: { l: 'Tekshirish', tone: 'primary' },
    open:   { l: 'Ochiq', tone: 'accent' },
    graded: { l: 'Baholandi', tone: 'success' },
    closed: { l: 'Yopiq', tone: 'neutral' },
  };

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Topshiriqlar" subtitle="2 ta tekshirish kutmoqda"
        right={<>{Icons.filter}{Icons.plus}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }}>
          {[
            { l: 'Hammasi', n: 12, act: true },
            { l: 'Tekshirish', n: 2 },
            { l: 'Ochiq', n: 5 },
            { l: 'Yopiq', n: 5 },
          ].map((t, i) => (
            <div key={t.l} style={{
              padding: '8px 14px', borderRadius: 999, fontSize: 12, fontWeight: 600,
              whiteSpace: 'nowrap',
              background: t.act ? 'var(--sf-ink)' : 'transparent',
              color: t.act ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: t.act ? 'none' : '1px solid var(--sf-border)',
              display: 'inline-flex', alignItems: 'center', gap: 6,
            }}>
              {t.l}
              <span style={{
                padding: '1px 6px', borderRadius: 999,
                fontSize: 10, fontWeight: 700,
                background: t.act ? 'rgba(255,252,245,0.2)' : 'var(--sf-surface-2)',
                color: t.act ? 'var(--sf-bg)' : 'var(--sf-muted)',
              }}>{t.n}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {items.map((it, i) => {
            const st = stateChip[it.state];
            const submitted = parseInt(it.sub.split('/')[0]);
            const total = parseInt(it.sub.split('/')[1]);
            const pct = (submitted / total) * 100;
            return (
              <div key={i} className="sf-card" style={{ padding: 14 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8,
                                alignItems: 'flex-start' }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      <SfPill tone={st.tone}>{st.l}</SfPill>
                      {it.ai && <SfAiBadge compact>Yordam</SfAiBadge>}
                    </div>
                    <div style={{ marginTop: 8, fontSize: 16, fontWeight: 700,
                                    letterSpacing: '-0.01em', lineHeight: 1.2 }}>{it.t}</div>
                    <div style={{ marginTop: 3, fontSize: 12, color: 'var(--sf-muted)' }}>
                      {it.c} · <span style={{ color: 'var(--sf-ink-2)', fontWeight: 600 }}>{it.d}</span>
                    </div>
                  </div>
                  {it.state === 'review' && (
                    <div style={{
                      width: 44, height: 44, borderRadius: 12,
                      background: 'var(--sf-primary)', color: '#FFFCF5',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 16, fontWeight: 800,
                      flexShrink: 0,
                    }}>{it.cnt}</div>
                  )}
                </div>

                {/* Submissions progress */}
                <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ flex: 1, height: 6, borderRadius: 4,
                                  background: 'var(--sf-surface-2)', overflow: 'hidden' }}>
                    <div style={{ width: `${pct}%`, height: '100%',
                                    background: it.state === 'graded' ? 'var(--sf-success)' : 'var(--sf-primary)' }} />
                  </div>
                  <span className="sf-mono" style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
                    {it.sub}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <SfTabBar active="cohort" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function CreateAssignmentScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ color: 'var(--sf-primary)', fontSize: 16, fontWeight: 600 }}>Bekor</span>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Yangi topshiriq</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>Qoralama avtomatik saqlandi</div>
          </div>
          <span style={{ color: 'var(--sf-primary)', fontWeight: 700, fontSize: 15 }}>E‘lon</span>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '16px 18px 100px' }}>
        {/* Title field */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Sarlavha</div>
        <div className="sf-card" style={{ padding: '14px 16px' }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--sf-ink)' }}>
            Kvadrat tenglamalar · Mashqlar 1–12
          </div>
          <div style={{ marginTop: 4, fontSize: 13, color: 'var(--sf-muted)' }}>
            Diskriminant va Viet formulasi orqali yechish
          </div>
        </div>

        {/* Cohort + due */}
        <div style={{ marginTop: 18, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                           textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Guruh</div>
            <div className="sf-card" style={{ padding: 12, display: 'flex',
                                                 alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 28, height: 28, borderRadius: 8, background: 'var(--sf-primary)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><SfStar size={16} color="#FFFCF5" /></div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600 }}>9-B Algebra</div>
                <div style={{ fontSize: 10, color: 'var(--sf-muted)' }}>24 o‘quvchi</div>
              </div>
            </div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                           textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Muddat</div>
            <div className="sf-card" style={{ padding: 12 }}>
              <div className="sf-mono" style={{ fontSize: 14, fontWeight: 600 }}>23.05 · 23:59</div>
              <div style={{ fontSize: 10, color: 'var(--sf-muted)' }}>Pen · ertaga emas</div>
            </div>
          </div>
        </div>

        {/* Type selector */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                         textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Tur</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
            {[
              { l: 'Yozma', i: Icons.edit, act: true },
              { l: 'Topshirish', i: Icons.upload },
              { l: 'Test', i: Icons.check },
              { l: 'Loyiha', i: Icons.folder },
            ].map((t, i) => (
              <div key={i} style={{
                padding: '12px 6px', borderRadius: 12, textAlign: 'center',
                background: t.act ? 'var(--sf-primary)' : 'var(--sf-surface)',
                color: t.act ? 'var(--sf-bg)' : 'var(--sf-ink-2)',
                border: t.act ? 'none' : '1px solid var(--sf-border)',
              }}>
                <div style={{ display: 'flex', justifyContent: 'center' }}>
                  {React.cloneElement(t.i, { size: 20 })}
                </div>
                <div style={{ marginTop: 6, fontSize: 11, fontWeight: 600 }}>{t.l}</div>
              </div>
            ))}
          </div>
        </div>

        {/* AI assistant block */}
        <div className="sf-ai-surface" style={{ marginTop: 20, padding: 16, borderRadius: 18 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <SfAiBadge>Topshiriq generatori</SfAiBadge>
                <div style={{ marginTop: 8, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                               fontSize: 17, lineHeight: 1.3 }}>
                  12 ta yangi mashq tayyorlandi — sinfning oldingi 3 darsiga moslashtirildi.
                </div>
              </div>
            </div>
            <div style={{ marginTop: 12, padding: 12, background: 'var(--sf-surface)',
                           border: '1px solid var(--sf-ai-border)', borderRadius: 12 }}>
              <div style={{ fontSize: 11, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                             textTransform: 'uppercase', fontWeight: 600 }}>1-misol · Oson</div>
              <div className="sf-mono" style={{ marginTop: 6, fontSize: 14, color: 'var(--sf-ink)' }}>
                x² − 5x + 6 = 0
              </div>
              <div style={{ marginTop: 4, fontSize: 11, color: 'var(--sf-muted)' }}>
                Diskriminantni hisoblang. Ildizlarni toping.
              </div>
            </div>
            <div style={{ marginTop: 10, display: 'flex', justifyContent: 'space-between',
                           alignItems: 'center' }}>
              <span style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
                <span className="sf-mono" style={{ color: 'var(--sf-ai)', fontWeight: 700 }}>~420</span> token · markaz limiti
              </span>
              <button className="sf-btn" style={{ background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                                                    fontSize: 13, padding: '8px 14px' }}>
                12 misolni kiritish
              </button>
            </div>
          </div>
        </div>

        {/* Settings */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                         textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Sozlamalar</div>
          <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
            {[
              { l: 'Maksimal baho', v: '5.0' },
              { l: 'Kechikish · gracePeriod', v: '24 soat' },
              { l: 'Qayta topshirish', v: '2 marta' },
              { l: 'Ota-onaga xabar', v: 'E‘lon qilingach' },
            ].map((s, i, a) => (
              <div key={i} style={{
                display: 'flex', justifyContent: 'space-between',
                padding: '12px 16px', alignItems: 'center',
                borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
              }}>
                <span style={{ fontSize: 13.5, color: 'var(--sf-ink)' }}>{s.l}</span>
                <span style={{ fontSize: 13, color: 'var(--sf-muted)' }}>{s.v} {React.cloneElement(Icons.chevR, { size: 14 })}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function GradeSubmissionScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS
        left={<><span style={{ display: 'inline-flex', alignItems: 'center' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}Ortga</span></>}
        right={<>5 / 24 · {Icons.more}</>}
        title="Akmal Akbarov"
        subtitle="Kvadrat tenglamalar"
      />

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '8px 18px 100px' }}>
        {/* Student strip */}
        <div className="sf-card" style={{ padding: 14, display: 'flex', alignItems: 'center', gap: 12 }}>
          <SfAvatar name="Akmal Akbarov" size={44} color="var(--sf-primary)" />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700 }}>Akbarov Akmal</div>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)' }}>
              Topshirildi: <span className="sf-mono" style={{ color: 'var(--sf-ink-2)' }}>16.05 14:23</span>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: 'var(--sf-surface-2)',
                           display: 'flex', alignItems: 'center', justifyContent: 'center',
                           color: 'var(--sf-ink-2)' }}>
              {React.cloneElement(Icons.arrowL, { size: 16 })}
            </div>
            <div style={{ width: 34, height: 34, borderRadius: 10, background: 'var(--sf-surface-2)',
                           display: 'flex', alignItems: 'center', justifyContent: 'center',
                           color: 'var(--sf-ink-2)' }}>
              {React.cloneElement(Icons.arrowR, { size: 16 })}
            </div>
          </div>
        </div>

        {/* Submission preview */}
        <div className="sf-card" style={{ marginTop: 12, padding: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                            textTransform: 'uppercase', fontWeight: 600 }}>1-misol · x² − 5x + 6 = 0</div>
            <SfPill tone="success">To‘g‘ri</SfPill>
          </div>
          <div className="sf-mono" style={{ marginTop: 10, fontSize: 14, color: 'var(--sf-ink-2)', lineHeight: 1.7 }}>
            D = 25 − 24 = 1<br/>
            x₁ = (5+1)/2 = 3<br/>
            x₂ = (5−1)/2 = 2
          </div>
          <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid var(--sf-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <div style={{ fontSize: 11, color: 'var(--sf-muted)', letterSpacing: '0.04em',
                              textTransform: 'uppercase', fontWeight: 600 }}>2-misol · 2x² + 3x − 5 = 0</div>
              <SfPill tone="danger">Xato</SfPill>
            </div>
            <div className="sf-mono" style={{ marginTop: 10, fontSize: 14, color: 'var(--sf-ink-2)', lineHeight: 1.7 }}>
              D = 9 + 40 = 49<br/>
              <span style={{ background: 'var(--sf-danger-soft)', padding: '0 4px' }}>
                x₁ = (−3 + 7) / 2 = <s>4</s>
              </span>
              <span style={{ color: 'var(--sf-muted)', fontFamily: 'inherit', fontStyle: 'italic',
                              marginLeft: 8 }}>
                ← 2 bo‘lishi kerak edi
              </span>
            </div>
          </div>
        </div>

        {/* AI assist — the hero panel */}
        <div className="sf-ai-surface" style={{ marginTop: 14, padding: 16, borderRadius: 18 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <SfAiBadge>Taklif qilingan baho</SfAiBadge>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                <span className="sf-mono" style={{ fontSize: 30, fontWeight: 700, color: 'var(--sf-ai)' }}>4</span>
                <span style={{ fontSize: 12, color: 'var(--sf-muted)' }}>/ 5</span>
              </div>
            </div>
            <div style={{ marginTop: 10, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                           fontSize: 16, lineHeight: 1.4 }}>
              “11 ta misol to‘g‘ri yechilgan. 2-misolda maxraj xatosi — diskriminant ishini takrorlash tavsiya etiladi.”
            </div>
            <div style={{ marginTop: 12, padding: 12, background: 'var(--sf-surface)',
                           borderRadius: 12, border: '1px solid var(--sf-ai-border)' }}>
              <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.04em',
                             textTransform: 'uppercase', color: 'var(--sf-muted)' }}>Tavsiya etilgan izoh</div>
              <div style={{ marginTop: 6, fontSize: 13, color: 'var(--sf-ink-2)', lineHeight: 1.5 }}>
                Akmal, juda yaxshi ish! Faqat 2-misolda formula yozishda ikkiga bo‘lishni unutibsiz. Keyingi darsda biror misolda yana mashq qilamiz.
              </div>
            </div>
            <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
              <button className="sf-btn" style={{ flex: 1, background: 'var(--sf-ink)',
                                                    color: 'var(--sf-bg)', fontSize: 13 }}>
                {React.cloneElement(Icons.check, { size: 16 })} Qabul qilish
              </button>
              <button className="sf-btn sf-btn--ghost" style={{ fontSize: 13,
                                                                  background: 'rgba(255,252,245,0.5)' }}>
                O‘zgartirish
              </button>
            </div>
          </div>
        </div>

        {/* Teacher rubric */}
        <div style={{ marginTop: 18 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                         textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Sizning bahoyingiz</div>
          <div className="sf-card" style={{ padding: 16 }}>
            <div style={{ display: 'flex', gap: 8 }}>
              {['2', '3', '4', '5'].map(g => (
                <div key={g} style={{
                  flex: 1, height: 56, borderRadius: 14,
                  border: g === '4' ? '2px solid var(--sf-primary)' : '1px solid var(--sf-border)',
                  background: g === '4' ? 'var(--sf-primary-soft)' : 'var(--sf-surface)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--sf-font-mono)', fontSize: 22, fontWeight: 700,
                  color: g === '4' ? 'var(--sf-primary)' : 'var(--sf-ink-2)',
                }}>{g}</div>
              ))}
            </div>
            <div style={{ marginTop: 12, padding: 10, background: 'var(--sf-surface-2)', borderRadius: 12,
                           fontSize: 13, color: 'var(--sf-muted)', minHeight: 44, lineHeight: 1.4 }}>
              Izoh yozing yoki AI tavsiyasini ishlating...
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)', display: 'flex', gap: 8 }}>
        <button className="sf-btn sf-btn--soft" style={{ flex: 1 }}>Qoldirish</button>
        <button className="sf-btn sf-btn--primary" style={{ flex: 2 }}>
          Saqlash va keyingi {React.cloneElement(Icons.arrowR, { size: 16 })}
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function GradebookScreen({ platform = 'ios' }) {
  const students = [
    { n: 'Akbarov A.', avg: 4.8, grades: [5, 5, 4, 5, 5, 4, 5, 5] },
    { n: 'Azizova M.',  avg: 4.6, grades: [5, 4, 5, 5, 4, 5, 4, 5] },
    { n: 'Bakirov S.',  avg: 3.8, grades: [4, 3, 4, 4, 3, 4, 4, 4] },
    { n: 'Davronova S.', avg: 4.2, grades: [4, 5, 4, 4, 4, 4, 5, 4] },
    { n: 'Eshmatov O.',  avg: 3.1, grades: [3, 2, 3, 3, 'n', 4, 3, 3] },
    { n: 'Fayzullayev D.', avg: 4.4, grades: [4, 5, 4, 5, 4, 4, 5, 4] },
    { n: 'G‘aniyev J.',   avg: 3.9, grades: [4, 4, 3, 4, 4, 4, 4, 4] },
    { n: 'Halimova Z.',   avg: 4.7, grades: [5, 5, 5, 4, 5, 5, 4, 5] },
    { n: 'Ibragimov S.',  avg: 4.0, grades: [4, 4, 4, 4, 4, 4, 4, 4] },
  ];
  const exams = ['M1', 'M2', 'M3', 'YI', 'M4', 'M5', 'M6', 'F'];

  const cellColor = (g) => {
    if (g === 'n') return { bg: 'var(--sf-surface-3)', fg: 'var(--sf-muted)' };
    if (g === 5) return { bg: 'var(--sf-success-soft)', fg: 'var(--sf-success)' };
    if (g === 4) return { bg: 'var(--sf-accent-soft)', fg: 'var(--sf-accent-ink)' };
    if (g === 3) return { bg: 'var(--sf-warn-soft)', fg: 'var(--sf-warn)' };
    return { bg: 'var(--sf-danger-soft)', fg: 'var(--sf-danger)' };
  };

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS
        left={<><span style={{ display: 'inline-flex', alignItems: 'center' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}9-B</span></>}
        right={<>{Icons.upload}{Icons.more}</>}
        title="Baholar"
        subtitle="II chorak · Algebra"
      />

      <div style={{ background: 'var(--sf-surface)', padding: '0 16px 12px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {['I', 'II', 'III', 'IV'].map((q, i) => (
            <div key={q} style={{
              flex: 1, padding: '8px 0', textAlign: 'center', borderRadius: 10,
              fontSize: 12, fontWeight: 700,
              background: i === 1 ? 'var(--sf-ink)' : 'transparent',
              color: i === 1 ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: i === 1 ? 'none' : '1px solid var(--sf-border)',
            }}>{q} chorak</div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '12px 0 100px' }}>
        {/* Header row */}
        <div style={{
          display: 'grid', gridTemplateColumns: '120px repeat(8, 32px) 44px', gap: 4,
          padding: '0 16px 8px', position: 'sticky', top: 0, background: 'var(--sf-bg)',
          fontSize: 10, color: 'var(--sf-muted)', fontWeight: 700, letterSpacing: '0.04em',
          textTransform: 'uppercase', zIndex: 1,
        }}>
          <div>O‘quvchi</div>
          {exams.map(e => <div key={e} style={{ textAlign: 'center' }}>{e}</div>)}
          <div style={{ textAlign: 'center', color: 'var(--sf-ink-2)' }}>O‘rt</div>
        </div>

        {students.map((s, i) => (
          <div key={i} style={{
            display: 'grid', gridTemplateColumns: '120px repeat(8, 32px) 44px', gap: 4,
            padding: '6px 16px', alignItems: 'center',
            background: i % 2 ? 'transparent' : 'var(--sf-surface)',
          }}>
            <div style={{ fontSize: 12, fontWeight: 600, whiteSpace: 'nowrap',
                            overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.n}</div>
            {s.grades.map((g, j) => {
              const c = cellColor(g);
              return (
                <div key={j} style={{
                  height: 30, borderRadius: 6,
                  background: c.bg, color: c.fg,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--sf-font-mono)', fontSize: 12, fontWeight: 700,
                }}>{g === 'n' ? '·' : g}</div>
              );
            })}
            <div className="sf-mono" style={{
              height: 30, borderRadius: 6, background: 'var(--sf-ink)', color: 'var(--sf-bg)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 12, fontWeight: 700,
            }}>{s.avg}</div>
          </div>
        ))}

        {/* AI insight */}
        <div className="sf-ai-surface" style={{ margin: '16px 16px', padding: 14, borderRadius: 14 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>Tahlil</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 13, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              <strong>Eshmatov Otabek</strong>ning 4-yarim-yillik imtihonida baho yo‘q. Davomati ham 72%. Yo‘qlama sababli bo‘lishi mumkin.
            </div>
          </div>
        </div>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, {
  AssignmentsScreen, CreateAssignmentScreen, GradeSubmissionScreen, GradebookScreen,
});
