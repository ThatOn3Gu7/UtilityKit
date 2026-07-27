import './terminal-shell.css';

/**
 * Shared terminal chrome used by both real and simulated tool players.
 * Keeps every tool's demo visually consistent with the UtilityKit CLI aesthetic.
 */
export default function TerminalShell({ title, subtitle, badge, children, footer }) {
  return (
    <div className="uk-term">
      <div className="uk-term-titlebar">
        <div className="uk-term-dots">
          <span className="uk-dot uk-dot-red" />
          <span className="uk-dot uk-dot-yellow" />
          <span className="uk-dot uk-dot-green" />
        </div>
        <div className="uk-term-title">
          <span className="uk-term-cmd">{title}</span>
          {subtitle && <span className="uk-term-sub">{subtitle}</span>}
        </div>
        {badge && <div className={`uk-term-badge uk-term-badge-${badge.kind || 'live'}`}>{badge.label}</div>}
      </div>
      <div className="uk-term-body">{children}</div>
      {footer && <div className="uk-term-footer">{footer}</div>}
    </div>
  );
}
