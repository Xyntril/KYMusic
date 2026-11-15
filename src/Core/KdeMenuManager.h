#pragma once

#include <QObject>
#include <QPointer>
#include <QMenuBar>
#include <QMenu>
#include <QAction>

class AppController;
class AuthController;
class QWindow;

class KdeMenuManager : public QObject {
  Q_OBJECT

public:
  explicit KdeMenuManager(AppController *appController, AuthController *authController, QObject *parent = nullptr);
  ~KdeMenuManager() override;

  void attachToWindow(QWindow *window);
  QMenuBar *menuBar() const { return m_menuBar; }

private:
  void setupMenus();

  AppController *m_appController = nullptr;
  AuthController *m_authController = nullptr;
  QMenuBar *m_menuBar = nullptr;
};
