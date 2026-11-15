#include "ThemeController.h"

#include <KColorScheme>
#include <KColorSchemeManager>
#include <QGuiApplication>
#include <QPalette>

ThemeController::ThemeController(QObject *parent) : QObject(parent) {
  m_schemeManager = new KColorSchemeManager(this);

  QSettings settings;
  m_themeMode = settings.value(QStringLiteral("theme/mode"), QStringLiteral("system")).toString();
  m_manualDark = settings.value(QStringLiteral("theme/dark"), false).toBool();

  reloadColors();

  if (qApp) {
    connect(qApp, &QGuiApplication::paletteChanged, this, [this](const QPalette &) {
      reloadColors();
    });
  }
}

ThemeController::~ThemeController() = default;

QString ThemeController::themeMode() const {
  return QStringLiteral("system");
}

bool ThemeController::isSystemTheme() const {
  return true;
}

bool ThemeController::darkTheme() const {
  // В системной теме KDE Plasma режим определяется по яркости фона окна
  return m_systemWindowBackground.lightnessF() < 0.5;
}

void ThemeController::setThemeMode(const QString &mode) {
  Q_UNUSED(mode);
  m_themeMode = QStringLiteral("system");
  emit themeModeChanged();
  emit darkThemeChanged();
  emit paletteChanged();
}

void ThemeController::setDarkTheme(bool dark) {
  Q_UNUSED(dark);
  // Приложение управляется системными настройками KDE Plasma
  emit darkThemeChanged();
}

void ThemeController::reloadColors() {
  KColorScheme windowScheme(QPalette::Active, KColorScheme::Window);
  KColorScheme viewScheme(QPalette::Active, KColorScheme::View);
  KColorScheme buttonScheme(QPalette::Active, KColorScheme::Button);
  KColorScheme selectionScheme(QPalette::Active, KColorScheme::Selection);

  m_systemWindowBackground = windowScheme.background().color();
  m_systemViewBackground = viewScheme.background().color();
  m_systemAlternateBackground = viewScheme.background(KColorScheme::AlternateBackground).color();
  m_systemTextColor = viewScheme.foreground().color();
  m_systemSubtextColor = viewScheme.foreground(KColorScheme::InactiveText).color();
  m_systemHighlightColor = selectionScheme.background().color();
  m_systemHighlightedTextColor = selectionScheme.foreground().color();
  m_systemBorderColor = windowScheme.shade(KColorScheme::MidShade);
  m_systemDividerColor = windowScheme.shade(KColorScheme::MidShade);
  m_systemButtonBackground = buttonScheme.background().color();
  m_systemButtonText = buttonScheme.foreground().color();

  QColor hover = m_systemHighlightColor;
  hover.setAlpha(45);
  m_systemHoverColor = hover;

  emit paletteChanged();
  emit darkThemeChanged();
}

QColor ThemeController::systemWindowBackground() const { return m_systemWindowBackground; }
QColor ThemeController::systemViewBackground() const { return m_systemViewBackground; }
QColor ThemeController::systemAlternateBackground() const { return m_systemAlternateBackground; }
QColor ThemeController::systemTextColor() const { return m_systemTextColor; }
QColor ThemeController::systemSubtextColor() const { return m_systemSubtextColor; }
QColor ThemeController::systemHighlightColor() const { return m_systemHighlightColor; }
QColor ThemeController::systemHighlightedTextColor() const { return m_systemHighlightedTextColor; }
QColor ThemeController::systemHoverColor() const { return m_systemHoverColor; }
QColor ThemeController::systemBorderColor() const { return m_systemBorderColor; }
QColor ThemeController::systemDividerColor() const { return m_systemDividerColor; }
QColor ThemeController::systemButtonBackground() const { return m_systemButtonBackground; }
QColor ThemeController::systemButtonText() const { return m_systemButtonText; }
