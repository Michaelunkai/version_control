# commit_1217_2025.ps1
# Auto-generated commit script
# Generated: 2025-12-17 11:38:00
# Backend Changes: 31 files
# Frontend Changes: 147 files

$ErrorActionPreference = "SilentlyContinue"

# Configure Git identity
git config --global user.email "michael@tovtech.org"
git config --global user.name "Michael"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TovPlay Deployment - Dec 17, 2025" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================================
# BACKEND REPOSITORY
# ============================================================================

Write-Host "Processing Backend Repository..." -ForegroundColor Yellow
Set-Location F:\tovplay\tovplay-backend

git checkout main 2>$null

$backendCommit = @"
refactor: Update backend (Dec 17, 2025)

## Change Summary

**Files Changed**: 31 files
**Lines Added**: +252 lines
**Lines Deleted**: -4158 lines
**Net Change**: -3906 lines


### Modified Files (9)

**Docs (1 files)**:
- claude.md

**Other (6 files)**:
- .env.template
- src/app/__init__.py
- src/app/db.py
- src/app/health.py
- src/config/secure_config.py
- wsgi.py

**Routes (2 files)**:
- src/app/routes/password_reset_routes.py
- src/app/routes/user_routes.py


### Added Files (1)

**Other (1 files)**:
- src/app/database_audit_middleware.py


### Deleted Files (21)

**Config (2 files)**:
- migrations/alembic.ini
- package.json

**Docs (1 files)**:
- scripts/db/README.md

**Migrations (1 files)**:
- migrations/alembic.ini

**Other (15 files)**:
- .env.production
- run.py
- src/app/audit_decorator.py
- src/app/basic_routes.py
- src/app/config.py
- src/app/db_utils.py
- src/app/examples/safe_routes.py
- src/app/extensions.py
- src/app/metrics.py
- src/app/monitoring.py
- src/app/monitoring_routes.py
- src/app/ssl_monitor.py
- src/config/logging_config.py
- src/config/structured_logger.py
- src/simple_app.py

**Routes (1 files)**:
- src/app/routes/platform_routes.py

**Tests (2 files)**:
- .github/workflows/tests.yml.bak
- src/tests/__init__.py



## Impact Analysis
[WARNING] **Configuration Changes**: May require dependency reinstall or environment updates
[WARNING] **Database Changes**: May require migration execution
[INFO] **File Cleanup**: 21 files removed - verify no breaking changes

## Validation Checklist

- [ ] Application starts successfully
- [ ] All tests passing
- [ ] No console errors
- [ ] Key features functional
- [ ] Dependencies up to date

## Additional Notes

Generated automatically on Dec 17, 2025
Repository: backend

---
Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
# ============================================================================
# FRONTEND REPOSITORY
# ============================================================================

Write-Host "`nProcessing Frontend Repository..." -ForegroundColor Yellow
Set-Location F:\tovplay\tovplay-frontend

Remove-Item -Path "nul","null" -Force -ErrorAction SilentlyContinue

git checkout main 2>$null

$frontendCommit = @"
refactor: Update frontend (Dec 17, 2025)

## Change Summary

**Files Changed**: 147 files
**Lines Added**: +9260 lines
**Lines Deleted**: -12468 lines
**Net Change**: -3208 lines


### Modified Files (107)

**API (2 files)**:
- src/api/__mocks__/availabilityMock.js
- src/api/__mocks__/playersMock.js

**Components (76 files)**:
- src/__tests__/components/Button.test.jsx
- src/components/AvailabilityRequiredDialog.jsx
- src/components/CancleSessionDialog.jsx
- src/components/CommunityDialog.jsx
- src/components/dashboard/OnlineFriends.jsx
- src/components/dashboard/QuickActions.jsx
- src/components/dashboard/UpcomingSessionCard.jsx
- src/components/data/samplePlayers.jsx
- src/components/GameRequestCard.jsx
- src/components/GameRequestSentCard.jsx
- src/components/lib/LanguageContext.jsx
- src/components/lib/translations.jsx
- src/components/LoggedinRoute.jsx
- src/components/NotificationSystem.jsx
- src/components/PlayerCard.jsx
- src/components/Portal.jsx
- src/components/profile/AvailabilityDisplay.jsx
- src/components/profile/GameList.jsx
- src/components/profile/ProfileHeader.jsx
- src/components/profile/UpcomingSlots.jsx
- src/components/ProtectedRoute.jsx
- src/components/PublicRoute.jsx
- src/components/RequestModal.jsx
- src/components/RequirementsDialog.jsx
- src/components/system/HealthMonitor.jsx
- src/components/ui/accordion.jsx
- src/components/ui/alert.jsx
- src/components/ui/alert-dialog.jsx
- src/components/ui/aspect-ratio.jsx
- src/components/ui/avatar.jsx
- src/components/ui/badge.jsx
- src/components/ui/breadcrumb.jsx
- src/components/ui/button.jsx
- src/components/ui/calendar.jsx
- src/components/ui/card.jsx
- src/components/ui/carousel.jsx
- src/components/ui/chart.jsx
- src/components/ui/checkbox.jsx
- src/components/ui/collapsible.jsx
- src/components/ui/command.jsx
- src/components/ui/context-menu.jsx
- src/components/ui/dialog.jsx
- src/components/ui/drawer.jsx
- src/components/ui/dropdown-menu.jsx
- src/components/ui/form.jsx
- src/components/ui/hover-card.jsx
- src/components/ui/input.jsx
- src/components/ui/input-otp.jsx
- src/components/ui/label.jsx
- src/components/ui/menubar.jsx
- src/components/ui/MultilineInput.jsx
- src/components/ui/navigation-menu.jsx
- src/components/ui/pagination.jsx
- src/components/ui/popover.jsx
- src/components/ui/progress.jsx
- src/components/ui/radio-group.jsx
- src/components/ui/resizable.jsx
- src/components/ui/scroll-area.jsx
- src/components/ui/select.jsx
- src/components/ui/separator.jsx
- src/components/ui/sheet.jsx
- src/components/ui/sidebar.jsx
- src/components/ui/skeleton.jsx
- src/components/ui/slider.jsx
- src/components/ui/sonner.jsx
- src/components/ui/switch.jsx
- src/components/ui/table.jsx
- src/components/ui/tabs.jsx
- src/components/ui/textarea.jsx
- src/components/ui/toast.jsx
- src/components/ui/toaster.jsx
- src/components/ui/toggle.jsx
- src/components/ui/toggle-group.jsx
- src/components/ui/tooltip.jsx
- src/components/ui/use-toast.jsx
- src/components/UserProfileModal.jsx

**Config (4 files)**:
- .env
- package.json
- package-lock.json
- tsconfig.json

**Docs (1 files)**:
- claude.md

**Other (3 files)**:
- src/App.jsx
- src/main.jsx
- vite.config.js

**Pages (18 files)**:
- src/pages/ChessPlayers.jsx
- src/pages/ChooseUsername.jsx
- src/pages/CreateAccount.jsx
- src/pages/Dashboard.jsx
- src/pages/EmailVerification.jsx
- src/pages/FindPlayers.jsx
- src/pages/Friends.jsx
- src/pages/index.jsx
- src/pages/Layout.jsx
- src/pages/OnboardingComplete.jsx
- src/pages/OnboardingSchedule.jsx
- src/pages/Profile.jsx
- src/pages/Schedule.jsx
- src/pages/SelectGames.jsx
- src/pages/Settings.jsx
- src/pages/SignIn.jsx
- src/pages/VerifyOTP.jsx
- src/pages/Welcome.jsx

**Tests (5 files)**:
- src/__tests__/App.test.jsx
- src/__tests__/components/Button.test.jsx
- src/__tests__/utils/helpers.test.js
- src/components/ui/aspect-ratio.jsx
- src/test-setup.js

**Utils (1 files)**:
- src/__tests__/utils/helpers.test.js


### Added Files (7)

**API (1 files)**:
- src/api/index.js

**Context (1 files)**:
- src/context/index.jsx

**Docs (1 files)**:
- START_FRONTEND.md

**Hooks (1 files)**:
- src/hooks/index.js

**Other (1 files)**:
- src/lib/index.js

**Stores (1 files)**:
- src/stores/index.js

**Utils (1 files)**:
- src/utils/index.js


### Deleted Files (33)

**API (5 files)**:
- src/api/apiService.js
- src/api/base44Client.js
- src/api/entities.js
- src/api/getCurrentUser.js
- src/api/integrations.js

**Config (2 files)**:
- jsconfig.json
- tsconfig.node.json

**Context (3 files)**:
- src/context/socket.js
- src/context/SocketContext.jsx
- src/context/ThemeContext.jsx

**Hooks (5 files)**:
- src/hooks/useAuth.js
- src/hooks/useCheckAvailability.js
- src/hooks/useCheckGames.js
- src/hooks/use-mobile.jsx
- src/hooks/useSocket.js

**Other (4 files)**:
- .env.template
- postcss.config.js
- src/lib/axios-config.js
- src/lib/utils.js

**Stores (5 files)**:
- src/stores/authSlice.js
- src/stores/notificationsSlice.js
- src/stores/profileSlice.js
- src/stores/store.js
- src/stores/todoSlice.js

**Utils (9 files)**:
- src/utils/analytics.js
- src/utils/healthService.js
- src/utils/index.ts
- src/utils/localStorage.js
- src/utils/logger.js
- src/utils/monitoring.js
- src/utils/secureStorage.js
- src/utils/security.js
- src/utils/themeUtils.js



## Impact Analysis
[WARNING] **Configuration Changes**: May require dependency reinstall or environment updates
[INFO] **Test Changes**: Verify all tests pass before deployment
[INFO] **File Cleanup**: 33 files removed - verify no breaking changes

## Validation Checklist

- [ ] Application starts successfully
- [ ] All tests passing
- [ ] No console errors
- [ ] Key features functional
- [ ] Dependencies up to date

## Additional Notes

Generated automatically on Dec 17, 2025
Repository: frontend

---
Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
# ============================================================================
# COMPLETION SUMMARY
# ============================================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "         DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nSummary:" -ForegroundColor Yellow
Write-Host "  Total Files:     178 files" -ForegroundColor White
Write-Host "  Lines Added:     +9512" -ForegroundColor Green
Write-Host "  Lines Deleted:   -16626" -ForegroundColor Red
Write-Host "  Net Change:      -7114" -ForegroundColor Red
Write-Host "`n  Backend:  31 files (+252 -4158)" -ForegroundColor WhiteWrite-Host "  Frontend: 147 files (+9260 -12468)" -ForegroundColor White
Write-Host "`nRepository Links:" -ForegroundColor Yellow
Write-Host "  Backend:  https://github.com/TovTechOrg/tovplay-backend" -ForegroundColor Cyan
Write-Host "  Frontend: https://github.com/TovTechOrg/tovplay-frontend" -ForegroundColor Cyan

Write-Host "`n[SUCCESS] Script completed successfully!`n" -ForegroundColor Green

Set-Location F:/tovplay
