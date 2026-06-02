// tf-screens-d1.jsx — Content library

function ContentScreen({ platform = 'ios' }) {
  const folders = [
    { n: 'Algebra · Daraja II', cnt: 24, color: 'var(--sf-primary)' },
    { n: 'Geometriya', cnt: 18, color: 'var(--sf-accent)' },
    { n: 'Olimpiada to‘plami', cnt: 42, color: 'var(--sf-ink-2)' },
  ];
  const files = [
    { t: 'Kvadrat tenglama · 03', i: Icons.pdf, m: '2.1 MB · 8 bet', c: 'var(--sf-danger)', ai: 'AI xulosa tayyor' },
    { t: 'Funksiyalar grafigi', i: Icons.video, m: '6:42 · MP4', c: 'var(--sf-accent)' },
    { t: 'Diskriminant · slayd', i: Icons.doc, m: 'PPTX · 16 slayd', c: 'var(--sf-primary)' },
    { t: 'Tenglamalar to‘plami', i: Icons.pdf, m: '880 KB · 12 bet', c: 'var(--sf-danger)' },
    { t: 'Matematik induktsiya', i: Icons.doc, m: 'DOCX · 4 bet', c: 'var(--sf-primary)' },
  ];

  return (
    <SfFrame>
      {platform === 'ios' ? <SfStatusBarIOS /> : <SfStatusBarAndroid />}
      <SfNavBarIOS large title="Materiallar"
        subtitle="Kutubxona · 84 fayl"
        right={<>{Icons.search}{Icons.upload}</>} />

      <div style={{ padding: '0 18px 12px', background: 'var(--sf-surface)' }}>
        <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }}>
          {['Hammasi', 'PDF', 'Video', 'Slayd', 'Mening', 'Markaz'].map((t, i) => (
            <div key={t} style={{
              padding: '6px 12px', borderRadius: 999, fontSize: 12, fontWeight: 600,
              whiteSpace: 'nowrap',
              background: i === 0 ? 'var(--sf-ink)' : 'transparent',
              color: i === 0 ? 'var(--sf-bg)' : 'var(--sf-muted)',
              border: i === 0 ? 'none' : '1px solid var(--sf-border)',
            }}>{t}</div>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'auto', background: 'var(--sf-bg)', padding: '14px 18px 100px' }}>
        {/* Folders */}
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8 }}>Papkalar</div>
        <div style={{ display: 'flex', gap: 10, overflowX: 'auto' }}>
          {folders.map((f, i) => (
            <div key={i} className="sf-card" style={{ minWidth: 160, padding: 14 }}>
              <div style={{ width: 38, height: 38, borderRadius: 11, background: f.color,
                              color: '#FFFCF5',
                              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {React.cloneElement(Icons.folder, { size: 20 })}
              </div>
              <div style={{ marginTop: 10, fontSize: 13, fontWeight: 700, lineHeight: 1.2 }}>{f.n}</div>
              <div style={{ marginTop: 2, fontSize: 10, color: 'var(--sf-muted)' }}>{f.cnt} fayl</div>
            </div>
          ))}
        </div>

        {/* Files */}
        <div style={{ marginTop: 18, fontSize: 11, fontWeight: 600, letterSpacing: '0.06em',
                       textTransform: 'uppercase', color: 'var(--sf-muted)', marginBottom: 8,
                       display: 'flex', justifyContent: 'space-between' }}>
          <span>So‘nggi fayllar</span>
          <span style={{ color: 'var(--sf-primary)' }}>Saralash</span>
        </div>

        <div className="sf-card" style={{ padding: 0, overflow: 'hidden' }}>
          {files.map((f, i, a) => (
            <div key={i} style={{
              display: 'flex', gap: 12, padding: '12px 14px', alignItems: 'center',
              borderBottom: i < a.length - 1 ? '1px solid var(--sf-border)' : 'none',
            }}>
              <div style={{ width: 40, height: 44, borderRadius: 10, background: f.c, color: '#FFFCF5',
                              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                {React.cloneElement(f.i, { size: 20 })}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600,
                                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{f.t}</div>
                <div style={{ marginTop: 2, display: 'flex', gap: 6, alignItems: 'center' }}>
                  <span style={{ fontSize: 10.5, color: 'var(--sf-muted)' }}>{f.m}</span>
                  {f.ai && <span className="sf-chip sf-chip--ai" style={{ fontSize: 9, padding: '1px 6px' }}>AI</span>}
                </div>
              </div>
              {React.cloneElement(Icons.download, { size: 18 })}
            </div>
          ))}
        </div>

        {/* Upload CTA */}
        <div style={{ marginTop: 16, padding: 18, borderRadius: 16,
                       border: '1.5px dashed var(--sf-border-strong)',
                       background: 'var(--sf-surface)', textAlign: 'center' }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: 'var(--sf-primary-soft)', color: 'var(--sf-primary)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto',
          }}>{React.cloneElement(Icons.upload, { size: 22 })}</div>
          <div style={{ marginTop: 10, fontSize: 14, fontWeight: 700 }}>Fayl yuklash</div>
          <div style={{ marginTop: 2, fontSize: 11, color: 'var(--sf-muted)' }}>
            PDF, MP4, PPTX, DOCX · 200 MB gacha
          </div>
        </div>
      </div>

      <SfTabBar active="me" platform={platform} />
      {platform === 'ios' ? <SfHomeIndicatorIOS /> : <SfNavBarAndroid />}
    </SfFrame>
  );
}

Object.assign(window, { ContentScreen });
