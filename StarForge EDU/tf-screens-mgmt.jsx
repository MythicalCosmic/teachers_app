// tf-screens-mgmt.jsx — Direct line to education center management

function MgmtInboxScreen({ platform = 'ios' }) {
  const threads = [
    { n: 'Karimova Rano', r: 'Direktor', last: 'Ertangi yig‘ilish 14:00 da o‘tadi.', t: '14:08', unread: 1, pin: true, online: true },
    { n: 'Ahmedov Botir', r: 'O‘quv ishlari bo‘yicha', last: 'Yangi karta sozlamalari haqida o‘qib chiqing.', t: '12:42', unread: 0 },
    { n: 'Yusupova Nargiza', r: 'Metodist · Matematika', last: 'Mavzular ro‘yxati yangilandi.', t: 'Du · 16:20', unread: 2 },
    { n: 'Markaz e‘lonlari', r: 'Avtomatik · barchaga', last: 'May oyi xulosalari · 23.05 gacha topshiring.', t: 'Du · 10:00', unread: 0, channel: true },
    { n: 'Tursunov Sherzod', r: 'Filial menejeri', last: 'Yunusobod filialida printer almashtirildi.', t: '17 May', unread: 0 },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Boshqaruv"
        subtitle="Markaz va filial bilan to‘g‘ridan-to‘g‘ri"
        right={<>{Icons.search}{Icons.edit}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { l: 'Hammasi', n: 5, act: true },
            { l: 'Direktor', n: 1 },
            { l: 'Metodist', n: 1 },
            { l: 'Markaz', n: 1 },
          ].map((t, i) => (
            <div key={t.l} style={{
              flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 10,
              fontSize: 11, fontWeight: 600,
              background: t.act ? 'var(--sf-ink)' : 'transparent',
              color: t.act ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: t.act ? 'none' : '1px solid var(--sf-border)',
            }}>{t.l} · {t.n}</div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)' }}>
        {threads.map((th, i) => (
          <div key={i} style={{
            display: 'flex', gap: 12, padding: '14px 18px', alignItems: 'center',
            borderBottom: '1px solid var(--sf-border)',
            background: th.unread > 0 ? 'var(--sf-surface)' : 'transparent',
          }}>
            <div style={{ position: 'relative' }}>
              {th.channel ? (
                <div style={{
                  width: 46, height: 46, borderRadius: 14, background: 'var(--sf-ink)',
                  color: 'var(--sf-bg)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><SfStar size={22} color="var(--sf-accent)" /></div>
              ) : <SfAvatar name={th.n} size={46} />}
              {th.online && (
                <div style={{ position: 'absolute', right: -2, bottom: -2, width: 14, height: 14,
                                borderRadius: '50%', background: 'var(--sf-success)',
                                border: '2.5px solid var(--sf-bg)' }} />
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontSize: 14, fontWeight: th.unread > 0 ? 700 : 600 }}>{th.n}</span>
                {th.pin && <span style={{ color: 'var(--sf-accent)' }}>{React.cloneElement(Icons.pin, { size: 12 })}</span>}
                {th.r.includes('Direktor') && <SfPill tone="primary">Direktor</SfPill>}
              </div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)', marginTop: 1 }}>{th.r}</div>
              <div style={{ marginTop: 4, fontSize: 12.5,
                              color: th.unread > 0 ? 'var(--sf-ink-2)' : 'var(--sf-muted)',
                              fontWeight: th.unread > 0 ? 600 : 400,
                              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{th.last}</div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
              <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>{th.t}</span>
              {th.unread > 0 && (
                <div style={{ minWidth: 20, height: 20, borderRadius: 10, padding: '0 6px',
                                background: 'var(--sf-primary)', color: '#FFFCF5',
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontSize: 11, fontWeight: 700 }}>{th.unread}</div>
              )}
            </div>
          </div>
        ))}
      </div>

      <div style={{ padding: '10px 18px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)' }}>
        <button className="sf-btn sf-btn--primary sf-btn--block" style={{ height: 48 }}>
          {React.cloneElement(Icons.edit, { size: 16 })} Yangi xabar
        </button>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function MgmtChatScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px 10px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ color: 'var(--sf-primary)' }}>{React.cloneElement(Icons.arrowL, { size: 18 })}</span>
          <SfAvatar name="Karimova Rano" size={36} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 6 }}>
              Karimova Rano <SfPill tone="primary">Direktor</SfPill>
            </div>
            <div style={{ fontSize: 10.5, color: 'var(--sf-success)' }}>
              <span style={{ display: 'inline-block', width: 6, height: 6, borderRadius: '50%',
                              background: 'var(--sf-success)', marginRight: 4 }} />
              onlayn · Demo Akademiya
            </div>
          </div>
          <div style={{ color: 'var(--sf-ink-2)' }}>{Icons.more}</div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px',
                     display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ textAlign: 'center', fontSize: 10, color: 'var(--sf-muted)',
                       letterSpacing: '0.06em', textTransform: 'uppercase', fontWeight: 600 }}>
          Bugun
        </div>

        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <SfAvatar name="Karimova Rano" size={28} />
          <div style={{ maxWidth: '76%', padding: '10px 14px', borderRadius: '4px 18px 18px 18px',
                          background: 'var(--sf-surface)', border: '1px solid var(--sf-border)' }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4 }}>
              Salom Nigora opa. Mayning yakuniy hisobotini 23 gacha topshirsangiz bo‘ladimi?
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, color: 'var(--sf-muted)' }}>11:08</div>
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{ maxWidth: '76%', padding: '10px 14px', borderRadius: '18px 18px 4px 18px',
                          background: 'var(--sf-primary)', color: '#FFFCF5' }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4 }}>
              Albatta. Bugun ertalab Up/Down kartalar va davomatni tahlil qilib, yopiq hisobotni jo‘nataman.
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, opacity: 0.8, display: 'flex',
                            justifyContent: 'flex-end', gap: 4 }}>
              <span>11:14</span>
              {React.cloneElement(Icons.check, { size: 12, stroke: 2.6 })}
            </div>
          </div>
        </div>

        {/* Announcement card */}
        <div style={{ padding: 12, borderRadius: 14, background: 'var(--sf-surface)',
                       border: '1px solid var(--sf-accent)', display: 'flex', gap: 10, alignItems: 'flex-start' }}>
          <div style={{ width: 32, height: 32, borderRadius: 10, background: 'var(--sf-accent-soft)',
                          color: 'var(--sf-accent-ink)',
                          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            {React.cloneElement(Icons.flag, { size: 16 })}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, color: 'var(--sf-muted)', letterSpacing: '0.05em',
                            textTransform: 'uppercase', fontWeight: 600 }}>Topshiriq · direktordan</div>
            <div style={{ marginTop: 4, fontSize: 13, fontWeight: 700 }}>May hisoboti</div>
            <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>
              Muddat: <span className="sf-mono" style={{ color: 'var(--sf-danger)', fontWeight: 700 }}>23.05 · 18:00</span>
            </div>
            <button className="sf-btn sf-btn--soft" style={{ marginTop: 8, fontSize: 12, padding: '6px 12px' }}>
              {React.cloneElement(Icons.arrowR, { size: 12 })} Vazifaga o‘tish
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <SfAvatar name="Karimova Rano" size={28} />
          <div style={{ maxWidth: '76%', padding: '10px 14px', borderRadius: '4px 18px 18px 18px',
                          background: 'var(--sf-surface)', border: '1px solid var(--sf-border)' }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4 }}>
              Rahmat. Yana bitta — ertaga 14:00 da yig‘ilish, oddiy holat bo‘yicha.
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, color: 'var(--sf-muted)' }}>14:08</div>
          </div>
        </div>
      </div>

      <div style={{ padding: '10px 14px 12px', background: 'var(--sf-surface)',
                     borderTop: '1px solid var(--sf-border)',
                     display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--sf-surface-2)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {React.cloneElement(Icons.attach, { size: 18 })}
        </div>
        <div style={{ flex: 1, background: 'var(--sf-surface-2)', borderRadius: 22,
                        padding: '10px 14px', fontSize: 13, color: 'var(--sf-muted)' }}>
          Direktorga yozish...
        </div>
        <div style={{ width: 38, height: 38, borderRadius: 12, background: 'var(--sf-primary)',
                        color: '#FFFCF5',
                        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {React.cloneElement(Icons.send, { size: 18 })}
        </div>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { MgmtInboxScreen, MgmtChatScreen });
