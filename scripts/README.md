# Upstream Sync Scripts

Diese Scripts helfen dabei, Updates vom Original-Repository (borb/amigahid-pico) zu holen und in deinen Fork zu integrieren.

## Übersicht

| Script | Funktion |
|--------|----------|
| `status-upstream.ps1` | Zeigt wie viele Commits du hinter borb bist |
| `sync-upstream.ps1` | Holt Updates in einen Test-Branch |
| `merge-upstream.ps1` | Merged getestete Updates in main |

## Täglicher Workflow

```powershell
# 1. Prüfen ob borb Updates hat
.\scripts\status-upstream.ps1

# 2. Wenn Updates vorhanden: Holen und testen
.\scripts\sync-upstream.ps1
# → Du bist jetzt auf "upstream-test" Branch
# → Bauen: cmd /c build-pico2.cmd
# → Flashen und testen auf Hardware

# 3. Wenn alles funktioniert: in main übernehmen
.\scripts\merge-upstream.ps1

# 4. In deinen GitHub-Fork pushen
git push origin main
```

## Branch-Strategie

```
main ─────────────────────────────────────► (produktiv, getestet)
  │                                              ↑
  │  merge wenn Tests OK                         │
  ↓                                              │
upstream-test ←── fetch borb/main ──────────────┘
```

- **main**: Dein produktiver Code + deine Anpassungen (VSCode configs etc.)
- **upstream-test**: Temporärer Branch zum Testen von borb's Updates

## Git Remotes

Nach dem Setup hast du zwei Remotes:

| Remote | URL | Zweck |
|--------|-----|-------|
| `origin` | github.com/Klaus-Kupferschmid/amigahid-pico | Dein Fork |
| `upstream` | github.com/borb/amigahid-pico | Original-Repository |

Prüfen mit: `git remote -v`

## Tipps

### Zurück zu main ohne merge
```powershell
git checkout main
```

### Merge abbrechen bei Konflikten
```powershell
git merge --abort
```

### Stash verwenden für temporäre Änderungen
```powershell
git stash push -m "Meine temporären Änderungen"
# ... arbeiten ...
git stash pop
```

### Nur bestimmte Commits übernehmen (cherry-pick)
```powershell
git checkout main
git cherry-pick <commit-hash>
```

## Fehlerbehebung

### "Could not access submodule"
Das pico-sdk Submodule hat manchmal andere Commit-Referenzen. Nach einem Merge:
```powershell
git submodule update --init --recursive
```

### Merge-Konflikte
1. Konflikte in den Dateien manuell lösen (Suche nach `<<<<<<<`)
2. `git add <datei>`
3. `git commit`

Oder abbrechen: `git merge --abort`
