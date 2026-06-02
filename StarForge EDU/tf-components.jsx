// tf-components.jsx — Shared atoms for the StarForge teacher app
// Icons (line, 1.7 stroke), small UI bits, platform chrome wrappers.

const SfIcon = ({ d, size = 22, stroke = 1.7, fill = 'none', children, style }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke="currentColor"
       strokeWidth={stroke} strokeLinecap="round" strokeLinejoin="round" style={style}>
    {d ? <path d={d} /> : children}
  </svg>
);

// 8-point star logomark — the StarForge identity
const SfStar = ({ size = 24, color = 'currentColor', style }) => (
  <svg width={size} height={size} viewBox="0 0 32 32" style={style}>
    <path d="M16 1 L19.4 11.2 L29.9 11.5 L21.3 17.6 L24.5 27.9 L16 21.4 L7.5 27.9 L10.7 17.6 L2.1 11.5 L12.6 11.2 Z"
          fill={color} />
    <circle cx="16" cy="16" r="2.2" fill="var(--sf-bg, #FBF6EC)" />
  </svg>
);

// Wordmark
const SfWordmark = ({ size = 18, color = 'var(--sf-ink)', accent = 'var(--sf-primary)' }) => (
  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 8, color }}>
    <SfStar size={size + 4} color={accent} />
    <span style={{
      fontFamily: 'var(--sf-font-ui)', fontWeight: 700, fontSize: size,
      letterSpacing: '-0.02em', lineHeight: 1
    }}>
      StarForge<span style={{ color: 'var(--sf-muted)', fontWeight: 500 }}> · EDU</span>
    </span>
  </span>
);

// Icon library — line, geometric, consistent stroke
const Icons = {
  home:     <SfIcon><path d="M3.5 11.2 L12 4 L20.5 11.2 V20 a1 1 0 0 1 -1 1 H4.5 a1 1 0 0 1 -1 -1 Z"/><path d="M9.5 21 v-6.5 h5 V21"/></SfIcon>,
  cal:      <SfIcon><rect x="3" y="5" width="18" height="16" rx="2.5"/><path d="M3 10 H21 M8 3 V7 M16 3 V7"/></SfIcon>,
  cohort:   <SfIcon><circle cx="9" cy="10" r="3.2"/><circle cx="17" cy="11" r="2.5"/><path d="M3.5 20 c0-3 2.5-5 5.5-5 s5.5 2 5.5 5"/><path d="M14.5 19.5 c0.3-2 2-3.5 4-3.5 c1 0 1.7 0.3 2 0.8"/></SfIcon>,
  book:     <SfIcon><path d="M4 5 a2 2 0 0 1 2-2 h12 v17 H6 a2 2 0 0 0 -2 2 Z M4 5 v15"/><path d="M8 7 H16 M8 11 H14"/></SfIcon>,
  chat:     <SfIcon><path d="M5 4 H19 a2 2 0 0 1 2 2 v9 a2 2 0 0 1 -2 2 H12 L7 21 V17 H5 a2 2 0 0 1 -2 -2 V6 a2 2 0 0 1 2 -2 Z"/></SfIcon>,
  bell:     <SfIcon><path d="M6 16 V11 a6 6 0 0 1 12 0 V16 L20 18 H4 Z M10 21 a2 2 0 0 0 4 0"/></SfIcon>,
  user:     <SfIcon><circle cx="12" cy="8" r="3.7"/><path d="M4.5 20 c0-3.5 3-6 7.5-6 s7.5 2.5 7.5 6"/></SfIcon>,
  check:    <SfIcon d="M5 12.5 L10 17.5 L19.5 7" stroke={2.4} />,
  x:        <SfIcon d="M6 6 L18 18 M18 6 L6 18" stroke={2.4} />,
  clock:    <SfIcon><circle cx="12" cy="12" r="9"/><path d="M12 7 V12 L15.5 14"/></SfIcon>,
  search:   <SfIcon><circle cx="11" cy="11" r="6"/><path d="M16 16 L20.5 20.5"/></SfIcon>,
  plus:     <SfIcon d="M12 5 V19 M5 12 H19" stroke={2.2} />,
  arrowR:   <SfIcon d="M5 12 H19 M14 6 L20 12 L14 18" />,
  arrowL:   <SfIcon d="M19 12 H5 M10 6 L4 12 L10 18" />,
  chevR:    <SfIcon d="M9 6 L15 12 L9 18"/>,
  chevD:    <SfIcon d="M6 9 L12 15 L18 9"/>,
  more:     <SfIcon><circle cx="5" cy="12" r="1.4" fill="currentColor"/><circle cx="12" cy="12" r="1.4" fill="currentColor"/><circle cx="19" cy="12" r="1.4" fill="currentColor"/></SfIcon>,
  filter:   <SfIcon d="M4 5 H20 M7 12 H17 M10 19 H14"/>,
  pin:      <SfIcon><path d="M12 21 V14 M6 8 a6 6 0 0 1 12 0 c0 4-3 6-6 6 s-6-2-6-6 Z"/></SfIcon>,
  edit:     <SfIcon><path d="M4 20 H8 L19 9 L15 5 L4 16 Z"/></SfIcon>,
  ai:       <SfIcon><path d="M12 3 L13.5 9 L19.5 10.5 L13.5 12 L12 18 L10.5 12 L4.5 10.5 L10.5 9 Z"/><circle cx="19" cy="5" r="1.2" fill="currentColor"/><circle cx="6" cy="19" r="1.2" fill="currentColor"/></SfIcon>,
  attach:   <SfIcon d="M14 6 L7.5 12.5 a3.5 3.5 0 0 0 5 5 L19.5 11 a5.5 5.5 0 0 0 -7.8 -7.8 L4.5 10.5"/>,
  send:     <SfIcon><path d="M4 12 L20 4 L14 20 L12 13 Z"/></SfIcon>,
  doc:      <SfIcon><path d="M6 3 H14 L19 8 V21 H6 Z M14 3 V8 H19 M8 13 H17 M8 17 H14"/></SfIcon>,
  pdf:      <SfIcon><path d="M6 3 H14 L19 8 V21 H6 Z M14 3 V8 H19"/></SfIcon>,
  video:    <SfIcon><rect x="3" y="6" width="14" height="12" rx="2"/><path d="M17 10 L22 7 V17 L17 14"/></SfIcon>,
  folder:   <SfIcon><path d="M3 7 a2 2 0 0 1 2-2 h4 L11 7 H19 a2 2 0 0 1 2 2 V18 a2 2 0 0 1 -2 2 H5 a2 2 0 0 1 -2 -2 Z"/></SfIcon>,
  upload:   <SfIcon d="M12 16 V4 M6 10 L12 4 L18 10 M4 20 H20"/>,
  print:    <SfIcon><path d="M7 9 V3 H17 V9 M5 9 H19 a2 2 0 0 1 2 2 V17 H17 V21 H7 V17 H3 V11 a2 2 0 0 1 2 -2 Z"/></SfIcon>,
  pie:      <SfIcon><path d="M12 3 V12 H21 a9 9 0 1 1 -9 -9 Z"/></SfIcon>,
  trend:    <SfIcon d="M4 17 L9 11 L13 14 L20 6 M20 6 H15 M20 6 V11"/>,
  globe:    <SfIcon><circle cx="12" cy="12" r="9"/><path d="M3 12 H21 M12 3 a13 13 0 0 1 0 18 M12 3 a13 13 0 0 0 0 18"/></SfIcon>,
  settings: <SfIcon><circle cx="12" cy="12" r="3"/><path d="M12 2 V5 M12 19 V22 M4 12 H2 M22 12 H19 M5.6 5.6 L7 7 M17 17 L18.4 18.4 M5.6 18.4 L7 17 M17 7 L18.4 5.6"/></SfIcon>,
  logout:   <SfIcon d="M9 5 H5 a1 1 0 0 0 -1 1 V18 a1 1 0 0 0 1 1 H9 M15 8 L20 12 L15 16 M20 12 H9"/>,
  brand:    <SfIcon><path d="M12 3 L14 9 L20 10 L15 14 L17 20 L12 17 L7 20 L9 14 L4 10 L10 9 Z"/></SfIcon>,
  shield:   <SfIcon d="M12 3 L20 6 V12 c0 5-4 8-8 9 c-4-1-8-4-8-9 V6 Z"/>,
  flag:     <SfIcon d="M5 21 V4 H15 L13 8 L15 12 H5"/>,
  download: <SfIcon d="M12 4 V16 M6 10 L12 16 L18 10 M4 20 H20"/>,
};

// iOS status bar replacement — clean, light-aware
function SfStatusBarIOS({ dark = false, time = '08:42' }) {
  const c = dark ? 'var(--sf-ink)' : 'var(--sf-ink)';
  return (
    <div style={{
      height: 54, padding: '18px 28px 8px',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      fontFamily: 'var(--sf-font-ui)', fontWeight: 600, fontSize: 16, color: c,
      letterSpacing: '-0.01em', position: 'relative', zIndex: 5,
    }}>
      <span>{time}</span>
      <div style={{
        position: 'absolute', left: '50%', top: 12, transform: 'translateX(-50%)',
        width: 110, height: 32, background: '#000', borderRadius: 100,
      }} />
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <svg width="18" height="11" viewBox="0 0 18 11">
          <rect x="0" y="6.5" width="3" height="4.5" rx="0.7" fill={c}/>
          <rect x="4.5" y="4" width="3" height="7" rx="0.7" fill={c}/>
          <rect x="9" y="2" width="3" height="9" rx="0.7" fill={c}/>
          <rect x="13.5" y="0" width="3" height="11" rx="0.7" fill={c}/>
        </svg>
        <svg width="14" height="11" viewBox="0 0 14 11">
          <path d="M7 2.6c1.9 0 3.6 0.7 4.8 1.9l0.9-0.9C11.2 2.1 9.2 1.2 7 1.2C4.8 1.2 2.8 2.1 1.3 3.6l0.9 0.9C3.4 3.3 5.1 2.6 7 2.6Z" fill={c}/>
          <path d="M7 5.5c1.1 0 2.1 0.4 2.8 1.1l0.9-0.9C9.7 4.7 8.4 4 7 4S4.3 4.7 3.3 5.7l0.9 0.9C4.9 5.9 5.9 5.5 7 5.5Z" fill={c}/>
          <circle cx="7" cy="8.5" r="1.2" fill={c}/>
        </svg>
        <svg width="24" height="11" viewBox="0 0 24 11">
          <rect x="0.4" y="0.4" width="20.5" height="10.2" rx="3" stroke={c} strokeOpacity="0.35" fill="none"/>
          <rect x="1.6" y="1.6" width="17.5" height="7.8" rx="1.8" fill={c}/>
          <path d="M22 3.6V7.4c0.7-0.3 1.2-1 1.2-1.9c0-0.9-0.5-1.6-1.2-1.9Z" fill={c} fillOpacity="0.4"/>
        </svg>
      </div>
    </div>
  );
}

// Android status bar — minimal warm
function SfStatusBarAndroid({ dark = false }) {
  const c = 'var(--sf-ink)';
  return (
    <div style={{
      height: 36, padding: '6px 18px 4px',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      fontFamily: 'var(--sf-font-ui)', fontWeight: 500, fontSize: 13, color: c,
      letterSpacing: '0.01em', position: 'relative', zIndex: 5,
    }}>
      <span>08:42</span>
      <div style={{
        position: 'absolute', left: '50%', top: 6, transform: 'translateX(-50%)',
        width: 18, height: 18, background: '#1a1a1a', borderRadius: 100,
      }} />
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <svg width="14" height="10" viewBox="0 0 14 10"><path d="M7 9.5 L0.5 3a8.5 8.5 0 0 1 13 0L7 9.5z" fill={c}/></svg>
        <svg width="14" height="10" viewBox="0 0 14 10"><path d="M12.5 9.5V0.8L1 9.5h11.5z" fill={c}/></svg>
        <svg width="20" height="10" viewBox="0 0 20 10">
          <rect x="0.5" y="0.5" width="17" height="9" rx="2" stroke={c} fill="none"/>
          <rect x="2" y="2" width="14" height="6" rx="1" fill={c}/>
          <rect x="18" y="3" width="1.5" height="4" rx="0.5" fill={c}/>
        </svg>
      </div>
    </div>
  );
}

// Android home indicator pill
function SfNavBarAndroid() {
  return (
    <div style={{
      height: 28, display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: 'transparent',
    }}>
      <div style={{ width: 110, height: 4, borderRadius: 4, background: 'var(--sf-ink)', opacity: 0.55 }} />
    </div>
  );
}

// iOS home indicator
function SfHomeIndicatorIOS() {
  return (
    <div style={{
      position: 'absolute', bottom: 8, left: 0, right: 0,
      display: 'flex', justifyContent: 'center',
      pointerEvents: 'none', zIndex: 30,
    }}>
      <div style={{ width: 134, height: 5, borderRadius: 3, background: 'var(--sf-ink)', opacity: 0.6 }} />
    </div>
  );
}

// Bottom tab bar — shared between platforms (light styling differences)
function SfTabBar({ active = 'home', platform = 'ios' }) {
  const tabs = [
    { id: 'home',   label: 'Bugun',    icon: Icons.home },
    { id: 'cohort', label: 'Guruhlar', icon: Icons.cohort },
    { id: 'tasks',  label: 'Vazifa',   icon: Icons.check },
    { id: 'ai',     label: 'AI',       icon: Icons.ai },
    { id: 'print',  label: 'Print',    icon: Icons.print },
  ];
  return (
    <div style={{
      display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start',
      padding: platform === 'ios' ? '10px 6px 22px' : '10px 6px 12px',
      background: 'var(--sf-surface)',
      borderTop: '1px solid var(--sf-border)',
    }}>
      {tabs.map(t => (
        <div key={t.id} style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          color: active === t.id ? 'var(--sf-primary)' : 'var(--sf-muted)',
          minWidth: 56,
        }}>
          <div style={{ position: 'relative' }}>
            {active === t.id && (
              <div style={{
                position: 'absolute', inset: -7, borderRadius: 14,
                background: 'var(--sf-primary-soft)',
              }} />
            )}
            <div style={{ position: 'relative' }}>{React.cloneElement(t.icon, { size: 22 })}</div>
          </div>
          <span style={{
            fontSize: 10.5, fontWeight: active === t.id ? 700 : 500,
            letterSpacing: '-0.005em',
          }}>{t.label}</span>
        </div>
      ))}
    </div>
  );
}

// Top app bar (Android-style — large title with subtitle)
function SfAppBarAndroid({ title, subtitle, right, left }) {
  return (
    <div style={{
      padding: '8px 18px 14px',
      background: 'var(--sf-surface)',
      borderBottom: '1px solid var(--sf-border)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 36, height: 36, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--sf-ink)' }}>
          {left}
        </div>
        <div style={{ display: 'flex', gap: 4, alignItems: 'center', color: 'var(--sf-ink)' }}>{right}</div>
      </div>
      <div style={{ marginTop: 4 }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.02em', color: 'var(--sf-ink)' }}>{title}</div>
        {subtitle && <div style={{ fontSize: 13, color: 'var(--sf-muted)', marginTop: 2 }}>{subtitle}</div>}
      </div>
    </div>
  );
}

// iOS-style nav bar (compact)
function SfNavBarIOS({ title, left, right, large, subtitle }) {
  return (
    <div style={{
      padding: large ? '8px 20px 16px' : '4px 18px 8px',
      background: 'var(--sf-surface)',
    }}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        minHeight: 44,
      }}>
        <div style={{ minWidth: 60, display: 'flex', alignItems: 'center', gap: 4, color: 'var(--sf-primary)', fontWeight: 600, fontSize: 16 }}>{left}</div>
        {!large && (
          <div style={{ fontWeight: 700, fontSize: 17, color: 'var(--sf-ink)', letterSpacing: '-0.01em' }}>{title}</div>
        )}
        <div style={{ minWidth: 60, display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: 10, color: 'var(--sf-primary)' }}>{right}</div>
      </div>
      {large && (
        <div style={{ marginTop: 6 }}>
          <div style={{ fontSize: 28, fontWeight: 800, letterSpacing: '-0.03em', color: 'var(--sf-ink)' }}>{title}</div>
          {subtitle && <div style={{ fontSize: 13, color: 'var(--sf-muted)', marginTop: 2 }}>{subtitle}</div>}
        </div>
      )}
    </div>
  );
}

// Avatar — gradient circle with initials
function SfAvatar({ name = 'A', size = 36, color }) {
  const initials = name.split(/\s+/).map(s => s[0]).slice(0, 2).join('').toUpperCase();
  // pick stable color from name hash
  const colors = ['#B85535', '#D89A2E', '#4F7B3B', '#2A6F9F', '#7A4A82', '#A55A24', '#3F6E5C'];
  const hash = [...name].reduce((a, c) => a + c.charCodeAt(0), 0) % colors.length;
  const bg = color || colors[hash];
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: bg, color: '#FFFCF5',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: 'var(--sf-font-ui)', fontWeight: 700,
      fontSize: size * 0.4, letterSpacing: '-0.01em',
      flexShrink: 0,
    }}>{initials}</div>
  );
}

// Pill chip used for status, time, badges
function SfPill({ tone = 'neutral', children, style }) {
  return <span className={`sf-chip sf-chip--${tone}`} style={style}>{children}</span>;
}

// AI badge — the signature element
function SfAiBadge({ children = 'AI', compact }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: compact ? '3px 8px' : '5px 10px',
      borderRadius: 999,
      background: 'var(--sf-ai-bg)',
      border: '1px solid var(--sf-ai-border)',
      color: 'var(--sf-ai)',
      fontSize: compact ? 10 : 11,
      fontWeight: 700,
      letterSpacing: '0.06em',
      textTransform: 'uppercase',
    }}>
      <span style={{ fontFamily: 'var(--sf-font-display)', fontStyle: 'italic', fontWeight: 400, fontSize: compact ? 13 : 14, textTransform: 'none', letterSpacing: 0 }}>Ai</span>
      {children !== 'AI' && children}
    </span>
  );
}

// Frame wrapper — applies theme + palette + the sf-app class
function SfFrame({ children, dark, palette, style, platform = 'ios' }) {
  return (
    <div className="sf-app"
         data-theme={dark ? 'dark' : 'light'}
         data-palette={palette || 'saroy'}
         style={{
           width: '100%', height: '100%',
           background: 'var(--sf-bg)',
           display: 'flex', flexDirection: 'column',
           overflow: 'hidden',
           ...style,
         }}>
      {children}
    </div>
  );
}

// Card primitive — physical-feel card with the StarForge star emblem.
// Used for Up Cards (positive) and Down Cards (warning). Card type
// names are dynamic — center admin configures them.
function SfCard({ kind = 'up', size = 'md', recipient, reason, issuer, when, typeName }) {
  // Default name resolution
  const name = typeName || (kind === 'up' ? 'Yulduz karta' : 'Ogohlantirish');
  const palette = kind === 'up'
    ? {
        bg: 'linear-gradient(135deg, #F6E0AC 0%, #E9C272 100%)',
        border: '#C49A3A',
        accent: '#7A4F0E',
        ink: '#3A2406',
        star: '#7A4F0E',
        chip: 'rgba(255,252,245,0.6)',
      }
    : {
        bg: 'linear-gradient(135deg, #F0C9BE 0%, #D88A75 100%)',
        border: '#A14026',
        accent: '#5C1A0C',
        ink: '#2D0F08',
        star: '#5C1A0C',
        chip: 'rgba(255,252,245,0.6)',
      };
  const scale = size === 'sm' ? 0.62 : size === 'lg' ? 1.0 : 0.82;
  return (
    <div style={{
      width: 240 * scale, height: 320 * scale,
      background: palette.bg,
      borderRadius: 14 * scale,
      border: `1px solid ${palette.border}`,
      position: 'relative', overflow: 'hidden',
      padding: 14 * scale,
      display: 'flex', flexDirection: 'column',
      boxShadow: `0 ${6*scale}px ${20*scale}px rgba(54,30,14,0.18), inset 0 1px 0 rgba(255,255,255,0.45)`,
      color: palette.ink,
    }}>
      {/* Decorative star pattern */}
      <div style={{ position: 'absolute', right: -30*scale, top: -30*scale, opacity: 0.18 }}>
        <SfStar size={140 * scale} color={palette.star} />
      </div>
      <div style={{ position: 'absolute', right: -20*scale, bottom: -20*scale, opacity: 0.08 }}>
        <SfStar size={100 * scale} color={palette.star} />
      </div>

      {/* Header row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', position: 'relative' }}>
        <span style={{
          fontSize: 9 * scale, fontWeight: 700, letterSpacing: '0.16em',
          textTransform: 'uppercase', color: palette.accent,
        }}>
          {kind === 'up' ? '↑ UP CARD' : '↓ DOWN CARD'}
        </span>
        <SfStar size={18 * scale} color={palette.star} />
      </div>

      {/* Type label — serif */}
      <div style={{
        marginTop: 8 * scale,
        fontFamily: 'var(--sf-font-display)', fontStyle: 'italic',
        fontSize: 22 * scale, lineHeight: 1.05,
        color: palette.ink,
      }}>{name}</div>

      <div style={{
        marginTop: 10 * scale, padding: `${4*scale}px ${8*scale}px`,
        background: palette.chip, borderRadius: 6 * scale,
        fontSize: 10 * scale, color: palette.accent, fontWeight: 600,
        display: 'inline-block', alignSelf: 'flex-start',
      }}>{recipient || 'Ism Familiya'}</div>

      {/* Reason */}
      <div style={{
        marginTop: 'auto', position: 'relative',
        fontSize: 11 * scale, lineHeight: 1.4, color: palette.ink,
      }}>
        {reason && (
          <div style={{ fontStyle: 'italic', borderLeft: `2px solid ${palette.accent}`,
                          paddingLeft: 8 * scale, opacity: 0.85 }}>
            “{reason}”
          </div>
        )}
        <div style={{ marginTop: 10 * scale, display: 'flex', justifyContent: 'space-between',
                       alignItems: 'flex-end', fontFamily: 'var(--sf-font-mono)',
                       fontSize: 9 * scale, color: palette.accent }}>
          <span>{issuer || 'N. Karimova'}</span>
          <span>{when || '19.05 · 09:42'}</span>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, {
  SfIcon, SfStar, SfWordmark, Icons,
  SfStatusBarIOS, SfStatusBarAndroid, SfNavBarAndroid, SfHomeIndicatorIOS,
  SfTabBar, SfAppBarAndroid, SfNavBarIOS, SfAvatar, SfPill, SfAiBadge, SfFrame,
  SfCard,
});
