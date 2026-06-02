// tf-screens-tasks.jsx — Notion/ClickUp-style task management
// Personal tasks + tasks assigned by management. Status pills, due dates,
// project tags, sub-tasks, priorities.

function TasksScreen({ platform = 'ios' }) {
  const tasks = [
    {
      pri: 'P1', state: 'doing', stateName: 'Bajarilmoqda', stateTone: 'primary',
      t: 'May oyi yakuniy hisobotini topshirish',
      proj: 'Hisobot', projColor: 'var(--sf-primary)',
      assigner: 'Karimova R.', deadline: 'Erta · 18:00',
      subs: { done: 2, total: 4 }, fromMgmt: true, urgent: true,
    },
    {
      pri: 'P2', state: 'todo', stateName: 'Boshlanmagan', stateTone: 'neutral',
      t: 'Kvadrat tenglamalar · slaydlarni yangilash',
      proj: 'Materiallar', projColor: 'var(--sf-accent)',
      assigner: 'Men', deadline: 'Pen · 23:59',
      subs: { done: 0, total: 3 },
    },
    {
      pri: 'P2', state: 'doing', stateName: 'Bajarilmoqda', stateTone: 'primary',
      t: 'So‘rovnoma · AI sifat baholash',
      proj: 'So‘rovnoma', projColor: 'var(--sf-ai)',
      assigner: 'Metodist', deadline: '22.05',
      subs: { done: 1, total: 1 }, fromMgmt: true,
    },
    {
      pri: 'P3', state: 'review', stateName: 'Tekshirishda', stateTone: 'accent',
      t: 'Olimpiada tayyorgarligi · 11-B uchun reja',
      proj: 'Tayyorlov', projColor: 'var(--sf-ink-2)',
      assigner: 'Yusupova N.', deadline: '25.05', fromMgmt: true,
    },
    {
      pri: 'P3', state: 'done', stateName: 'Tugatildi', stateTone: 'success',
      t: 'Yangi karta nomlarini ko‘rib chiqish',
      proj: 'Markaz', projColor: 'var(--sf-success)',
      assigner: 'Direktor', deadline: '18.05', fromMgmt: true,
    },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Vazifalar"
        subtitle="3 ta bugun · 2 ta direktordan"
        right={<>{Icons.filter}{Icons.plus}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { l: 'Hammasi', n: 12, act: true },
            { l: 'Mendan', n: 7 },
            { l: 'Boshqaruv', n: 5 },
            { l: 'Tugatildi', n: 8 },
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

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '12px 18px 100px' }}>
        {/* Today section */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                       padding: '0 4px 8px' }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                          textTransform: 'uppercase', color: 'var(--sf-muted)' }}>
            Bugun · 3 ta
          </div>
          <div style={{ display: 'flex', gap: 4 }}>
            {['List', 'Board'].map((v, i) => (
              <div key={v} style={{
                padding: '4px 10px', borderRadius: 6, fontSize: 11, fontWeight: 600,
                background: i === 0 ? 'var(--sf-ink)' : 'transparent',
                color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
                border: i === 0 ? 'none' : '1px solid var(--sf-border)',
              }}>{v}</div>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {tasks.map((task, i) => {
            const stateColors = {
              primary: { bg: 'var(--sf-primary-soft)', fg: 'var(--sf-primary-ink)' },
              neutral: { bg: 'var(--sf-surface-2)', fg: 'var(--sf-muted)' },
              accent:  { bg: 'var(--sf-accent-soft)', fg: 'var(--sf-accent-ink)' },
              success: { bg: 'var(--sf-success-soft)', fg: 'var(--sf-success)' },
            };
            const sc = stateColors[task.stateTone];
            return (
              <div key={i} className="sf-card" style={{
                padding: 14, position: 'relative',
                opacity: task.state === 'done' ? 0.65 : 1,
              }}>
                {/* Left rail */}
                <div style={{
                  position: 'absolute', left: 0, top: 14, bottom: 14, width: 3,
                  borderRadius: 3,
                  background: task.urgent ? 'var(--sf-danger)' : task.projColor,
                }} />
                <div style={{ paddingLeft: 8 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                    {/* Checkbox */}
                    <div style={{
                      width: 18, height: 18, borderRadius: 5,
                      background: task.state === 'done' ? 'var(--sf-success)' : 'transparent',
                      border: task.state === 'done' ? 'none' : '1.5px solid var(--sf-border-strong)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: '#FFFCF5',
                    }}>{task.state === 'done' && React.cloneElement(Icons.check, { size: 12, stroke: 3.2 })}</div>
                    <span style={{
                      padding: '2px 6px', borderRadius: 4,
                      background: sc.bg, color: sc.fg,
                      fontSize: 10, fontWeight: 700,
                      letterSpacing: '0.04em', textTransform: 'uppercase',
                    }}>{task.stateName}</span>
                    {task.fromMgmt && (
                      <span style={{
                        padding: '2px 6px', borderRadius: 4,
                        background: 'var(--sf-ink)', color: 'var(--sf-bg)',
                        fontSize: 10, fontWeight: 700,
                      }}>BOSHQARUV</span>
                    )}
                    <span style={{ flex: 1 }} />
                    <span className="sf-mono" style={{
                      fontSize: 10, fontWeight: 700,
                      color: task.pri === 'P1' ? 'var(--sf-danger)' :
                              task.pri === 'P2' ? 'var(--sf-warn)' :
                              'var(--sf-muted)',
                    }}>{task.pri}</span>
                  </div>
                  <div style={{
                    marginTop: 8, fontSize: 14, fontWeight: 600, lineHeight: 1.3,
                    color: task.state === 'done' ? 'var(--sf-muted)' : 'var(--sf-ink)',
                    textDecoration: task.state === 'done' ? 'line-through' : 'none',
                  }}>{task.t}</div>
                  <div style={{ marginTop: 8, display: 'flex', gap: 12, alignItems: 'center',
                                  fontSize: 11, color: 'var(--sf-muted)' }}>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <span style={{ width: 8, height: 8, borderRadius: 2, background: task.projColor }} />
                      {task.proj}
                    </span>
                    {task.subs && (
                      <span className="sf-mono">{task.subs.done}/{task.subs.total} subt</span>
                    )}
                    <span style={{ flex: 1 }} />
                    <span className="sf-mono" style={{
                      color: task.urgent ? 'var(--sf-danger)' :
                              task.state === 'done' ? 'var(--sf-muted)' :
                              'var(--sf-ink-2)',
                      fontWeight: task.urgent ? 700 : 500,
                    }}>{task.deadline}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* AI assistant card */}
        <div className="sf-ai-surface" style={{ marginTop: 18, padding: 14, borderRadius: 16 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>Vazifa yordamchi</SfAiBadge>
            <div style={{ marginTop: 8, fontSize: 13, color: 'var(--sf-ink-2)', lineHeight: 1.4 }}>
              May hisobotini yozish uchun ish boshlasangiz, AI o‘tkan oygi davomat va kartalardan jamlama tayyorlab beraman.
            </div>
            <button className="sf-btn" style={{ marginTop: 10, background: 'var(--sf-ink)',
                                                   color: 'var(--sf-bg)', fontSize: 13, padding: '8px 14px' }}>
              Boshlash {React.cloneElement(Icons.arrowR, { size: 12 })}
            </button>
          </div>
        </div>
      </div>

      <div style={{ padding: '10px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)' }}>
        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 48 }}>
          {React.cloneElement(Icons.plus, { size: 18 })} Yangi vazifa
        </button>
      </div>

      <SfTabBar active="tasks" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function TaskDetailScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ color: 'var(--sf-primary)' }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2 }}>
              {React.cloneElement(Icons.arrowL, { size: 18 })}
              <span style={{ fontSize: 15, fontWeight: 600 }}>Vazifalar</span>
            </span>
          </span>
          <div style={{ display: 'flex', gap: 12 }}>
            <span style={{ color: 'var(--sf-ink-2)' }}>{React.cloneElement(Icons.print, { size: 18 })}</span>
            <span style={{ color: 'var(--sf-ink-2)' }}>{Icons.more}</span>
          </div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 20px 100px' }}>
        {/* Header */}
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <SfPill tone="primary">BAJARILMOQDA</SfPill>
          <span style={{ padding: '4px 8px', borderRadius: 4, background: 'var(--sf-ink)',
                          color: 'var(--sf-bg)', fontSize: 10, fontWeight: 700,
                          letterSpacing: '0.04em' }}>BOSHQARUV</span>
          <span className="sf-mono" style={{ fontSize: 10, fontWeight: 700,
                                                color: 'var(--sf-danger)' }}>P1</span>
        </div>
        <h2 style={{ marginTop: 10, marginBottom: 0,
                       fontSize: 26, lineHeight: 1.15, letterSpacing: '-0.025em', fontWeight: 800 }}>
          May oyi yakuniy <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                                            fontWeight: 400 }}>hisobotini</span> topshirish
        </h2>

        {/* Properties — Notion-style */}
        <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 4 }}>
          {[
            { l: 'Loyiha', v: 'Hisobot · oylik', icon: 'dot', dotColor: 'var(--sf-primary)' },
            { l: 'Bergan', v: 'Karimova R. · Direktor', icon: 'avatar' },
            { l: 'Muddat', v: 'Ertaga · 18:00', icon: 'date', urgent: true },
            { l: 'Sub-vazifa', v: '2 / 4 bajarildi', icon: 'check' },
            { l: 'Tag', v: 'Markaz · Yarim oy · Mat', icon: 'tag' },
          ].map((p, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12,
                                     padding: '6px 0', fontSize: 12 }}>
              <span style={{ width: 80, color: 'var(--sf-muted)', display: 'flex',
                              alignItems: 'center', gap: 6 }}>
                {p.icon === 'dot' && <span style={{ width: 6, height: 6, borderRadius: '50%',
                                                       background: p.dotColor }} />}
                {p.icon === 'avatar' && React.cloneElement(Icons.user, { size: 13 })}
                {p.icon === 'date' && React.cloneElement(Icons.cal, { size: 13 })}
                {p.icon === 'check' && React.cloneElement(Icons.check, { size: 13 })}
                {p.icon === 'tag' && React.cloneElement(Icons.brand, { size: 13 })}
                <span>{p.l}</span>
              </span>
              <span style={{
                color: p.urgent ? 'var(--sf-danger)' : 'var(--sf-ink-2)',
                fontWeight: p.urgent ? 700 : 600,
              }}>{p.v}</span>
            </div>
          ))}
        </div>

        <div style={{ height: 1, background: 'var(--sf-border)', margin: '18px 0' }} />

        {/* Description block */}
        <div style={{ fontSize: 14, lineHeight: 1.6, color: 'var(--sf-ink)' }}>
          May oyi bo‘yicha yakuniy hisobotni tayyorlash. Hisobotda quyidagilar bo‘lishi kerak:
        </div>

        {/* Sub-tasks */}
        <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 2 }}>
          {[
            { t: 'Davomat statistikasi · 3 guruh', done: true },
            { t: 'Up/Down kartalar tahlili', done: true },
            { t: 'AI suhbat asosida tavsiyalar', done: false, current: true },
            { t: 'Yakuniy xulosa · 1 sahifa', done: false },
          ].map((s, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10,
                                     padding: '8px 6px', borderRadius: 6,
                                     background: s.current ? 'var(--sf-primary-soft)' : 'transparent' }}>
              <div style={{
                width: 18, height: 18, borderRadius: 5, flexShrink: 0,
                background: s.done ? 'var(--sf-success)' : 'transparent',
                border: s.done ? 'none' : `1.5px solid ${s.current ? 'var(--sf-primary)' : 'var(--sf-border-strong)'}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: '#FFFCF5',
              }}>{s.done && React.cloneElement(Icons.check, { size: 12, stroke: 3.2 })}</div>
              <span style={{
                fontSize: 14, flex: 1,
                color: s.done ? 'var(--sf-muted)' : 'var(--sf-ink)',
                textDecoration: s.done ? 'line-through' : 'none',
                fontWeight: s.current ? 700 : 400,
              }}>{s.t}</span>
              {s.current && <span style={{ width: 6, height: 6, borderRadius: '50%',
                                              background: 'var(--sf-primary)',
                                              animation: 'sfBlink 1s steps(2) infinite' }} />}
            </div>
          ))}
        </div>

        {/* Code-style block */}
        <div style={{
          marginTop: 18, padding: 14, borderRadius: 10,
          background: 'var(--sf-surface-2)',
          fontFamily: 'var(--sf-font-mono)', fontSize: 12, color: 'var(--sf-ink-2)',
          lineHeight: 1.6,
        }}>
          <div style={{ color: 'var(--sf-muted)' }}># Hisobot shabloni</div>
          <div>1. Yunusobod filiali · 3 guruh</div>
          <div>2. Davomat: 94% (+2 → o‘sib)</div>
          <div>3. Up kartalar: <span style={{ color: '#7A4F0E', fontWeight: 700 }}>↑ 18</span></div>
          <div>4. Down kartalar: <span style={{ color: 'var(--sf-danger)', fontWeight: 700 }}>↓ 4</span></div>
        </div>

        {/* AI panel */}
        <div className="sf-ai-surface" style={{ marginTop: 18, padding: 14, borderRadius: 16 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <SfAiBadge>Hisobot yordamchi</SfAiBadge>
            <div style={{ marginTop: 8, fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                            fontSize: 15, lineHeight: 1.35 }}>
              “Sizning 9-B, Algebra Mid va 10-V ma‘lumotlaringizdan yarim avtomatik hisobot tuzdim. Ko‘rib chiqing va kerakli joylarga qo‘l tegdiring.”
            </div>
            <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <span className="sf-chip sf-chip--ai">Qoralama tayyor</span>
              <span className="sf-chip sf-chip--ai">3 sahifa · PDF</span>
            </div>
          </div>
        </div>

        {/* Activity */}
        <div style={{ marginTop: 22, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 10 }}>
          Faollik · 4 ta
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[
            { who: 'Karimova R.', what: 'vazifani sizga biriktirdi', t: '17 May · 14:08' },
            { who: 'Siz', what: '"Davomat statistikasi"ni tugatdingiz', t: '18 May · 10:22' },
            { who: 'Siz', what: '"Up/Down kartalar tahlili"ni tugatdingiz', t: '19 May · 09:42' },
            { who: 'AI', what: 'qoralama tayyorladi', t: 'Hozir' },
          ].map((a, i) => (
            <div key={i} style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
              {a.who === 'AI' ? (
                <div style={{ width: 24, height: 24, borderRadius: 6,
                                background: 'var(--sf-ai-bg)', border: '1px solid var(--sf-ai-border)',
                                color: 'var(--sf-ai)',
                                fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
                                fontSize: 11, fontWeight: 600,
                                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>Ai</div>
              ) : <SfAvatar name={a.who} size={24} />}
              <div style={{ flex: 1, fontSize: 12, lineHeight: 1.4 }}>
                <span style={{ fontWeight: 700 }}>{a.who}</span>
                <span style={{ color: 'var(--sf-muted)' }}> {a.what}</span>
                <span className="sf-mono" style={{ display: 'block', fontSize: 10,
                                                      color: 'var(--sf-muted)', marginTop: 2 }}>{a.t}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ padding: '12px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)', display: 'flex', gap: 8 }}>
        <button className="sf-btn sf-btn--soft" style={{ flex: 1 }}>Qoldirish</button>
        <button className="sf-btn sf-btn--primary" style={{ flex: 1 }}>
          {React.cloneElement(Icons.check, { size: 16 })} Tugatish
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
      <style>{`@keyframes sfBlink { 0%, 50% { opacity: 1; } 50.01%, 100% { opacity: 0; } }`}</style>
    </SfFrame>
  );
}

Object.assign(window, { TasksScreen, TaskDetailScreen });
