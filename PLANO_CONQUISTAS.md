# Plano: Integrar Conquistas do Google Play Games Services

## 1. Configurar Google Cloud Console

- Acessar https://console.cloud.google.com
- Criar um projeto (ou usar o existente do app)
- Ativar a API "Google Play Games Services"
- Em Credenciais > Tela de consentimento OAuth: configurar como "Externo"
- Em Credenciais > Criar credencial OAuth 2.0:
  - Tipo: Android
  - Package name: `com.godot.gameJumper`
  - SHA-1: obter com `keytool -list -v -keystore sua_keystore.jks`
- Anotar o Client ID gerado

## 2. Configurar Google Play Console

- Acessar https://play.google.com/console
- Ir em **Crescimento > Servicos de jogos do Play > Configuracao**
- Criar um novo jogo ou vincular ao existente
- Vincular o projeto do Google Cloud (Client ID do passo anterior)
- Ir em **Conquistas** e criar cada uma:

### Sugestoes de conquistas

| Nome | Descricao | Tipo | Condicao no codigo |
|---|---|---|---|
| Primeiro Salto | Capture seu primeiro circulo | Padrao | score >= 1 |
| Iniciante | Alcance 10 pontos | Padrao | score >= 10 |
| Veterano | Alcance 50 pontos | Padrao | score >= 50 |
| Mestre | Alcance 100 pontos | Padrao | score >= 100 |
| Lenda | Alcance 200 pontos | Padrao | score >= 200 |
| Nivel 5 | Alcance o nivel 5 | Padrao | level >= 5 |
| Nivel 10 | Alcance o nivel 10 | Padrao | level >= 10 |
| Nivel 20 | Alcance o nivel 20 | Padrao | level >= 20 |
| Persistente | Jogue 50 partidas | Incremental (50) | death_count total |
| Viciado | Jogue 200 partidas | Incremental (200) | death_count total |
| Combo x5 | Consiga bonus de 5 em uma partida | Padrao | bonus >= 5 |
| Combo x10 | Consiga bonus de 10 em uma partida | Padrao | bonus >= 10 |

- Anotar o ID de cada conquista (formato `CgkI...`)
- Publicar as conquistas

## 3. Instalar plugin no Godot

- Plugin recomendado: PGSGP (Play Games Services Godot Plugin)
  - Repo: https://github.com/Cgisca/PGSGP
  - Verificar releases para versao compativel com Godot 4.6
- Alternativa: Android Plugin Bridge do Godot 4 (chamar a API Java diretamente)
- Instalar seguindo as instrucoes do repositorio (copiar addons + android plugin)

## 4. Codigo

### 4.1 Adicionar variaveis em settings.gd

```gdscript
var total_games_played = 0
var games_file = "user://games_played.save"

# IDs das conquistas (trocar pelos IDs reais do Play Console)
var achievements = {
    "first_jump": "CgkI...",
    "score_10": "CgkI...",
    "score_50": "CgkI...",
    "score_100": "CgkI...",
    "score_200": "CgkI...",
    "level_5": "CgkI...",
    "level_10": "CgkI...",
    "level_20": "CgkI...",
    "persistent": "CgkI...",
    "addicted": "CgkI...",
    "combo_5": "CgkI...",
    "combo_10": "CgkI...",
}
```

### 4.2 Inicializar no Main.gd

```gdscript
func _ready():
    if is_mobile:
        PlayGamesServices.sign_in()
```

### 4.3 Verificar conquistas nos momentos certos

No `set_score()`:
```gdscript
if score >= 1:
    PlayGamesServices.unlock_achievement(Settings.achievements["first_jump"])
if score >= 10:
    PlayGamesServices.unlock_achievement(Settings.achievements["score_10"])
# ... etc
```

No `_on_Jumper_captured()` quando o level sobe:
```gdscript
if level >= 5:
    PlayGamesServices.unlock_achievement(Settings.achievements["level_5"])
# ... etc
```

No `set_bonus()`:
```gdscript
if bonus >= 5:
    PlayGamesServices.unlock_achievement(Settings.achievements["combo_5"])
if bonus >= 10:
    PlayGamesServices.unlock_achievement(Settings.achievements["combo_10"])
```

No `_on_Jumper_died()`:
```gdscript
Settings.total_games_played += 1
Settings.save_games_played()
PlayGamesServices.increment_achievement(Settings.achievements["persistent"], 1)
PlayGamesServices.increment_achievement(Settings.achievements["addicted"], 1)
```

## 5. Testar

1. Adicionar conta de teste no Play Console (Servicos de jogos > Testadores)
2. Exportar APK assinado com a mesma keystore do SHA-1 cadastrado
3. Instalar no device e verificar:
   - Login automatico ao abrir o app
   - Pop-up de conquista desbloqueada ao atingir condicoes
   - Conquistas visiveis no app Google Play Games

## 6. Checklist final

- [ ] Todas as conquistas criadas no Play Console
- [ ] IDs das conquistas preenchidos no codigo
- [ ] SHA-1 da keystore de release cadastrado no Google Cloud
- [ ] Conta de teste adicionada no Play Console
- [ ] Testado em device fisico com login Google
- [ ] Conquistas publicadas (nao apenas em rascunho)
