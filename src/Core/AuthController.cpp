#include "AuthController.h"
#include "../Yandex/Account/AccountService.h"
#include "../Yandex/Auth/YandexAuth.h"

AuthController::AuthController(YandexAuth *auth, AccountService *accountService, QObject *parent)
    : QObject(parent), m_auth(auth), m_accountService(accountService) {
  Q_ASSERT(m_auth != nullptr);
  Q_ASSERT(m_accountService != nullptr);

  m_authenticated = m_auth->isAuthenticated();

  connect(m_accountService, &AccountService::accountReceived, this, [this](const Account &account) {
    m_account = account;
    const bool wasAuthenticated = m_authenticated;
    m_authenticated = true;
    emit accountChanged();
    if (wasAuthenticated != m_authenticated) emit authenticatedChanged();
  });

  connect(m_accountService, &AccountService::errorOccurred, this, [this](const QString &message) {
    if (!m_auth->isAuthenticated() || message.contains(QStringLiteral("token"), Qt::CaseInsensitive) ||
        message.contains(QStringLiteral("401")) || message.contains(QStringLiteral("403"))) {
      const bool wasAuthenticated = m_authenticated;
      m_authenticated = false;
      if (wasAuthenticated != m_authenticated) emit authenticatedChanged();
    }
    emit errorOccurred(message);
  });

  if (m_authenticated) {
    loadAccount();
  }
}

bool AuthController::authenticated() const {
  return m_authenticated;
}

QString AuthController::displayName() const {
  return m_account.displayName;
}

QString AuthController::login() const {
  return m_account.login;
}

QString AuthController::extractToken(const QString &input) const {
  const QString value = input.trimmed();
  const QString marker = "access_token=";
  const int start = value.indexOf(marker);

  // Обычный токен — оставляем как есть.
  if (start < 0) return value;
  const int tokenStart = start + marker.length();
  const int tokenEnd = value.indexOf('&', tokenStart);
  if (tokenEnd < 0) return value.mid(tokenStart).trimmed();
  return value.mid(tokenStart, tokenEnd - tokenStart).trimmed();
}

void AuthController::loginWithToken(const QString &token) {
  const QString extractedToken = extractToken(token);

  if (extractedToken.isEmpty()) {
    emit errorOccurred("Не удалось найти OAuth-токен");
    return;
  }

  if (!m_auth->setToken(extractedToken)) {
    emit errorOccurred("Не удалось сохранить токен");
    return;
  }

  const bool wasAuthenticated = m_authenticated;
  m_authenticated = true;
  if (!wasAuthenticated) {
    emit authenticatedChanged();
  }

  loadAccount();
}

void AuthController::logout() {
  m_auth->clearToken();

  m_account = Account{};
  const bool wasAuthenticated = m_authenticated;
  m_authenticated = false;
  emit accountChanged();
  if (wasAuthenticated != m_authenticated) {
    emit authenticatedChanged();
  }
}

void AuthController::loadAccount() {
  m_accountService->loadAccount();
}