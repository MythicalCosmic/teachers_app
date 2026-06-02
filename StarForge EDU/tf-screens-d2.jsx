// tf-screens-d2.jsx — Messages / parent chat

function MessagesScreen({ platform = 'ios' }) {
  const threads = [
    { n: 'Akbarova Dilnoza', sub: '9-B · Akmal ona', last: 'Rahmat, ustoz! Ertaga albatta...', t: '14:42', unread: 0, online: true },
    { n: '9-B ota-onalar', sub: 'Guruh chat · 24 azo', last: 'Nigora opa: Ertangi darsda...', t: '12:18', unread: 3, group: true },
    { n: 'Azizova Sevara', sub: '9-B · Madina ona', last: 'Yozma ish bo‘yicha...', t: 'Du', unread: 1 },
    { n: 'Eshmatova Gulnora', sub: '9-B · Otabek ona', last: 'Bolam bugun darsga kela ol...', t: 'Du', unread: 2 },
    { n: 'Karimova Rano', sub: 'Direktor', last: 'Ertangi yig‘ilish 14:00 da', t: '16 May', unread: 0, pin: true },
    { n: 'Bakirova Zarnigor', sub: '9-B · Sherzod ona', last: 'Yaxshi, biz keldik', t: '15 May', unread: 0 },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Xabarlar"
        subtitle="6 ta yangi"
        right={<>{Icons.search}{Icons.edit}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { l: 'Hammasi', n: 4, act: true },
            { l: 'Ota-onalar', n: 4 },
            { l: 'Hamkasblar', n: 1 },
            { l: 'Markaz', n: 1 },
          ].map((t, i) => (
            <div key={t.l} style={{
              flex: 1, padding: '6px 0', textAlign: 'center', borderRadius: 10,
              fontSize: 12, fontWeight: 600,
              background: t.act ? 'var(--sf-ink)' : 'transparent',
              color: t.act ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: t.act ? 'none' : '1px solid var(--sf-border)',
            }}>
              {t.l} {t.n > 0 && <span style={{ opacity: 0.7 }}>· {t.n}</span>}
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)' }}>
        {threads.map((th, i) => (
          <div key={i} style={{
            display: 'flex', gap: 12, padding: '14px 18px', alignItems: 'center',
            borderBottom: '1px solid var(--sf-border)',
            background: th.unread > 0 ? 'var(--sf-surface)' : 'var(--sf-bg)',
          }}>
            <div style={{ position: 'relative' }}>
              {th.group ? (
                <div style={{
                  width: 46, height: 46, borderRadius: 14,
                  background: 'var(--sf-primary)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#FFFCF5',
                }}><SfStar size={22} color="#FFFCF5" /></div>
              ) : (
                <SfAvatar name={th.n} size={46} />
              )}
              {th.online && (
                <div style={{
                  position: 'absolute', right: -2, bottom: -2, width: 14, height: 14,
                  borderRadius: '50%', background: 'var(--sf-success)',
                  border: '2.5px solid var(--sf-bg)',
                }} />
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontSize: 14, fontWeight: th.unread > 0 ? 700 : 600 }}>{th.n}</span>
                {th.pin && <span style={{ color: 'var(--sf-accent)', display: 'inline-flex' }}>{React.cloneElement(Icons.pin, { size: 12 })}</span>}
              </div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-muted)', marginTop: 1 }}>{th.sub}</div>
              <div style={{ marginTop: 4, fontSize: 12.5,
                              color: th.unread > 0 ? 'var(--sf-ink-2)' : 'var(--sf-muted)',
                              fontWeight: th.unread > 0 ? 600 : 400,
                              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {th.last}
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
              <span className="sf-mono" style={{ fontSize: 10, color: 'var(--sf-muted)' }}>{th.t}</span>
              {th.unread > 0 && (
                <div style={{
                  minWidth: 20, height: 20, borderRadius: 10, padding: '0 6px',
                  background: 'var(--sf-primary)', color: '#FFFCF5',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 11, fontWeight: 700,
                }}>{th.unread}</div>
              )}
            </div>
          </div>
        ))}
      </div>

      <SfTabBar active="chat" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

function ChatScreen({ platform = 'ios' }) {
  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <div style={{ background: 'var(--sf-surface)', padding: '4px 18px 12px',
                     borderBottom: '1px solid var(--sf-border)' }}>
        <div style={{ height: 44, display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ color: 'var(--sf-primary)', fontSize: 16, display: 'inline-flex',
                          alignItems: 'center' }}>
            {React.cloneElement(Icons.arrowL, { size: 18 })}
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
            <SfAvatar name="Akbarova Dilnoza" size={36} />
            <div>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Akbarova Dilnoza</div>
              <div style={{ fontSize: 10.5, color: 'var(--sf-success)' }}>
                <span style={{ display: 'inline-block', width: 6, height: 6,
                                borderRadius: '50%', background: 'var(--sf-success)', marginRight: 4 }} />
                onlayn · Akmal ona · 9-B
              </div>
            </div>
          </div>
          <div style={{ color: 'var(--sf-primary)' }}>{Icons.more}</div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)',
                     padding: '14px 18px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>

        {/* Date sep */}
        <div style={{ textAlign: 'center', fontSize: 10, color: 'var(--sf-muted)',
                       letterSpacing: '0.06em', textTransform: 'uppercase', fontWeight: 600,
                       margin: '4px 0' }}>
          Bugun
        </div>

        {/* Incoming */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end' }}>
          <SfAvatar name="Akbarova Dilnoza" size={28} />
          <div style={{
            maxWidth: '76%', padding: '10px 14px', borderRadius: '4px 18px 18px 18px',
            background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
          }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4, color: 'var(--sf-ink)' }}>
              Assalomu alaykum, Nigora opa. Akmal bugun darsda nima yangilik qildi?
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, color: 'var(--sf-muted)' }}>09:42</div>
          </div>
        </div>

        {/* Outgoing */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{
            maxWidth: '76%', padding: '10px 14px', borderRadius: '18px 18px 4px 18px',
            background: 'var(--sf-primary)', color: '#FFFCF5',
          }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4 }}>
              Va alaykum assalom! Akmal bugun yaxshi ishladi — kvadrat tenglamani mustaqil yechib berdi. Faqat 2-misolda formuladagi kichik xato bo‘ldi, biz birga ko‘rib chiqdik.
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, opacity: 0.8, display: 'flex',
                            justifyContent: 'flex-end', gap: 4 }}>
              <span>09:48</span>
              {React.cloneElement(Icons.check, { size: 12, stroke: 2.6 })}
            </div>
          </div>
        </div>

        {/* AI suggested reply panel */}
        <div className="sf-ai-surface" style={{ padding: 12, borderRadius: 16, marginTop: 4 }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <SfAiBadge compact>Javob taklifi</SfAiBadge>
              <span style={{ fontSize: 10, color: 'var(--sf-muted)' }}>uz · 3 variant</span>
            </div>
            <div style={{ marginTop: 8, display: 'flex', flexDirection: 'column', gap: 6 }}>
              {[
                'Bugungi mavzu — kvadrat tenglamalar, Akmal yaxshi ishladi.',
                'Akmalning bugungi natijasi · 4 baho. Uy ishini topshirsa, qoldirgan misolni qaytaramiz.',
                'Akmal hozir o‘rta darajada. Qisqa konsultatsiya yordam beradi.',
              ].map((t, i) => (
                <div key={i} style={{
                  padding: 10, background: 'var(--sf-surface)',
                  border: '1px solid var(--sf-ai-border)', borderRadius: 10,
                  fontSize: 12.5, color: 'var(--sf-ink-2)', lineHeight: 1.4,
                  display: 'flex', alignItems: 'center', gap: 8,
                }}>
                  <span style={{ flex: 1 }}>{t}</span>
                  <span style={{ color: 'var(--sf-ai)', display: 'inline-flex' }}>
                    {React.cloneElement(Icons.arrowR, { size: 14 })}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Incoming */}
        <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', marginTop: 4 }}>
          <SfAvatar name="Akbarova Dilnoza" size={28} />
          <div style={{
            maxWidth: '76%', padding: '10px 14px', borderRadius: '4px 18px 18px 18px',
            background: 'var(--sf-surface)', border: '1px solid var(--sf-border)',
          }}>
            <div style={{ fontSize: 13.5, lineHeight: 1.4, color: 'var(--sf-ink)' }}>
              Rahmat, ustoz! Ertaga albatta mashqlarni qilamiz.
            </div>
            <div style={{ marginTop: 6, fontSize: 9.5, color: 'var(--sf-muted)' }}>14:42</div>
          </div>
        </div>
      </div>

      {/* Input */}
      <div style={{
        padding: '10px 14px 12px', background: 'var(--sf-surface)',
        borderTop: '1px solid var(--sf-border)',
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <div style={{
          width: 38, height: 38, borderRadius: 12, background: 'var(--sf-surface-2)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: 'var(--sf-ink-2)',
        }}>{React.cloneElement(Icons.attach, { size: 18 })}</div>
        <div style={{
          flex: 1, background: 'var(--sf-surface-2)', borderRadius: 22,
          padding: '10px 14px', fontSize: 13, color: 'var(--sf-muted)',
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <span style={{ flex: 1 }}>Yozish...</span>
          <SfAiBadge compact>↺</SfAiBadge>
        </div>
        <div style={{
          width: 38, height: 38, borderRadius: 12, background: 'var(--sf-primary)',
          color: '#FFFCF5',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{React.cloneElement(Icons.send, { size: 18 })}</div>
      </div>

      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { MessagesScreen, ChatScreen });
